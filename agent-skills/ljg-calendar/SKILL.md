---
name: ljg-calendar
version: "1.2.0"
description: "macOS Calendar read/write via AppleScript. Use when user says '加到日历', '添加日历', '写入日历', '下周安排', '日程', '日历', 'calendar', or provides text/image with event details to schedule, or asks about upcoming events."
---

## Usage

<example>
User: 加到日历 [附带聊天截图或文本描述]
Assistant: [Calls ljg-calendar, parses content, writes to Calendar]
</example>

<example>
User: 明天下午3点开会，在望京SOHO，帮我加到日历
Assistant: [Calls ljg-calendar with the text]
</example>

<example>
User: 下周有什么安排
Assistant: [Calls ljg-calendar, queries next week's events]
</example>

## 约束

本 skill 不生成文件，直接操作 macOS Calendar，因此 L0 org-mode/denote 规范不适用。

核心约束：
- AppleScript 日期构造 **禁止字符串解析**，必须逐字段赋值（详见 `references/applescript-patterns.md`）
- 字段赋值顺序：year → month → day → hours → minutes → seconds
- 默认写入 `"个人"` 日历，用户指定其他日历时按指定写入
- 解析不确定时，向用户确认后再写入

## Instructions

为了执行本项技能，请严格按照以下步骤操作：

### 0. 判断操作类型

根据用户意图分流：
- **查询**（"下周安排"、"这周有什么事"、"明天日程"）→ 跳到步骤 Q
- **写入**（"加到日历"、附带事件信息的文本/图片）→ 跳到步骤 1

---

### Q. 查询日历事件

读取 `references/applescript-patterns.md`，使用查询模式。

**时间范围推断**：
- "下周" → 下周一 00:00 到下周日 24:00
- "这周" → 本周一 00:00 到本周日 24:00
- "明天" → 明天 00:00 到明天 24:00
- "最近" → 今天到未来 7 天

通过 AppleScript 遍历所有日历，按日期排序输出。区分全天事件和定时事件，定时事件显示时间和地点。

**执行方式**：Bash 工具使用 `run_in_background: true` 执行 osascript，再通过 TaskOutput 取回结果。用户端只看到最终格式化表格，不暴露原始脚本和输出。

结果用表格呈现。完成后结束，不继续后续步骤。

---

### 1. 读取参考资料

读取 `references/applescript-patterns.md`，加载 AppleScript 安全模式。

### 2. 解析事件信息

从用户输入（文本或图片）中提取以下字段：

| 字段 | 必填 | 说明 |
|------|------|------|
| 标题 (summary) | 是 | 事件名称 |
| 日期 (date) | 是 | 年月日 |
| 开始时间 (start) | 否 | 缺省则创建全天事件 |
| 结束时间 (end) | 否 | 缺省则开始时间 +2h |
| 地点 (location) | 否 | |
| 备注 (description) | 否 | |
| 目标日历 | 否 | 缺省 "个人" |

**图片输入**：先识别图片中的文字内容（聊天记录、海报、邮件截图等），再从中提取事件信息。

**日期推断**：
- "明天" "下周三" 等相对日期 → 基于当前日期计算
- "3.4" "3/4" "3月4号" → 当年对应日期
- 缺少年份 → 默认当年；如该日期已过且距今 < 30天 → 仍用当年；否则用下一年

### 3. 确认（仅在模糊时）

如果所有字段都能明确提取，直接执行写入，不需确认。

仅在以下情况向用户确认：
- 日期不明确（如 "过阵子"、"最近"）
- 存在多个可能的事件
- 关键信息矛盾

### 4. 构造 AppleScript 并执行

使用 Bash 工具执行 `osascript -e '...'`，设置 `run_in_background: true`，再通过 TaskOutput 取回结果。

**日期构造模板**（严格遵循）：

```applescript
set startD to current date
set year of startD to {YEAR}
set month of startD to {MONTH}
set day of startD to {DAY}
set hours of startD to {HOUR}
set minutes of startD to {MINUTE}
set seconds of startD to 0
```

**全天事件**：`allday event:true`，end date 设为次日 00:00。

### 5. 报告结果

写入成功后，用一行简洁确认：

```
已添加：{日期} {时间} — {标题} @ {地点}
```
