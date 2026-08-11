import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
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
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '无人死亡可能意味着：Monk 保护成功 / Soldier 能力 / 恶魔自杀传位。',
          style: AppTextStyles.caption
              .copyWith(color: context.gameColors.inkViolet),
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
Future<void> _confirmDeath(
  BuildContext context,
  WidgetRef ref, {
  required Player player,
  required Future<void> Function() action,
  required String verb,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('确认$verb'),
      content: Text('将 ${player.seatNumber} 号 ${player.name} 标记为$verb？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('确认$verb'),
        ),
      ],
    ),
  );
  if (confirmed ?? false) await action();
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
