import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/domain/game_end.dart';
import 'package:flutter/material.dart';

/// 对局结束确认 dialog（issue #37）。
///
/// 两种入口：
/// - [showEvilCandidate]：存活 ≤ 2 时提示"邪恶获胜？"
/// - [showDemonCheck]：处决后确认"被处决者是恶魔吗？"，可录入死亡揭示角色
abstract final class EndGameDialog {
  /// 存活 ≤ 2 提示。返回 true=确认邪恶获胜，false/null=继续游戏。
  static Future<bool?> showEvilCandidate(
    BuildContext context, {
    required int aliveCount,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('存活人数告急', style: AppTextStyles.title),
        content: Text(
          '场上仅剩 $aliveCount 名存活玩家。\n按官方规则，仅剩 2 人时邪恶阵营获胜。',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('继续游戏'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.gameColors.blood,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('邪恶获胜'),
          ),
        ],
      ),
    );
  }

  /// 处决后确认。返回 [GameEndResult]；null = 取消。
  static Future<GameEndResult?> showDemonCheck(
    BuildContext context, {
    required String executedName,
  }) {
    Character? revealed;
    return showDialog<GameEndResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('$executedName 被处决', style: AppTextStyles.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('他是恶魔吗？', style: AppTextStyles.body),
              const SizedBox(height: 12),
              DropdownButtonFormField<Character>(
                initialValue: revealed,
                decoration: const InputDecoration(
                  labelText: '揭示的角色（可选）',
                  isDense: true,
                ),
                items: [
                  for (final c in Character.values)
                    DropdownMenuItem(value: c, child: Text(c.nameCn)),
                ],
                onChanged: (c) => setState(() => revealed = c),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                GameEndResult(goodWin: false, revealedRole: revealed),
              ),
              child: const Text('不是，继续'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.gameColors.trustConfirmedGood,
              ),
              onPressed: () => Navigator.pop(
                context,
                GameEndResult(goodWin: true, revealedRole: revealed),
              ),
              child: const Text('是恶魔，善良获胜'),
            ),
          ],
        ),
      ),
    );
  }
}
