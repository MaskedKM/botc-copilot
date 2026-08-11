import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/info_input_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 我的信息录入弹层（issue #34）。
///
/// 首次使用时先确认"哪个座位是我"（写入 games.my_player_id），
/// 之后按 myRole 的 InfoInputType 提供录入，写入 isMine=true。
class MyInfoSheet extends ConsumerWidget {
  /// 创建我的信息弹层。
  const MyInfoSheet({required this.game, super.key});

  /// 当前对局。
  final Game game;

  /// 弹出我的信息录入。
  static Future<void> show(BuildContext context, {required Game game}) {
    return showModalBottomSheet<void>(
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
    final myRole = game.myRole;
    final gameColors = context.gameColors;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '我的信息 · ${myRole?.nameCn ?? "未设置角色"}',
            style: AppTextStyles.title,
          ),
          const SizedBox(height: 16),
          if (game.myPlayerId == null) ...[
            Text(
              '首次使用：哪个座位是你？',
              style: AppTextStyles.headline
                  .copyWith(color: gameColors.goldBright),
            ),
            const SizedBox(height: 8),
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
                    },
                  ),
              ],
            ),
          ] else if (myRole != null) ...[
            Builder(
              builder: (context) {
                final myPlayer =
                    players.where((p) => p.id == game.myPlayerId).firstOrNull;
                if (myPlayer == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '座位：${myPlayer.seatNumber}号 ${myPlayer.name}',
                      style: AppTextStyles.caption
                          .copyWith(color: gameColors.inkViolet),
                    ),
                    const SizedBox(height: 8),
                    InfoInputFactory.build(
                      character: myRole,
                      players: players,
                      onSubmit: (payload) async {
                        final dayRecordId = await ref
                            .read(gameBoardProvider(game.id).notifier)
                            .ensureCurrentDayRecord();
                        await ref
                            .read(playerDetailRepositoryProvider)
                            .declareInfo(
                              playerId: myPlayer.id,
                              dayRecordId: dayRecordId,
                              character: myRole,
                              payload: payload,
                              isMine: true,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('我的信息已记录')),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            Text(
              '开局设置时未选择角色，无法提供信息录入。',
              style: AppTextStyles.caption
                  .copyWith(color: gameColors.inkViolet),
            ),
          ],
        ],
      ),
    );
  }
}
