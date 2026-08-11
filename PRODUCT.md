# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

> Flutter 单代码库，同时发布 iOS + Android。iOS 上遵守 HIG（safe area、edge-swipe back、44pt 触控），Android 上遵守 Material 3（48dp 触控、系统 Back、edge-to-edge insets）。

## Users

《血染钟楼》(Blood on the Clocktower) 线下对局玩家。使用场景：昏暗灯光的桌游局现场，一只手拿手机，注意力在桌面讨论上，录入必须极快（≤3 次点击）。中文优先。

## Product Purpose

对局推理辅助工具：**不是电子笔记本，而是推理引擎**。帮助玩家在对局中快速记录 → 结构化 → 交叉验证 → 推理分析（矛盾检测、排除法追踪、投票分析），并在赛后复盘。

## Positioning

理解 BotC 的信息网络结构（五大推理公理：角色唯一、座位收缩、伪装排他、醉毒一命、恶魔传承）并内建自动矛盾检测与推理追踪——现有工具（BOTC Notes、The Grim、Clocktower Notebook）均无此能力。

## Operating Context

- 纯离线，对局中不依赖网络；每次操作自动持久化，无手动保存。
- 一局游戏持续 30-90 分钟，跨多个昼/夜阶段。
- 线下局光线昏暗 → 暗色主题是第一公民。
- 对局中用户处于"任务中"状态（Operate 模式）：扫读、速录、防误触优先于视觉表现。

## Capabilities and Constraints

- Phase 1（MVP）：开局设置、座位圆环 CustomPainter、每日信息记录（角色自适应输入）、事件时间线、多局存档、暗色主题。
- Phase 2：推理引擎（矛盾检测、信息可靠性、排除法、角色矩阵、投票分析）。
- Phase 3：逻辑链编辑器、复盘回放、AI 辅助。
- 技术栈：Flutter + Riverpod + Drift + go_router，Feature-first Clean Architecture。

## Brand Commitments

- 主题方向已定（来自 AGENTS.md）：**暗色哥特**（深紫/深蓝底 + 金色点缀），契合 BotC 的哥特氛围并护眼。
- 座位圆环为 UI 核心，始终可见，信息面板围绕它展开。

## Evidence on Hand

- `docs/DESIGN.md`：产品信息模型、数据 schema、竞品分析（事实依据）。
- 尚无视觉资产（logo、图标、字体文件）——不得虚构。

## Product Principles

1. **录入速度第一** — 任何信息录入 ≤3 次点击。
2. **圆环为核心** — 座位圆环始终可见，一切围绕它组织。
3. **暗色优先** — 哥特暗色是默认且唯一必须的配色方案。
4. **防误触** — 死亡/处决等关键操作需确认。
5. **自动保存** — 每次操作立即持久化。

## Accessibility & Inclusion

- 暗色下的对比度需满足 WCAG AA（正文 ≥4.5:1）。
- 信任度/阵营色同时配有形状或文字标记，不单靠颜色区分（色弱友好）。
- 支持系统级 Reduce Motion / 移除动画设置。
