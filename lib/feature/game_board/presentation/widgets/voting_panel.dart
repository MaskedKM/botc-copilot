import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/data/nomination_repository.dart';
import 'package:botc_copilot/feature/game_board/domain/nomination_rules.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/day_panels.dart';
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
    final dayRecord =
        ref.watch(currentDayRecordProvider((gameId, day))).valueOrNull;
    final gameColors = context.gameColors;

    final playersById = {for (final p in players) p.id: p};

    // 今日是否已处决（#79：处决后提名阶段结束）
    final executed = dayRecord?.dayExecutionPlayerId != null;

    // 当天「即将死亡」判定（issue #53 最高票累计 + 平票规则）。
    final aliveCount = players.where((p) => p.isAlive).length;
    final pending = NominationRules.pendingExecution(nominations, aliveCount);
    final pendingNominee = pending is PendingExecution
        ? playersById[(pending).nomineeId]
        : null;

    return Column(
      children: [
        // 今日处决已执行（#79）：处决后当天提名阶段结束
        if (executed)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: gameColors.inkViolet.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: gameColors.inkViolet, width: 1),
            ),
            child: Text(
              '今日处决已执行，提名阶段已结束。',
              style: AppTextStyles.body.copyWith(color: gameColors.inkViolet),
            ),
          )
        // 即将死亡 / 平票提示条
        else if (pending is PendingExecution || pending is PendingTie)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: gameColors.blood.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: gameColors.blood, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pending is PendingExecution
                      ? '即将死亡：${pendingNominee?.seatNumber ?? "?"}号 '
                          '${pendingNominee?.name ?? "?"}'
                          '（${(pending).forCount} 票，可被更高票替换）'
                      : '平票 ${(pending as PendingTie).forCount} 票'
                          ' —— 无人即将死亡，后续须超过此票数',
                  style: AppTextStyles.body.copyWith(color: gameColors.blood),
                ),
                // 一键处决（issue #85）：从「即将死亡」直达处决录入
                if (pending is PendingExecution && pendingNominee != null) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => confirmDeath(
                      context,
                      ref,
                      player: pendingNominee,
                      action: () => ref
                          .read(gameBoardProvider(gameId).notifier)
                          .recordExecution(pendingNominee.id),
                      verb: '处决',
                      gameId: gameId,
                    ),
                    icon: const Icon(Icons.gavel),
                    label: const Text('记录处决'),
                  ),
                ],
              ],
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              n.passed ? Icons.gavel : Icons.close,
                              color: n.passed
                                  ? gameColors.blood
                                  : gameColors.inkViolet,
                            ),
                            // 删除误录的提名（issue #83）
                            IconButton(
                              tooltip: '删除提名',
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: gameColors.inkViolet,
                              ),
                              onPressed: () =>
                                  _confirmDeleteNomination(context, ref, n.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: (players.isEmpty || executed)
                ? null
                : () => NominationEntrySheet.show(context, gameId: gameId),
            icon: const Icon(Icons.how_to_vote),
            label: Text(executed ? '今日已处决' : '记录提名'),
          ),
        ),
      ],
    );
  }
}

/// 删除提名的二次确认（issue #83）。
///
/// 说明连带影响：删除后释放其消耗的死票、重算当天最高票（派生数据均为
/// 实时计算，无需额外级联）。
Future<void> _confirmDeleteNomination(
  BuildContext context,
  WidgetRef ref,
  int nominationId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('删除这条提名？'),
      content: const Text('删除后将释放其消耗的死票、并重算当天最高票。'
          '该操作不可撤销。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  if (confirmed ?? false) {
    await ref.read(nominationRepositoryProvider).deleteNomination(nominationId);
  }
}
