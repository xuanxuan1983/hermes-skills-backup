---
name: multi-platform-publishing-system
description: Build complete multi-platform content publishing systems with API, web interface, and automated scheduling
tags: [publishing, api, automation, social-media, content-management]
complexity: advanced
---

# Multi-Platform Publishing System

Build comprehensive systems for automatically publishing content across multiple social media platforms (WeChat, Weibo, Zhihu, etc.) with unified management, format adaptation, and scheduling.

## When to Use

- Building content management systems for multi-platform publishing
- Automating social media content distribution
- Creating unified publishing workflows for content creators
- Developing API-driven publishing solutions
- Setting up scheduled content automation

## Architecture Components

### 1. Core Publisher Engine
- Platform adapter pattern for extensibility
- Content format adaptation per platform
- Publish state tracking and duplicate prevention
- Scheduling and automation logic

### 2. API Service Layer
- RESTful endpoints for all operations
- Health monitoring and statistics
- Webhook support for external integrations
- Configuration management

### 3. Web Management Interface
- Real-time status dashboard
- Content creation and editing
- Publishing controls and monitoring
- Platform configuration

### 4. Content Storage System
- JSON-based article storage (scalable to database)
- Media file management
- Publication history tracking
- Tag and metadata support

## Implementation Steps

### Step 1: Create Base Architecture

```python
# Platform adapter pattern
class PlatformAdapter:
    def __init__(self, config):
        self.config = config
        self.name = self.__class__.__name__.replace('Adapter', '')
    
    def format_content(self, article):
        """Override per platform for content adaptation"""
        return {
            'title': article['title'],
            'content': article['content'],
            'images': article.get('images', []),
            'tags': article.get('tags', [])
        }
    
    def publish(self, article):
        """Override per platform for publishing logic"""
        raise NotImplementedError
    
    def is_enabled(self):
        return self.config.get('enabled', False)

# Content manager for storage and state
class ContentManager:
    def __init__(self, content_dir="./content"):
        self.content_dir = Path(content_dir)
        self.content_dir.mkdir(exist_ok=True)
        self.published_log = self.content_dir / "published.json"
```

### Step 2: Implement Platform Adapters

```python
class WeChatAdapter(PlatformAdapter):
    def format_content(self, article):
        content = super().format_content(article)
        # WeChat-specific formatting
        wechat_content = content['content']
        
        # Add tags as hashtags at end
        if content['tags']:
            wechat_content += f"\n\n🏷️ {' '.join(['#' + tag for tag in content['tags']])}"
        
        # Add custom footer
        footer = self.config.get('footer', '')
        if footer:
            wechat_content += f"\n\n{footer}"
        
        content['content'] = wechat_content
        return content
    
    def publish(self, article):
        # WeChat API implementation
        access_token = self._get_access_token()
        # Create draft, upload media, publish...
        return post_id

class WeiboAdapter(PlatformAdapter):
    def format_content(self, article):
        content = super().format_content(article)
        
        # Handle Weibo 2000 character limit
        weibo_content = content['title'] + "\n\n" + content['content']
        if len(weibo_content) > 2000:
            weibo_content = weibo_content[:1950] + "...\n\n[全文请看评论]"
        
        # Convert to topic tags
        if content['tags']:
            tags_str = ' '.join([f"#{tag}#" for tag in content['tags']])
            weibo_content += f"\n\n{tags_str}"
        
        content['content'] = weibo_content
        return content
```

### Step 3: Build API Service

```python
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/api/articles', methods=['GET', 'POST'])
def manage_articles():
    if request.method == 'GET':
        # Return article list with pagination
        pending = publisher.content_manager.get_pending_articles()
        return jsonify({
            'pending_count': len(pending),
            'pending_articles': pending[:10],
            'published_count': len(publisher.content_manager.published)
        })
    
    elif request.method == 'POST':
        # Add new article
        data = request.json
        article_id = publisher.add_content(
            data.get('title'),
            data.get('content'),
            data.get('tags', []),
            data.get('images', []),
            data.get('publish_time')
        )
        return jsonify({
            'status': 'success',
            'article_id': article_id
        })

@app.route('/api/publish', methods=['POST'])
def publish_articles():
    data = request.json or {}
    article_id = data.get('article_id')
    platforms = data.get('platforms', [])
    
    if article_id:
        # Publish specific article
        article = get_article_by_id(article_id)
        results = publisher.publish_all_platforms(article)
    else:
        # Publish all pending
        publisher.auto_publish()
        results = {'status': 'batch_started'}
    
    return jsonify(results)
```

### Step 4: Create Web Interface

```html
<!-- Key patterns for web interface -->
<script>
async function apiCall(endpoint, options = {}) {
    const response = await fetch(`${API_BASE}${endpoint}`, {
        headers: {
            'Content-Type': 'application/json',
            ...options.headers
        },
        ...options
    });
    return response.json();
}

async function addArticle(title, content, tags) {
    const result = await apiCall('/articles', {
        method: 'POST',
        body: JSON.stringify({ title, content, tags })
    });
    
    // Refresh UI
    loadArticlesList();
    updateStats();
}

async function publishArticle(articleId) {
    await apiCall('/publish', {
        method: 'POST',
        body: JSON.stringify({ article_id: articleId })
    });
    
    loadArticlesList();
}
</script>
```

### Step 5: Add Scheduling System

```python
import schedule
import threading

class MultiPlatformPublisher:
    def start_scheduler(self):
        publish_time = self.config.get('schedule', {}).get('publish_time', '09:00')
        
        # Daily scheduled publishing
        schedule.every().day.at(publish_time).do(self.auto_publish)
        
        # Hourly check for immediate publishing
        schedule.every().hour.do(self.auto_publish)
        
        while True:
            schedule.run_pending()
            time.sleep(60)
    
    def auto_publish(self):
        pending_articles = self.content_manager.get_pending_articles()
        max_daily = self.config.get('schedule', {}).get('max_daily_posts', 3)
        
        published_count = 0
        for article in pending_articles:
            if published_count >= max_daily:
                break
            
            # Check if scheduled time has arrived
            publish_time = article.get('publish_time')
            if publish_time and datetime.now() < datetime.fromisoformat(publish_time):
                continue
            
            results = self.publish_all_platforms(article)
            if any(results.values()):
                published_count += 1
```

## Configuration Management

### Config File Structure
```json
{
  "wechat": {
    "enabled": false,
    "app_id": "your_app_id",
    "app_secret": "your_app_secret",
    "author": "author_name",
    "footer": "custom_footer"
  },
  "weibo": {
    "enabled": false,
    "access_token": "your_token",
    "app_key": "your_key"
  },
  "schedule": {
    "auto_publish": true,
    "publish_time": "09:00",
    "max_daily_posts": 3,
    "interval_seconds": 300
  }
}
```

### Environment Setup Script
```python
def install_dependencies():
    requirements = ['requests', 'schedule', 'flask', 'pathlib']
    for package in requirements:
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', package])

def create_directories():
    dirs = ['content', 'images', 'logs']
    for dir_name in dirs:
        os.makedirs(dir_name, exist_ok=True)
```

## Key Design Patterns

### 1. Platform Adapter Pattern
- Unified interface for all platforms
- Easy to add new platforms
- Platform-specific content formatting
- Independent API handling

### 2. Content State Management
- JSON-based storage (easily migrated to DB)
- Publication state tracking
- Duplicate prevention
- Scheduling support

### 3. Multi-Interface Architecture
- Command line interface
- REST API
- Web management interface
- Webhook endpoints

### 4. Error Handling and Resilience
- API rate limiting respect
- Automatic token refresh
- Graceful failure handling
- Comprehensive logging

## Testing Strategy

### API Testing
```python
def test_api_endpoints():
    # Health check
    response = requests.get(f"{base_url}/health")
    assert response.json()['status'] == 'ok'
    
    # Add article
    article_data = {
        "title": "Test Article",
        "content": "Test content",
        "tags": ["test"]
    }
    response = requests.post(f"{base_url}/articles", json=article_data)
    assert response.json()['status'] == 'success'
    
    # Publish test
    response = requests.post(f"{base_url}/publish")
    assert 'message' in response.json()
```

### Platform Adapter Testing
```python
def test_platform_adapter():
    adapter = WeChatAdapter(config)
    
    # Test content formatting
    article = {"title": "Test", "content": "Content", "tags": ["tag1"]}
    formatted = adapter.format_content(article)
    assert "#tag1" in formatted['content']
    
    # Test enabled check
    assert adapter.is_enabled() == config.get('enabled', False)
```

## Common Pitfalls

### API Rate Limits
- Implement proper delays between platform calls
- Respect each platform's rate limiting
- Use exponential backoff for retries

### Token Management
- Automatic token refresh for expired credentials
- Secure storage of API keys
- Graceful handling of authentication failures

### Content Formatting
- Test content adaptation across all platforms
- Handle character limits properly
- Ensure image/media compatibility

### State Consistency
- Atomic operations for publish state updates
- Proper error recovery
- Consistent logging for debugging

## Extension Points

### Adding New Platforms
1. Create new adapter inheriting from PlatformAdapter
2. Implement format_content() and publish() methods
3. Add platform config to JSON schema
4. Register in MultiPlatformPublisher

### Database Integration
```python
# Replace JSON storage with database
class DatabaseContentManager:
    def __init__(self, db_connection):
        self.db = db_connection
    
    def add_article(self, title, content, tags):
        # SQL INSERT logic
        pass
    
    def get_pending_articles(self):
        # SQL SELECT with WHERE status='pending'
        pass
```

### Advanced Scheduling
- Cron-style scheduling expressions
- Time zone handling
- Content pipelines
- A/B testing support

This pattern provides a complete, production-ready foundation for multi-platform content publishing systems.