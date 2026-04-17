# GEOFlow API 接口文档

## 认证

所有 API 请求都需要在请求头中包含认证令牌：

```
Authorization: Bearer YOUR_API_TOKEN
```

## 基础响应格式

```json
{
    "success": true,
    "data": {},
    "message": "操作成功",
    "request_id": "uuid",
    "timestamp": "2024-04-14T10:30:00Z"
}
```

## 系统管理接口

### 系统状态
- **GET** `/api/v1/system/status`
- 获取系统运行状态和版本信息

```bash
curl -H "Authorization: Bearer TOKEN" \
  http://localhost/api/v1/system/status
```

### 健康检查
- **GET** `/api/v1/system/health`
- 检查系统各组件健康状态

```bash
curl -H "Authorization: Bearer TOKEN" \
  http://localhost/api/v1/system/health
```

### 系统指标
- **GET** `/api/v1/system/metrics`
- 获取系统性能指标

## 认证接口

### 用户登录
- **POST** `/api/v1/auth/login`
- 用户登录获取 API 令牌

```json
{
    "username": "admin",
    "password": "password"
}
```

### 刷新令牌
- **POST** `/api/v1/auth/refresh`
- 刷新访问令牌

### 登出
- **POST** `/api/v1/auth/logout`
- 用户登出，使令牌失效

## 任务管理接口

### 创建任务
- **POST** `/api/v1/tasks`
- 创建新的内容生成任务

```json
{
    "title": "文章标题",
    "keywords": ["关键词1", "关键词2"],
    "template_id": "template_1",
    "model_config": "gpt-4",
    "priority": "normal",
    "scheduled_at": "2024-04-14T15:00:00Z"
}
```

### 任务列表
- **GET** `/api/v1/tasks`
- 获取任务列表

**查询参数：**
- `status`: 任务状态 (pending, running, completed, failed)
- `limit`: 每页数量 (默认: 20)
- `offset`: 偏移量 (默认: 0)
- `sort`: 排序字段 (created_at, updated_at, priority)
- `order`: 排序方向 (asc, desc)

```bash
curl -H "Authorization: Bearer TOKEN" \
  "http://localhost/api/v1/tasks?status=pending&limit=10"
```

### 任务详情
- **GET** `/api/v1/tasks/{task_id}`
- 获取单个任务详细信息

### 执行任务
- **POST** `/api/v1/tasks/{task_id}/execute`
- 立即执行指定任务

### 取消任务
- **POST** `/api/v1/tasks/{task_id}/cancel`
- 取消正在执行的任务

### 重试任务
- **POST** `/api/v1/tasks/{task_id}/retry`
- 重新执行失败的任务

### 任务状态
- **GET** `/api/v1/tasks/{task_id}/status`
- 获取任务执行状态和进度

### 任务日志
- **GET** `/api/v1/tasks/{task_id}/logs`
- 获取任务执行日志

### 批量操作
- **POST** `/api/v1/tasks/batch`
- 批量操作任务

```json
{
    "task_ids": [1, 2, 3, 4, 5],
    "action": "execute|cancel|retry|delete"
}
```

## 文章管理接口

### 文章列表
- **GET** `/api/v1/articles`
- 获取文章列表

**查询参数：**
- `status`: 文章状态 (draft, review, approved, published, rejected)
- `category`: 分类ID
- `author`: 作者ID
- `keyword`: 关键词搜索
- `limit`: 每页数量
- `offset`: 偏移量

### 文章详情
- **GET** `/api/v1/articles/{article_id}`
- 获取文章详细信息

### 创建文章
- **POST** `/api/v1/articles`
- 手动创建文章

```json
{
    "title": "文章标题",
    "content": "文章内容",
    "excerpt": "文章摘要",
    "keywords": ["关键词1", "关键词2"],
    "category_id": 1,
    "tags": ["标签1", "标签2"],
    "seo_title": "SEO标题",
    "seo_description": "SEO描述",
    "featured_image": "图片URL"
}
```

### 更新文章
- **PUT** `/api/v1/articles/{article_id}`
- 更新文章信息

### 删除文章
- **DELETE** `/api/v1/articles/{article_id}`
- 删除文章

### 文章审核
- **PUT** `/api/v1/articles/{article_id}/review`
- 审核文章

```json
{
    "status": "approved|rejected",
    "comments": "审核意见"
}
```

### 发布文章
- **POST** `/api/v1/articles/{article_id}/publish`
- 发布文章到前台

```json
{
    "platform": "website|wechat|weibo",
    "publish_time": "2024-04-14T16:00:00Z"
}
```

### 撤回文章
- **POST** `/api/v1/articles/{article_id}/unpublish`
- 从前台撤回文章

### 批量操作
- **POST** `/api/v1/articles/batch`
- 批量操作文章

```json
{
    "article_ids": [1, 2, 3],
    "action": "approve|reject|publish|unpublish|delete"
}
```

## 素材管理接口

### 关键词库

#### 上传关键词
- **POST** `/api/v1/materials/keywords/upload`
- 批量上传关键词

```bash
curl -X POST -F "file=@keywords.csv" \
  -F "category=medical_beauty" \
  -H "Authorization: Bearer TOKEN" \
  http://localhost/api/v1/materials/keywords/upload
```

#### 关键词列表
- **GET** `/api/v1/materials/keywords`
- 获取关键词列表

#### 添加关键词
- **POST** `/api/v1/materials/keywords`
- 添加单个关键词

```json
{
    "keyword": "医美",
    "category": "medical_beauty",
    "search_volume": 1000,
    "difficulty": "medium",
    "tags": ["热门", "推荐"]
}
```

### 标题库

#### 标题列表
- **GET** `/api/v1/materials/titles`
- 获取标题库列表

#### 批量添加标题
- **POST** `/api/v1/materials/titles`
- 批量添加标题

```json
{
    "titles": [
        "医美行业发展趋势分析",
        "2024年整形美容市场报告"
    ],
    "category": "medical_beauty",
    "tags": ["分析", "报告"]
}
```

### 图片库

#### 上传图片
- **POST** `/api/v1/materials/images`
- 上传图片素材

```bash
curl -X POST -F "image=@image.jpg" \
  -F "category=medical_beauty" \
  -F "alt_text=医美设备" \
  -F "tags=设备,医疗" \
  -H "Authorization: Bearer TOKEN" \
  http://localhost/api/v1/materials/images
```

#### 图片列表
- **GET** `/api/v1/materials/images`
- 获取图片素材列表

#### 删除图片
- **DELETE** `/api/v1/materials/images/{image_id}`
- 删除图片素材

### 知识库

#### 知识条目列表
- **GET** `/api/v1/materials/knowledge`
- 获取知识库条目

#### 添加知识条目
- **POST** `/api/v1/materials/knowledge`
- 添加知识库条目

```json
{
    "title": "医美行业监管政策",
    "content": "详细内容...",
    "category": "regulation",
    "tags": ["政策", "监管"],
    "source": "官方文件",
    "relevance_score": 0.9
}
```

## 模板管理接口

### 模板列表
- **GET** `/api/v1/templates`
- 获取内容模板列表

### 创建模板
- **POST** `/api/v1/templates`
- 创建新的内容模板

```json
{
    "name": "SEO文章模板",
    "type": "article",
    "template": "# {{title}}\n\n{{introduction}}\n\n## 主要内容\n{{content}}\n\n## 总结\n{{conclusion}}",
    "variables": [
        {"name": "title", "type": "string", "required": true},
        {"name": "introduction", "type": "text", "required": false},
        {"name": "content", "type": "text", "required": true},
        {"name": "conclusion", "type": "text", "required": false}
    ],
    "category": "seo"
}
```

### 更新模板
- **PUT** `/api/v1/templates/{template_id}`
- 更新模板内容

### 删除模板
- **DELETE** `/api/v1/templates/{template_id}`
- 删除模板

## 分析统计接口

### 内容统计
- **GET** `/api/v1/analytics/content`
- 获取内容生产统计

### 任务统计
- **GET** `/api/v1/analytics/tasks`
- 获取任务执行统计

### 关键词分析
- **GET** `/api/v1/analytics/keywords`
- 获取关键词使用分析

## 错误码说明

| 错误码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 201 | 创建成功 |
| 400 | 请求参数错误 |
| 401 | 未授权访问 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 409 | 资源冲突 |
| 422 | 数据验证失败 |
| 429 | 请求频率超限 |
| 500 | 服务器内部错误 |
| 502 | 网关错误 |
| 503 | 服务不可用 |

## 速率限制

- 一般接口：每秒 10 次请求
- 认证接口：每分钟 5 次请求
- 上传接口：每分钟 20 次请求

超出限制将返回 429 错误码。