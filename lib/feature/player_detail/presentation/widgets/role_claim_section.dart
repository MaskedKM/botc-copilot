
import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/script_definition.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/shared/widgets/help_tooltip.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 角色声明区（草稿：onSelect 只更新草稿，不写 DB）。
class RoleClaimSection extends ConsumerWidget {
  const RoleClaimSection({
    required this.gameId,
    required this.selected,
    required this.onSelect,
    this.readOnly = false,
    this.onUndo,
  });

  final int gameId;
  final Character? selected;
  final void Function(Character) onSelect;

  /// 只读（复盘）：chip 不可选。
  final bool readOnly;

  /// 撤销最新声明（误声明纠错，#160 #11）；null=无声明/只读，不显示。
  final Future<void> Function()? onUndo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final helpLevel = ref.watch(gameHelpLevelProvider(gameId));
    final script = ref.watch(
          gameByIdProvider(gameId).select((g) => g.valueOrNull?.script),
        ) ??
        Script.troubleBrewing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('角色声明', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        // 按阵营分组（与开局选角 role_step 一致，#160 P0）：首夜为 5-15 人
        // 逐一声明是最高频操作，平铺 22 chip 线性扫描 + 相邻易误点。
        for (final team in const [
          Team.townsfolk,
          Team.outsider,
          Team.minion,
          Team.demon,
        ]) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              team.nameCn,
              style: AppTextStyles.caption.copyWith(
                color: team.isGood
                    ? context.gameColors.goldBright
                    : context.gameColors.bloodBright,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final c in ScriptDefinition.of(script).byTeam(team))
                ChoiceChip(
                  label: Text(c.nameCn),
                  selected: selected == c,
                  onSelected: readOnly ? null : (_) => onSelect(c),
                ),
            ],
          ),
        ],
        // 新手模式：显示当前声明角色的能力描述（issue #41）
        if (selected != null)
          HelpTooltip(
            level: helpLevel,
            icon: Icons.auto_stories_outlined,
            text: '${selected!.nameCn}：${selected!.ability}',
          ),
        // 撤销最新声明（误声明纠错，#160 #11；与信息/备注/提名可删对称）。
        if (onUndo != null && selected != null && !readOnly)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onUndo,
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('撤销声明'),
            ),
          ),
      ],
    );
  }
}
