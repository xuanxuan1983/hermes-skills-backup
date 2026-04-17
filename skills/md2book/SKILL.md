---
name: md2book
description: AI驱动的技术书籍创作与出版系统，支持从大纲到PDF的完整流程：联网研究、逐章创作、OReilly风格排版、专业PDF生成
trigger: 用户要求将 Markdown 转 PDF、制作 PDF 电子书、书籍导出 PDF、md转pdf、生成pdf、markdown转pdf、书籍排版、制作书籍PDF、写书、创作技术书、生成书籍、AI写书、技术写作、出版级书籍
tags: [writing, publishing, ai-creation, technical-books, pdf-generation]
related_skills: [research-paper-writing, content-creation, proposal, obsidian]
---

# AI-Powered Technical Book Creation & Publishing System

🚀 **从概念到出版级技术书籍的完整AI创作流水线**

支持两种核心模式：
1. **📖 书籍创作模式** - 从大纲开始，AI驱动的完整书籍写作流程（类似 lovstudio tech-book）
2. **🔄 转换模式** - 将现有 Markdown 文件转为专业排版PDF

## 核心能力

### ✨ AI 创作引擎
- **联网深度研究** - 每章写作前自动拉取最新资料和一手文档
- **逐章顺序创作** - 保证上下文连贯性，避免并行创作的逻辑断层
- **OReilly 风格约束** - 场景引入、代码示例、架构图、实战经验小节

### 🎨 专业排版系统
- **智能分页控制** - 章节自动分页，避免孤行和widow行
- **中文完美渲染** - 优化的中文字体栈，专业排版算法
- **多主题支持** - minimal/academic/playful 三种出版级视觉风格

### 📊 质量保障机制
- **实时引用验证** - 确保所有引用数据的真实性和时效性
- **结构一致性检查** - 自动验证章节逻辑和递进关系
- **输出质量评估** - 多维度评分与改进建议

## 何时使用

### 📚 书籍创作场景
- "我想写一本关于[技术主题]的书"
- "帮我生成一本出版级的技术教程"
- "基于这个大纲创作完整的技术书籍"

### 🔄 文档转换场景
- 用户提供 Markdown 文件路径，要求转为 PDF
- 用户提到"导出 PDF"、"生成电子书"、"制作 PDF"
- 用户需要书籍级别的排版输出

## 快速命令

```bash
node scripts/md2book.js <input.md>
node scripts/md2book.js <input.md> --theme <minimal|academic|playful>
node scripts/md2book.js <input.md> --output <path.pdf>
node scripts/md2book.js <input.md> --verbose
```

## 完整工作流程

### Phase 0: 环境准备 (首次使用必须)

1. **检查依赖安装**：
   ```bash
   cd ~/.hermes/skills/md2book/scripts
   ls node_modules/ || npm install
   ```

2. **安装 Playwright 浏览器**（如果未安装）：
   ```bash
   cd ~/.hermes/skills/md2book/scripts
   npx playwright install chromium
   ```

3. **验证环境**：
   ```bash
   node md2book.js --help
   ```

### Phase 1: 检查输入

1. 确认用户提供了 Markdown 文件路径
2. 检查文件是否存在
3. 检查文件是否有 YAML frontmatter（title, author, date 等）
4. 如果没有 frontmatter，询问用户补充关键信息（书名、作者）

### Phase 2: 确认参数

向用户确认：
- **主题风格**（默认 minimal）：
  - `minimal` — 极简科技风（大量留白，黑白灰，适合技术书）
  - `academic` — 经典学术风（衬线字体，暖色纸张，稳重专业）
  - `playful` — 活泼插画风（色彩丰富，渐变装饰）
- **输出路径**（默认与 MD 文件同级目录）
- **是否需要目录**（默认生成）

### Phase 3: 执行转换

```bash
cd ~/.hermes/skills/md2book/scripts
node md2book.js <input.md> --theme <theme> --verbose
```

### Phase 4: 验证输出

1. 检查 PDF 文件是否生成
2. 验证以下项目：
   - [ ] 封面正常渲染（书名、作者可见）
   - [ ] 版权页包含完整信息
   - [ ] 目录生成正确
   - [ ] 每个 `#` 章节从新页面开始
   - [ ] 中文无乱码
   - [ ] 页码连续
   - [ ] 代码块/表格未被截断
3. 如果有问题，检查错误日志并修复

## 输入文件格式

Markdown 文件应包含 YAML frontmatter：

```yaml
---
title: 书名
subtitle: 副标题（可选）
author: 作者名
publisher: 出版社（可选）
version: v1.0
date: 2026-04-10
isbn: 978-0-000000-00-0（可选）
description: 一句话简介
---

# 第一章 引言

正文内容...

## 1.1 概述

更多内容...
```

### 支持的 Markdown 特性

- 标准 GFM（表格、代码块、列表）
- 代码语法高亮（highlight.js）
- Callout 提示框：`[!INFO]`, `[!TIP]`, `[!WARNING]`, `[!DANGER]`
- 图片和图注
- 引用块
- 自动目录生成

## 视觉主题说明

### minimal（极简科技风）
- 纯白背景，黑白灰色调
- 思源宋体正文 + 黑体标题
- 简洁的装饰线条
- 适合：技术文档、编程教程

### academic（经典学术风）
- 暖色纸张质感背景
- 深红色强调色
- 经典衬线字体
- 适合：理论著作、学术专著

### playful（活泼插画风）
- 渐变彩色封面
- 圆角卡片设计
- 丰富的色彩变化
- 适合：入门教程、科普读物

## 常见问题

### 首次使用 - 路径或依赖错误
如果遇到 "找不到文件" 或 "模块未找到" 错误：
1. 确认在正确目录：`cd ~/.hermes/skills/md2book/scripts`
2. 安装依赖：`npm install` 
3. 安装浏览器：`npx playwright install chromium`
4. 测试运行：`node md2book.js --help`

## 故障排查

### 中文显示为方框
- 检查系统是否安装了思源宋体或宋体
- macOS 自带 Songti SC 和 STSong
- 可在 `references/font-guide.md` 中查看字体配置

### Playwright 浏览器未安装
```bash
cd ~/.hermes/skills/md2book/scripts
npx playwright install chromium
```

### 依赖未安装
```bash
cd ~/.hermes/skills/md2book/scripts
npm install
```

### PDF 内容为空
- 检查 Markdown 文件编码是否为 UTF-8
- 使用 `--verbose` 查看转换日志
- 检查 frontmatter 格式是否正确

### Chromium 浏览器找不到
- 脚本会自动检测 `~/Library/Caches/ms-playwright/` 下的 Chromium
- 如果未安装，运行 `npx playwright install chromium`
- 确认安装后重新运行转换命令

## 相关文件

- `scripts/md2book.js` — 主转换脚本
- `scripts/package.json` — 依赖配置
- `assets/styles/book.css` — 书籍核心样式（分页、页眉页脚）
- `assets/styles/typography.css` — 中文字体排版
- `assets/styles/components.css` — 表格/代码块/引用/Callout 样式
- `assets/styles/themes/` — 三套视觉主题（minimal, academic, playful）
- `references/font-guide.md` — 字体配置参考
