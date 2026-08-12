import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/data/nomination_repository.dart';
import 'package:botc_copilot/feature/game_board/domain/nomination_rules.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/nomination_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 投票面板（替换 #6 的占位 Tab）：当日提名列表 + 新增提名。
class VotingPanel extends ConsumerWidget {
  /// 创建面板。
  const VotingPanel({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(
      gameBoardProvider(gameId).select((s) => s.currentDay),
    );
    final nominations =
        ref.watch(dayNominationsProvider((gameId, day))).valueOrNull ?? [];
    final players = ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];
    final gameColors = context.gameColors;

    final playersById = {for (final p in players) p.id: p};

    // 当天「即将死亡」判定（issue #53 最高票累计 + 平票规则）。
    final aliveCount = players.where((p) => p.isAlive).length;
    final pending = NominationRules.pendingExecution(nominations, aliveCount);
    final pendingNominee = pending is PendingExecution
        ? playersById[(pending).nomineeId]
        : null;

    return Column(
      children: [
        // 即将死亡 / 平票提示条
        if (pending is PendingExecution || pending is PendingTie)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: gameColors.blood.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: gameColors.blood, width: 1),
            ),
            child: Text(
              pending is PendingExecution
                  ? '即将死亡：${pendingNominee?.seatNumber ?? "?"}号 '
                      '${pendingNominee?.name ?? "?"}'
                      '（${(pending).forCount} 票，可被更高票替换）'
                  : '平票 ${(pending as PendingTie).forCount} 票'
                      ' —— 无人即将死亡，后续须超过此票数',
              style: AppTextStyles.body.copyWith(color: gameColors.blood),
            ),
          ),
        Expanded(
          child: nominations.isEmpty
              ? Center(
                  child: Text(
                    '今天还没有提名。点下方按钮记录一次提名。',
                    style: AppTextStyles.caption
                        .copyWith(color: gameColors.inkViolet),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: nominations.length,
                  itemBuilder: (context, index) {
                    final n = nominations[index];
                    final votes = NominationRules.decodeVotes(n.voteResultJson);
                    final forCount = NominationRules.countFor(votes);
                    final nominator = playersById[n.nominatorPlayerId];
                    final nominee = playersById[n.nomineePlayerId];
                    final isPending = pending is PendingExecution &&
                        n.nomineePlayerId == (pending).nomineeId;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isPending
                          ? gameColors.blood.withValues(alpha: 0.08)
                          : null,
                      child: ListTile(
                        title: Text(
                          '${nominator?.name ?? "?"} 提名 ${nominee?.name ?? "?"}'
                          '${nominee != null && !nominee.isAlive ? ' ☠' : ''}',
                          style: AppTextStyles.headline,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '赞成 $forCount 票'
                              '${n.passed ? ' · 通过' : ' · 未通过'}',
                              style: AppTextStyles.caption.copyWith(
                                color: n.passed
                                    ? gameColors.blood
                                    : gameColors.inkViolet,
                              ),
                            ),
                            if ((n.defenseText ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '「${n.defenseText}」',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption,
                                ),
                              ),
                          ],
                        ),
                        trailing: Icon(
                          n.passed ? Icons.gavel : Icons.close,
                          color: n.passed
                              ? gameColors.blood
                              : gameColors.inkViolet,
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: players.isEmpty
                ? null
                : () => NominationEntrySheet.show(context, gameId: gameId),
            icon: const Icon(Icons.how_to_vote),
            label: const Text('记录提名'),
          ),
        ),
      ],
    );
  }
}
