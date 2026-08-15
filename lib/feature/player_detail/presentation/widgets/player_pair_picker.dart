import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// 双人玩家选择器（信息输入公共组件）。
///
/// 点选两名玩家（如 Fortune Teller 的占卜对象），
/// 已选数达 2 时再点会替换最早的选择。
class PlayerPairPicker extends StatelessWidget {
  /// 创建双人选择器。
  const PlayerPairPicker({
    required this.players,
    required this.selected,
    required this.onChanged,
    this.excludePlayerId,
    this.aliveOnly = false,
    super.key,
  });

  /// 候选玩家。
  final List<Player> players;

  /// 当前选中的玩家 id 集合（最多 2 个）。
  final Set<int> selected;

  /// 排除的玩家 id（Chambermaid 不能选自己；null = 不排除）。
  final int? excludePlayerId;

  /// 只列存活玩家（Chambermaid「2 名存活玩家」；FT 等可任选，默认全列）。
  final bool aliveOnly;

  /// 选择变化回调。
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择两名玩家（${selected.length}/2）',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final p in players.where((p) =>
                p.id != excludePlayerId && (!aliveOnly || p.isAlive)))
              ChoiceChip(
                label: Text('${p.seatNumber}号 ${p.name}'),
                selected: selected.contains(p.id),
                onSelected: (_) {
                  final next = Set<int>.of(selected);
                  if (next.contains(p.id)) {
                    next.remove(p.id);
                  } else {
                    if (next.length >= 2) next.remove(next.first);
                    next.add(p.id);
                  }
                  onChanged(next);
                },
              ),
          ],
        ),
      ],
    );
  }
}
