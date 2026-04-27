# AppleScript 日历操作模式

## 核心原则：日期构造

**永远不要** 用字符串构造日期（如 `date "2026-03-04 19:00:00"`），AppleScript 的日期字符串解析因 locale 不同会产生灾难性错误。

**唯一正确方式**：从 `current date` 出发，逐字段赋值。

```applescript
set d to current date
set year of d to 2026
set month of d to 3
set day of d to 4
set hours of d to 19
set minutes of d to 0
set seconds of d to 0
```

> 注意：字段赋值顺序建议 year → month → day，避免月末溢出（如 3月31日 → 设month为2 → 溢出）。

## 创建事件

```applescript
tell application "Calendar"
    tell calendar "个人"
        make new event with properties {summary:"标题", location:"地点", start date:startD, end date:endD, description:"备注"}
    end tell
end tell
```

## 创建全天事件

```applescript
tell application "Calendar"
    tell calendar "个人"
        make new event with properties {summary:"标题", allday event:true, start date:startD, end date:endD}
    end tell
end tell
```

## 查询事件

```applescript
tell application "Calendar"
    set startDate to current date
    -- set fields...
    set endDate to startDate + 7 * days
    repeat with cal in calendars
        set evts to (every event of cal whose start date ≥ startDate and start date < endDate)
        repeat with e in evts
            -- process event
        end repeat
    end repeat
end tell
```

## 默认日历

- 写入目标：`"个人"` 日历（用户 iCloud 主日历）
- 如用户指定其他日历（如 "工作"），按指定写入

## 常见陷阱

1. **日期字符串解析** — 已禁止，见上
2. **月末溢出** — 设 day 为 31 后改 month 为 2 会出错，先设 year/month 再设 day
3. **全天事件的 end date** — 应为次日 00:00，不是当天 23:59
4. **时区** — `current date` 自动使用系统时区，无需手动处理
