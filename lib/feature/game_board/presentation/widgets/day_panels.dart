import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/data/nomination_repository.dart';
import 'package:botc_copilot/feature/game_board/domain/game_end.dart';
import 'package:botc_copilot/feature/game_board/domain/nomination_rules.dart';
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
              // 选中态由显式 nightConfirmed 驱动，避免预建记录假选中（#77）。
              selected: dayRecord?.nightConfirmed == true &&
                  dayRecord?.nightDeathPlayerId == null,
              onSelected: (_) => notifier.recordNightDeath(null),
            ),
            for (final p in players.where((p) => p.isAlive))
              ChoiceChip(
                label: Text('${p.seatNumber}号 ${p.name}'),
                selected: dayRecord?.nightDeathPlayerId == p.id,
                onSelected: (_) => confirmDeath(
                  context,
                  ref,
                  player: p,
                  action: () => notifier.recordNightDeath(p.id),
                  verb: '夜晚死亡',
                  gameId: gameId,
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
    final todayNominations =
        ref.watch(dayNominationsProvider((gameId, day))).valueOrNull ?? [];
    final notifier = ref.read(gameBoardProvider(gameId).notifier);

    // 处决合法性参考（issue #85）：当天「即将死亡」者
    final aliveCount = players.where((p) => p.isAlive).length;
    final pending =
        NominationRules.pendingExecution(todayNominations, aliveCount);
    final pendingId =
        pending is PendingExecution ? pending.nomineeId : null;
    // 警告文案用：「3号 玩家3（5 票）」
    String? pendingLabel;
    if (pending is PendingExecution) {
      final nominee = players
          .where((p) => p.id == pending.nomineeId)
          .firstOrNull;
      if (nominee != null) {
        pendingLabel = '${nominee.seatNumber}号 ${nominee.name}'
            '（${pending.forCount} 票）';
      }
    }

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
            for (final p in players)
              ChoiceChip(
                // 处决候选含死人（处决死人是合法操作，#80）；死者标 ☠
                label: Text(
                  '${p.seatNumber}号 ${p.name}'
                  '${p.isAlive ? '' : ' ☠'}',
                ),
                selected: dayRecord?.dayExecutionPlayerId == p.id,
                onSelected: (_) => _confirmExecution(
                  context,
                  ref,
                  player: p,
                  gameId: gameId,
                  pendingId: pendingId,
                  pendingLabel: pendingLabel,
                  notifier: notifier,
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
/// 撤销/改选由 provider 处理：重选「无人死亡」或改选他人会自动复活前者。
///
/// 公开以便投票面板的「即将死亡→处决」复用（issue #85）。
Future<void> confirmDeath(
  BuildContext context,
  WidgetRef ref, {
  required Player player,
  required Future<GameEndSuggestion?> Function() action,
  required String verb,
  required int gameId,
}) async {
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

/// 处决合法性校验（issue #85）。
///
/// 若当天有「即将死亡」者且选的不是他 → 先警告（不阻止，覆盖 Virgin 等
/// 特殊流程时需要）；确认后再走标准 [confirmDeath] 二次确认 + 结束判定。
Future<void> _confirmExecution(
  BuildContext context,
  WidgetRef ref, {
  required Player player,
  required int gameId,
  required int? pendingId,
  required String? pendingLabel,
  required GameBoardNotifier notifier,
}) async {
  if (pendingId != null && pendingId != player.id) {
    final override = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('处决对象非台上即将死亡者'),
        content: Text('当前即将死亡的是 ${pendingLabel ?? '另一玩家'}，不是此人。'
            '仍要处决吗？（Virgin 处决提名者等特殊流程可能需要手动覆盖）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('仍要处决'),
          ),
        ],
      ),
    );
    if (!(override ?? false)) return;
  }
  await confirmDeath(
    context,
    ref,
    player: player,
    action: () => notifier.recordExecution(player.id),
    verb: '处决',
    gameId: gameId,
  );
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
      // Saint 处决 → 邪恶立即获胜（issue #54）。
      // App 按玩家**声明**提示：声明圣徒被处决时弹出邪恶胜确认。
      // 用户否认（如恶魔 bluff 圣徒，实际应善良胜）→ 继续走恶魔确认。
      if (await _claimedSaint(ref, executedPlayerId)) {
        if (!context.mounted) return;
        final evilWin = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('圣徒被处决'),
            content: Text('$executedName 声明为圣徒。处决圣徒会使善良方'
                '立即战败。结束对局？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('邪恶获胜'),
              ),
            ],
          ),
        );
        if (evilWin ?? false) {
          await notifier.endGame(goodWin: false);
          return;
        }
        // 未确认邪恶胜 → 落入下方恶魔确认流程（不 return）
        if (!context.mounted) return;
      }
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

/// 该玩家最新声明的角色是否为圣徒（issue #54 Saint 处决判定）。
Future<bool> _claimedSaint(WidgetRef ref, int playerId) async {
  final claims = await ref
      .read(appDatabaseProvider)
      .roleClaimsDao
      .watchByPlayer(playerId)
      .first;
  return claims.isNotEmpty && claims.last.character == Character.saint;
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
