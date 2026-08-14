import 'package:botc_copilot/core/constants/script_definition.dart';
import 'package:botc_copilot/core/constants/team.dart';
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
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text('我的座位', style: AppTextStyles.caption),
                    ),
                    Expanded(
                      child: DropdownButton<int>(
                        // 范围外的残留值（如改了人数）回退为 null，避免越界。
                        value: (state.mySeat != null &&
                                state.mySeat! >= 1 &&
                                state.mySeat! <= state.playerCount)
                            ? state.mySeat
                            : null,
                        hint: const Text('选择你的座位'),
                        isExpanded: true,
                        items: [
                          // 0 = 不指定（清除已选座位）
                          const DropdownMenuItem(
                            value: 0,
                            child: Text('不指定'),
                          ),
                          for (var i = 1; i <= state.playerCount; i++)
                            DropdownMenuItem(
                              value: i,
                              child: Text(
                                '$i 号 · ${state.playerNames[i - 1]}',
                                style: AppTextStyles.body,
                              ),
                            ),
                        ],
                        onChanged: (seat) {
                          if (seat != null) {
                            ref
                                .read(setupProvider.notifier)
                                .selectMySeat(seat == 0 ? null : seat);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 恶魔 Bluff 录入（仅当我是恶魔时；≤6 人局恶魔无 Bluff——官方规则 #113）
        if (state.myRole != null &&
            state.myRole!.team == Team.demon) ...[
          if (state.playerCount >= 7)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '恶魔 Bluff（选 3 个）',
                      style: AppTextStyles.headline
                          .copyWith(color: gameColors.bloodBright),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '说书人给你的 3 个不在场角色。这是推理的关键约束。',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final c in ScriptDefinition.of(state.script)
                            .characters
                            .where(
                              // #152 BUG-1：官方 Bluff = 3 个不在场的好人角色
                              // （镇民 + 外来者）。原 `!= demon` 误含爪牙（
                              // Poisoner/Spy/SW/Baron），污染角色矩阵标注与
                              // 排除法矛盾检测。
                              (c) => c.team.isGood,
                            ))
                          ChoiceChip(
                            label: Text(c.nameCn),
                            selected: state.demonBluffs.contains(c),
                            onSelected: (_) => ref
                                .read(setupProvider.notifier)
                                .toggleBluff(c),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '已选 ${state.demonBluffs.length}/3'
                      '${state.demonBluffs.length == 3 ? '' : '（须选满 3 个）'}',
                      style: AppTextStyles.caption.copyWith(
                        color: state.demonBluffs.length == 3
                            ? gameColors.goldBright
                            : gameColors.bloodBright,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: Icon(Icons.info_outline, color: gameColors.inkViolet),
                title: const Text('本局恶魔无 Bluff 信息'),
                subtitle: const Text('≤6 人局恶魔不知爪牙，亦不获得不在场角色信息。'),
              ),
            ),
          const SizedBox(height: 12),
        ],
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
