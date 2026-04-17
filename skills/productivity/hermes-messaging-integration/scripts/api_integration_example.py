#!/usr/bin/env python3
"""
外部系统 API 集成示例
演示如何将 Hermes 与任意外部系统集成的通用模式
"""

import requests
import json
from typing import Dict, Optional, Any

class GenericAPIIntegration:
    """通用 API 集成基类"""
    
    def __init__(self, base_url: str, auth_endpoint: str = "/api/v1/auth/login"):
        self.base_url = base_url.rstrip('/')
        self.auth_endpoint = auth_endpoint
        self.token = None
        self.user_info = None
        
    def authenticate(self, credentials: Dict[str, str]) -> bool:
        """通用认证方法"""
        try:
            response = requests.post(
                f"{self.base_url}{self.auth_endpoint}",
                json=credentials,
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    self.token = data['data']['token']
                    self.user_info = data['data'].get('admin') or data['data'].get('user')
                    return True
                    
            return False
        except Exception as e:
            print(f"认证失败: {e}")
            return False
    
    def make_request(self, method: str, endpoint: str, **kwargs) -> Optional[requests.Response]:
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
        
        try:
            return requests.request(method, url, timeout=30, **kwargs)
        except Exception as e:
            print(f"请求失败: {e}")
            return None
    
    def get_system_status(self) -> Dict[str, Any]:
        """获取系统状态的通用模式"""
        # 尝试多个常见的状态端点
        status_endpoints = ['system/status', 'status', 'health', 'info']
        
        for endpoint in status_endpoints:
            response = self.make_request('GET', endpoint)
            if response and response.status_code == 200:
                try:
                    data = response.json()
                    if data.get('success'):
                        return data['data']
                except:
                    continue
        
        # 如果没有专门的状态端点，通过其他信息构建状态
        return {
            "connected": True,
            "user": self.user_info.get('display_name') if self.user_info else "Unknown",
            "role": self.user_info.get('role') if self.user_info else "Unknown"
        }
    
    def list_resources(self, resource_type: str, params: Dict = None) -> List[Dict]:
        """通用资源列表获取"""
        response = self.make_request('GET', resource_type, params=params or {})
        
        if response and response.status_code == 200:
            try:
                data = response.json()
                if data.get('success'):
                    # 处理不同的数据结构
                    result_data = data['data']
                    if isinstance(result_data, dict):
                        return result_data.get('items', result_data.get('data', []))
                    elif isinstance(result_data, list):
                        return result_data
            except:
                pass
                
        return []

class GEOFlowIntegration(GenericAPIIntegration):
    """GEOFlow 系统集成"""
    
    def __init__(self, base_url: str = "http://localhost:18080"):
        super().__init__(base_url)
        
    def login(self, username: str = "admin", password: str = "admin888") -> bool:
        """GEOFlow 登录"""
        return self.authenticate({"username": username, "password": password})
    
    def get_tasks(self, status: str = None) -> List[Dict]:
        """获取任务列表"""
        params = {"status": status} if status else {}
        return self.list_resources("tasks", params)
    
    def get_articles(self, status: str = None) -> List[Dict]:
        """获取文章列表"""
        params = {"status": status} if status else {}
        return self.list_resources("articles", params)
    
    def create_task(self, task_data: Dict) -> Optional[Dict]:
        """创建任务"""
        response = self.make_request('POST', 'tasks', json=task_data)
        
        if response and response.status_code in [200, 201]:
            try:
                data = response.json()
                if data.get('success'):
                    return data['data']
            except:
                pass
        
        return None
    
    def get_comprehensive_status(self) -> Dict:
        """获取 GEOFlow 综合状态"""
        status = self.get_system_status()
        
        # 添加统计信息
        tasks = self.get_tasks()
        articles = self.get_articles()
        
        status.update({
            "task_count": len(tasks),
            "article_count": len(articles),
            "recent_tasks": tasks[:5] if tasks else [],
            "recent_articles": articles[:5] if articles else []
        })
        
        return status

# Hermes 工具函数 - 可被 Hermes 直接调用
def connect_to_geoflow(username: str = "admin", password: str = "admin888") -> str:
    """连接到 GEOFlow 系统"""
    geoflow = GEOFlowIntegration()
    
    if geoflow.login(username, password):
        status = geoflow.get_comprehensive_status()
        
        return f"""✅ GEOFlow 连接成功!

📊 系统状态:
- 用户: {status.get('user', 'Unknown')}
- 权限: {status.get('role', 'Unknown')}
- 任务数量: {status.get('task_count', 0)}
- 文章数量: {status.get('article_count', 0)}

🔗 API 地址: http://localhost:18080
✅ 系统运行正常，可以开始管理内容了！"""
    else:
        return "❌ GEOFlow 连接失败，请检查系统是否运行或凭据是否正确"

def analyze_geoflow_content_status() -> str:
    """分析 GEOFlow 内容状态"""
    geoflow = GEOFlowIntegration()
    
    if not geoflow.login():
        return "❌ 无法连接到 GEOFlow 系统"
    
    tasks = geoflow.get_tasks()
    articles = geoflow.get_articles()
    
    # 统计任务状态
    task_stats = {}
    for task in tasks:
        status = task.get('status', 'unknown')
        task_stats[status] = task_stats.get(status, 0) + 1
    
    # 统计文章状态  
    article_stats = {}
    for article in articles:
        status = article.get('status', 'unknown')
        article_stats[status] = article_stats.get(status, 0) + 1
    
    report = f"""📊 GEOFlow 内容状态分析

🔄 任务统计 (总计 {len(tasks)} 个):
"""
    
    for status, count in task_stats.items():
        report += f"  - {status}: {count} 个\n"
    
    report += f"""
📝 文章统计 (总计 {len(articles)} 个):
"""
    
    for status, count in article_stats.items():
        report += f"  - {status}: {count} 篇\n"
    
    report += """
💡 建议操作:
1. 创建新的内容生成任务
2. 审核待发布的文章
3. 监控任务执行进度
4. 优化关键词策略"""
    
    return report

def test_external_api_integration():
    """测试外部 API 集成功能"""
    print("🔗 测试外部系统 API 集成")
    print("=" * 40)
    
    # 测试 GEOFlow 连接
    result = connect_to_geoflow()
    print(result)
    
    print("\n" + "=" * 40)
    
    # 测试内容状态分析
    analysis = analyze_geoflow_content_status()
    print(analysis)

if __name__ == "__main__":
    test_external_api_integration()