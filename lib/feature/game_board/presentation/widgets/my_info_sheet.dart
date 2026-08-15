import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/shared/game_private.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 首夜「我的座位」onboarding 弹层（issue #34 / #131）。
///
/// 仅在 `games.my_player_id` 为空时出现——让用户首次确认「哪个座位是我」。
/// 确认座位后，所有「我的」信息录入 / 换座（#86）/ 私密爪牙名单（#108）统一
/// 在 [PlayerDetailSheet] 的 isMe 分支处理（#131 统一入口，避免首夜两套
/// 弹层来回切换）。
class MyInfoSheet extends ConsumerWidget {
  /// 创建 onboarding 弹层。
  const MyInfoSheet({required this.game, super.key});

  /// 当前对局。
  final Game game;

  /// 弹出首夜座位 onboarding；返回用户选定的玩家 id（未选关闭返回 null）。
  static Future<int?> show(BuildContext context, {required Game game}) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: MyInfoSheet(game: game),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players =
        ref.watch(gamePlayersProvider(game.id)).valueOrNull ?? [];
    final gameColors = context.gameColors;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('哪个座位是你？', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text(
            '确认后即可在玩家详情中录入你的夜间信息，后续也可在那里更换座位。',
            style: AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
          ),
          // #281：恶魔 7+ 漏录 Bluff 引导（漏录则排除法约束静默失效）。
          if (game.myRole != null &&
              game.myRole!.team == Team.demon &&
              game.playerCount >= 7 &&
              demonBluffsOf(game).isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '你是恶魔：确认座位后，请在玩家详情录入 3 个 Bluff 角色'
              '（不在场好人）——排除法依赖它。',
              style: AppTextStyles.caption.copyWith(color: gameColors.bloodBright),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final p in players)
                ChoiceChip(
                  label: Text('${p.seatNumber}号 ${p.name}'),
                  selected: false,
                  onSelected: (_) async {
                    await ref
                        .read(appDatabaseProvider)
                        .gamesDao
                        .updateMyPlayerId(game.id, p.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已设为 ${p.seatNumber}号 ${p.name}'),
                        ),
                      );
                      Navigator.of(context).pop(p.id);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
