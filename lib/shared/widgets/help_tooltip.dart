import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';

/// 可复用的分层帮助提示组件（issue #41）。
///
/// - beginner：默认展开（L1 规则提示直接可见）
/// - normal：折叠为可点开的提示条
/// - expert：不渲染（零干扰）
class HelpTooltip extends StatelessWidget {
  /// 创建提示。
  const HelpTooltip({
    required this.level,
    required this.text,
    this.icon = Icons.help_outline,
    super.key,
  });

  /// 当前帮助层级。
  final HelpLevel level;

  /// 提示内容。
  final String text;

  /// 图标。
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (level == HelpLevel.expert) return const SizedBox.shrink();
    final gameColors = context.gameColors;

    if (level == HelpLevel.beginner) {
      // 新手：直接展开
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: gameColors.inkViolet.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: gameColors.inkViolet),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.caption
                    .copyWith(color: gameColors.inkViolet),
              ),
            ),
          ],
        ),
      );
    }

    // 普通：折叠
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        dense: true,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        leading: Icon(icon, size: 14, color: gameColors.inkViolet),
        title: Text(
          '规则提示',
          style:
              AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              text,
              style: AppTextStyles.caption
                  .copyWith(color: gameColors.inkViolet),
            ),
          ),
        ],
      ),
    );
  }
}
