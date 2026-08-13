import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/setup/presentation/providers/setup_provider.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:botc_copilot/shared/widgets/help_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 4：选择我的角色（按阵营分组）。
class RoleStep extends ConsumerWidget {
  /// 创建步骤页。
  const RoleStep({super.key});

  static const _teams = [
    Team.townsfolk,
    Team.outsider,
    Team.minion,
    Team.demon,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(setupProvider.select((s) => s.myRole));
    final notifier = ref.read(setupProvider.notifier);
    final gameColors = context.gameColors;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('我的角色', style: AppTextStyles.title),
        HelpTooltip(
          level: HelpLevel.normal,
          icon: Icons.person_search_outlined,
          text: '选择你被告知的角色（你的真实身份）。App 据此提供你的夜间信息录入与能力追踪。',
        ),
        const SizedBox(height: 16),
        for (final team in _teams) ...[
          _TeamHeader(team: team),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final role in Character.byTeam(team))
                _RoleChip(
                  role: role,
                  selected: role == selected,
                  onTap: () => notifier.selectRole(role),
                ),
            ],
          ),
          // 选中角色时显示能力描述
          if (selected != null && selected.team == team) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: team.isGood
                    ? gameColors.goldBright.withValues(alpha: 0.1)
                    : gameColors.blood.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selected.ability,
                style: AppTextStyles.body,
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    return Row(
      children: [
        Text(
          team.nameCn,
          style: AppTextStyles.headline.copyWith(
            color: team.isGood ? gameColors.goldBright : gameColors.blood,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Divider(color: AppColors.lineGold, thickness: 0.5),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final Character role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(role.nameCn),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primary,
      labelStyle: AppTextStyles.label.copyWith(
        color: selected ? AppColors.textOnGold : AppColors.textPrimary,
      ),
      side: BorderSide(
        color: selected ? colorScheme.primary : AppColors.lineHairline,
        width: selected ? 1.5 : 0.5,
      ),
      showCheckmark: false,
    );
  }
}
