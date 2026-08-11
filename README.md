# 🩸 BotC Copilot

> Blood on the Clocktower 对局推理助手 — 不只是笔记，而是推理引擎。

## 为什么做这个？

现有 BotC 玩家工具都停留在"电子笔记本"层面——记录信息，但不帮你分析。
BotC 的核心乐趣在于**信息网络的交叉推理**：角色 A 的信息 × 角色 B 的信息 → 谁在说谎？
没有任何工具帮你做这个推理。BotC Copilot 要解决这个问题。

## 功能

### ✅ Phase 1 — MVP（已完成）

- 🪑 **钟面座位圆环** — 1 号位 12 点方向顺时针排布，死亡压暗占位，信任度五色环，存活邻座自动收缩
- 📝 **角色自适应信息录入** — 10 种输入模板（数字/双人+是否/角色+双人/角色名/自由文本…），≤3 次点击完成录入
- 🧭 **开局设置向导** — 选剧本 → 人数（自动显示阵营配置）→ 拖拽排座位 → 选角色，2 分钟完成
- 📅 **每日事件流** — 按天分组：夜死/角色声明/信息声明/处决/掘墓人
- 🗂️ **多局存档** — 历史对局列表、继续/删除，纯离线自动保存
- 🎨 **暗色哥特主题** — 墨紫底 + 烛光金 + 血红点缀，思源宋体标题（字体打包，零联网）

### 🚧 Phase 2 — 推理引擎（规划中）

- 自动矛盾检测（角色重复声明 / 外来者数量冲突 / Empath vs 声明）
- 信息可靠性追踪（醉/毒标记）
- 排除法追踪器（确认好人 / 恶魔候选）
- 角色声明交叉矩阵、投票模式分析

### Phase 3 — 高级

- 逻辑链编辑器、复盘时间线回放、AI 辅助分析

## 技术栈

Flutter · Riverpod · Drift (SQLite) · go_router · Feature-first Clean Architecture

## 构建

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift 代码生成
flutter test                                               # 83 个测试
flutter build apk --release                                # Android 包
```

也可在 GitHub Actions 手动触发 `build` workflow 构建 APK（Artifacts 下载）。

## 文档

| 文档 | 内容 |
|------|------|
| [`docs/DESIGN.md`](docs/DESIGN.md) | 产品设计：信息模型、推理公理、数据 schema |
| [`docs/UI-STYLE.md`](docs/UI-STYLE.md) | 视觉规范：色板/字阶/组件/动效 token |
| [`PRODUCT.md`](PRODUCT.md) | 产品定位与约束 |
| [`AGENTS.md`](AGENTS.md) | Agent 执行规则 + BotC 领域知识 |

## License

MIT
