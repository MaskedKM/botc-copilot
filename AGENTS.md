# BotC Copilot — Agent 执行规则

本文件定义 AI Agent（Claude Code / Codex / Hermes 等）在本项目的执行规则。启动时自动加载。

## 项目概述

**BotC Copilot** 是一款《血染钟楼》(Blood on the Clocktower) 对局推理助手 App。

**核心定位**：不是电子笔记本，而是推理引擎。理解 BotC 的信息网络结构，帮助玩家在对局中快速记录 → 结构化 → 交叉验证 → 推理分析。

**平台**：iOS + Android，纯离线，无需联网。

## 技术栈

| 层 | 选型 | 理由 |
|----|------|------|
| 框架 | **Flutter (Dart)** | 自绘座位圆环是核心交互，CustomPainter 内置 API；AOT 编译冷启动 <200ms |
| 状态管理 | **Riverpod** | 编译期安全、可测试、无 boilerplate |
| 本地数据库 | **Drift** (reactive SQLite) | 类型安全、reactive query、自动 migration |
| 路由 | **go_router** | 声明式路由，支持 deep link |
| 架构 | **Feature-first Clean Architecture** | 每个 feature 独立 data/domain/presentation 三层 |

**不使用**：React Native（自绘需额外依赖 react-native-skia）、Redux（过重）、Hive（查询能力弱）。

## 项目结构

```
lib/
├── main.dart
├── app.dart                    # MaterialApp + 主题 + 路由
├── core/                       # 跨 feature 共享
│   ├── constants/              # 剧本配置、角色定义
│   ├── theme/                  # 暗色哥特主题
│   ├── utils/                  # 工具函数
│   └── database/               # Drift database 实例 + shared DAO
├── feature/
│   ├── setup/                  # 开局设置（选剧本/人数/座位/角色）
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── game_board/             # 对局主界面（座位圆环 + 当日面板）
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── widgets/
│   │       │   ├── seat_ring.dart       # 座位圆环 CustomPainter
│   │       │   ├── player_card.dart     # 玩家信息卡
│   │       │   └── day_panel.dart       # 当日信息面板
│   │       └── providers/
│   ├── player_detail/          # 玩家详情（角色声明/信息/信任度）
│   ├── timeline/               # 每日事件流
│   └── reasoning/              # 推理引擎（Phase 2）
├── shared/
│   ├── widgets/                # 通用 UI 组件
│   └── models/                 # 跨 feature 的数据模型
└── l10n/                       # 国际化（中文优先）
```

## BotC 领域知识

### 玩家配置表（Trouble Brewing 基准）

| 玩家数 | 镇民 | 外来者 | 爪牙 | 恶魔 | 邪恶总数 |
|--------|------|--------|------|------|----------|
| 5      | 3    | 0      | 1    | 1    | 2        |
| 6      | 3    | 1      | 1    | 1    | 2        |
| 7      | 5    | 0      | 1    | 1    | 2        |
| 8      | 5    | 1      | 1    | 1    | 2        |
| 9      | 5    | 2      | 1    | 1    | 2        |
| 10     | 7    | 0      | 2    | 1    | 3        |
| 11     | 7    | 1      | 2    | 1    | 3        |
| 12     | 7    | 2      | 2    | 1    | 3        |
| 13     | 9    | 0      | 2    | 1    | 3        |
| 14     | 9    | 1      | 2    | 1    | 3        |
| 15     | 9    | 2      | 3    | 1    | 4        |

> Baron 在场时：+2 外来者、-2 镇民。App 需在 setup 时展示基础配置，推理阶段提示 Baron 可能性。

### Trouble Brewing 角色（22个）

**镇民 (Townsfolk)**：Washerwoman 洗衣妇、Librarian 图书管理员、Investigator 调查员、Chef 厨师、Empath 共情者、Fortune Teller 占卜师、Undertaker 掘墓人、Monk 僧侣、Ravenkeeper 渡鸦守护者、Virgin 处女、Slayer 猎杀者、Soldier 士兵、Mayor 市长

**外来者 (Outsiders)**：Butler 管家、Drunk 醉汉、Recluse 隐士、Saint 圣徒

**爪牙 (Minions)**：Poisoner 投毒者、Spy 间谍、Scarlet Woman 绯红女、Baron 男爵

**恶魔 (Demons)**：Imp 小恶魔

### 角色信息输入模板

不同角色提供的信息类型不同，App 需按角色自动适配输入界面：

| 角色类型 | 信息格式 | UI 组件 |
|----------|----------|---------|
| Chef | 数字 0-N | NumberPicker |
| Empath | 数字 0-2 | NumberPicker |
| Fortune Teller | 选 2 人 + 是/否 | 双人选择器 + Toggle |
| Investigator | 选 1 爪牙角色 + 选 2 人 | 角色选择 + 双人选择器 |
| Washerwoman | 选 1 镇民角色 + 选 2 人 | 角色选择 + 双人选择器 |
| Librarian | 选 1 外来者角色 + 选 2 人(或"无") | 角色选择 + 双人选择器 |
| Undertaker | 选 1 角色名（被处决者身份） | 角色选择 |
| 其他 | 自由文本 | TextField |

### 五大推理公理（Phase 2 推理引擎的规则基础）

1. **角色唯一**：同一好人角色至多 1 个。两人声明同一角色 → 至少一假。
2. **座位收缩**：死亡玩家从邻座计算中物理移除，两侧存活者直接并拢。
3. **伪装排他**：恶魔的 3 个 Bluff 角色物理上不在场。
4. **醉毒一命**：一次性技能在醉/毒时发动 = 永久失效。
5. **恶魔传承**：恶魔传给已死玩家 = 邪恶立刻战败。

### 两种核心推理范式

- **单链逻辑**：假设 A 真 → 推导 B → 推导 C → 结论自洽则 A 大概率真
- **双链逻辑**：A/B 互斥 → 分别假设各自为真 → 比较哪个结论更合理

## 开发约定

### 代码风格

- Dart 官方 lint rules（`flutter_lints` + `very_good_analysis`）
- 文件命名：`snake_case.dart`
- 类命名：`PascalCase`
- private 成员以 `_` 开头
- 每个公共类/方法必须有 dartdoc 注释

### 状态管理 (Riverpod)

```dart
// Provider 命名：featureName + EntityName + Provider
final gameBoardPlayersProvider = StateNotifierProvider<...>();

// 分层：
// - RepositoryProvider：数据库访问
// - StateNotifierProvider：业务状态
// - Provider：纯计算/派生数据
```

### 数据库 (Drift)

- 所有表继承 `Table`，字段用 `IntColumn` 等类型安全 API
- 每次schema变更必须写 migration（`schemaVersion` + `MigrationStrategy`）
- 复杂查询用 `customSelect` + DTO 映射
- reactive query：`.watch()` 返回 `Stream<List<T>>`，UI 自动更新

### 测试策略

| 层 | 测试类型 | 工具 |
|----|----------|------|
| Domain | Unit test | `flutter_test` |
| Data/DAO | Integration test | Drift 内存数据库 |
| Presentation | Widget test | `flutter_test` + Riverpod `ProviderScope` |
| 推理引擎 | Property-based test | 覆盖五大公理的边界场景 |

**核心测试覆盖目标**：
- 座位圆环：死亡后邻座重算逻辑
- 矛盾检测：角色重复声明、外来者数量冲突
- 角色输入模板：每种角色类型的输入→存储→回显

### Commit 规范

```
<type>(<scope>): <description>

type: feat | fix | refactor | test | docs | chore | ui
scope: setup | game-board | player-detail | timeline | reasoning | database | core
```

示例：`feat(game-board): 座位圆环死亡动画 + 邻座高亮`

### UI 原则

1. **录入速度第一**：任何信息录入 ≤3 次点击
2. **暗色优先**：哥特主题（深紫/深蓝底 + 金色点缀），符合 BotC 氛围 + 护眼
3. **圆环为核心**：座位圆环始终可见，信息面板围绕它展开
4. **防误触**：标记死亡/处决等关键操作需确认
5. **自动保存**：每次操作立即持久化，不需要手动保存按钮

## 开发阶段

### Phase 1 — MVP（~9 天）
- 开局设置流程
- 座位圆环 CustomPainter
- 每日信息记录（角色自适应输入）
- 每日事件流时间线
- 多局存档
- 暗色主题

### Phase 2 — 推理引擎
- 自动矛盾检测（角色重复/外来者数量/Empath vs 声明）
- 信息可靠性追踪（醉/毒标记）
- 排除法追踪器（确认好人 / 恶魔候选）
- 角色声明交叉矩阵
- 投票时间线 + 分析

### Phase 3 — 高级
- 逻辑链编辑器
- 复盘模式 + 时间线回放
- AI 辅助分析（LLM 矛盾检测 + 假设推演）
- 语音/自然语言快速录入

## 外部资源

- [设计文档](docs/DESIGN.md) — 完整产品信息模型 + 数据 schema
- [GitHub 仓库](https://github.com/MaskedKM/botc-copilot)
- [官方 Wiki](https://wiki.bloodontheclocktower.com) — 角色规则权威参考
- [botc.guide](https://botc.guide) — 角色能力速查
- [botc-ai-copilot](https://github.com/Shell-human/botc-ai-copilot) — 推理公理体系来源
