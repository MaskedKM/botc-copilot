import 'package:botc_copilot/core/constants/character.dart';

// ── 归属定位（#233 文档化）──────────────────────────────────────
// 本文件是 **Character 附属数据**（确认路径 + 机械交互，TB 全量 map），
// 与 character.dart 的角色元数据同族；按 #229 两级实体管理归属 Character
// 侧（非 ScriptDefinition 聚合——交互多为跨剧本通用机制，仅个别剧本特例
// 随 #217 分表）。查询语义与消费端 `?? const CharacterReference()` 降级
// （character_reference_page.dart）不变；Magician/Legion 等 #233 锚点
// 角色暂无条目 → 走降级空参考，S&V 录入时补。

/// 角色间的一条机械交互规则（官方规则可推导，issue #60 功能2）。
class CharacterInteraction {
  /// 创建交互。
  const CharacterInteraction(this.text, {this.relatedTo = const {}});

  /// 交互描述（如「被毒/醉当晚读数为假」）。
  final String text;

  /// 涉及的角色（用于上下文感知高亮）。空集 = 通用规则（始终显示，不高亮）。
  final Set<Character> relatedTo;
}

/// 单个角色的参考信息（issue #60）。
class CharacterReference {
  /// 创建参考。
  const CharacterReference({this.confirmPath, this.interactions = const []});

  /// 确认路径：如何机械地验证 / 反驳该角色声明（源自能力 + 官方机制）。
  /// 可空——并非所有角色都有可观测的确认方法。
  final String? confirmPath;

  /// 机械交互规则（与其他角色的能力交互）。
  final List<CharacterInteraction> interactions;
}

/// 角色参考表（Trouble Brewing）。未列出的角色仅展示能力文本。
///
/// 全部内容为官方规则可推导：确认路径源自能力机制，交互源自 axiom 4
/// （醉/毒）+ 角色能力（Recluse/Spy 登记、SW 传位、Baron 配置等）。
/// 策略建议（Playing As/Against、Cover Identities）非官方规则，另行处理。
const characterReferences = <Character, CharacterReference>{
  // ---- 镇民：信息 / 可验证角色 ----
  Character.washerwoman: CharacterReference(
    confirmPath: '「2 人中有 1 个某镇民」——被点名的 2 人之一是该镇民'
        '（除非信息被污染）。',
    interactions: [
      CharacterInteraction('被毒 / 醉当晚，所得信息为假。', relatedTo: {Character.poisoner}),
    ],
  ),
  Character.librarian: CharacterReference(
    confirmPath: '「2 人中有 1 个某外来者，或本局无外来者」。',
    interactions: [
      CharacterInteraction('被毒 / 醉当晚，所得信息为假。', relatedTo: {Character.poisoner}),
    ],
  ),
  Character.investigator: CharacterReference(
    confirmPath: '「2 人中有 1 个某爪牙」。',
    interactions: [
      CharacterInteraction('被毒 / 醉当晚，所得信息为假。', relatedTo: {Character.poisoner}),
    ],
  ),
  Character.chef: CharacterReference(
    confirmPath: '数字 = 相邻邪恶玩家对数；与邪恶座位分布交叉验证。',
    interactions: [
      CharacterInteraction('被毒 / 醉当晚，数字为假。', relatedTo: {Character.poisoner}),
    ],
  ),
  Character.empath: CharacterReference(
    confirmPath: '邻座被处决 / 夜杀后，读数应相应变化（死者不再计入）'
        '——变化方向验证邻座阵营。',
    interactions: [
      CharacterInteraction('被毒 / 醉当晚，读数为假。', relatedTo: {Character.poisoner}),
      CharacterInteraction('邻座含隐士时，隐士（善良）可能被计为邪恶 → 多算。',
          relatedTo: {Character.recluse}),
      CharacterInteraction('邻座含间谍时，间谍（邪恶）可能被计为善良 → 少算。',
          relatedTo: {Character.spy}),
    ],
  ),
  Character.fortuneTeller: CharacterReference(
    confirmPath: '多次占卜同一目标；须排除「红鲱鱼」（一名好人会被误判为恶魔）。',
    interactions: [
      CharacterInteraction('被毒 / 醉当晚，判定为假。', relatedTo: {Character.poisoner}),
      CharacterInteraction('一名好人会被误判为恶魔（红鲱鱼），须排查。'),
      CharacterInteraction('隐士可能被误判为恶魔。', relatedTo: {Character.recluse}),
    ],
  ),
  Character.undertaker: CharacterReference(
    confirmPath: '报出当日被处决者角色 ↔ 该玩家死亡揭示对比。',
    interactions: [
      CharacterInteraction('被毒 / 醉当晚，信息为假。', relatedTo: {Character.poisoner}),
      CharacterInteraction('间谍死后可能登记为好人 / 隐士登记为邪恶 → 掘墓人报错。',
          relatedTo: {Character.spy, Character.recluse}),
    ],
  ),
  Character.monk: CharacterReference(
    confirmPath: '选择保护后当夜无人死亡 ⇒ 可能挡下恶魔的攻击。',
    interactions: [
      CharacterInteraction('保护对象当晚不被恶魔杀死。', relatedTo: {Character.imp}),
    ],
  ),
  Character.ravenkeeper: CharacterReference(
    confirmPath: '夜死后报出目标角色 ↔ 死亡揭示对比。',
    interactions: [
      CharacterInteraction('被毒 / 醉当夜（被杀时）报角色为假。',
          relatedTo: {Character.poisoner}),
    ],
  ),
  Character.virgin: CharacterReference(
    confirmPath: '首次被镇民提名 → 提名者立即处决（无投票）。'
        '此现象发生 ⇒ 提名者是镇民。',
    interactions: [
      CharacterInteraction('触发条件：提名者须为镇民；处女须未被毒 / 醉且未死。'),
    ],
  ),
  Character.slayer: CharacterReference(
    confirmPath: '公开射杀目标死亡 ⇒ 目标是恶魔；未死 ⇒ 能力已消耗'
        '（目标非恶魔，或猎杀者被毒 / 醉）。',
    interactions: [
      CharacterInteraction('对恶魔射杀致死；对非恶魔不死且永久消耗能力。',
          relatedTo: {Character.imp}),
    ],
  ),
  Character.soldier: CharacterReference(
    confirmPath: '恶魔攻击不死 ⇒ Soldier 在场。',
    interactions: [
      CharacterInteraction('恶魔能力杀不死你（被毒 / 醉时失效）。',
          relatedTo: {Character.imp}),
    ],
  ),
  Character.mayor: CharacterReference(
    interactions: [
      CharacterInteraction('3 人存活且当日无人被处决 → 善良胜。'),
      CharacterInteraction('夜晚即将死亡时，可能由另一名玩家代死。'),
    ],
  ),

  // ---- 外来者 ----
  Character.butler: CharacterReference(
    interactions: [
      CharacterInteraction('只能在主人投票时投票（次日白天）。'),
    ],
  ),
  Character.drunk: CharacterReference(
    interactions: [
      CharacterInteraction('你以为自己是某镇民，但你的「能力 / 信息」是魔典伪造——'
          '你不知道自己是醉汉。'),
    ],
  ),
  Character.recluse: CharacterReference(
    interactions: [
      CharacterInteraction('可能被共情者计为邪恶 / 占卜师误判为恶魔 / 调查员误判为爪牙 / 死后登记为邪恶。',
          relatedTo: {Character.empath, Character.fortuneTeller, Character.investigator, Character.undertaker}),
    ],
  ),
  Character.saint: CharacterReference(
    interactions: [
      CharacterInteraction('被处决 → 邪恶立即获胜。'),
    ],
  ),

  // ---- 爪牙 ----
  Character.poisoner: CharacterReference(
    interactions: [
      CharacterInteraction('投毒使目标当晚 + 次日白天能力失效、信息为假，黄昏解除。'),
    ],
  ),
  Character.spy: CharacterReference(
    interactions: [
      CharacterInteraction('每夜可查看魔典（全局角色 / 状态）。'),
      CharacterInteraction('可能被共情者计为善良 / 洗衣妇误判为镇民 / 图书管理员误判为外来者 / 死后登记为好人。',
          relatedTo: {Character.empath, Character.washerwoman, Character.librarian, Character.undertaker}),
    ],
  ),
  Character.scarletWoman: CharacterReference(
    interactions: [
      CharacterInteraction('恶魔死亡且 ≥5 人存活时，成为新恶魔（当晚不行动）。',
          relatedTo: {Character.imp}),
    ],
  ),
  Character.baron: CharacterReference(
    interactions: [
      CharacterInteraction('本局额外 +2 外来者、-2 镇民（开局配置）。'),
    ],
  ),

  // ---- 恶魔 ----
  Character.imp: CharacterReference(
    interactions: [
      CharacterInteraction('杀自己 → 一名存活爪牙成为新恶魔（绯红女优先）。',
          relatedTo: {Character.scarletWoman}),
    ],
  ),
};

/// 交互是否「活跃」（涉及在场声明角色），用于上下文感知高亮。
///
/// 通用交互（[CharacterInteraction.relatedTo] 为空）返回 false——始终显示，
/// 但不高亮。
bool interactionActive(CharacterInteraction i, Set<Character> claimed) =>
    i.relatedTo.any(claimed.contains);
