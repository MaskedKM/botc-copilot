import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/setup/presentation/providers/setup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 2：选择人数（含阵营配置预览）。
class PlayerCountStep extends ConsumerWidget {
  /// 创建步骤页。
  const PlayerCountStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(setupProvider.select((s) => s.playerCount));
    final setup = PlayerSetup.forCount(count);
    final gameColors = context.gameColors;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('玩家人数', style: AppTextStyles.title),
        const SizedBox(height: 8),
        Text(
          '$count 人',
          style: AppTextStyles.display
              .copyWith(color: gameColors.goldBright),
          textAlign: TextAlign.center,
        ),
        Slider(
          value: count.toDouble(),
          min: PlayerSetup.minPlayers.toDouble(),
          max: PlayerSetup.maxPlayers.toDouble(),
          divisions: PlayerSetup.maxPlayers - PlayerSetup.minPlayers,
          label: '$count 人',
          onChanged: (v) =>
              ref.read(setupProvider.notifier).setPlayerCount(v.round()),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('本局配置', style: AppTextStyles.headline),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CountBadge(label: '镇民', count: setup.townsfolk),
                    _CountBadge(label: '外来者', count: setup.outsiders),
                    _CountBadge(
                      label: '爪牙',
                      count: setup.minions,
                      color: gameColors.bloodBright,
                    ),
                    _CountBadge(
                      label: '恶魔',
                      count: setup.demons,
                      color: gameColors.bloodBright,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '邪恶阵营共 ${setup.evilCount} 人。若 Baron 在场：+2 外来者、-2 镇民。',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label, required this.count, this.color});

  final String label;
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: AppTextStyles.title.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
