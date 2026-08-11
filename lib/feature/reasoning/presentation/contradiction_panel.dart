import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/contradiction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 矛盾列表面板（issue #38）：推理 Tab 内容。
///
/// 原则：默认折叠，不干扰推理体验；只标记不一致，绝不输出身份结论。
class ContradictionPanel extends ConsumerWidget {
  /// 创建面板。
  const ContradictionPanel({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contradictions = ref.watch(contradictionsProvider(gameId));
    final gameColors = context.gameColors;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('矛盾检测', style: AppTextStyles.headline),
            const SizedBox(width: 8),
            if (contradictions.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: gameColors.blood.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${contradictions.length}',
                  style: AppTextStyles.caption
                      .copyWith(color: gameColors.blood),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '只标记数据不一致，身份判断由你来做。',
          style:
              AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
        ),
        const SizedBox(height: 12),
        if (contradictions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '未发现矛盾标记',
                style: AppTextStyles.caption
                    .copyWith(color: gameColors.inkViolet),
              ),
            ),
          )
        else
          ...contradictions.map(
            (c) => _ContradictionTile(contradiction: c),
          ),
      ],
    );
  }
}

class _ContradictionTile extends StatelessWidget {
  const _ContradictionTile({required this.contradiction});

  final Contradiction contradiction;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final isWarning =
        contradiction.severity == ContradictionSeverity.warning;
    final color = isWarning ? gameColors.blood : gameColors.inkViolet;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        dense: true,
        leading: Icon(
          isWarning ? Icons.warning_amber : Icons.info_outline,
          size: 18,
          color: color,
        ),
        title: Text(
          contradiction.type.nameCn,
          style: AppTextStyles.body.copyWith(color: color),
        ),
        subtitle: contradiction.dayNumber != null
            ? Text(
                '第 ${contradiction.dayNumber} 天',
                style: AppTextStyles.caption,
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              contradiction.description,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
