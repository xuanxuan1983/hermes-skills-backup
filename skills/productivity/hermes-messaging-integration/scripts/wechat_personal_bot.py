#!/usr/bin/env python3
"""
个人微信机器人集成 Hermes AI
使用 itchat 库实现个人微信与 Hermes 的集成
"""

import itchat
import requests
import json
import time
import threading
import queue
import logging
from pathlib import Path
from typing import Dict, Optional
import hashlib

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class WeChatHermesBot:
    def __init__(self, hermes_endpoint: str = "http://localhost:8080"):
        self.hermes_endpoint = hermes_endpoint.rstrip('/')
        self.user_sessions = {}  # 用户会话管理
        self.message_queue = queue.Queue()
        self.processing_thread = None
        self.running = False
        
        # 配置文件路径
        self.config_file = Path.home() / ".hermes" / "wechat_bot_config.json"
        self.load_config()
    
    def load_config(self):
        """加载配置文件"""
        if self.config_file.exists():
            with open(self.config_file, 'r', encoding='utf-8') as f:
                config = json.load(f)
                self.hermes_endpoint = config.get('hermes_endpoint', self.hermes_endpoint)
                self.auto_reply = config.get('auto_reply', True)
                self.allowed_users = config.get('allowed_users', [])  # 空列表表示允许所有用户
                self.admin_users = config.get('admin_users', [])
        else:
            # 创建默认配置
            self.save_config()
    
    def save_config(self):
        """保存配置文件"""
        config = {
            'hermes_endpoint': self.hermes_endpoint,
            'auto_reply': getattr(self, 'auto_reply', True),
            'allowed_users': getattr(self, 'allowed_users', []),
            'admin_users': getattr(self, 'admin_users', [])
        }
        
        self.config_file.parent.mkdir(parents=True, exist_ok=True)
        with open(self.config_file, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2, ensure_ascii=False)
    
    def get_user_id(self, user) -> str:
        """获取用户唯一标识"""
        # 使用微信号或昵称的哈希作为用户ID
        user_info = user.get('NickName', '') + user.get('UserName', '')
        return hashlib.md5(user_info.encode()).hexdigest()[:12]
    
    def is_user_allowed(self, user) -> bool:
        """检查用户是否被允许使用机器人"""
        if not self.allowed_users:  # 空列表表示允许所有用户
            return True
        
        user_id = self.get_user_id(user)
        nickname = user.get('NickName', '')
        return user_id in self.allowed_users or nickname in self.allowed_users
    
    def is_admin_user(self, user) -> bool:
        """检查是否为管理员用户"""
        user_id = self.get_user_id(user)
        nickname = user.get('NickName', '')
        return user_id in self.admin_users or nickname in self.admin_users
    
    async def send_to_hermes(self, message: str, user_id: str, user_info: Dict) -> str:
        """将消息发送给 Hermes AI 处理"""
        try:
            # 构建请求数据
            request_data = {
                "message": message,
                "user_id": user_id,
                "platform": "wechat_personal",
                "user_context": {
                    "nickname": user_info.get('NickName', ''),
                    "sex": user_info.get('Sex', 0),
                    "city": user_info.get('City', ''),
                    "province": user_info.get('Province', '')
                }
            }
            
            # 发送请求到 Hermes API
            response = requests.post(
                f"{self.hermes_endpoint}/api/chat",
                json=request_data,
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                return result.get("response", "抱歉，我现在无法处理您的消息。")
            else:
                logger.error(f"Hermes API 返回错误: {response.status_code}")
                return "服务暂时繁忙，请稍后再试。"
                
        except requests.exceptions.Timeout:
            logger.error("请求 Hermes API 超时")
            return "处理时间较长，请稍后再试。"
        except requests.exceptions.ConnectionError:
            logger.error("无法连接到 Hermes API")
            return "服务暂时不可用，请稍后再试。"
        except Exception as e:
            logger.error(f"处理消息时出错: {e}")
            return f"处理消息时出现错误: {str(e)}"
    
    def process_message_queue(self):
        """处理消息队列"""
        while self.running:
            try:
                message_data = self.message_queue.get(timeout=1)
                if message_data is None:
                    break
                
                msg, sender = message_data
                user_id = self.get_user_id(sender)
                
                # 发送到 Hermes 处理
                import asyncio
                response = asyncio.run(self.send_to_hermes(
                    msg['Text'], 
                    user_id, 
                    sender
                ))
                
                # 回复消息
                msg.reply(response)
                
                logger.info(f"已回复用户 {sender.get('NickName', 'Unknown')}: {response[:50]}...")
                
            except queue.Empty:
                continue
            except Exception as e:
                logger.error(f"处理消息队列时出错: {e}")
    
    def handle_text_message(self, msg):
        """处理文本消息"""
        sender = msg['FromUserName']
        text = msg['Text']
        
        # 获取发送者信息
        sender_info = itchat.search_friends(userName=sender)
        if not sender_info:
            return
        
        sender_info = sender_info[0]
        
        # 检查用户权限
        if not self.is_user_allowed(sender_info):
            logger.info(f"拒绝未授权用户 {sender_info.get('NickName', 'Unknown')}")
            return
        
        # 处理管理员命令
        if self.is_admin_user(sender_info) and text.startswith('/admin'):
            self.handle_admin_command(msg, text)
            return
        
        # 过滤系统消息和特殊消息
        if text.startswith('http://') or '邀请你加入了群聊' in text:
            return
        
        logger.info(f"收到消息 - 用户: {sender_info.get('NickName', 'Unknown')}, 内容: {text[:30]}...")
        
        # 将消息加入处理队列
        self.message_queue.put((msg, sender_info))
    
    def handle_admin_command(self, msg, command: str):
        """处理管理员命令"""
        parts = command.split()
        cmd = parts[0] if parts else ""
        
        if cmd == '/admin_status':
            status_info = f"""
🤖 微信 Hermes 机器人状态
━━━━━━━━━━━━━━━━━━━━
🟢 运行状态: 正常
📊 队列消息: {self.message_queue.qsize()}
👥 活跃会话: {len(self.user_sessions)}
🔗 Hermes API: {self.hermes_endpoint}
━━━━━━━━━━━━━━━━━━━━
使用 /admin_help 查看更多命令
            """
            msg.reply(status_info)
            
        elif cmd == '/admin_help':
            help_text = """
🛠️ 管理员命令列表
━━━━━━━━━━━━━━━━━━━━
/admin_status - 查看机器人状态
/admin_users - 管理授权用户
/admin_config - 查看配置信息
/admin_restart - 重启机器人服务
/admin_help - 显示此帮助
━━━━━━━━━━━━━━━━━━━━
            """
            msg.reply(help_text)
            
        elif cmd == '/admin_config':
            config_info = f"""
⚙️ 当前配置
━━━━━━━━━━━━━━━━━━━━
🔗 Hermes 端点: {self.hermes_endpoint}
✅ 自动回复: {'开启' if getattr(self, 'auto_reply', True) else '关闭'}
👥 授权用户数: {len(getattr(self, 'allowed_users', []))}
👑 管理员数: {len(getattr(self, 'admin_users', []))}
━━━━━━━━━━━━━━━━━━━━
            """
            msg.reply(config_info)
        
        else:
            msg.reply("未知的管理员命令，使用 /admin_help 查看可用命令")
    
    def handle_group_message(self, msg):
        """处理群组消息"""
        # 只在被@的时候回复群消息
        if itchat.search_friends(userName=msg['FromUserName']):
            # 获取自己的昵称
            self_nickname = itchat.search_friends()[0]['NickName']
            
            # 检查是否被@
            if f"@{self_nickname}" in msg['Text']:
                # 移除@标记
                text = msg['Text'].replace(f"@{self_nickname}", "").strip()
                
                # 创建修改后的消息对象进行处理
                modified_msg = msg.copy()
                modified_msg['Text'] = text
                self.handle_text_message(modified_msg)
    
    def start_bot(self):
        """启动机器人"""
        logger.info("启动微信 Hermes 机器人...")
        
        # 启动消息处理线程
        self.running = True
        self.processing_thread = threading.Thread(target=self.process_message_queue)
        self.processing_thread.daemon = True
        self.processing_thread.start()
        
        # 注册消息处理器
        @itchat.msg_register(itchat.content.TEXT, isFriendChat=True)
        def text_reply(msg):
            self.handle_text_message(msg)
        
        @itchat.msg_register(itchat.content.TEXT, isGroupChat=True)
        def group_reply(msg):
            self.handle_group_message(msg)
        
        @itchat.msg_register([itchat.content.PICTURE, itchat.content.RECORDING, 
                             itchat.content.ATTACHMENT, itchat.content.VIDEO])
        def media_reply(msg):
            # 下载媒体文件并发送给 Hermes 处理
            try:
                filename = msg.download()
                sender_info = itchat.search_friends(userName=msg['FromUserName'])[0]
                
                if not self.is_user_allowed(sender_info):
                    return
                
                # 发送文件信息给 Hermes
                file_info = f"用户发送了文件: {filename}"
                msg.reply("我收到了您的文件，正在处理中...")
                
                # 这里可以扩展文件处理逻辑
                
            except Exception as e:
                logger.error(f"处理媒体文件时出错: {e}")
                msg.reply("处理文件时出现问题，请稍后再试。")
        
        # 登录并启动
        try:
            logger.info("正在登录微信...")
            itchat.login(enableCmdQR=True, hotReload=True)
            
            logger.info("✅ 微信登录成功！机器人已启动")
            logger.info(f"🔗 Hermes 端点: {self.hermes_endpoint}")
            
            # 向自己发送启动消息
            itchat.send("🤖 Hermes AI 机器人已启动！", toUserName='filehelper')
            
            # 开始运行
            itchat.run()
            
        except KeyboardInterrupt:
            logger.info("用户中断，正在停止机器人...")
            self.stop_bot()
        except Exception as e:
            logger.error(f"机器人运行出错: {e}")
            self.stop_bot()
    
    def stop_bot(self):
        """停止机器人"""
        logger.info("正在停止机器人...")
        self.running = False
        
        if self.processing_thread:
            self.message_queue.put(None)  # 发送停止信号
            self.processing_thread.join(timeout=5)
        
        logger.info("机器人已停止")

def main():
    print("🤖 微信 Hermes AI 机器人")
    print("=" * 40)
    
    # 检查依赖
    try:
        import itchat
        import requests
    except ImportError as e:
        print(f"❌ 缺少依赖库: {e}")
        print("请安装: pip install itchat requests")
        return
    
    # 获取配置
    hermes_endpoint = input("请输入 Hermes 端点 (默认: http://localhost:8080): ").strip()
    if not hermes_endpoint:
        hermes_endpoint = "http://localhost:8080"
    
    # 创建机器人实例
    bot = WeChatHermesBot(hermes_endpoint)
    
    # 配置管理员
    print("\n设置管理员用户 (可选):")
    while True:
        admin = input("输入管理员微信昵称 (回车结束): ").strip()
        if not admin:
            break
        if not hasattr(bot, 'admin_users'):
            bot.admin_users = []
        bot.admin_users.append(admin)
        print(f"✅ 已添加管理员: {admin}")
    
    # 保存配置
    bot.save_config()
    
    print("\n🚀 启动机器人...")
    print("扫码登录后，机器人将自动开始工作")
    print("发送消息给机器人测试功能")
    print("按 Ctrl+C 停止机器人")
    
    # 启动机器人
    bot.start_bot()

if __name__ == "__main__":
    main()