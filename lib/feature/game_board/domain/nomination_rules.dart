import 'dart:convert';

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
}
