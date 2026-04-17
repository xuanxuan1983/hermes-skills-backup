---
name: geoflow-management
title: GEOFlow 智能内容生产系统管理
description: GEOFlow 系统的 CLI 集成和智能管理工具，支持任务调度、内容生成、素材管理和多平台发布
tags: [geo, seo, content-management, cli-integration, automation, php, postgresql]
---

# GEOFlow 智能内容生产系统管理

## 概述

GEOFlow 是一个面向 GEO/SEO 内容运营场景的开源内容生产系统，提供完整的内容创作链路：模型配置 → 素材管理 → 任务调度 → 草稿审核 → 前台发布。

## 系统架构

**技术栈：**
- 后端：PHP + PostgreSQL
- 部署：Docker Compose
- API：RESTful 风格，v1 版本
- 前端：Web 管理界面

**核心功能模块：**
- 🤖 多模型内容生成（兼容 OpenAI 接口）
- 📦 批量任务运行（调度、队列、重试）
- 🗂 素材统一管理（标题库、关键词库、图片库、知识库）
- 📋 审核发布工作流（草稿 → 审核 → 发布）
- 🔍 SEO 优化（元信息、Open Graph、结构化数据）

## 快速部署

### 1. 克隆项目
```bash
git clone https://github.com/yaojingang/GEOFlow.git
cd GEOFlow
```

### 2. 环境配置
```bash
# 复制环境配置文件
cp .env.example .env

# 编辑配置文件
vim .env
```

### 3. Docker 部署
```bash
# 开发环境
docker-compose up -d

# 生产环境
docker-compose -f docker-compose.prod.yml up -d
```

### 4. 初始化数据库
```bash
# 进入容器
docker exec -it geoflow_app /bin/bash

# 运行初始化脚本
php bin/init_database.php
```

## CLI 管理接口

### 系统状态检查
```bash
# 检查系统运行状态
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost/api/v1/system/status

# 检查数据库连接
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost/api/v1/system/health
```

### 任务管理
```bash
# 创建内容生成任务
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "title": "医美行业趋势分析",
    "keywords": ["医美", "整形", "美容"],
    "template_id": "article_template_1",
    "model_config": "gpt-4"
  }' \
  http://localhost/api/v1/tasks

# 查看任务列表
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost/api/v1/tasks?status=pending&limit=10

# 执行任务
curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost/api/v1/tasks/{task_id}/execute

# 获取任务状态
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost/api/v1/tasks/{task_id}/status
```

### 内容管理
```bash
# 获取文章列表
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost/api/v1/articles?status=draft&limit=20

# 审核文章
curl -X PUT -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"status": "approved", "comments": "内容质量良好"}' \
  http://localhost/api/v1/articles/{article_id}/review

# 发布文章
curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost/api/v1/articles/{article_id}/publish

# 批量操作
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"article_ids": [1,2,3], "action": "publish"}' \
  http://localhost/api/v1/articles/batch
```

### 素材管理
```bash
# 上传关键词库
curl -X POST -F "file=@keywords.csv" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost/api/v1/materials/keywords/upload

# 管理标题库
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"titles": ["标题1", "标题2"], "category": "medical_beauty"}' \
  http://localhost/api/v1/materials/titles

# 图片素材管理
curl -X POST -F "image=@image.jpg" \
  -F "category=medical_beauty" \
  -F "tags=整形,美容" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost/api/v1/materials/images
```

## Hermes 集成脚本

### Python CLI 客户端
```python
#!/usr/bin/env python3
"""
GEOFlow CLI 客户端
与 Hermes 集成的智能内容管理工具
"""

import requests
import json
import argparse
from typing import Dict, List, Optional

class GEOFlowClient:
    def __init__(self, base_url: str, token: str):
        self.base_url = base_url.rstrip('/')
        self.token = token
        self.headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
    
    def create_batch_tasks(self, keywords_file: str, template_id: str = "default"):
        """批量创建内容生成任务"""
        with open(keywords_file, 'r', encoding='utf-8') as f:
            keywords = [line.strip() for line in f if line.strip()]
        
        tasks = []
        for keyword in keywords:
            task_data = {
                "title": f"{keyword}相关内容",
                "keywords": [keyword],
                "template_id": template_id,
                "model_config": "gpt-4"
            }
            response = requests.post(
                f"{self.base_url}/api/v1/tasks",
                headers=self.headers,
                json=task_data
            )
            if response.status_code == 201:
                tasks.append(response.json()['data'])
                print(f"✓ 创建任务: {keyword}")
            else:
                print(f"✗ 创建失败: {keyword} - {response.text}")
        
        return tasks
    
    def monitor_tasks(self, task_ids: List[int]):
        """监控任务执行状态"""
        for task_id in task_ids:
            response = requests.get(
                f"{self.base_url}/api/v1/tasks/{task_id}/status",
                headers=self.headers
            )
            if response.status_code == 200:
                status = response.json()['data']
                print(f"任务 {task_id}: {status['status']} - {status.get('progress', 0)}%")
    
    def auto_review_articles(self, criteria: Dict):
        """智能文章审核"""
        response = requests.get(
            f"{self.base_url}/api/v1/articles?status=draft",
            headers=self.headers
        )
        
        if response.status_code == 200:
            articles = response.json()['data']
            for article in articles:
                # 简单的自动审核逻辑
                if len(article['content']) > criteria.get('min_length', 500):
                    review_data = {
                        "status": "approved",
                        "comments": "自动审核通过"
                    }
                    requests.put(
                        f"{self.base_url}/api/v1/articles/{article['id']}/review",
                        headers=self.headers,
                        json=review_data
                    )
                    print(f"✓ 自动审核通过: {article['title']}")

def main():
    parser = argparse.ArgumentParser(description='GEOFlow CLI 管理工具')
    parser.add_argument('--url', required=True, help='GEOFlow 系统 URL')
    parser.add_argument('--token', required=True, help='API Token')
    
    subparsers = parser.add_subparsers(dest='command', help='可用命令')
    
    # 批量任务创建
    batch_parser = subparsers.add_parser('batch-tasks', help='批量创建任务')
    batch_parser.add_argument('--keywords-file', required=True, help='关键词文件')
    batch_parser.add_argument('--template', default='default', help='模板ID')
    
    # 任务监控
    monitor_parser = subparsers.add_parser('monitor', help='监控任务')
    monitor_parser.add_argument('--task-ids', nargs='+', type=int, help='任务ID列表')
    
    # 自动审核
    review_parser = subparsers.add_parser('auto-review', help='自动审核文章')
    review_parser.add_argument('--min-length', type=int, default=500, help='最小字数')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    client = GEOFlowClient(args.url, args.token)
    
    if args.command == 'batch-tasks':
        client.create_batch_tasks(args.keywords_file, args.template)
    elif args.command == 'monitor':
        client.monitor_tasks(args.task_ids)
    elif args.command == 'auto-review':
        criteria = {'min_length': args.min_length}
        client.auto_review_articles(criteria)

if __name__ == '__main__':
    main()
```

## 智能工作流

### 1. 内容规划工作流
```bash
# 基于关键词研究生成内容计划
geoflow-cli batch-tasks --keywords-file medical_beauty_keywords.txt --template seo_article

# 监控任务执行
geoflow-cli monitor --task-ids 1 2 3 4 5

# 自动质量检查和审核
geoflow-cli auto-review --min-length 800
```

### 2. SEO 优化工作流
```python
def optimize_for_seo(client, article_id):
    """SEO 优化处理"""
    # 获取文章内容
    article = client.get_article(article_id)
    
    # 分析关键词密度
    keywords = extract_keywords(article['content'])
    
    # 生成 SEO 元数据
    meta_data = {
        'title': optimize_title(article['title'], keywords),
        'description': generate_description(article['content']),
        'keywords': keywords[:10],  # 取前10个关键词
        'og_image': select_best_image(article['images'])
    }
    
    # 更新文章 SEO 信息
    client.update_article_seo(article_id, meta_data)
```

### 3. 多平台发布工作流
```python
def multi_platform_publish(client, article_id, platforms):
    """多平台发布"""
    article = client.get_article(article_id)
    
    for platform in platforms:
        # 根据平台特点调整内容格式
        formatted_content = format_for_platform(article, platform)
        
        # 发布到目标平台
        publish_result = client.publish_to_platform(
            article_id, 
            platform, 
            formatted_content
        )
        
        if publish_result['success']:
            print(f"✓ 发布成功: {platform}")
        else:
            print(f"✗ 发布失败: {platform} - {publish_result['error']}")
```

## 监控和维护

### 系统监控脚本
```bash
#!/bin/bash
# GEOFlow 系统健康监控

check_system_health() {
    echo "检查 GEOFlow 系统状态..."
    
    # 检查 Docker 容器
    docker-compose ps
    
    # 检查 API 状态
    curl -s -o /dev/null -w "%{http_code}" http://localhost/api/v1/system/health
    
    # 检查数据库连接
    docker exec geoflow_db pg_isready
    
    # 检查磁盘空间
    df -h | grep docker
}

monitor_tasks() {
    echo "检查待处理任务..."
    curl -H "Authorization: Bearer $API_TOKEN" \
      http://localhost/api/v1/tasks?status=pending | jq '.data | length'
}

cleanup_old_logs() {
    echo "清理旧日志文件..."
    find ./logs -name "*.log" -mtime +7 -delete
}

# 执行监控检查
check_system_health
monitor_tasks
cleanup_old_logs
```

## 扩展集成

### 与其他 AI 服务集成
```python
class AIServiceIntegrator:
    def __init__(self, geoflow_client):
        self.geoflow = geoflow_client
    
    def integrate_claude_api(self, prompt_template):
        """集成 Claude API 进行内容生成"""
        # 调用 Claude API
        response = claude_api.generate_content(prompt_template)
        
        # 创建 GEOFlow 任务
        task_data = {
            "content": response.content,
            "source": "claude_api",
            "template_id": "ai_generated"
        }
        return self.geoflow.create_article(task_data)
    
    def integrate_image_ai(self, text_prompt):
        """集成 AI 图片生成服务"""
        # 生成图片
        image_url = image_ai.generate(text_prompt)
        
        # 上传到 GEOFlow 素材库
        return self.geoflow.upload_image(image_url, {"source": "ai_generated"})
```

## 常见问题与解决

### API 认证问题
```bash
# 获取新的 API Token
curl -X POST -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "your_password"}' \
  http://localhost/api/v1/auth/login
```

### 任务执行失败
```bash
# 查看任务详细错误信息
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost/api/v1/tasks/{task_id}/logs

# 重试失败的任务
curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost/api/v1/tasks/{task_id}/retry
```

### 性能优化
```bash
# 查看系统性能指标
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost/api/v1/system/metrics

# 清理缓存
curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost/api/v1/system/cache/clear
```

## 使用技巧

1. **批量操作**: 使用 CLI 工具进行大规模内容生产
2. **自动化工作流**: 设置定时任务自动执行内容生成和发布
3. **质量控制**: 建立自动化的内容质量检查机制
4. **SEO 优化**: 利用系统的 SEO 功能提升内容搜索排名
5. **多平台适配**: 根据不同平台特点调整内容格式

通过这个 skill，您可以充分利用 GEOFlow 系统的强大功能，实现智能化的内容生产和管理！