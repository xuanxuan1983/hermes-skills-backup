---
name: multi-platform-article-publish
description: 多平台文章发布工作流：微信公众号(v29/纽约客双模板) + 博客 + X线程 + 微博，一站式完成。触发：用户说"发文章"、"发到公众号"、"多平台发布"。
triggers:
  - 发文章
  - 发到公众号
  - 发到博客
  - 多平台发布
  - 发布文章
---

# Multi-Platform Article Publishing Workflow

多平台文章发布工作流：微信公众号 + 博客 + X线程 + 微博，一站式完成。

## 模板选择规则

### v29 模板（硬核复古）
- **特征**：01/02/03大编号 + happycapy极简留白 + Hardcore Retro-Tech Gem封面图
- **适用**：干货方法论、工具测评、增长实战、数据驱动型内容
- **封面图风格**：Gem System 2.0（机器人+撞色背景+技术图解）

### 纽约客杂志风（New Yorker Magazine）
- **特征**：暖白纸张背景+皱纹纹路+GHOST背景字+大号英文副标题+纽约客插画风格配图
- **适用**：专家视角、行业洞察、个人IP、认知升级、深度分析
- **封面图风格**：New Yorker editorial illustration（精致线条+知识分子气质）

### 选择决策树
```
内容有强烈个人视角/专家署名/行业分析/认知启蒙？
  是 → 纽约客杂志风
  否 → 内容是方法论/工具/数据/实操步骤？
        是 → v29
        否 → 纽约客杂志风
```

## 发布平台优先级

1. **博客** — 母稿，永久沉淀，GEO入口
2. **微信公众号** — 转化场，深度内容+成交
3. **X/Twitter** — 测试场，短内容验证选题
4. **微博** — 热点追踪（可选）

## 执行步骤

### Step 1: 内容分析与模板选择

读取用户提供的文章内容，判断模板类型，提取：
- 标题、核心主题、章节结构、关键数据/观点

### Step 2: 图片生成（MiniMax）

**封面图 prompt 模板（v29）**：
```
A futuristic retro-tech illustration featuring a humanoid robot or AI interface, bold geometric shapes, educational manual print aesthetic, Riso print colors (copper blue, cyan, magenta on cream background), wide angle, technical diagram feel, high contrast, educational poster style
```

**封面图 prompt 模板（纽约客）**：
```
A sophisticated New Yorker magazine style illustration: [具体场景], editorial illustration style, muted blue and gold tones, detailed linework, intellectual atmosphere, warm paper texture
```

**配图 prompt（纽约客）**：根据文章内容场景定制

生成后上传到博客获取公开URL：
```bash
curl -X POST https://blog.filldmy.com/api/uploads \
  -H "Authorization: Bearer qm_8uXMYOrTzQxFF6I0QAUV_YXKrzchqyBT" \
  -F "file=@/tmp/image.jpg"
```

### Step 3: 博客发布

```bash
curl -X POST https://blog.filldmy.com/api/posts \
  -H "Authorization: Bearer qm_8uXMYOrTzQxFF6I0QAUV_YXKrzchqyBT" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d @/tmp/blog-post.json
```

### Step 4: 微信公众号发布

**优先用 API 方式**（稳定，自动处理图片URL上传）：
```bash
SKILL_DIR=~/.hermes/skills/baoyu-skills/skills/baoyu-post-to-wechat
BAOYU_CHROME_PROFILE_DIR=~/Library/Application\ Support/baoyu-skills/chrome-profile \
  bun "$SKILL_DIR/scripts/wechat-api.ts" /path/to/article.html \
  --title "标题" --author "萱宜" --summary "摘要" --account zxy-growth
```

图片处理流程：
1. 先把图片上传到博客（`POST https://blog.filldmy.com/api/uploads`）获取公开URL
2. HTML里的图片src直接用博客的公开URL
3. `wechat-api.ts` 会自动把URL图片下载并上传到微信服务器

**不要用浏览器方式**（`wechat-article.ts`）——Chrome daemon经常断，连接不稳定，需要手动介入。

### Step 5: X线程发布

每条推文：
```bash
BAOYU_CHROME_PROFILE_DIR=~/Library/Application\ Support/baoyu-skills/chrome-profile \
  opencli twitter post "🧵/N 内容 #hashtag"
```

### Step 6: 微博（可选）

用 Chrome 打开 `https://card.weibo.com/article/v3/editor` 手动发布

## 关键路径

- v29模板：`~/.hermes/skills/baoyu-skills/skills/baoyu-post-to-wechat/references/模板_v29.html`
- 纽约客模板：`~/.hermes/skills/productivity/wechat-magazine-article/references/article_template_v18.html`
- 博客Token：`qm_8uXMYOrTzQxFF6I0QAUV_YXKrzchqyBT`
- 账号：zxy-growth（陈萱宜的增长实验室）

## 踩坑记录

- **微信发布优先用 API 方式**：`wechat-api.ts` 比浏览器方式更稳定
- **微信封面图必须通过 API 上传**：不能用外链，必须先上传获取 media_id
- **Chrome debug port 超时**：先 `pkill -f "remote-debugging-port"` 再重试
- **博客封面上传可能403**：先用外链 URL，事后手动后台替换

## 换电脑恢复

需要手动重新配置：
- API keys（不在 GitHub 里）
- OpenCLI + Chrome 扩展
- Chrome profile 登录状态（微博/X）
- 博客 Admin 密码

已备份（git clone 即可恢复）：
- `~/.hermes/skills/` 全部
