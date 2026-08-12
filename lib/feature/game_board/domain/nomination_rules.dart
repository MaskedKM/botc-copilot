import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/core/database/app_database.dart';

/// 一票的取值。
enum Vote {
  /// 赞成。
  forVote,

  /// 反对。
  against,

  /// 弃权。
  abstain,
}

/// 单个玩家的投票记录。
class VoteEntry {
  /// 创建投票记录。
  const VoteEntry({
    required this.playerId,
    required this.vote,
    this.isDeadVote = false,
  });

  /// 投票玩家 id。
  final int playerId;

  /// 票向。
  final Vote vote;

  /// 是否为死票（死亡玩家的唯一一票）。
  final bool isDeadVote;

  /// 转 JSON map。
  Map<String, Object?> toJson() => {
        'playerId': playerId,
        'vote': vote.name,
        'isDeadVote': isDeadVote,
      };

  /// 从 JSON map 解析。
  factory VoteEntry.fromJson(Map<String, dynamic> json) => VoteEntry(
        playerId: json['playerId'] as int,
        vote: Vote.values.byName(json['vote'] as String),
        isDeadVote: json['isDeadVote'] as bool? ?? false,
      );
}

/// 提名/投票规则校验与计票（官方规则，issue #33）。
abstract final class NominationRules {
  /// 计票：赞成票数（不含弃权/反对）。
  static int countFor(List<VoteEntry> votes) =>
      votes.where((v) => v.vote == Vote.forVote).length;

  /// 处决阈值：赞成票 ≥ 存活人数一半（向上取整）。
  static int threshold(int aliveCount) => (aliveCount / 2).ceil();

  /// 是否通过（达到处决阈值）。
  static bool isPassed(List<VoteEntry> votes, int aliveCount) =>
      countFor(votes) >= threshold(aliveCount);

  /// 校验：某人今天是否已提名过。
  static bool hasNominatedToday(List<Nomination> todayNominations, int playerId) =>
      todayNominations.any((n) => n.nominatorPlayerId == playerId);

  /// 校验：某人今天是否已被提名过。
  static bool hasBeenNominatedToday(
    List<Nomination> todayNominations,
    int playerId,
  ) =>
      todayNominations.any((n) => n.nomineePlayerId == playerId);

  /// 某死亡玩家的死票是否已在本局用过。
  static bool deadVoteUsed(
    List<Nomination> allNominations,
    int playerId,
  ) {
    for (final n in allNominations) {
      final votes = decodeVotes(n.voteResultJson);
      if (votes.any((v) => v.playerId == playerId && v.isDeadVote)) {
        return true;
      }
    }
    return false;
  }

  /// 解码投票 JSON。
  static List<VoteEntry> decodeVotes(String json) {
    final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    return list.map(VoteEntry.fromJson).toList();
  }

  /// 计算当天「即将死亡」者（官方最高票累计机制，issue #53）。
  ///
  /// 处决不是每次提名独立判断，而是当天累计最高票：
  /// - 仅考虑达到处决阈值（[threshold]）的提名。
  /// - 在通过的提名中取最高赞成票：
  ///   - 唯一最高 → 该被提名者即将死亡（[PendingExecution]），
  ///     后续出现更高票会**替换**为新的即将死亡者。
  ///   - 最高票并列 → [PendingTie]：无人即将死亡，后续须**超过**此票数。
  /// - 无通过提名 → [PendingNone]。
  ///
  /// 注：[NominationRules.hasBeenNominatedToday] 保证同一被提名者每天
  /// 至多出现一次，故并列即不同人平票。
  static PendingExecutionResult pendingExecution(
    List<Nomination> todayNominations,
    int aliveCount,
  ) {
    final thresh = threshold(aliveCount);
    final passed = <(int nomineeId, int forCount)>[];
    for (final n in todayNominations) {
      final forCount = countFor(decodeVotes(n.voteResultJson));
      if (forCount >= thresh) {
        passed.add((n.nomineePlayerId, forCount));
      }
    }
    if (passed.isEmpty) return const PendingNone();
    final top = passed.map((p) => p.$2).reduce((a, b) => a > b ? a : b);
    final topNominees = passed.where((p) => p.$2 == top).toList();
    if (topNominees.length == 1) {
      return PendingExecution(topNominees.single.$1, top);
    }
    return PendingTie(top);
  }

  /// Virgin 触发场景检测（issue #54 收尾）。
  ///
  /// 官方规则：处女首次被镇民提名（且未被毒/醉）时，提名者立即被处决、
  /// 当天提名结束；能力随之消耗。本函数按玩家**声明**判定是否构成场景：
  /// - 被提名者最新声明为 Virgin 且能力未消耗（abilityUsed=false）
  /// - 提名者最新声明为 Townsfolk
  ///
  /// 返回被触发 Virgin 的 playerId（即 nominee），否则 null。是否真正
  /// 触发（醉/毒）由 UI 弹窗交用户确认。
  static int? virginTriggerScenario({
    required int nominatorId,
    required int nomineeId,
    required Map<int, RoleClaim> latestClaim,
    required Map<int, Player> playersById,
  }) {
    final nomineeClaim = latestClaim[nomineeId];
    final nominatorClaim = latestClaim[nominatorId];
    if (nomineeClaim == null || nominatorClaim == null) return null;
    if (nomineeClaim.character != Character.virgin) return null;
    if (nominatorClaim.character.team != Team.townsfolk) return null;
    final nominee = playersById[nomineeId];
    if (nominee == null || nominee.abilityUsed) return null;
    if (!nominee.isAlive) return null; // 死亡玩家无能力，不触发（review M3）
    return nomineeId;
  }
}

/// 当天「即将死亡」判定结果（issue #53）。
sealed class PendingExecutionResult {
  const PendingExecutionResult();
}

/// 唯一最高票 → 该被提名者即将死亡。
class PendingExecution extends PendingExecutionResult {
  const PendingExecution(this.nomineeId, this.forCount);

  /// 即将死亡的被提名者 id。
  final int nomineeId;

  /// 其获得的赞成票数。
  final int forCount;
}

/// 最高票平票 → 无人即将死亡，后续须超过 [forCount]。
class PendingTie extends PendingExecutionResult {
  const PendingTie(this.forCount);

  /// 并列的最高票数。
  final int forCount;
}

/// 无人达到处决阈值。
class PendingNone extends PendingExecutionResult {
  const PendingNone();
}
