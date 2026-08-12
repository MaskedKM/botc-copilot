import 'package:botc_copilot/core/constants/character.dart';

/// 对局结束建议（issue #37）。
///
/// 官方规则：
/// - 善良胜：恶魔被处决 / 市长特殊胜利（3 人存活且无处决，issue #88）
/// - 邪恶胜：仅剩 2 名存活玩家
sealed class GameEndSuggestion {
  const GameEndSuggestion();
}

/// 存活 ≤ 2，邪恶可能获胜。
class EvilWinCandidate extends GameEndSuggestion {
  const EvilWinCandidate(this.aliveCount);

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
