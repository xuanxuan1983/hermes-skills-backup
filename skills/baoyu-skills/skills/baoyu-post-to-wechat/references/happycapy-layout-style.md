# 萱宜公众号文章排版规范（2025版）

## 两套模板

| 模板 | 文件 | 适用场景 |
|------|------|---------|
| 模板一（Competence型） | `article_template.html` | 认知型文章，三个观点并列，有大编号装饰 |
| 模板二（Training型） | `article_template_v2.html` | 观点型文章，逻辑严密，有讽刺感，含纽约客插画 |

模板文件位置：`~/.baoyu-skills/baoyu-post-to-wechat/`

---

## 通用排版规范

### 字体 + 行距 + 字间距（经微信实测有效）
- 正文：16px / 行距1.75 / 字距1px
- 章节标题：衬线字体 22px
- 章节副标题：等宽英文字母，字距2.5px
- 引言块：16px，字距同正文
- 作者区简介：15px / 行距1.75 / 字距2px

### 配色方案
- 背景：`#FAF5EF`（暖白，微信可见）
- 正文：`#3D3D3D`（暖黑）
- 标题：`#1A1A1A`（近黑）
- 副标题/元信息：`#AAAAAA` / `#B8A898`（暖灰）
- 引言左边框：`#C8BEB0`（暖灰）
- 分隔线：`#D4C8B8`（暖灰）
- 插图描边：`#E8DED0`（极淡暖灰）

### 微信渲染限制（经验证）
- `border-top` 样式会被微信强制覆盖 → 用 `<hr>` 元素代替
- SVG 背景噪点不支持 → 用纯色 `#FAF5EF` 代替
- 字体渲染依赖系统字体，建议使用：`PingFang SC` / `Noto Serif SC` / `SF Mono`

---

## 封面图生成规范

### 风格一：硬核复古（Gem System 2.0）
用于：公众号封面图

```
In the style of image_0.png, using a high-density, hard-edged polka dot halftone screen texture. The dots must be solid black and sharp, with zero transparency or gradient, creating a raw, coarse Riso print effect. Featuring a vivid, grainy vivid orange textured background wall and a contrasting neon teal floor.
[场景描述].
Rendered with heavy, hand-drawn black ink outlines. Minimalist, clean yet high-contrast aesthetic. It evokes a 1960s educational manual print feel. Wide angle view.
```

Prompt模板（JSON格式）：
```json
{
  "Gem_System": "Hardcore Retro-Tech Gem 2.0 (Full Auto)",
  "Article_Content": {
    "Title": "[标题]",
    "Keywords": "[3个核心英文关键词]",
    "Scene_Description": "[英文具体物理场景]"
  },
  "Style_Preferences": {
    "Vibe": "educational manual print, Riso print",
    "Complexity": "wide angle, focused on detail"
  }
}
```

### 风格二：纽约客插画风
用于：文章内容配图

```
New Yorker magazine illustration style. Hand-drawn ink sketch, fine cross-hatching, muted sepia and grey tones. [场景描述]. Intellectual humor, understated elegance. Black ink lines on cream paper. Like a New Yorker cover illustration. 4K detailed.
```

---

## 模板一（Competence型）结构
- 顶部：元信息（字数 + 阅读时间）
- 内容：01/02/03大编号章节 + 引言块
- 作者区：圆形头像（72px）+ 居中文字 + 简介

## 模板二（Training型）结构
- 顶部：字数+阅读时间（12px斜体）
- 内容：衬线章节标题 + 等宽英文副标题 + 引言块
- 配图：3-4张纽约客插画（对应核心观点场景）
- 分隔线：`<hr>` 暖色
- 作者区：圆形头像（100px居中）+ 居中文字 + 简介

---

## 微信公众号账号配置
```
~/.baoyu-skills/baoyu-post-to-wechat/EXTEND.md
```

| 账号 | AppID | 用途 |
|------|-------|------|
| 陈萱宜的增长实验室 | wx21be176ab87280d7 | zxy-growth |
| DMY她时尚 | wx10951656e9a582db | dmy-fashion |
