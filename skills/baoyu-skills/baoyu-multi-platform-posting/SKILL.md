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

## 第三步：博客发布（正确流程）

**必须通过 API POST，封面图在 payload 阶段就写入，不走编辑器。**

### 3.1 生成封面图
```bash
source ~/.baoyu-skills/baoyu-imagine/.env
curl -X POST "https://api.minimaxi.com/v1/image_generation" \
  -H "Authorization: Bearer $MINIMAX_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"image-01","prompt":"纽约客风格prompt","image_size":"1280x720","return_url":true}' \
  --max-time 90 --output /tmp/cover_resp.json

# 提取URL
python3 -c "import json; d=json.load(open('/tmp/cover_resp.json')); print(d['data']['image_urls'][0])"
```

### 3.2 下载并上传封面图
```bash
curl -sL "图片URL" -o /tmp/cover.jpg
curl -X POST "https://blog.filldmy.com/api/uploads" \
  -H "Authorization: Bearer qm_8uXMYOrTzQxFF6I0QAUV_YXKrzchqyBT" \
  -F "file=@/tmp/cover.jpg;type=image/jpeg"
# 返回: {"url":"/api/images/image/2026/04/xxx.jpg",...}
```

### 3.3 API POST 发布文章
封面图markdown必须写入content开头：
```json
{
  "title": "标题",
  "slug": "url-slug",
  "content": "![封面](https://blog.filldmy.com/api/images/image/2026/04/xxx.jpg)\n\n正文...",
  "description": "描述",
  "tags": ["标签"],
  "status": "published"
}
```

```bash
curl -X POST "https://blog.filldmy.com/api/posts" \
  -H "Authorization: Bearer qm_8uXMYOrTzQxFF6I0QAUV_YXKrzchqyBT" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d @/tmp/post.json
```

**注意：**
- `cover_image` API字段无效，必须用 markdown 插入 content 开头
- API PUT 不支持更新文章（报404），编辑只能通过编辑器页面

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

**云端服务器（当前环境）无法调用微信API**，原因：微信对云服务器IP主动拦截（getStableAccessToken返回404，access_token立刻失效），即使IP加白名单也不行。

**正确方式：用浏览器opencli + 手动发布**

```bash
# 打开公众号编辑器
BAOYU_CHROME_PROFILE_DIR=~/Library/Application\\ Support/baoyu-skills/chrome-profile \
  opencli browser open "https://mp.weixin.qq.com"

# 扫码登录后：
# 内容与互动 → 图文消息 → 新的创作 → 图文消息
# 手动粘贴HTML内容 + 上传封面图 → 保存草稿
```

wechat-article.ts 脚本在云端环境不可用（40001错误），仅当agent跑在用户本地机器时才可能成功。

## 平台能力状态

| 平台 | 状态 | 备注 |
|------|------|------|
| 博客 | ✅ | blog.filldmy.com API |
| X/Twitter | ✅ | opencli twitter post |
| 微博 | ⚠️ | opencli browser + 手动发布 |
| 微信公众号 | ⚠️ | 云端环境API不通，浏览器手动发布 |
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

## 关键经验：博客封面图机制

**封面图的正确实现方式：**
- `cover_image` API字段无效，必须用 markdown `![封面](url)` 插入 content 开头
- 博客系统以文章内容里的**第一张图片**作为封面图展示
- ProseMirror 编辑器不支持通过 JS `innerHTML` 插入 markdown 图片语法——图片会显示为原始文本
- 因此：**封面图必须在 API POST 时就写入 content，不走编辑器**

**正确流程：**
```
生成封面图 → 上传获取URL → API POST含封面图markdown的文章 → 完成
```

**错误流程（已验证失败）：**
```
API POST 文章 → 编辑器手动添加封面图 → JS innerHTML插入markdown → 封面不生效
```

## 关键经验：MiniMax API Key

- 必须从 `~/.baoyu-skills/baoyu-imagine/.env` 加载 `MINIMAX_API_KEY`
- 直接 `os.environ` 取不到（execute_code 环境和 shell 环境不同）
- 用 `terminal` + `source .env` 方式最可靠

## 常见问题

**关键经验：博客API调用时content必须是完整HTML字符串，不能传文件路径或占位符。**

```bash
# 正确：content是完整HTML字符串
python3 -c "
import json
with open('/tmp/article.html') as f:
    html = f.read()
data = json.dumps({'title': '...', 'content': html, 'author': '萱宜', 'tags': [...]}).encode('utf-8')
req = urllib.request.Request('https://blog.filldmy.com/api/posts', data=data, headers={'Authorization': 'Bearer TOKEN', 'Content-Type': 'application/json; charset=utf-8'}, method='POST')
with urllib.request.urlopen(req) as r:
    print(r.read())
"

# 错误示例：content里传了占位符字符串
# content: "(见本地文件，已生成)"  ← 文章内容会显示为占位符！
```

**常见问题：Cloudflare ASNNN 屏蔽PUT请求**

blog.filldmy.com 被 Cloudflare ASNNN 保护，PUT 请求返回 1010 ASN 屏蔽。更新文章的正确方式：DELETE 旧文章 → POST 新文章（不是PUT）。slug会变，内容完整比URL不变更重要。

**Q: MiniMax 图像生成失败 login fail?**
A: API Key 不在环境变量中，需 `source ~/.baoyu-skills/baoyu-imagine/.env` 后再调用。

**Q: 微博登录状态丢失？**
A: 确保 BAOYU_CHROME_PROFILE_DIR 指向正确的 Chrome profile 目录。

**Q: 博客 PUT 更新文章报404/1010?**
A: 博客 API 不支持 PUT 更新文章（Cloudflare ASNNN屏蔽PUT）。正确做法：删掉旧文章，重新POST一篇新的。slug会变，但内容完整更重要。

**Q: WeChat API 40001 凭证错误?**
A: 微信API报40001，原因排查顺序：
1. **云端服务器IP被拦截**（本次遇到）——微信对云服务器IP主动拒绝，getStableAccessToken返回404，access_token立即失效。即使IP加白名单也无法通过API调用。**无解，只能用浏览器方式。**
2. access_token已过期——每次调用前必须重新获取
3. IP未加入白名单——部分服务号有IP白名单限制
4. AppSecret错误——确认是账号的原始secret非重置后的

若均无效：浏览器打开 https://mp.weixin.qq.com 扫码登录 → 内容与互动 → 图文消息 → 手动粘贴 → 保存草稿。
