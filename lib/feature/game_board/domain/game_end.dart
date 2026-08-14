import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/shared/models/enums.dart';

/// 对局结束建议（issue #37）。
///
/// 官方规则：
/// - 善良胜：恶魔被处决 / 市长特殊胜利（3 人存活且无处决，issue #88）/
///   恶魔已死无继承人时的人头判定（issue #208）
/// - 邪恶胜：仅剩 2 名存活玩家（前提：恶魔活到此时）
sealed class GameEndSuggestion {
  const GameEndSuggestion();
}

/// 存活 ≤ 2，邪恶可能获胜。
class EvilWinCandidate extends GameEndSuggestion {
  const EvilWinCandidate(this.aliveCount);

  /// 当前存活人数。
  final int aliveCount;
}

/// 恶魔确认已死且无存活继承人 → 善良胜候选（issue #208）。
///
/// 官方「恶魔**活到**只剩 2 人」是人头邪恶胜的前提；当存档事实（死亡
/// 揭示 / 传承链，见 `DemonStatusResolver`）显示恶魔已死且无继时，2 人
/// 存活应提示善良胜而非邪恶胜。认知极限：SW 自动继承等未记录事件不可
/// 知——本候选仅作对话框首选，由用户终裁。
class GoodWinCandidate extends GameEndSuggestion {
  const GoodWinCandidate(this.aliveCount);

  /// 当前存活人数。
  final int aliveCount;
}

/// 处决发生后，需确认被处决者是否是恶魔。
class DemonExecutionCheck extends GameEndSuggestion {
  const DemonExecutionCheck({
    required this.executedPlayerId,
    required this.executedName,
    required this.aliveCountAfter,
  });

  /// 被处决者 id。
  final int executedPlayerId;

  /// 被处决者显示名（座位号+名字）。
  final String executedName;

  /// 处决后的存活人数（用于"不是恶魔"后继续检查邪恶胜）。
  final int aliveCountAfter;
}

/// 存活 == 3 且当天无人被处决 → 市长可能触发善良胜（issue #88）。
///
/// 官方规则（Mayor "How to Run"）：黄昏时若恰好 3 名玩家存活且当日无人
/// 被处决，善良获胜。平票 / 不足阈值也算「无人被处决」。需用户确认市长
/// 在场且未被毒 / 醉（App 无法确认真身，仅按声明 / 我的角色门控提示）。
class MayorVictoryCandidate extends GameEndSuggestion {
  const MayorVictoryCandidate(this.aliveCount);

  /// 当前存活人数（触发时 == 3）。
  final int aliveCount;
}

/// 恶魔死亡，可能传承或善良胜（issue #89 公理5）。
///
/// 三种触发路径：Imp 夜间自杀（[DeathWay.suicide]）、白天处决恶魔
/// （[DeathWay.execution]）、Slayer 击杀恶魔（[DeathWay.slayer]）。
/// 与 [MayorVictoryCandidate] 同级——需用户在确认框裁决：
/// - [scarletWomanEligible] = true → 绯红女自动继承，预选 SW 为继承人；
/// - 否则自杀路径 → 选一名存活爪牙继承；处决/Slayer 路径 → 善良胜。
///
/// [scarletWomanTainted] 仅作提示（SW 被标毒/醉时按规则可能不触发，由
/// 用户裁决）——App 无法确认真身毒/醉，遵循「警告不阻止」原则。
class DemonSuccessionCandidate extends GameEndSuggestion {
  /// 创建候选。
  const DemonSuccessionCandidate({
    required this.demonPlayerId,
    required this.demonName,
    required this.way,
    required this.aliveCountAfter,
    required this.scarletWomanEligible,
    required this.scarletWomanPlayerId,
    required this.scarletWomanTainted,
  });

  /// 死亡的恶魔玩家 id。
  final int demonPlayerId;

  /// 恶魔显示名（座位号+名字）。
  final String demonName;

  /// 恶魔死亡方式。
  final DeathWay way;

  /// 死后存活人数（用于阈值判断与显示）。
  final int aliveCountAfter;

  /// SW 是否满足继承条件（在场存活 + 死前 ≥5 + 首次）。
  final bool scarletWomanEligible;

  /// SW 玩家 id（[scarletWomanEligible] 为 true 时非空）。
  final int? scarletWomanPlayerId;

  /// SW 是否被标记毒/醉（提示用，不改变 [scarletWomanEligible]）。
  final bool scarletWomanTainted;
}

/// 对局结束规则（纯函数，可测试）。
abstract final class GameEndRules {
  /// 处决阈值之外的核心规则：存活 ≤ 2 时邪恶获胜候选。
  static bool isEvilWinCandidate(int aliveCount) => aliveCount <= 2;

  /// 用户确认被处决者是恶魔 → 善良获胜。
  static bool isGoodWin({required bool executedWasDemon}) => executedWasDemon;

  /// 市长胜利候选：恰好 3 名存活玩家且当天无人被处决（issue #88）。
  static bool isMayorWinCandidate(
    int aliveCount, {
    required bool noExecutionToday,
  }) =>
      aliveCount == 3 && noExecutionToday;
}

/// 结束确认结果（dialog 返回）。
class GameEndResult {
  /// 创建结果。
  const GameEndResult({this.goodWin, this.revealedRole});

  /// true=善良胜，false=邪恶胜，null=继续游戏。
  final bool? goodWin;

  /// 可选：被处决者揭示的角色（死亡揭示声明）。
  final Character? revealedRole;
}

/// 传承确认结果（dialog 返回，issue #89）。
class SuccessionResult {
  /// 创建结果。
  const SuccessionResult({
    required this.occurred,
    this.toPlayerId,
    this.trigger,
    this.revealedRole,
  });

  /// true = 传承发生（游戏继续）；false = 恶魔真死，善良胜。
  final bool occurred;

  /// 继承人（新恶魔）。occurred=true 且继承人已知时非空。
  final int? toPlayerId;

  /// 传承机制。
  final SuccessionTrigger? trigger;

  /// 可选：恶魔的死亡揭示角色（处决/Slayer 路径用）。
  final Character? revealedRole;
}
