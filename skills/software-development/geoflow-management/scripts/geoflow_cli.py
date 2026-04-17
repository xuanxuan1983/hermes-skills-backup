#!/usr/bin/env python3
"""
GEOFlow CLI 客户端
与 Hermes 集成的智能内容管理工具
"""

import requests
import json
import argparse
import os
import sys
from typing import Dict, List, Optional
from datetime import datetime
import csv

class GEOFlowClient:
    def __init__(self, base_url: str, token: str):
        self.base_url = base_url.rstrip('/')
        self.token = token
        self.headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
    
    def _make_request(self, method: str, endpoint: str, **kwargs):
        """统一的请求处理方法"""
        url = f"{self.base_url}/api/v1/{endpoint.lstrip('/')}"
        try:
            response = requests.request(method, url, headers=self.headers, **kwargs)
            return response
        except requests.exceptions.RequestException as e:
            print(f"请求失败: {e}")
            return None
    
    def system_status(self):
        """检查系统状态"""
        response = self._make_request('GET', 'system/status')
        if response and response.status_code == 200:
            status = response.json()
            print("✓ 系统运行正常")
            print(f"  版本: {status.get('version', 'N/A')}")
            print(f"  启动时间: {status.get('uptime', 'N/A')}")
            return True
        else:
            print("✗ 系统状态异常")
            return False
    
    def create_batch_tasks(self, keywords_file: str, template_id: str = "default", model: str = "gpt-4"):
        """批量创建内容生成任务"""
        if not os.path.exists(keywords_file):
            print(f"✗ 关键词文件不存在: {keywords_file}")
            return []
        
        with open(keywords_file, 'r', encoding='utf-8') as f:
            keywords = [line.strip() for line in f if line.strip()]
        
        print(f"准备创建 {len(keywords)} 个任务...")
        tasks = []
        
        for i, keyword in enumerate(keywords, 1):
            task_data = {
                "title": f"{keyword}相关内容分析",
                "keywords": [keyword],
                "template_id": template_id,
                "model_config": model,
                "priority": "normal",
                "scheduled_at": None  # 立即执行
            }
            
            response = self._make_request('POST', 'tasks', json=task_data)
            if response and response.status_code == 201:
                task = response.json()['data']
                tasks.append(task)
                print(f"✓ [{i}/{len(keywords)}] 创建任务: {keyword} (ID: {task['id']})")
            else:
                error_msg = response.text if response else "网络错误"
                print(f"✗ [{i}/{len(keywords)}] 创建失败: {keyword} - {error_msg}")
        
        print(f"批量任务创建完成，成功: {len(tasks)}, 失败: {len(keywords) - len(tasks)}")
        return tasks
    
    def monitor_tasks(self, task_ids: List[int] = None):
        """监控任务执行状态"""
        if task_ids:
            # 监控指定任务
            for task_id in task_ids:
                response = self._make_request('GET', f'tasks/{task_id}/status')
                if response and response.status_code == 200:
                    status = response.json()['data']
                    progress = status.get('progress', 0)
                    print(f"任务 {task_id}: {status['status']} - {progress}%")
                else:
                    print(f"✗ 任务 {task_id}: 获取状态失败")
        else:
            # 监控所有进行中的任务
            response = self._make_request('GET', 'tasks?status=running,pending')
            if response and response.status_code == 200:
                tasks = response.json()['data']
                if tasks:
                    print(f"当前有 {len(tasks)} 个活跃任务:")
                    for task in tasks:
                        progress = task.get('progress', 0)
                        print(f"  任务 {task['id']}: {task['status']} - {progress}% - {task['title']}")
                else:
                    print("当前没有活跃任务")
    
    def auto_review_articles(self, criteria: Dict):
        """智能文章审核"""
        response = self._make_request('GET', 'articles?status=draft&limit=50')
        if not response or response.status_code != 200:
            print("✗ 获取草稿文章失败")
            return
        
        articles = response.json()['data']
        print(f"找到 {len(articles)} 篇待审核文章")
        
        approved_count = 0
        for article in articles:
            should_approve = self._evaluate_article(article, criteria)
            
            if should_approve:
                review_data = {
                    "status": "approved",
                    "comments": "自动审核通过 - 符合质量标准"
                }
                
                response = self._make_request(
                    'PUT', 
                    f'articles/{article["id"]}/review',
                    json=review_data
                )
                
                if response and response.status_code == 200:
                    approved_count += 1
                    print(f"✓ 自动审核通过: {article['title']}")
                else:
                    print(f"✗ 审核失败: {article['title']}")
        
        print(f"自动审核完成，通过: {approved_count}/{len(articles)}")
    
    def _evaluate_article(self, article: Dict, criteria: Dict) -> bool:
        """评估文章是否符合审核标准"""
        content = article.get('content', '')
        title = article.get('title', '')
        
        # 检查字数
        if len(content) < criteria.get('min_length', 500):
            return False
        
        # 检查标题长度
        if len(title) < criteria.get('min_title_length', 10):
            return False
        
        # 检查关键词密度（简单实现）
        keywords = article.get('keywords', [])
        if keywords:
            keyword_mentions = sum(1 for kw in keywords if kw.lower() in content.lower())
            if keyword_mentions / len(keywords) < 0.5:  # 至少50%关键词被提及
                return False
        
        return True
    
    def export_articles(self, status: str = 'published', output_file: str = None):
        """导出文章数据"""
        response = self._make_request('GET', f'articles?status={status}&limit=1000')
        if not response or response.status_code != 200:
            print(f"✗ 获取{status}文章失败")
            return
        
        articles = response.json()['data']
        
        if not output_file:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            output_file = f'geoflow_articles_{status}_{timestamp}.csv'
        
        with open(output_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['ID', '标题', '状态', '创建时间', '关键词', '字数'])
            
            for article in articles:
                writer.writerow([
                    article['id'],
                    article['title'],
                    article['status'],
                    article.get('created_at', ''),
                    ','.join(article.get('keywords', [])),
                    len(article.get('content', ''))
                ])
        
        print(f"✓ 导出完成: {output_file} ({len(articles)} 篇文章)")
    
    def bulk_publish(self, article_ids: List[int], platform: str = None):
        """批量发布文章"""
        if not article_ids:
            print("✗ 没有指定要发布的文章")
            return
        
        success_count = 0
        for article_id in article_ids:
            data = {'platform': platform} if platform else {}
            response = self._make_request('POST', f'articles/{article_id}/publish', json=data)
            
            if response and response.status_code == 200:
                success_count += 1
                print(f"✓ 文章 {article_id} 发布成功")
            else:
                error_msg = response.text if response else "网络错误"
                print(f"✗ 文章 {article_id} 发布失败: {error_msg}")
        
        print(f"批量发布完成，成功: {success_count}/{len(article_ids)}")

def load_config():
    """加载配置文件"""
    config_file = os.path.expanduser('~/.geoflow_config.json')
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            return json.load(f)
    return {}

def save_config(config):
    """保存配置文件"""
    config_file = os.path.expanduser('~/.geoflow_config.json')
    with open(config_file, 'w') as f:
        json.dump(config, f, indent=2)

def main():
    parser = argparse.ArgumentParser(description='GEOFlow CLI 管理工具')
    parser.add_argument('--url', help='GEOFlow 系统 URL')
    parser.add_argument('--token', help='API Token')
    parser.add_argument('--config', action='store_true', help='配置 URL 和 Token')
    
    subparsers = parser.add_subparsers(dest='command', help='可用命令')
    
    # 系统状态
    subparsers.add_parser('status', help='检查系统状态')
    
    # 批量任务创建
    batch_parser = subparsers.add_parser('batch-tasks', help='批量创建任务')
    batch_parser.add_argument('--keywords-file', required=True, help='关键词文件')
    batch_parser.add_argument('--template', default='default', help='模板ID')
    batch_parser.add_argument('--model', default='gpt-4', help='AI模型')
    
    # 任务监控
    monitor_parser = subparsers.add_parser('monitor', help='监控任务')
    monitor_parser.add_argument('--task-ids', nargs='+', type=int, help='任务ID列表')
    
    # 自动审核
    review_parser = subparsers.add_parser('auto-review', help='自动审核文章')
    review_parser.add_argument('--min-length', type=int, default=500, help='最小字数')
    review_parser.add_argument('--min-title-length', type=int, default=10, help='最小标题长度')
    
    # 导出文章
    export_parser = subparsers.add_parser('export', help='导出文章')
    export_parser.add_argument('--status', default='published', help='文章状态')
    export_parser.add_argument('--output', help='输出文件名')
    
    # 批量发布
    publish_parser = subparsers.add_parser('bulk-publish', help='批量发布文章')
    publish_parser.add_argument('--article-ids', nargs='+', type=int, required=True, help='文章ID列表')
    publish_parser.add_argument('--platform', help='发布平台')
    
    args = parser.parse_args()
    
    # 处理配置
    config = load_config()
    
    if args.config:
        url = input("请输入 GEOFlow URL: ")
        token = input("请输入 API Token: ")
        config.update({'url': url, 'token': token})
        save_config(config)
        print("✓ 配置已保存")
        return
    
    # 获取 URL 和 Token
    url = args.url or config.get('url')
    token = args.token or config.get('token')
    
    if not url or not token:
        print("✗ 缺少 URL 或 Token，请使用 --config 进行配置")
        return
    
    if not args.command:
        parser.print_help()
        return
    
    # 创建客户端
    client = GEOFlowClient(url, token)
    
    # 执行命令
    if args.command == 'status':
        client.system_status()
    elif args.command == 'batch-tasks':
        client.create_batch_tasks(args.keywords_file, args.template, args.model)
    elif args.command == 'monitor':
        client.monitor_tasks(args.task_ids)
    elif args.command == 'auto-review':
        criteria = {
            'min_length': args.min_length,
            'min_title_length': args.min_title_length
        }
        client.auto_review_articles(criteria)
    elif args.command == 'export':
        client.export_articles(args.status, args.output)
    elif args.command == 'bulk-publish':
        client.bulk_publish(args.article_ids, args.platform)

if __name__ == '__main__':
    main()