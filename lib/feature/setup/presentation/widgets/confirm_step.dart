import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/setup/presentation/providers/setup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 5：确认开局信息。
class ConfirmStep extends ConsumerWidget {
  /// 创建步骤页。
  const ConfirmStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupProvider);
    final gameColors = context.gameColors;
    final setup = state.playerSetup;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('确认开局', style: AppTextStyles.title),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(label: '剧本', value: state.script.nameCn),
                _Row(label: '人数', value: '${state.playerCount} 人'),
                _Row(
                  label: '配置',
                  value: '${setup.townsfolk} 镇民 / ${setup.outsiders} 外来者 / '
                      '${setup.minions} 爪牙 / ${setup.demons} 恶魔',
                ),
                _Row(
                  label: '我的角色',
                  value: state.myRole?.nameCn ?? '未选择',
                  valueColor: gameColors.goldBright,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('座位顺序', style: AppTextStyles.headline),
                const SizedBox(height: 8),
                for (var i = 0; i < state.playerNames.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${i + 1}. ${state.playerNames[i]}',
                      style: AppTextStyles.body,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
