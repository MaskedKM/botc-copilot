import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/game_board/domain/nomination_rules.dart';

/// 单次提名的投票详情（解码后）。
class NominationVoteDetail {
  /// 创建详情。
  const NominationVoteDetail({
    required this.nominationId,
    required this.dayNumber,
    required this.nominatorId,
    required this.nomineeId,
    required this.passed,
    required this.votes,
  });

  /// 提名 id。
  final int nominationId;

  /// 提名发生的白天序号（从 1 起）。
  final int dayNumber;

  /// 提名者 id。
  final int nominatorId;

  /// 被提名者 id。
  final int nomineeId;

  /// 是否达到处决阈值。
  final bool passed;

  /// 逐投票者记录（已解码）。
  final List<VoteEntry> votes;
}

/// 两玩家之间的投票一致性（issue #57）。
class VoteConsistency {
  /// 创建一致性记录。
  const VoteConsistency({
    required this.playerIdA,
    required this.playerIdB,
    required this.participatedTogether,
    required this.agreedCount,
  });

  /// 玩家 A（较小 id）。
  final int playerIdA;

  /// 玩家 B（较大 id）。
  final int playerIdB;

  /// 两人都有投票记录（参与）的共同提名数。
  ///
  /// 官方规则：存活玩家每天可投多次，故跨提名累计；死者全场仅 1 票，
  /// 数据稀疏不参与聚类。详细模式（[NominationRules.fillQuickVotes] 之外）
  /// 未录入的玩家视为「缺席」——缺席不计入分母，区别于「弃权」。
  final int participatedTogether;

  /// 其中票向相同（同为赞成 / 同为反对 / 同为弃权）的次数。
  final int agreedCount;

  /// 同向比例 [0,1]；无共同提名时为 0。
  double get ratio =>
      participatedTogether == 0 ? 0 : agreedCount / participatedTogether;
}

/// 高频同投组（连通分量，issue #57）。
///
/// 仅作模式观察，不判定阵营：常同方向投票可能同阵营，亦可能巧合。
class VoteCluster {
  /// 创建分组。
  const VoteCluster({required this.playerIds, required this.avgRatio});

  /// 组内玩家 id（已排序）。
  final List<int> playerIds;

  /// 组内两两平均同向比例。
  final double avgRatio;
}

/// 异常投票：某票背离该玩家自身历史「跟随多数」模式（issue #57）。
class VoteAnomaly {
  /// 创建异常记录。
  const VoteAnomaly({
    required this.nominationId,
    required this.dayNumber,
    required this.voterId,
    required this.nomineeId,
    required this.actualVote,
    required this.majorityVote,
    required this.historicalMajorityRate,
  });

  /// 提名 id。
  final int nominationId;

  /// 白天序号。
  final int dayNumber;

  /// 投票者 id。
  final int voterId;

  /// 被提名者 id。
  final int nomineeId;

  /// 该票实际票向。
  final Vote actualVote;

  /// 当次提名的多数立场（存活参与者中赞成/反对的众数）。
  final Vote majorityVote;

  /// 该玩家此前跟随多数的比率（本票发生前）。
  final double historicalMajorityRate;
}

/// 投票模式分析聚合结果。
class VotingAnalysis {
  /// 创建结果。
  const VotingAnalysis({
    required this.details,
    required this.consistency,
    required this.clusters,
    required this.anomalies,
  });

  /// 按时间序（天序、id）排列的逐提名详情。
  final List<NominationVoteDetail> details;

  /// 一致性矩阵：playerIdA -> playerIdB -> 一致性。对称填充。
  /// 所有玩家均为外层 key（无数据者内层为空 map），便于矩阵渲染。
  final Map<int, Map<int, VoteConsistency>> consistency;

  /// 高频同投组（仅存活玩家）。
  final List<VoteCluster> clusters;

  /// 异常投票列表。
  final List<VoteAnomaly> anomalies;
}

/// 投票模式分析（纯函数，issue #57）。
///
/// 全部派生自既有 [Nomination] + [Player] 数据，不引入 schema 变更，
/// 不写入数据库。原则：只展示投票数据，不判定阵营。
abstract final class VotingAnalyzer {
  /// 默认聚类阈值：同向比例 ≥ 此值视为高频同投边。
  static const double defaultClusterRatio = 0.7;

  /// 默认最小共同提名数：少于此数不建边（数据不足）。
  static const int defaultClusterMinData = 2;

  /// 异常检测：历史跟随多数的最小提名数（少于此无法建立模式）。
  static const int defaultAnomalyMinHistory = 2;

  /// 异常检测：历史「跟随多数」比率阈值，超过且本次背离 → 标记。
  static const double defaultAnomalyBreakRatio = 0.7;

  /// 全量分析。
  static VotingAnalysis analyze({
    required List<Nomination> nominations,
    required List<Player> players,
    required Map<int, int> dayRecordToDayNumber,
    double clusterRatio = defaultClusterRatio,
    int clusterMinData = defaultClusterMinData,
    int anomalyMinHistory = defaultAnomalyMinHistory,
    double anomalyBreakRatio = defaultAnomalyBreakRatio,
  }) {
    final details = _buildDetails(nominations, dayRecordToDayNumber);
    // 聚类候选 = 全部玩家：是否成团由「共同提名数 ≥ minData」把关，
    // 不按当前存活状态排除——生前有足量投票数据的死者仍属于其投票阵营
    // （其死亡后无新投票，数据自然冻结，不影响后续）。
    final allIds = <int>{for (final p in players) p.id};
    final consistency = _buildConsistency(details, players);
    final clusters = _detectClusters(
      consistency: consistency,
      candidateIds: allIds,
      ratio: clusterRatio,
      minData: clusterMinData,
    );
    final anomalies = _detectAnomalies(
      details: details,
      minHistory: anomalyMinHistory,
      breakRatio: anomalyBreakRatio,
    );
    return VotingAnalysis(
      details: details,
      consistency: consistency,
      clusters: clusters,
      anomalies: anomalies,
    );
  }

  /// 解码并按时间序（天序 → id）排列提名。
  static List<NominationVoteDetail> _buildDetails(
    List<Nomination> nominations,
    Map<int, int> dayRecordToDayNumber,
  ) {
    final sorted = [...nominations]
      ..sort((a, b) {
        final da = dayRecordToDayNumber[a.dayRecordId] ?? 0;
        final db = dayRecordToDayNumber[b.dayRecordId] ?? 0;
        final cmp = da.compareTo(db);
        return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });
    return [
      for (final n in sorted)
        NominationVoteDetail(
          nominationId: n.id,
          dayNumber: dayRecordToDayNumber[n.dayRecordId] ?? 0,
          nominatorId: n.nominatorPlayerId,
          nomineeId: n.nomineePlayerId,
          passed: n.passed,
          votes: NominationRules.decodeVotes(n.voteResultJson),
        ),
    ];
  }

  /// 构建一致性矩阵。
  ///
  /// 对每条提名，取「有投票记录」的玩家集合，两两累加：共同参与 +1，
  /// 同向再 +1。缺席（无记录）者不进入任何配对。
  static Map<int, Map<int, VoteConsistency>> _buildConsistency(
    List<NominationVoteDetail> details,
    List<Player> players,
  ) {
    // 累加器：a<b 的有序对 -> [participated, agreed]
    final acc = <int, Map<int, List<int>>>{};

    for (final d in details) {
      final voteOf = <int, Vote>{
        for (final v in d.votes) v.playerId: v.vote,
      };
      final ids = voteOf.keys.toList()..sort();
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          final a = ids[i];
          final b = ids[j];
          final slot = acc.putIfAbsent(a, () => {}).putIfAbsent(b, () => [0, 0]);
          slot[0] += 1; // 共同参与
          if (voteOf[a] == voteOf[b]) slot[1] += 1; // 同向
        }
      }
    }

    final result = <int, Map<int, VoteConsistency>>{
      for (final p in players) p.id: <int, VoteConsistency>{},
    };
    acc.forEach((a, inner) {
      inner.forEach((b, val) {
        final c = VoteConsistency(
          playerIdA: a,
          playerIdB: b,
          participatedTogether: val[0],
          agreedCount: val[1],
        );
        result[a]?[b] = c;
        result.putIfAbsent(b, () => <int, VoteConsistency>{})[a] = c;
      });
    });
    return result;
  }

  /// 高频同投组检测：在候选者间，同向比例 ≥ [ratio] 且共同提名数
  /// ≥ [minData] 的配对连边，取连通分量（≥2 人）。候选者为全部玩家，
  /// 数据不足者（共同提名 < [minData]）自然不成边。
  static List<VoteCluster> _detectClusters({
    required Map<int, Map<int, VoteConsistency>> consistency,
    required Set<int> candidateIds,
    required double ratio,
    required int minData,
  }) {
    // 并查集
    final parent = <int, int>{for (final id in candidateIds) id: id};
    int find(int x) {
      var root = x;
      while (parent[root] != root) {
        root = parent[root]!;
      }
      // 路径压缩
      var cur = x;
      while (parent[cur] != root) {
        final next = parent[cur]!;
        parent[cur] = root;
        cur = next;
      }
      return root;
    }

    // 成边的配对（a < b）→ 同向比例，用于 avgRatio
    final edges = <int, Map<int, double>>{};
    final candidates = candidateIds.toList()..sort();
    for (var i = 0; i < candidates.length; i++) {
      final a = candidates[i];
      final inner = consistency[a];
      if (inner == null) continue;
      for (var j = i + 1; j < candidates.length; j++) {
        final b = candidates[j];
        final c = inner[b];
        if (c == null) continue;
        if (c.participatedTogether >= minData && c.ratio >= ratio) {
          parent[find(a)] = find(b);
          edges.putIfAbsent(a, () => <int, double>{})[b] = c.ratio;
        }
      }
    }

    final groups = <int, List<int>>{};
    for (final id in candidates) {
      groups.putIfAbsent(find(id), () => []).add(id);
    }

    final clusters = <VoteCluster>[];
    for (final members in groups.values) {
      if (members.length < 2) continue;
      final memberSet = members.toSet();
      members.sort();
      // avgRatio 仅取实际成边的对，避免把组内未成边的弱关联拉进来。
      final edgeRatios = <double>[];
      edges.forEach((a, inner) {
        if (!memberSet.contains(a)) return;
        inner.forEach((b, r) {
          if (memberSet.contains(b)) edgeRatios.add(r);
        });
      });
      final avg = edgeRatios.isEmpty
          ? 0.0
          : edgeRatios.reduce((x, y) => x + y) / edgeRatios.length;
      clusters.add(VoteCluster(playerIds: members, avgRatio: avg));
    }
    clusters.sort((a, b) => b.playerIds.length.compareTo(a.playerIds.length));
    return clusters;
  }

  /// 异常投票检测。
  ///
  /// 按时间序遍历：对每条有「多数立场」（投票时存活者赞成/反对众数，平票
  /// 或无人投票则无）的提名，检查每个「投票时存活」的投票者是否背离多数
  /// ——若其历史（此前有明确多数的提名）跟随率 ≥ [breakRatio] 且样本
  /// ≥ [minHistory]，标记本次为异常。历史在本票处理**之后**更新。
  ///
  /// 时间正确性：用每票的 [VoteEntry.isDeadVote]（= 亡者唯一一票）判定
  /// 「投票时是否存活」，而**非**当前存活状态——否则生前投的票会因玩家
  /// 后来死亡被误排除，污染多数判定。弃权为中立信号：既不触发异常，也
  /// 不计入跟随多数的历史。
  static List<VoteAnomaly> _detectAnomalies({
    required List<NominationVoteDetail> details,
    required int minHistory,
    required double breakRatio,
  }) {
    final matches = <int, int>{};
    final total = <int, int>{};
    final anomalies = <VoteAnomaly>[];

    for (final d in details) {
      final majority = _majorityStance(d);
      if (majority == null) continue; // 无明确多数，不计入历史也不判定

      for (final v in d.votes) {
        if (v.isDeadVote) continue; // 死票：亡者唯一一票，仅详情展示
        if (v.vote == Vote.abstain) continue; // 弃权：中立信号，不参与
        final t = total[v.playerId] ?? 0;
        final m = matches[v.playerId] ?? 0;
        final priorRate = t == 0 ? 0.0 : m / t;
        if (v.vote != majority && t >= minHistory && priorRate >= breakRatio) {
          anomalies.add(VoteAnomaly(
            nominationId: d.nominationId,
            dayNumber: d.dayNumber,
            voterId: v.playerId,
            nomineeId: d.nomineeId,
            actualVote: v.vote,
            majorityVote: majority,
            historicalMajorityRate: priorRate,
          ));
        }
        // 更新历史（本票之后）
        total[v.playerId] = t + 1;
        if (v.vote == majority) matches[v.playerId] = m + 1;
      }
    }
    return anomalies;
  }

  /// 当次提名的多数立场：「投票时存活」参与者中赞成/反对的众数。
  /// 死票（[VoteEntry.isDeadVote]）与弃权均不计入；平票或无人 → null。
  static Vote? _majorityStance(NominationVoteDetail d) {
    var fors = 0;
    var againsts = 0;
    for (final v in d.votes) {
      if (v.isDeadVote) continue;
      if (v.vote == Vote.forVote) {
        fors++;
      } else if (v.vote == Vote.against) {
        againsts++;
      }
    }
    if (fors == 0 && againsts == 0) return null;
    if (fors == againsts) return null;
    return fors > againsts ? Vote.forVote : Vote.against;
  }
}
