import 'package:botc_copilot/core/constants/character.dart';

/// 单步夜晚行动（Trouble Brewing 夜晚唤醒顺序）。
class NightOrderStep {
  /// 创建一步。
  const NightOrderStep({
    required this.character,
    required this.action,
    this.note,
  });

  /// 行动角色。
  final Character character;

  /// 行动简述（如「投毒」「杀人」「读存活邻座邪恶人数」）。
  final String action;

  /// 附加说明（时序 / 触发条件），可空。
  final String? note;
}

/// 首夜行动顺序（TB）。
///
/// 官方顺序：Poisomer → Spy → Scarlet Woman（被动）→ Imp（学习信息，首夜
/// 不杀人）→ Washerwoman → Librarian → Investigator → Chef → Empath →
/// Fortune Teller → Butler。
const firstNightSteps = <NightOrderStep>[
  NightOrderStep(
    character: Character.poisoner,
    action: '投毒',
    note: '当夜 + 次日白天生效，黄昏解除',
  ),
  NightOrderStep(character: Character.spy, action: '查看全局角色 / 状态'),
  NightOrderStep(
    character: Character.scarletWoman,
    action: '（被动）',
    note: '恶魔死亡时，若 SW 存活且 ≥5 人存活 → 传位',
  ),
  NightOrderStep(
    character: Character.imp,
    action: '得知爪牙 / 自己是恶魔',
    note: '首夜不杀人',
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
];

/// 后续夜行动顺序（TB）。
///
/// 官方顺序：Poisomer → Monk → Imp（杀人）→ Fortune Teller → Empath →
/// Undertaker → Ravenkeeper → Spy。关键时序：Imp 杀人在 FT/Empath 之前，
/// 故当夜被杀的 FT/Empath 来不及读数。
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
    character: Character.imp,
    action: '杀人',
    note: '先于占卜师 / 共情者——被杀者当晚无读数',
  ),
  NightOrderStep(character: Character.fortuneTeller, action: '查 2 人是否恶魔'),
  NightOrderStep(character: Character.empath, action: '读存活邻座邪恶人数'),
  NightOrderStep(
    character: Character.undertaker,
    action: '得知当日被处决者角色',
    note: '仅当日有处决',
  ),
  NightOrderStep(
    character: Character.ravenkeeper,
    action: '得知目标角色',
    note: '仅当夜死亡时醒来（在 Imp 之后）',
  ),
  NightOrderStep(character: Character.spy, action: '查看全局角色 / 状态'),
];

/// 当天对应的夜晚步骤：day ≤ 1 首夜，否则后续夜。
List<NightOrderStep> nightStepsForDay(int dayNumber) =>
    dayNumber <= 1 ? firstNightSteps : otherNightSteps;
