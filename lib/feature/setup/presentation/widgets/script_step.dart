import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/feature/setup/presentation/providers/setup_provider.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:botc_copilot/shared/widgets/help_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 1：选择剧本。
class ScriptStep extends ConsumerWidget {
  /// 创建步骤页。
  const ScriptStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(setupProvider.select((s) => s.script));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('选择剧本', style: AppTextStyles.title),
        HelpTooltip(
          level: HelpLevel.normal,
          icon: Icons.menu_book_outlined,
          text: '剧本决定本局可用的角色与规则。当前仅支持《暗流涌动》(TB)。',
        ),
        const SizedBox(height: 16),
        for (final script in Script.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ScriptCard(
              script: script,
              selected: script == selected,
              // MVP 只内置 TB 角色池；BMR/S&V 角色数据未就绪前禁用，
              // 防止"选了 BMR 却只能选 TB 角色"的数据不一致。
              enabled: script == Script.troubleBrewing,
              onTap: () =>
                  ref.read(setupProvider.notifier).selectScript(script),
            ),
          ),
      ],
    );
  }
}

class _ScriptCard extends StatelessWidget {
  const _ScriptCard({
    required this.script,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Script script;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outline,
          width: selected ? 1.5 : 0.5,
        ),
      ),
      child: ListTile(
        minTileHeight: 64,
        enabled: enabled,
        title: Text('${script.nameCn} · ${script.abbr}'),
        subtitle: Text(enabled ? script.nameEn : '${script.nameEn}（即将支持）'),
        trailing: selected
            ? Icon(Icons.check_circle, color: colorScheme.primary)
            : null,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
