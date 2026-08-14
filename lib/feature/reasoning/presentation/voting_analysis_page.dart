import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/domain/nomination_rules.dart';
import 'package:botc_copilot/feature/game_board/data/nomination_repository.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/presentation/player_detail_sheet.dart';
import 'package:botc_copilot/feature/reasoning/data/voting_analysis_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/voting_analysis.dart';
import 'package:botc_copilot/shared/widgets/loading_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 投票模式分析页（issue #57）。
///
/// 展示既有提名数据的派生分析：逐提名详情、玩家×玩家一致性热力图、
/// 高频同投组、异常投票。原则：只展示投票数据，不判定阵营。
class VotingAnalysisPage extends ConsumerWidget {
  /// 创建页面。
  const VotingAnalysisPage({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  /// 打开页面。
  static void show(BuildContext context, {required int gameId}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VotingAnalysisPage(gameId: gameId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(votingAnalysisProvider(gameId));
    final playersAsync = ref.watch(gamePlayersProvider(gameId));
    final nominationsAsync = ref.watch(gameNominationsProvider(gameId));
    final players = playersAsync.valueOrNull ?? [];
    // 区分「加载中 / 出错」与「确无提名」：provider 在这几种情况都返回 null，
    // 用底层流的加载/错误态分别显示（#138：裸转圈改文案、流错误改重试）。
    final loading =
        nominationsAsync.isLoading || playersAsync.isLoading;
    final hasError = nominationsAsync.hasError || playersAsync.hasError;
    final gameColors = context.gameColors;

    return Scaffold(
      appBar: AppBar(title: const Text('投票分析')),
      body: SafeArea(
        child: hasError
            ? ErrorRetryView(
                onRetry: () {
                  ref.invalidate(gameNominationsProvider(gameId));
                  ref.invalidate(gamePlayersProvider(gameId));
                },
              )
            : loading
                ? const LoadingView()
                : analysis == null
                    ? _Empty(gameColors: gameColors)
                    : _VotingAnalysisView(
                        gameId: gameId,
                        analysis: analysis,
                        players: players,
                      ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.gameColors});

  final GameColors gameColors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.how_to_vote_outlined,
                size: 48, color: gameColors.inkViolet),
            const SizedBox(height: 12),
            Text('暂无提名记录', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Text(
              '在「投票」页录入提名后，此处自动生成投票模式分析。',
              style:
                  AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VotingAnalysisView extends StatelessWidget {
  const _VotingAnalysisView({
    required this.gameId,
    required this.analysis,
    required this.players,
  });

  /// 对局 id（drill-down → 玩家详情，#138）。
  final int gameId;

  final VotingAnalysis analysis;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final byId = {for (final p in players) p.id: p};
    final seats = [...players]..sort((a, b) => a.seatNumber.compareTo(b.seatNumber));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (analysis.anomalies.isNotEmpty) ...[
          _SectionTitle(
            icon: Icons.flag_outlined,
            text: '异常投票（${analysis.anomalies.length}）',
          ),
          const SizedBox(height: 6),
          Text(
            '背离自身「跟随多数」历史模式的投票。仅作记录，不判定阵营。',
            style:
                AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
          ),
          const SizedBox(height: 8),
          for (final a in analysis.anomalies)
            _AnomalyTile(anomaly: a, byId: byId, gameId: gameId),
          const SizedBox(height: 16),
        ],
        if (analysis.clusters.isNotEmpty) ...[
          _SectionTitle(
            icon: Icons.group_work_outlined,
            text: '高频同投组（${analysis.clusters.length}）',
          ),
          const SizedBox(height: 6),
          Text(
            '经常投同方向的玩家。可能同阵营，亦可能巧合——请自行判断。',
            style:
                AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in analysis.clusters)
                _ClusterCard(cluster: c, byId: byId, gameId: gameId),
            ],
          ),
          const SizedBox(height: 16),
        ],
        _SectionTitle(
          icon: Icons.grid_on,
          text: '投票一致性矩阵',
        ),
        const SizedBox(height: 6),
        Text(
          '每格 = 两玩家同向投票次数 / 共同参与提名数。缺席（未录入）不计入。',
          style: AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
        ),
        const SizedBox(height: 8),
        _RatioLegend(gameColors: gameColors),
        const SizedBox(height: 8),
        _ConsistencyMatrix(seats: seats, analysis: analysis, byId: byId),
        const SizedBox(height: 16),
        _SectionTitle(
          icon: Icons.list_alt,
          text: '逐提名详情（${analysis.details.length}）',
        ),
        const SizedBox(height: 8),
        for (final d in analysis.details)
          _NominationDetailTile(detail: d, byId: byId),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    return Row(
      children: [
        Icon(icon, size: 18, color: gameColors.goldBright),
        const SizedBox(width: 6),
        Text(text, style: AppTextStyles.headline),
      ],
    );
  }
}

class _AnomalyTile extends StatelessWidget {
  const _AnomalyTile({required this.anomaly, required this.byId, required this.gameId});

  final VoteAnomaly anomaly;
  final Map<int, Player> byId;

  /// 对局 id（drill-down → 玩家详情，#138）。
  final int gameId;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final voter = byId[anomaly.voterId];
    final nominee = byId[anomaly.nomineeId];
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      // drill-down：点异常票 tile 直达投票者详情（#138）。
      child: InkWell(
        onTap: voter == null
            ? null
            : () => PlayerDetailSheet.show(context, gameId: gameId, player: voter),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '第 ${anomaly.dayNumber} 天 · 对 ${_label(nominee)} 的提名',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _voteChip(anomaly.actualVote, gameColors),
                Text(
                  '${_label(voter)} 投${_voteLabel(anomaly.actualVote)}'
                  '（当次多数：${_voteLabel(anomaly.majorityVote)}）',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '此前 ${(anomaly.historicalMajorityRate * 100).round()}% 跟随多数',
              style: AppTextStyles.caption
                  .copyWith(color: gameColors.trustSuspect),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ClusterCard extends StatelessWidget {
  const _ClusterCard({required this.cluster, required this.byId, required this.gameId});

  final VoteCluster cluster;
  final Map<int, Player> byId;

  /// 对局 id（drill-down → 玩家详情，#138）。
  final int gameId;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: gameColors.inkViolet.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gameColors.inkViolet.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '平均同向 ${(cluster.avgRatio * 100).round()}%',
            style: AppTextStyles.caption
                .copyWith(color: gameColors.goldBright),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final id in cluster.playerIds)
                ActionChip(
                  label: Text(
                    '${byId[id]?.seatNumber ?? "?"}号'
                    '${(byId[id]?.isAlive ?? true) ? '' : '☠'}',
                    style: AppTextStyles.caption,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  // drill-down：点玩家直达详情（#138）。
                  onPressed: () {
                    final p = byId[id];
                    if (p != null) {
                      PlayerDetailSheet.show(context, gameId: gameId, player: p);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatioLegend extends StatelessWidget {
  const _RatioLegend({required this.gameColors});

  final GameColors gameColors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('低',
            style: AppTextStyles.caption.copyWith(color: gameColors.inkViolet)),
        const SizedBox(width: 4),
        Container(
          width: 72,
          height: 8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gameColors.goldBright.withValues(alpha: 0.12),
                gameColors.goldBright.withValues(alpha: 0.72),
              ],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text('高',
            style:
                AppTextStyles.caption.copyWith(color: gameColors.goldBright)),
        const SizedBox(width: 12),
        Text('同向投票比例 · 「·」= 无共同提名',
            style: AppTextStyles.caption
                .copyWith(color: gameColors.inkViolet)),
      ],
    );
  }
}

class _ConsistencyMatrix extends StatelessWidget {
  const _ConsistencyMatrix({
    required this.seats,
    required this.analysis,
    required this.byId,
  });

  final List<Player> seats;
  final VotingAnalysis analysis;
  final Map<int, Player> byId;

  static const double _nameColWidth = 56;
  static const double _cellSize = 36;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(_cellSize),
        columnWidths: const {0: FixedColumnWidth(_nameColWidth)},
        border: TableBorder.all(
          color: gameColors.inkViolet.withValues(alpha: 0.15),
          width: 0.5,
        ),
        children: [
          // 表头：左上角空白 + 各列座位号
          TableRow(
            children: [
              const SizedBox(height: _cellSize),
              for (final p in seats)
                SizedBox(
                  height: _cellSize,
                  child: Center(
                    child: Text(
                      '${p.seatNumber}',
                      style: AppTextStyles.caption
                          .copyWith(color: gameColors.inkViolet),
                    ),
                  ),
                ),
            ],
          ),
          for (final row in seats)
            TableRow(
              children: [
                SizedBox(
                  height: _cellSize,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        '${row.seatNumber}${row.isAlive ? '' : '☠'}·'
                        '${_shortName(row.name)}',
                        style: AppTextStyles.caption.copyWith(
                          color: row.isAlive
                              ? null
                              : AppColors.textPrimary.withValues(alpha: 0.45),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                for (final col in seats)
                  _cell(context, row, col, gameColors),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    Player row,
    Player col,
    GameColors gameColors,
  ) {
    if (row.id == col.id) {
      // 对角线：自身
      return SizedBox(
        height: _cellSize,
        child: Container(
          color: gameColors.inkViolet.withValues(alpha: 0.18),
          child: Icon(Icons.remove, size: 12, color: gameColors.inkViolet),
        ),
      );
    }
    final c = analysis.consistency[row.id]?[col.id];
    final participated = c?.participatedTogether ?? 0;
    if (participated == 0) {
      return SizedBox(
        height: _cellSize,
        child: Center(
          child: Text('·',
              style: AppTextStyles.caption
                  .copyWith(color: gameColors.inkViolet.withValues(alpha: 0.5))),
        ),
      );
    }
    final ratio = c!.ratio;
    final color = gameColors.goldBright.withValues(alpha: 0.12 + ratio * 0.6);
    // #165 A3：热力图单元格颜色信息读屏不可达——加 Semantics label（同投次数 +
    // 占比）使颜色语义可达；excludeSemantics 避免裸「5/8」被重复朗读。
    return Semantics(
      label: '${row.seatNumber}号与${col.seatNumber}号：'
          '${c.agreedCount}/$participated 次同投'
          '（${(ratio * 100).round()}%）',
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _showPair(context, row, col, c, gameColors),
        child: Container(
          height: _cellSize,
          color: color,
          alignment: Alignment.center,
          child: Text(
            '${c.agreedCount}/${participated}',
            style: AppTextStyles.caption.copyWith(fontSize: 11),
          ),
        ),
      ),
    );
  }

  void _showPair(BuildContext context, Player a, Player b,
      VoteConsistency c, GameColors gameColors) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        title: Text('${a.seatNumber}号 vs ${b.seatNumber}号',
            style: AppTextStyles.headline),
        content: Text(
          '共同参与提名 ${c.participatedTogether} 次，'
          '其中同向 ${c.agreedCount} 次（${(c.ratio * 100).round()}%）。',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _NominationDetailTile extends StatelessWidget {
  const _NominationDetailTile({required this.detail, required this.byId});

  final NominationVoteDetail detail;
  final Map<int, Player> byId;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final nominator = byId[detail.nominatorId];
    final nominee = byId[detail.nomineeId];
    final forCount =
        detail.votes.where((v) => v.vote == Vote.forVote).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding:
            const EdgeInsets.fromLTRB(12, 0, 12, 8),
        dense: true,
        title: Text(
          '第 ${detail.dayNumber} 天 · ${_label(nominator)} 提名 ${_label(nominee)}',
          style: AppTextStyles.body,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '赞成 $forCount 票 · ${detail.passed ? '通过' : '未通过'}',
            style: AppTextStyles.caption.copyWith(
              color: detail.passed
                  ? gameColors.trustConfirmedGood
                  : gameColors.inkViolet,
            ),
          ),
        ),
        children: [
          for (final v in detail.votes) _voteRow(v, byId[v.playerId], gameColors),
        ],
      ),
    );
  }

  Widget _voteRow(VoteEntry v, Player? p, GameColors gameColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              _label(p),
              style: AppTextStyles.caption.copyWith(
                color: p == null || p.isAlive
                    ? null
                    : AppColors.textPrimary.withValues(alpha: 0.45),
              ),
            ),
          ),
          _voteChip(v.vote, gameColors),
          if (v.isDeadVote) ...[
            const SizedBox(width: 6),
            Text('死票',
                style: AppTextStyles.caption
                    .copyWith(color: gameColors.trustSuspect)),
          ],
        ],
      ),
    );
  }
}

/// 小号投票标签。
Widget _voteChip(Vote vote, GameColors gameColors) {
  final color = _voteColor(vote, gameColors);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(
      _voteLabel(vote),
      style: AppTextStyles.caption.copyWith(color: color, fontSize: 11),
    ),
  );
}

String _voteLabel(Vote v) => switch (v) {
      Vote.forVote => '赞成',
      Vote.against => '反对',
      Vote.abstain => '弃权',
    };

Color _voteColor(Vote v, GameColors c) => switch (v) {
      Vote.forVote => c.trustConfirmedGood,
      // #165 A4：blood 在小号文字未达 AA，用 bloodBright（≈4.7:1）。
      Vote.against => c.bloodBright,
      Vote.abstain => c.inkViolet,
    };

String _label(Player? p) => p == null ? '?' : '${p.seatNumber}号 ${p.name}';

String _shortName(String name) =>
    name.length > 3 ? name.substring(0, 3) : name;
