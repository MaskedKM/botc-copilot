
import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';

/// 信任度调整区（草稿：onSelect 只更新草稿，不写 DB）。
class TrustSection extends StatelessWidget {
  const TrustSection({
    required this.current,
    required this.onSelect,
    this.readOnly = false,
  });

  final TrustLevel current;
  final void Function(TrustLevel) onSelect;

  /// 只读（复盘）：chip 不可选。
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('信任度', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final level in TrustLevel.values)
              ChoiceChip(
                label: Text(level.nameCn),
                selected: current == level,
                selectedColor: gameColors.ofTrustLevel(level),
                labelStyle: AppTextStyles.label.copyWith(
                  color: current == level
                      ? AppColors.textOnGold
                      : AppColors.textPrimary,
                ),
                onSelected: readOnly ? null : (_) => onSelect(level),
              ),
          ],
        ),
      ],
    );
  }
}

/// 毒标记区（按天，仅「毒」；草稿：onChanged 只更新草稿，不写 DB）。
///
/// 醉汉是整局身份，不在此处——见 [DrunkSuspicionSection]（#109）。
class PoisonSection extends StatelessWidget {
  const PoisonSection({
    required this.day,
    required this.marked,
    required this.onChanged,
    this.readOnly = false,
  });

  final int day;
  final bool marked;
  final void Function(bool) onChanged;

  /// 只读（复盘）：开关不可拨。
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('毒状态（按天）', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text(
            '标记为可能被毒（第 $day 天）',
            style: AppTextStyles.body,
          ),
          subtitle: Text(
            '官方：毒当夜 + 次日白天生效、黄昏解除。被毒者「无能力」，'
            '其获得的信息可能为假，可靠性自动降为「可能被污染」。',
            style: AppTextStyles.caption
                .copyWith(color: gameColors.inkViolet),
          ),
          value: marked,
          activeTrackColor: gameColors.inkViolet,
          onChanged: readOnly ? null : onChanged,
        ),
      ],
    );
  }
}

/// 僵怖假死标记区（BMR，#217 增量4B；即时落库）。
///
/// 官方：僵怖「第 1 次死亡时你活着但登记为死」——存活计数/投票按存活算，
/// 邻座收缩/死亡重建按死亡算。我是僵怖时处决自动登记；他人假死由用户
/// 推测标记（仅拨旗标，不写 deathDay/Cause）。
class FakeDeathSection extends StatelessWidget {
  const FakeDeathSection({
    required this.marked,
    required this.onChanged,
    this.readOnly = false,
  });

  final bool marked;
  final void Function(bool) onChanged;

  /// 只读（复盘）：开关不可拨。
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('僵怖假死（BMR）', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text('登记为死但活着', style: AppTextStyles.body),
          subtitle: Text(
            '官方：僵怖首次死亡时活着但登记为死——圆环按死亡显示，'
            '存活计数/投票仍按存活算；邻座收缩按死亡处理。'
            '第二次死亡为真死。',
            style: AppTextStyles.caption
                .copyWith(color: gameColors.inkViolet),
          ),
          value: marked,
          activeTrackColor: gameColors.inkViolet,
          onChanged: readOnly ? null : onChanged,
        ),
      ],
    );
  }
}

/// 疑似醉汉标记区（整局身份推测，#109；草稿：onChanged 只更新草稿）。
///
/// 官方：醉汉是整局身份（从头到尾醉酒、自己不知道、信息为假），与按天的毒
/// 不同。一次标记全局长效，该玩家所有信息（历史 + 未来）按可能不可靠处理。
class DrunkSuspicionSection extends StatelessWidget {
  const DrunkSuspicionSection({
    required this.marked,
    required this.onChanged,
    this.readOnly = false,
  });

  final bool marked;
  final void Function(bool) onChanged;

  /// 只读（复盘）：开关不可拨。
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('疑似醉汉（整局）', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text(
            '怀疑是醉汉',
            style: AppTextStyles.body,
          ),
          subtitle: Text(
            '官方：醉汉是整局身份，其所有信息都为假（自己不知道）。'
            '标记后该玩家全部信息（历史 + 未来）按可能不可靠处理。',
            style: AppTextStyles.caption
                .copyWith(color: gameColors.inkViolet),
          ),
          value: marked,
          activeTrackColor: gameColors.inkViolet,
          onChanged: readOnly ? null : onChanged,
        ),
      ],
    );
  }
}
