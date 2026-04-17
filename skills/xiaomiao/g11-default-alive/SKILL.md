---
name: g11-default-alive
description: |
  用户在问"公司能活多久"、讨论"要不要融资"、计算"账上的钱能撑多久"时激活。
  信号词: "跑道"、"现金流"、"盈亏平衡"、"能活多久"、"不用融资也能活"。
  不适用于: 已有盈利能力讨论扩张、需要资本投入才能运营的行业。
source_book: 《小而美》 萨希尔·拉文吉亚
source_chapter: 第六章「有意识地跟企业一起成长」
tags: [financial-health, YC, runway, survival-test]
related_skills: []
---

# 术语: 默认存活/默认死亡 (Default Alive / Default Dead)

## R — 原文 (Reading)

> YC公司的创始人保罗·格雷厄姆可以根据一家公司"默认存活还是默认死亡"立即对其规模做出评估。如果开支和营收保持不变，公司会存活还是死亡？

> — 萨希尔·拉文吉亚, 第六章

---

## I — 方法论骨架 (Interpretation)

Default Alive是一种**极简二元诊断：只问一个二元问题——活还是死**。

核心问题:
- 如果开支和营收保持不变，公司会存活还是死亡？
- 如果停止主动销售，公司会存活还是死亡？

为什么重要:
- 任何"我们增长很快所以没问题"的说辞，在Default Dead面前都站不住脚
- 这个二元测试迫使创始人看清现实

---

## A1 — 书中的应用 (Past Application)

### 案例 1: YC的筛选问题
- **问题**: 如何快速判断一家创业公司的健康度
- **方法论的使用**: "如果开支和营收保持不变，公司会存活还是死亡？"
- **结论**: 只需要问一个二元问题
- **结果**: 创始人被迫看清现实

### 案例 2: Gumroad的财务演变
- **问题**: 从每月亏损到Default Alive
- **方法论的使用**: 不断测试Default Alive状态
- **结论**: Default Alive是通往盈利自信的起点
- **结果**: 最终实现盈利

---

## A2 — 触发场景 (Future Trigger) ★

### 用户会在什么情境下需要这个 skill?

1. 用户问"公司能活多久"——需要Default Alive测试
2. 用户在讨论"要不要融资"——先测试Default Alive
3. 用户计算"账上的钱能撑多久"——跑道计算
4. 用户说"我们增长很快所以没问题"——需要二元测试
5. 用户不清楚公司的盈亏平衡点——需要Default Alive诊断

### 语言信号 (用户的话里出现这些就应激活)

- "跑道"
- "现金流"
- "盈亏平衡"
- "能活多久"
- "不用融资也能活"

### 与相邻 skill 的区分

- 与 "g09-profitable-confidence" 的区别: g09是程度量表（多健康），本skill是二元诊断（活还是死）
- 与 "财务分析" 的区别: 那是详细分析，本方法是快速筛选

---

## E — 可执行步骤 (Execution)

当 skill 被激活后, agent 应按以下步骤执行:

1. **计算当前burn rate**
   - 完成标准: 月支出 - 月收入 = 月burn

2. **测试Default Alive状态**
   - 完成标准: 用户回答"如果停止主动销售，公司会存活还是死亡"

3. **制定止血计划**
   - 完成标准: 如果是Default Dead，用户制定4个月实现Default Alive的计划
   - 判停条件: 如果已经是Default Alive，融资讨论才有意义

---

## B — 边界 (Boundary) ★

### 不要在以下情况使用此 skill

- 已有盈利能力的公司——他们已经是Default Alive
- 需要大量资本才能运营的行业——那不是本方法的适用范围
- 讨论扩张战略——那是增长问题，不是生存问题

### 作者在书中警告的失败模式

- 创始人不知道自己公司的Default Alive状态
- 认为"增长快"= "活着"——其实可能只是烧钱快
- 等待投资人而不是先止血

### 容易混淆的邻近方法论

- "现金流预测" — 那是时间序列分析，本方法是二元测试
- "盈亏平衡分析" — 那是财务指标，本方法是战略判断

---

## 相关 skills (阶段 3 填充)

- depends-on: 
- contrasts-with: 
- composes-with: g09-profitable-confidence, ce05-vc-dependency-hallucination

---

## 审计信息

- **验证通过**: V1 ✓ / V2 ✓ / V3 ✓
- **测试通过率**: 待测试
- **蒸馏时间**: 2026-04-17

---

## 相关链接

- **[g09-profitable-confidence](../g09-profitable-confidence/SKILL.md)** — 盈利自信: Default Alive之后的进阶目标
- **[ce01-quibi-failure](../ce01-quibi-failure/SKILL.md)** — Quibi失败: Default Dead的极端案例
- **[ce05-vc-dependency-hallucination](../ce05-vc-dependency-hallucination/SKILL.md)** — VC依赖幻觉: 不要等投资人来救Default Dead
