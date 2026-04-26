---
name: baoyu-multi-platform-posting
description: 多平台内容发布完整工作流：博客+微博+公众号+X。从文章内容到全平台分发的标准化流程。
trigger: 用户说"发到X个平台"、发布文章到多个社交媒体平台、或需要把一篇内容同步到多个渠道。
---

# baoyu-multi-platform-posting

多平台内容发布完整工作流。从文章内容到博客+微博+公众号+X的全流程。

## 工作流总览

```
用户提供文章内容
    ↓
内容拆解适配各平台
    ↓
封面图生成（MiniMax）
    ↓
博客发布（API）
    ↓
X线程发布（opencli）
    ↓
微博文章（opencli browser）
    ↓
微信公众号（wechat-article.ts）
```

## 第一步：内容拆解适配

根据文章内容，生成各平台版本：
- **博客**：完整原文 + 封面图 markdown 插入开头
- **微博**：头条文章格式（标题+精华段落）
- **X**：9条线程格式，每条140字内
- **公众号**：HTML格式，含表格、引用、分割线

## 第二步：生成封面图（MiniMax）

```python
import urllib.request, json

payload = json.dumps({
    "model": "image-01",  # 注意：不是 imagen-01
    "prompt": "描述词",
    "image_size": "1280x720",
    "return_url": True
}).encode()

req = urllib.request.Request(
    "https://api.minimaxi.com/v1/image_generation",
    data=payload,
    headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
    method="POST"
)
with urllib.request.urlopen(req, timeout=60) as resp:
    result = json.loads(resp.read())
    # 响应字段是 image_urls（数组），不是 image_url
    img_url = result["data"]["image_urls"][0]
    # URL 里的 %2F 要替换才能下载
    img_url = img_url.replace("%2F", "/").replace("%25", "%")
```

## 第三步：博客发布

### 3.1 上传封面图
```bash
curl -X POST "https://blog.filldmy.com/api/uploads" \
  -H "Authorization: Bearer {token}" \
  -F "file=@/path/to/cover.jpg;type=image/jpeg"
```

### 3.2 发布文章
封面图必须以 markdown 形式写入 content 开头：
```json
{
  "title": "标题",
  "slug": "url-slug",
  "content": "![封面](https://blog.filldmy.com/api/images/image/...)\n\n正文...",
  "description": "描述",
  "tags": ["标签1", "标签2"],
  "status": "published"
}
```
注意：`cover_image` API 字段不生效，必须用 markdown 插入内容开头。

```bash
curl -X POST "https://blog.filldmy.com/api/posts" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d @/tmp/post.json
```

### 3.3 更新已有文章
```bash
curl -X PUT "https://blog.filldmy.com/api/posts/{slug}" ...
```

## 第四步：X线程发布

```bash
BAOYU_CHROME_PROFILE_DIR=~/Library/Application\ Support/baoyu-skills/chrome-profile \
  opencli twitter post "推文内容"  # 每次一条，逐条发
```

## 第五步：微博文章

### 方法1：脚本（容易超时）
```bash
cd ~/.hermes/skills/baoyu-skills/skills/baoyu-post-to-weibo
SKILL_DIR=~/.hermes/skills/baoyu-skills/skills/baoyu-post-to-weibo
BAOYU_CHROME_PROFILE_DIR=~/Library/Application\ Support/baoyu-skills/chrome-profile \
  bun "$SKILL_DIR/scripts/weibo-article.ts" /path/to/article.md
```

### 方法2：浏览器直接填（推荐，成功率更高）
```bash
BAOYU_CHROME_PROFILE_DIR=~/Library/Application\ Support/baoyu-skills/chrome-profile \
  opencli browser open "https://card.weibo.com/article/v3/editor"
# 内容填好后用户手动点发布
```
封面图在编辑器右侧栏手动上传。

## 第六步：微信公众号

```bash
cd ~/.hermes/skills/baoyu-skills/skills/baoyu-post-to-wechat
SKILL_DIR=~/.hermes/skills/baoyu-skills/skills/baoyu-post-to-wechat
BAOYU_CHROME_PROFILE_DIR=~/Library/Application\ Support/baoyu-skills/chrome-profile \
  bun "$SKILL_DIR/scripts/wechat-article.ts" \
  --html /path/to/article.html \
  --title "文章标题"
```
注意：`--html` 和 `--title` 是命名参数，不是位置参数。草稿自动保存到公众号后台。

## 平台能力状态

| 平台 | 状态 | 备注 |
|------|------|------|
| 博客 | ✅ | blog.filldmy.com API |
| X/Twitter | ✅ | opencli twitter post |
| 微博 | ✅ | opencli browser + 手动发布 |
| 微信公众号 | ✅ | wechat-article.ts 脚本 |
| 知乎 | ❌ | 无发文命令，需浏览器自动化 |
| Notion | ⏳ | API可连，但页面需手动分享 |

## 常见问题

**Q: wechat-article.ts 报 Module not found?**
A: 确认在 skill 目录下运行：
```bash
cd ~/.hermes/skills/baoyu-skills/skills/baoyu-post-to-wechat
```

**Q: 微博文章脚本超时？**
A: 改用 opencli browser 方式，内容填好后用户手动点发布。脚本 launch Chrome 会超时。

**Q: 博客封面图不显示？**
A: `cover_image` API字段无效，必须用 markdown 格式 `![封面](url)` 插入 content 正文开头。

**Q: MiniMax 图像生成失败 invalid model?**
A: 模型名是 `image-01`，不是 `imagen-01`。

**Q: MiniMax 图像生成失败 unsupported model?**
A: 账号可能没有开通图像生成 API，只有文本 API。换用其他图源或让用户手动处理。

**Q: 微博登录状态丢失？**
A: 确保 BAOYU_CHROME_PROFILE_DIR 指向正确的 Chrome profile 目录。
