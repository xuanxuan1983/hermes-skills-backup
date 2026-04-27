---
name: ljg-infograph
description: >
  Generates a well-designed infographic (PNG) from user-provided content.
  Auto-structures text into visual modules with grid layout.
  Use when user says "信息图", "infograph", "做成信息图", or wants
  to visualize information as a structured graphic.
user_invocable: true
---

## 约束

本 skill 输出为视觉文件（PNG），不适用 L0 中的 Org-mode、Denote 和 ASCII-only 规范。

## Usage

<example>
User: /ljg-infograph [一段文字或笔记内容]
Assistant: [分析内容，生成信息图 PNG 到 ~/Downloads/]
</example>

## Instructions

### 步骤 1：读取资源

读取以下文件：
- `~/.claude/skills/ljg-infograph/assets/infograph_template.html`
- 确认截图脚本：`~/.claude/skills/ljg-infograph/assets/capture.js`

### 步骤 2：内容分析与模块化

**2.1 提取元信息**

从用户输入中识别：
- **标题**：文章/笔记标题，或从内容提炼（≤ 15 字）
- **副标题**：一句话概括内容核心（≤ 30 字）
- **来源**：作者或出处（用户提供则用，否则 `李继刚`）

**2.2 选择主色调**

整张图使用**单一主色**，根据内容主题选择：

| 主题 | accent | accent-light | accent-dark |
|------|--------|-------------|-------------|
| 科技/AI | `#2563EB` | `#EFF6FF` | `#1E3A5F` |
| 方法论/教育 | `#7C3AED` | `#F5F3FF` | `#3B1F6E` |
| 商业/金融 | `#0D9488` | `#F0FDFA` | `#134E48` |
| 健康/生活 | `#059669` | `#ECFDF5` | `#064E3B` |
| 创意/设计 | `#D97706` | `#FFFBEB` | `#78350F` |
| 通用默认 | `#2563EB` | `#EFF6FF` | `#1E3A5F` |

**2.3 拆分为信息模块**

将内容拆分为 **5-8 个信息模块**，每个模块包含：
- **模块标题**：2-6 字，名词性短语
- **模块类型**：从下表选择
- **模块内容**：该模块的具体信息

| 类型 | 适用场景 | HTML 结构 |
|------|---------|----------|
| `（默认）` | 要点列举 | `ul.check-list > li` |
| `mod-stat` | 关键数字 | `.stat-row > .stat > .stat-number + .stat-label` |
| `mod-steps` | 步骤流程 | `.step-item > .step-num + .step-text` |
| `mod-highlight` | 核心洞察（全宽） | `p.insight` 居中大字 |
| `mod-dark` | 结论/警告（全宽） | 深色底白字，内部可嵌任意元素 |
| `mod-table` | 对比数据 | `table.info-table > th + td` |
| `mod-compare` | A vs B | `.compare-row > .compare-item` |

**禁止使用的模块**：不要生成「关键词/标签」类模块（如 `mod-tags`）。论文关键词、书籍术语索引等属于信息密度极低的填充物，不应出现在信息图中。

**2.4 布局规划**

- 默认占 1 列，`mod-highlight` / `mod-dark` 设为 `span-2`
- 模块不加 `color-*` class——全局只用一个 accent 色
- 相邻两列模块内容量尽量接近，保持视觉对齐
- **孤儿对齐**：模板内置 JS 自动处理——若末尾单列模块落单，会自动展开为全宽。无需手动干预

### 步骤 3：生成 HTML

每个模块渲染为：
```html
<div class="module {类型class} {span-2}">
  <div class="module-title">模块标题</div>
  <!-- 按类型填充 -->
</div>
```

**渲染模板**，替换变量：

| 变量 | 内容 |
|------|------|
| `{{TITLE}}` | 主标题 |
| `{{SUBTITLE}}` | 副标题 |
| `{{ACCENT}}` | 主色 |
| `{{ACCENT_LIGHT}}` | 主色浅底 |
| `{{ACCENT_DARK}}` | 主色深底 |
| `{{GRID_HTML}}` | 所有模块 HTML |
| `{{SOURCE}}` | 来源/署名 |

### 步骤 4：文件命名与截图

文件名从标题提取 `{name}`（中文直接用，去标点，≤ 20 字符）。

```bash
node ~/.claude/skills/ljg-infograph/assets/capture.js /tmp/ljg_infograph_{name}.html ~/Downloads/{name}.png 1080 800 fullpage
```

### 步骤 5：交付

1. 报告文件路径
2. 执行 `open ~/Downloads/`
