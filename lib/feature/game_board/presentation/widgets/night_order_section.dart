import 'package:botc_copilot/core/constants/night_order.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';

/// 夜晚行动顺序参考（issue #61 功能1）。
///
/// 纯展示 widget：由父组件（[NightPanel]）传入 [currentDay] / [helpLevel]，
/// 便于直接测试、无需 provider override。按当前天数默认展示首夜（day 1）
/// 或后续夜顺序，可手动切换。HelpLevel 分层：新手展开 / 普通折叠 / 老手隐藏
/// （与 HelpTooltip 一致）。时序洞察写入相关步骤的 note（如 Imp 杀人
/// 先于占卜师 / 共情者）。
class NightOrderSection extends StatefulWidget {
  /// 创建参考区。
  const NightOrderSection({
    required this.currentDay,
    required this.helpLevel,
    super.key,
  });

  /// 当前天数（决定默认展示首夜还是后续夜）。
  final int currentDay;

  /// 帮助层级（决定展开 / 折叠 / 隐藏）。
  final HelpLevel helpLevel;

  @override
  State<NightOrderSection> createState() => _NightOrderSectionState();
}

class _NightOrderSectionState extends State<NightOrderSection> {
  /// 用户手动切换覆盖；null → 跟随当前天数。
  NightPhase? _override;

  @override
  void didUpdateWidget(covariant NightOrderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 天数变化（推进到下一天）→ 清除手动覆盖，重新跟随当前天
    if (oldWidget.currentDay != widget.currentDay) {
      _override = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.helpLevel == HelpLevel.expert) {
      return const SizedBox.shrink();
    }
    final phase = _override ??
        (widget.currentDay <= 1
            ? NightPhase.firstNight
            : NightPhase.otherNight);
    final content = _content(phase);

    // 新手：直接展开；普通：折叠为 ExpansionTile
    if (widget.helpLevel == HelpLevel.beginner) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('夜晚行动顺序参考', style: AppTextStyles.headline),
          const SizedBox(height: 8),
          content,
        ],
      );
    }
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        dense: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: const Text('夜晚行动顺序参考', style: AppTextStyles.body),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _content(NightPhase phase) {
    final steps =
        phase == NightPhase.firstNight ? firstNightSteps : otherNightSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<NightPhase>(
          segments: const [
            ButtonSegment(value: NightPhase.firstNight, label: Text('首夜')),
            ButtonSegment(value: NightPhase.otherNight, label: Text('后续夜')),
          ],
          selected: {phase},
          onSelectionChanged: (s) => setState(() => _override = s.first),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < steps.length; i++)
          _StepRow(index: i + 1, step: steps[i]),
      ],
    );
  }
}

/// 夜晚阶段（用于 SegmentedButton 切换）。
enum NightPhase { firstNight, otherNight }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.step});

  final int index;
  final NightOrderStep step;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$index.',
              style: AppTextStyles.caption
                  .copyWith(color: gameColors.goldBright),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${step.displayLabel} · ${step.action}',
                  style: AppTextStyles.body,
                ),
                if (step.note != null)
                  Text(
                    step.note!,
                    style: AppTextStyles.caption
                        .copyWith(color: gameColors.inkViolet),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
