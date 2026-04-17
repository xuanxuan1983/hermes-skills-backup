---
name: hermes-messaging-integration
title: Hermes AI 消息平台集成指南
description: 完整的 Hermes AI 接入飞书、个人微信、企业微信等消息平台的配置和使用指南
tags: [feishu, wechat, telegram, discord, messaging, integration, hermes, automation]
---

# Hermes AI 消息平台集成指南

## 🎯 支持的平台

Hermes AI 原生支持以下消息平台：

### 官方支持平台
- ✅ **飞书 / Lark (Feishu)** - 企业级即时通讯
- ✅ **企业微信 (WeCom)** - 腾讯企业通讯解决方案
- ✅ **Telegram** - 最佳体验，功能最完整
- ✅ **Discord** - 社区和团队协作
- ✅ **WhatsApp** - 个人和商务消息
- ✅ **Signal** - 隐私优先的加密通讯
- ✅ **Slack** - 企业团队协作
- ✅ **Matrix** - 开源去中心化通讯
- ✅ **钉钉 (DingTalk)** - 阿里巴巴企业通讯
- ✅ **邮件 (Email)** - IMAP/SMTP 支持
- ✅ **短信 (SMS)** - 通过 Twilio

### 个人微信解决方案
由于微信官方限制，个人微信需要使用第三方方案：
- 🔧 **微信机器人** (通过 itchat/wechaty)
- 🔧 **微信公众号** (官方 API)
- 🔧 **微信小程序** (云函数集成)

## 🚀 快速开始

### 1. 飞书 (Feishu) 集成

#### 第一步：配置飞书机器人
```bash
# 启动 Hermes 平台配置
hermes gateway setup
```

在配置界面中选择 `Feishu / Lark`，然后按照向导操作：

1. **创建飞书应用**
   - 访问 [飞书开放平台](https://open.feishu.cn/)
   - 创建企业自建应用
   - 获取 App ID 和 App Secret

2. **配置权限**
   - 机器人权限：发送消息、接收消息
   - 通讯录权限：获取用户信息
   - 文件权限：上传下载文件

3. **设置回调地址**
   ```
   https://your-domain.com/webhook/feishu
   ```

#### 第二步：环境配置
在 `~/.hermes/.env` 文件中添加：

```env
# 飞书配置
FEISHU_APP_ID=your_app_id_here
FEISHU_APP_SECRET=your_app_secret_here
FEISHU_VERIFICATION_TOKEN=your_verification_token
FEISHU_ENCRYPT_KEY=your_encrypt_key

# 可选：自定义配置
FEISHU_BOT_NAME=Hermes AI
FEISHU_WEBHOOK_URL=https://your-domain.com/webhook/feishu
```

#### 第三步：启动服务
```bash
# 安装并启动 Gateway 服务
hermes gateway install
hermes gateway start

# 检查状态
hermes gateway status
```

### 2. 企业微信 (WeCom) 集成

#### 配置企业微信应用
```bash
hermes gateway setup
# 选择 "WeCom (Enterprise WeChat)"
```

1. **创建企业微信应用**
   - 登录 [企业微信管理后台](https://work.weixin.qq.com/)
   - 应用管理 → 创建应用
   - 获取 AgentId、Secret

2. **环境变量配置**
```env
# 企业微信配置
WECOM_CORP_ID=your_corp_id
WECOM_AGENT_ID=your_agent_id
WECOM_AGENT_SECRET=your_agent_secret
WECOM_TOKEN=your_token
WECOM_ENCODING_AES_KEY=your_aes_key
```

### 3. Telegram 集成 (推荐体验最佳)

#### 创建 Telegram Bot
```bash
# 与 @BotFather 对话创建机器人
# 获得 Bot Token
```

#### 配置 Telegram
```bash
hermes gateway setup
# 选择 "Telegram"
```

```env
# Telegram 配置
TELEGRAM_BOT_TOKEN=your_bot_token_here
TELEGRAM_WEBHOOK_URL=https://your-domain.com/webhook/telegram

# 可选配置
TELEGRAM_ADMIN_IDS=123456789,987654321  # 管理员用户ID
TELEGRAM_ALLOWED_USERS=all  # 或具体用户ID列表
```

### 4. Discord 集成

#### 创建 Discord 应用
1. 访问 [Discord 开发者门户](https://discord.com/developers/applications)
2. 创建新应用 → Bot → 复制 Token
3. 配置权限和 Slash Commands

```env
# Discord 配置
DISCORD_BOT_TOKEN=your_discord_token
DISCORD_APPLICATION_ID=your_app_id
DISCORD_GUILD_ID=your_server_id  # 可选，限制到特定服务器
```

## 🔧 个人微信解决方案

### 方案一：微信公众号 (官方推荐)

已经在您的系统中集成，参考 `wechat_publisher.py`：

```python
# 微信公众号配置
WECHAT_APP_ID=your_wechat_app_id
WECHAT_APP_SECRET=your_wechat_app_secret
WECHAT_TOKEN=your_verification_token
```

### 方案二：微信机器人 (第三方)

使用 wechaty 或 itchat 库：

```bash
# 安装依赖
pip install wechaty
```

```python
# 微信机器人集成脚本
import asyncio
from wechaty import Wechaty, Contact, Room, Message
import requests

class WeChatHermesBot:
    def __init__(self, hermes_endpoint="http://localhost:8080"):
        self.hermes_endpoint = hermes_endpoint
        
    async def on_message(self, message: Message):
        """处理微信消息"""
        if message.is_self():
            return
            
        # 获取消息内容
        text = message.text()
        sender = message.talker()
        
        # 发送到 Hermes AI 处理
        response = await self.send_to_hermes(text, sender.contact_id)
        
        # 回复消息
        await message.say(response)
    
    async def send_to_hermes(self, message: str, user_id: str):
        """将消息发送给 Hermes AI 处理"""
        try:
            response = requests.post(f"{self.hermes_endpoint}/api/chat", json={
                "message": message,
                "user_id": user_id,
                "platform": "wechat"
            })
            return response.json().get("response", "抱歉，我现在无法处理您的消息。")
        except Exception as e:
            return f"服务暂时不可用: {str(e)}"

# 启动微信机器人
async def main():
    bot = Wechaty()
    hermes_bot = WeChatHermesBot()
    
    bot.on('message', hermes_bot.on_message)
    
    await bot.start()

if __name__ == "__main__":
    asyncio.run(main())
```

### 方案三：微信小程序集成

创建微信小程序，通过云函数调用 Hermes API：

```javascript
// 云函数: hermes-chat
const cloud = require('wx-server-sdk')
const axios = require('axios')

cloud.init()

exports.main = async (event, context) => {
  const { message, openid } = event
  
  try {
    const response = await axios.post('https://your-hermes-api.com/chat', {
      message: message,
      user_id: openid,
      platform: 'wechat_miniprogram'
    })
    
    return {
      success: true,
      data: response.data.response
    }
  } catch (error) {
    return {
      success: false,
      error: error.message
    }
  }
}
```

## 🎛️ 高级配置

### 多平台统一配置

在 `~/.hermes/config.yaml` 中配置多平台工具集：

```yaml
# 平台工具配置
platform_toolsets:
  cli: [hermes-cli]
  telegram: [hermes-telegram] 
  discord: [hermes-discord]
  feishu: [terminal, file, web, vision, tts, browser, skills, todo]
  wecom: [web, vision, skills, todo, file]
  
# 会话重置策略
session_reset:
  mode: both
  idle_minutes: 1440  # 24小时
  at_hour: 4  # 凌晨4点重置

# 每个用户独立会话
group_sessions_per_user: true
```

### 权限控制

```yaml
# 用户权限控制 (在 .env 中)
TELEGRAM_ADMIN_IDS=123456789
TELEGRAM_ALLOWED_USERS=123456789,987654321
FEISHU_ALLOWED_DOMAINS=your-company.com
DISCORD_ALLOWED_GUILDS=your_server_id
```

### 自定义命令和快捷方式

```yaml
# 自定义平台行为
messaging:
  # 命令前缀
  command_prefix: "/"
  
  # 快捷命令
  shortcuts:
    geoflow: "skill_view geoflow-management"
    publish: "使用多平台发布系统发布内容"
    report: "生成 GEO 优化报告"
    
  # 自动回复
  auto_responses:
    welcome: "你好！我是 Hermes AI，可以帮助您进行内容创作、GEO 优化、多平台发布等任务。"
```

## 📱 使用方法

### 基本聊天
直接向机器人发送消息即可开始对话：

```
用户: 帮我分析一下医美行业的GEO可见度
Hermes: 我来为您分析医美行业的GEO可见度情况...
```

### 命令操作
```bash
# 系统命令
/status - 查看系统状态
/new - 开始新对话
/reset - 重置当前会话

# 技能相关
/skills - 查看可用技能
/skill geoflow-management - 加载特定技能

# 文件操作
/file upload - 上传文件
/file list - 列出文件

# 任务管理
/todo - 查看任务列表
/cron - 管理定时任务
```

### 文件传输
- 📎 **上传文件**: 直接发送文件给机器人
- 📊 **数据分析**: 支持 Excel, CSV, PDF 分析
- 🖼️ **图片处理**: 自动识别和分析图片内容

## 🔒 安全最佳实践

### 1. 网络安全
```bash
# 使用 HTTPS 和域名
WEBHOOK_BASE_URL=https://your-secure-domain.com

# 配置防火墙
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp
```

### 2. 访问控制
```yaml
# 限制访问用户
ALLOWED_USER_IDS=user1,user2,user3
ADMIN_USER_IDS=admin1,admin2

# IP 白名单
ALLOWED_IPS=192.168.1.0/24,10.0.0.0/8
```

### 3. 数据保护
```yaml
# 会话数据加密
encryption:
  enabled: true
  key: your_encryption_key
  
# 自动清理
cleanup:
  session_ttl: 24h
  file_ttl: 7d
```

## 🚀 部署到生产环境

### 使用 Docker 部署

```dockerfile
FROM python:3.11-slim

# 安装 Hermes
RUN pip install hermes-agent

# 复制配置文件
COPY config.yaml /root/.hermes/config.yaml
COPY .env /root/.hermes/.env

# 启动服务
CMD ["hermes", "gateway", "run"]
```

### 使用 systemd 服务

```ini
[Unit]
Description=Hermes AI Gateway
After=network.target

[Service]
Type=simple
User=hermes
WorkingDirectory=/home/hermes
ExecStart=/usr/local/bin/hermes gateway run
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Nginx 反向代理

```nginx
server {
    listen 443 ssl http2;
    server_name your-hermes-domain.com;
    
    # SSL 配置
    ssl_certificate /etc/ssl/certs/your-cert.crt;
    ssl_certificate_key /etc/ssl/private/your-key.key;
    
    # Webhook 路由
    location /webhook/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 🔍 故障排除

### 常见问题

1. **连接问题**
```bash
# 检查服务状态
hermes gateway status
hermes doctor

# 查看日志
hermes logs --follow
```

2. **权限问题**
```bash
# 检查配置
hermes config
cat ~/.hermes/.env
```

3. **网络问题**
```bash
# 测试 webhook
curl -X POST https://your-domain.com/webhook/test \
  -H "Content-Type: application/json" \
  -d '{"test": "message"}'
```

### 调试模式

```yaml
# 开启详细日志
display:
  tool_progress: verbose
  
agent:
  verbose: true
```

## 🔗 与外部系统集成

### API 集成模式

成功集成外部系统的通用模式：

```python
class ExternalSystemIntegration:
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip('/')
        self.token = None
        
    def authenticate(self, username: str, password: str) -> bool:
        """通用认证模式"""
        try:
            response = requests.post(
                f"{self.base_url}/api/v1/auth/login",
                json={"username": username, "password": password}
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    self.token = data['data']['token']
                    return True
            return False
        except Exception:
            return False
    
    def make_authenticated_request(self, method: str, endpoint: str, **kwargs):
        """统一的认证请求处理"""
        if not self.token:
            return None
            
        headers = kwargs.get('headers', {})
        headers.update({
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json'
        })
        kwargs['headers'] = headers
        
        url = f"{self.base_url}/api/v1/{endpoint.lstrip('/')}"
        return requests.request(method, url, **kwargs)
```

### 集成 GEOFlow 示例

成功集成 GEOFlow 内容管理系统的关键步骤：

1. **API 探索**: 使用 curl 测试认证和基本接口
2. **令牌管理**: 正确提取和使用 Bearer 令牌
3. **错误处理**: 解析 API 错误响应，了解必填字段
4. **功能封装**: 创建 Python 类封装 API 调用

```bash
# 测试认证
curl -X POST http://localhost:18080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin888"}'

# 提取令牌并测试接口
TOKEN=$(curl -s ... | jq -r '.data.token')
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:18080/api/v1/tasks
```

## 🎉 集成效果

成功集成后，您可以：

✅ **在飞书中直接与 Hermes AI 对话**  
✅ **通过企业微信管理 GEOFlow 系统**  
✅ **在 Telegram 中执行复杂的自动化任务**  
✅ **多平台同步您的 AI 助手体验**  
✅ **团队协作时共享 AI 能力**  
✅ **集成外部 API 系统进行统一管理**

现在您就拥有了一个真正的 AI 助手，随时随地为您服务！