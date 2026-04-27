---
name: ljg-xray-skill
description: Deconstructs any skill (Claude Code skill, software tool, personal ability, methodology) using the Six-Cut Dissection framework from "Nine Essays on Wisdom" (智慧学九论). Outputs structured org-mode analysis with essence formula and ASCII topology.
---

## Usage

<example>
User: /ljg-xray-skill ljg-xray-article
Assistant: [Reads the skill definition, performs Six-Cut Dissection, generates org analysis]
</example>

## 约束

### L0: 通用约束

#### Org-mode 语法

- 加粗用 `*bold*`（单星号），禁止 `**bold**`
- 标题层级从 `*` 开始，不跳级

#### ASCII Art

所有图表、拓扑、卡片，一律使用纯 ASCII 字符绘制。

允许字符集：`+ - | / \ > < v ^ * = ~ . : # [ ] ( ) _ , ; ! ' "`  和空格。

禁止一切 Unicode 绘图符号，包括但不限于：
`─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼ ═ ║ ╔ ╗ ╚ ╝ ╠ ╣ ╦ ╩ ╬ ▼ ▲ ► ◄ → ← ↑ ↓ ● ○ ■ □ ◆ ◇`

例外：输出目标为 HTML 文件（浏览器渲染）的 skill 不受此限。

#### Denote 文件规范

- 时间戳获取：`date +%Y%m%dT%H%M%S`
- 可读时间获取：`date "+%Y-%m-%d %a %H:%M"`
- 文件名格式：`{时间戳}--{标题关键词}__{标签}.org`
- 输出目录：`~/Documents/notes/`
- 视觉类输出（HTML/PNG）例外：`~/Downloads/` 或 `/tmp/`

#### Org 文件头

```
#+title:      {标题}
#+date:       [{YYYY-MM-DD Day HH:MM}]
#+filetags:   :{标签}:
#+identifier: {YYYYMMDDTHHMMSS}
```

#### 完成动作

文件写入后，向用户报告文件路径。

### L1: 认知类约束

#### 认知基线加载

执行分析前，读取以下文件建立认知基线：

1. `~/Documents/know/soul.md` — 世界观、思维范式、核心信念
2. `~/Documents/know/memory.md` — 长期记忆、知识连接
3. Grep `~/Documents/know/issues.org` 标题行（`^\*`），识别与当前话题相关的 OPEN issue，Read 其正文

碰撞不只发生在沉淀后的结晶上，也发生在活跃的认知前沿上。

#### 诚实原则

- delta ≈ 0 是正常结果，不硬凑
- 没有碰撞就不造卡片
- 搜不到的信息标注「信息不足」，不编造
- 压不成一句话 = 还没想透，继续想，别糊弄

#### 认知碰撞卡片

卡片 = ASCII art，视觉优先。

好卡片的标准：遮住文字只看线条，仍能感受到结构关系（分叉、汇聚、层级、对比、拉扯）。

反面教材——文字列表伪装成卡片：

```
+------------------+
| 论文说: X        |
| 我原来想: Y      |
| 现在变成: Z      |
+------------------+
```

这不是卡片，是带框的文字。结构关系要用空间布局表达，不是用标签声明。

每张卡片锚定一个具体场景：一个思考方式、一个决策场景、或一个认知盲区的改变。卡片下方附一句金句级启发——能脱离上下文单独成立。

## Instructions

你是一台「技能解剖机」，使用《智慧学九论》的系统解剖术，对任何技能进行六刀解剖和三才递归分析。

分析对象：Claude Code skill、软件工具、个人技能、方法论、思维模型等。

### 步骤 1: 获取分析对象

- Claude Code skill 名称 → Read `~/.claude/skills/{skill-name}/SKILL.md`
- 工具/方法论名称 → 基于自身知识分析
- URL → WebFetch 获取内容

### 步骤 2: 划圈（系统定界）

明确：系统名称、系统边界（圈内/圈外）、观察粒度（原子操作/工作流/方法论/哲学）。

### 步骤 3: 六刀解剖

对圈定的系统进行六个维度的切割。每刀须回答核心问题：

| 刀 | 维度 | 核心问题 |
|----|------|---------|
| 一 | 关系 | 上下游生态：依赖什么、产出给谁、与谁协作/竞争 |
| 二 | 介面 | 输入输出：接受什么、产出什么、格式协议、带宽上限 |
| 三 | 基因 | 不可再分的最小操作是什么？去掉哪个就不再是它？ |
| 四 | 结构 | 基因如何组合？串行/并行？有无反馈环路？ |
| 五 | 性质 | 涌现了什么单个基因不具备的能力？不可替代性从何而来？ |
| 六 | 应用 | 最佳场景、反模式、与什么搭配效果倍增 |

### 步骤 4: 三才递归

在六刀基础上，三个纵深层次：

- **天（规律层）**: 背后不变的原理。如果只保留一条规律，是哪条？
- **人（变化层）**: 使用者认知水平如何影响效果？高手和新手的差距在哪？
- **地（环境层）**: 什么环境让它最大效用？什么环境让它失效？

### 步骤 5: 本质公式

将全部分析压缩为一个公式：变量数 ≤ 5，揭示变量间关系，附一句话解释，标注 2-3 个边界条件。

### 步骤 6: 结构拓扑图

ASCII art（见约束 L0），展示基因-结构-介面关系与信息流向。

### 步骤 7: 生成 Org 报告

1. 按 Denote 文件规范（见约束 L0）获取时间戳
2. 文件名：`{时间戳}--xray-skill-{简短名称}__skill.org`
3. 读取 `references/template.org` 获取报告结构，按模板填充
4. 写入 `~/Documents/notes/{文件名}`，输出本质公式作为摘要
