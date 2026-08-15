import 'package:botc_copilot/core/constants/character.dart';

/// 单步夜晚行动（Trouble Brewing 夜晚唤醒顺序，官方数据）。
///
/// 数据来源：官方 script 夜序（botc-tools.xyz）。`character` 为空时表示
/// 开场说明性步骤（醉汉分配 / 爪牙信息 / 恶魔信息），用 [label] 展示；
/// 角色步骤的展示名派生自 [Character.nameCn]（见 [displayLabel]）。
class NightOrderStep {
  /// 创建一步。
  const NightOrderStep({
    this.character,
    this.label,
    required this.action,
    this.note,
  });

  /// 行动角色；开场说明性步骤为 null。
  final Character? character;

  /// 仅说明性步骤使用的展示名（如「恶魔信息」）。角色步骤留空，
  /// 由 [displayLabel] 取 [Character.nameCn]。
  final String? label;

  /// 行动简述（如「投毒」「杀人」「得知 2 人中有 1 个某镇民」）。
  final String action;

  /// 附加说明（时序 / 触发条件），可空。
  final String? note;

  /// 展示名：说明性步骤用 [label]，角色步骤用 [Character.nameCn]。
  String get displayLabel => label ?? character?.nameCn ?? '';
}

/// 首夜行动顺序（TB）。
///
/// 开场说明性步骤（全局规则，非剧本专属，#232 提取共享）：
/// 醉汉分配 → 爪牙信息 → 恶魔信息（7+）。各官方剧本首夜共用；
/// 后续夜无开场步骤（爪牙/恶魔信息仅首夜）。
const openingSteps = <NightOrderStep>[
  NightOrderStep(
    label: '醉汉（分配）',
    action: '说书人秘密指定一名玩家为醉汉——其角色 / 信息为假',
    note: '仅本局有 Drunk 时',
  ),
  NightOrderStep(
    label: '爪牙信息',
    action: '爪牙互认识；恶魔向爪牙亮明',
    note: '7+ 人局恶魔亦知爪牙；≤6 人局恶魔不知爪牙',
  ),
  NightOrderStep(
    label: '恶魔信息',
    action: '恶魔看爪牙 + 3 个不在场好人角色（Bluff）',
    note: '仅 7+ 人局；≤6 人局恶魔无 Bluff',
  ),
];

/// TB 首夜步骤（官方 botc-release nightsheet 顺序，#267 勘正）：
/// 开场共享步骤 → Poisoner → Washerwoman → Librarian → Investigator →
/// Chef → Empath → Fortune Teller → Butler → Spy。
/// 首夜无 SW 位与 Imp 行动位（恶魔信息已在开场共享步骤；首夜不杀人）。
const firstNightSteps = <NightOrderStep>[
  ...openingSteps,
  NightOrderStep(
    character: Character.poisoner,
    action: '投毒',
    note: '当夜 + 次日白天生效，黄昏解除',
  ),
  NightOrderStep(
    character: Character.washerwoman,
    action: '得知 2 人中有 1 个某镇民',
  ),
  NightOrderStep(
    character: Character.librarian,
    action: '得知 2 人中有 1 个某外来者（或无）',
  ),
  NightOrderStep(
    character: Character.investigator,
    action: '得知 2 人中有 1 个某爪牙',
  ),
  NightOrderStep(character: Character.chef, action: '得知邪恶邻座对数'),
  NightOrderStep(character: Character.empath, action: '得知存活邻座邪恶人数'),
  NightOrderStep(
    character: Character.fortuneTeller,
    action: '得知目标是否恶魔（含红鲱鱼登记）',
  ),
  NightOrderStep(character: Character.butler, action: '选择主人'),
  NightOrderStep(character: Character.spy, action: '查看魔典（全局角色 / 状态）'),
];

/// 后续夜行动顺序（TB，官方 botc-release nightsheet 顺序，#267 勘正）。
///
/// Poisoner → Monk → Scarlet Woman → Imp（杀人）→ Ravenkeeper → Empath →
/// Fortune Teller → Undertaker → Butler → Spy。关键时序：Imp 杀人在
/// Ravenkeeper/Empath/FT 之前——被 Imp 杀的读数角色当晚无读数；
/// Ravenkeeper 紧跟 Imp（被杀即醒）。
const otherNightSteps = <NightOrderStep>[
  NightOrderStep(
    character: Character.poisoner,
    action: '投毒',
    note: '当夜 + 次日白天生效，黄昏解除',
  ),
  NightOrderStep(
    character: Character.monk,
    action: '选择保护对象',
    note: '保护在 Imp 杀人之前 → 当夜生效',
  ),
  NightOrderStep(
    character: Character.scarletWoman,
    action: '（被动）',
    note: '恶魔死亡时，若 SW 存活且 ≥5 人存活 → 成新恶魔（当晚不行动）',
  ),
  NightOrderStep(
    character: Character.imp,
    action: '杀人',
    note: '先于渡鸦 / 掘墓 / 共情 / 占卜——被杀者当晚无读数',
  ),
  NightOrderStep(
    character: Character.ravenkeeper,
    action: '得知目标角色',
    note: '仅当夜被 Imp 杀死时醒来（紧跟 Imp）',
  ),
  NightOrderStep(
    character: Character.empath,
    action: '读存活邻座邪恶人数',
    note: '在 Imp 杀人之后——被杀邻座不再计入',
  ),
  NightOrderStep(character: Character.fortuneTeller, action: '查 2 人是否恶魔'),
  NightOrderStep(
    character: Character.undertaker,
    action: '得知当日被处决者角色',
    note: '仅当日有处决',
  ),
  NightOrderStep(
    character: Character.butler,
    action: '选择主人（次日仅主人投票时可投票）',
  ),
  NightOrderStep(character: Character.spy, action: '查看魔典（全局角色 / 状态）'),
];

