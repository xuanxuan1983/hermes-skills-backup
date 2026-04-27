---
name: ljg-xray-prompt
description: Deconstructs a user-provided prompt using the "Universal Gravity Formula" (Ω = A + M · V). It extracts the Persona (Anchor), Intent (Vector), and Logic (Matrix), and visualizes the flow topology using high-fidelity ASCII art rendered in a local retro-styled HTML file.
---

## 约束

本 skill 输出为 HTML 文件（浏览器渲染），不适用 L0 中的 Org-mode、Denote 和 ASCII-only 规范。

## Usage

<example>
User: 请分析这个提示词："你是一位冷酷的代码审查员..."
Assistant: [Calls ljg-xray-prompt with the prompt content]
</example>

## Instructions

为了执行 Prompt 万有引力分析，请严格按以下步骤操作：

1. 读取资源与模版
请读取以下两个文件的全部内容并暂存到内存中：
- `assets/template.html`
- `references/topology_examples.md` (高保真 ASCII 范例库)

2. 意向与配色分析
感知 input_prompt 的整体意象，选择配色方案：
- 经典黑客: #0f0 (主色), #000 (背景), #004400 (暗色)
- 復古终端: #ffb000 (主色), #1a1a00 (背景), #664400 (暗色)
- 赛博朋克: #0ff (主色), #001a1a (背景), #004444 (暗色)
- 警告高压: #ff3333 (主色), #1a0000 (背景), #440000 (暗色)

记录颜色代码（COLOR_MAIN, COLOR_BG, COLOR_DIM）及主题名（THEME_NAME）。

3. 逻辑解构 (Ω 公式)
基于 Ω(Output) = Project [ A + M · V ] 提取内容：
- A (Anchor): 初始坐标/人设
- V (Vector): 意图/动力
- M (Matrix): 拓扑算子/逻辑结构

4. 拓扑绘制 (核心步骤)
判断 input_prompt 的核心逻辑形状，从 `references/topology_examples.md` 中选择最匹配的一个范式（线性、辩证、双轨、闭环或递归）。

**绘制要求**：
- **骨架复用**：直接使用范例中的 Unicode 制表符 (Box-Drawing Characters)，确保图形结构坚固。
- **内容注入**：不要保留范例中的 "Step 1" 或 "Thesis" 等占位符，而是将第 3 步分析出的具体内容（简短的关键词）填入 ASCII 框中。
- **排版对齐**：填入文字后，必须手动调整空格和线条长度，确保 ASCII 图形的对齐和美观。不要让线条断裂。

5. 渲染与写入文件
使用分析结果替换 `template.html` 中的变量：
- 替换所有颜色变量 ({{COLOR_MAIN}} 等) 和内容变量 ({{ANCHOR}} 等)。
- 将 {{TOPOLOGY_ASCII}} 替换为第 4 步绘制的 ASCII 图形。

**执行文件操作**：
1.  创建文件 `/tmp/ljg_xray_prompt_analysis_result.html`。
2.  将渲染后的 HTML 写入文件。

6. 唤起浏览器
执行系统命令打开文件：
- macOS: `open /tmp/ljg_xray_prompt_analysis_result.html`

向用户报告分析完成，并展示 ASCII 拓扑图的一个缩略预览。
