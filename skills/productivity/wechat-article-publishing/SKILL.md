---
name: wechat-article-publishing
description: 微信公众号文章全流程发布：从内容 → 封面图生成 → 排版 → 推送草稿箱。包含设计规范、作者卡片生成、两种内容结构模板。
trigger: 用户说「发公众号文章」「帮我发布到微信」「推草稿箱」
---

# 微信公众号文章发布全流程

## 工作流

```
用户 → 发来文章内容/主题
我 → 判断内容类型 → 生成封面图 → 排版 → 推草稿箱
用户 → 公众号后台发布
```

## 内容类型判断

| 类型 | 特征 | 结构 |
|------|------|------|
| 认知型 | 三个观点并列、概念拆解 | 01/02/03 大编号章节 |
| 情绪型 | 一句接一句的追问、刺痛场景 | H2 标题 + 短段落 |

## 封面图生成

**MiniMax China API（推荐）：**
```bash
curl -s -X POST "https://api.minimaxi.com/v1/image_generation" \
  -H "Authorization: Bearer $MINIMAX_CN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "image-01",
    "prompt": "[英文描述，纽约客插画风格]",
    "image_size": "1280x720",
    "return_url": true
  }'
```

> 注意：必须用 `image-01`，不能用 `imagen-01`（不支持）

**纽约客风格封面 prompt 模板：**
```
A sophisticated New Yorker magazine style illustration: [具体场景描述], editorial illustration style, detailed linework, muted blue and gold tones, intellectual and authoritative atmosphere
```

**v29封面 prompt 模板：**
```
In the style of image_0.png, using a high-density, hard-edged polya dot halftone screen texture. [具体英文场景描述]. Rendered with heavy, hand-drawn black ink outlines. Minimalist, clean yet high-contrast aesthetic.
```

## 配图生成

同一文章需要 3 张正文配图（纽约客风格）：
1. 场景/概念解释图
2. 数据/对比/时间线图
3. 关键词/引用类图

生成后上传到博客获取公开 URL，再嵌入 HTML。

## 图片上传到博客（用于微信公众号）

微信公众号无法引用外链图片，必须先上传到已有域名获取 media_id：

```bash
curl -s -X POST "https://blog.filldmy.com/api/uploads" \
  -H "Authorization: Bearer qm_8uXMYOrTzQxFF6I0QAUV_YXKrzchqyBT" \
  -F "file=@/path/to/image.jpg"
```
返回 `url` 字段，在 HTML 中使用完整 URL `https://blog.filldmy.com` + url。

## 模板选择（auto 自动判断）

```bash
bun run ~/.hermes/skills/baoyu-skills/skills/baoyu-post-to-wechat/scripts/wechat-api.ts \
  ~/Desktop/03-Content/文章名.md \
  --type news --author "萱宜" --template auto --cover ~/cover.jpg
```

| 条件 | 模板 |
|------|------|
| 2-5 个顶格 H2 + 结构化信号（编号/步骤/法则） | v29（01/02/03 大编号 + 牛皮纸纹理） |
| 6+ 个 H2 章节 | ny（纽约客皱纹纸模板） |
| 其他 | ny（默认） |

**v29 wrapper**：`~/.hermes/skills/baoyu-skills/skills/baoyu-post-to-wechat/wrappers/v29.html`
**ny wrapper**：`~/.hermes/skills/baoyu-skills/skills/baoyu-post-to-wechat/wrappers/ny.html`

## 已知 Bug & Fix（必读）

### md-to-wechat H2 解析失败

md-to-wechat 生成的 HTML 中 `>` 被编码为 `&gt;`，导致解析器把 `</h2>` 错误匹配到开标签内部。

**已修复**：wechat-api.ts 中跳过 `&` 后面的 `>`，并跳过紧贴开标签的 `</h2>`（<10字符间隔）。

### md-to-wechat 蓝色字体

h2 里注入蓝色 `color:#1E50A2`。已在 wechat-api.ts 中 strip 三种蓝色格式。

### WeChat API 403/1010

用 `bun run wechat-api.ts`，不用 Python urllib（Cloudflare 拦截）。

## 推送命令

```bash
bun run ~/.hermes/skills/baoyu-skills/skills/baoyu-post-to-wechat/scripts/wechat-api.ts \
  ~/Desktop/03-Content/文章名.md \
  --type news --author "萱宜" --template auto --cover ~/cover.jpg
```

**成功标志**：`Published successfully! media_id: ...`

**配色规范（纽约客风）：**
- 暖白底：`#f2ede4` + SVG纸张纹路
- 深灰字：`#3d3d3d`
- GHOST编号：`rgba(62,62,62,0.1)` 透明大字
- 副标题色：`#c0b8a8`
- 分隔线：`rgba(62,62,62,0.09)`

**字体（WeChat 兼容）：**
- 标题：Source Han Serif CN / Noto Serif SC
- 正文：PingFang SC
- 副标题/标签：SF Mono / Menlo（等宽英文字母间距）

**纽约客风文章结构：**
- 封面图：全宽纽约客插画风格
- 引言：一句核心观点（非摘要重复）
- 01/02/03 章节：大编号锚点（82px透明字）+ 中文标题 + 英文副标题
- 配图：纽约客风格插画（3:2比例）
- 分隔：1px细线
- 一句话总结：斜体居中
- 作者区：灰底卡片，姓名/职业/简介

**v29文章结构：**
- 顶部元信息：共 X 字 · 阅读约 Y 分钟
- 引言：一句核心观点（非摘要重复）
- 01/02/03 章节：大编号锚点 + 中文标题 + 英文副标题
- 分隔：60px 居中细线
- 作者区：圆形头像（72px）+ 简介

## 作者卡片（图片方案）

用 PIL 生成作者卡片图，比 HTML/CSS 更稳定：

1. 用 `/tmp/make_author_card.py` 脚本
2. 圆形头像 + 暖白底 `#FAF5EF`
3. 衬线字体名字 + 等宽职业标签
4. 直接嵌入文章底部 `<img src="/tmp/author_card.png" style="width:100%" />`

## 推送命令

```bash
bun ~/.hermes/skills/baoyu-skills/skills/baoyu-post-to-wechat/scripts/wechat-api.ts \
  [文章.html路径] \
  --account zxy-growth \
  --cover [封面图路径] \
  --title "[标题]"
```

账号别名：zxy-growth（陈萱宜的增长实验室）

## WeChat CSS 限制（重要）

以下效果在 WeChat 中会被覆盖或失效：
- SVG 背景纹理 → 用纯色背景
- 自定义 Google Fonts → 使用系统字体
- CSS letter-spacing 扩展英文单词间距 → 避免在多单词标签上用 letter-spacing
- 复杂的 CSS 背景层级 → 用图片代替

## 文件路径

- 模板：`~/.baoyu-skills/baoyu-post-to-wechat/article_template.html`
- 签名：`~/.baoyu-skills/baoyu-post-to-wechat/wechat_signature.md`
- 图片 key：`~/.baoyu-skills/baoyu-imagine/.env`
- 作者卡片脚本：`/tmp/make_author_card.py`
