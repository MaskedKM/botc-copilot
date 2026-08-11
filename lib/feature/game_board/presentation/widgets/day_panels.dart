import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/domain/game_end.dart';
import 'package:botc_copilot/shared/widgets/help_tooltip.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/end_game_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 夜晚结果面板：记录今夜死亡。
class NightPanel extends ConsumerWidget {
  /// 创建面板。
  const NightPanel({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(
      gameBoardProvider(gameId).select((s) => s.currentDay),
    );
    final dayRecord =
        ref.watch(currentDayRecordProvider((gameId, day))).valueOrNull;
    final players = ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];
    final notifier = ref.read(gameBoardProvider(gameId).notifier);
    final helpLevel = ref.watch(gameHelpLevelProvider(gameId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('第 $day 天 · 夜晚死亡', style: AppTextStyles.headline),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('无人死亡'),
              selected: dayRecord?.nightDeathPlayerId == null &&
                  dayRecord != null,
              onSelected: (_) => notifier.recordNightDeath(null),
            ),
            for (final p in players.where((p) => p.isAlive))
              ChoiceChip(
                label: Text('${p.seatNumber}号 ${p.name}'),
                selected: dayRecord?.nightDeathPlayerId == p.id,
                onSelected: (_) => _confirmDeath(
                  context,
                  ref,
                  player: p,
                  action: () => notifier.recordNightDeath(p.id),
                  verb: '夜晚死亡',
                  gameId: gameId,
                  currentPlayerId: dayRecord?.nightDeathPlayerId,
                  onUndo: () => notifier.recordNightDeath(null),
                ),
              ),
          ],
        ),
        HelpTooltip(
          level: helpLevel,
          text: '无人死亡可能意味着：Monk 保护成功 / Soldier 能力 / '
              '恶魔自杀传位 / 恶魔被毒。',
        ),
      ],
    );
  }
}

/// 白天面板：记录处决。
class DayPanel extends ConsumerWidget {
  /// 创建面板。
  const DayPanel({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(
      gameBoardProvider(gameId).select((s) => s.currentDay),
    );
    final dayRecord =
        ref.watch(currentDayRecordProvider((gameId, day))).valueOrNull;
    final players = ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];
    final notifier = ref.read(gameBoardProvider(gameId).notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('第 $day 天 · 白天处决', style: AppTextStyles.headline),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('无处决'),
              selected:
                  dayRecord?.dayExecutionPlayerId == null && dayRecord != null,
              onSelected: (_) => notifier.recordExecution(null),
            ),
            for (final p in players.where((p) => p.isAlive))
              ChoiceChip(
                label: Text('${p.seatNumber}号 ${p.name}'),
                selected: dayRecord?.dayExecutionPlayerId == p.id,
                onSelected: (_) => _confirmDeath(
                  context,
                  ref,
                  player: p,
                  action: () => notifier.recordExecution(p.id),
                  verb: '处决',
                  gameId: gameId,
                  currentPlayerId: dayRecord?.dayExecutionPlayerId,
                  onUndo: () => notifier.recordExecution(null),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '角色声明与信息录入在玩家详情中（点圆环上的玩家）。',
          style: AppTextStyles.caption
              .copyWith(color: context.gameColors.inkViolet),
        ),
      ],
    );
  }
}

/// 破坏性操作二次确认（防误触原则）。
/// 夜晚死亡/处决为 toggle：已选中再点 → 撤销（恢复为 null）。
Future<void> _confirmDeath(
  BuildContext context,
  WidgetRef ref, {
  required Player player,
  required Future<GameEndSuggestion?> Function() action,
  required String verb,
  required int gameId,
  required int? currentPlayerId,
  required VoidCallback onUndo,
}) async {
  // toggle：已选中 → 撤销
  if (currentPlayerId == player.id) {
    onUndo();
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('确认$verb'),
      content: Text('${player.seatNumber}号 ${player.name} $verb？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('确认'),
        ),
      ],
    ),
  );
  if (!(confirmed ?? false)) return;
  final suggestion = await action();
  if (suggestion != null && context.mounted) {
    await _handleEndSuggestion(context, ref, gameId, suggestion);
  }
}

/// 处理结束建议：弹 dialog → 用户确认 → 更新状态。
Future<void> _handleEndSuggestion(
  BuildContext context,
  WidgetRef ref,
  int gameId,
  GameEndSuggestion suggestion,
) async {
  final notifier = ref.read(gameBoardProvider(gameId).notifier);
  switch (suggestion) {
    case EvilWinCandidate(:final aliveCount):
      final confirmed = await EndGameDialog.showEvilCandidate(
        context,
        aliveCount: aliveCount,
      );
      if (confirmed ?? false) {
        await notifier.endGame(goodWin: false);
      }
    case DemonExecutionCheck(
        :final executedPlayerId,
        :final executedName,
        :final aliveCountAfter,
      ):
      final result = await EndGameDialog.showDemonCheck(
        context,
        executedName: executedName,
      );
      if (result == null || !context.mounted) return;
      if (result.goodWin ?? false) {
        // 是恶魔 → 善良获胜（附带可选的死亡揭示）
        await notifier.endGame(
          goodWin: true,
          revealedPlayerId: executedPlayerId,
          revealedRole: result.revealedRole,
        );
      } else if (result.revealedRole != null) {
        // 不是恶魔但揭示了角色 → 只记死亡揭示
        await notifier.recordRevealOnly(
          playerId: executedPlayerId,
          role: result.revealedRole!,
        );
      }
      if (context.mounted &&
          !(result.goodWin ?? false) &&
          GameEndRules.isEvilWinCandidate(aliveCountAfter)) {
        await _checkEvilWinAfterExecution(context, notifier, aliveCountAfter);
      }
  }
}

/// 处决非恶魔后，若存活 ≤ 2 则级联提示邪恶获胜。
Future<void> _checkEvilWinAfterExecution(
  BuildContext context,
  GameBoardNotifier notifier,
  int aliveCount,
) async {
  final confirmed = await EndGameDialog.showEvilCandidate(
    context,
    aliveCount: aliveCount,
  );
  if (confirmed ?? false) {
    await notifier.endGame(goodWin: false);
  }
}

/// 占位面板：投票分析 / 我的推理（后续 issue 实现）。
class ComingSoonPanel extends StatelessWidget {
  /// 创建占位面板。
  const ComingSoonPanel({required this.title, required this.hint, super.key});

  /// 面板标题。
  final String title;

  /// 引导语。
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Text(
              hint,
              style: AppTextStyles.caption
                  .copyWith(color: context.gameColors.inkViolet),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
