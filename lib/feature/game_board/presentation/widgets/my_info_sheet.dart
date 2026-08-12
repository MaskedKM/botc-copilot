import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/info_input_factory.dart';
import 'package:botc_copilot/shared/game_private.dart';
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
    final ongoing = ref.watch(isGameOngoingProvider(game.id));

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
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已设为 ${p.seatNumber}号 ${p.name}'),
                          ),
                        );
                      }
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
                    // #86：任何阶段可修正我的座位（开局选错可补救）
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            _changeSeatDialog(context, ref, game, players),
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('更换座位'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // #81：对局结束后信息录入只读（更换座位 #86 不受影响）
                    if (ongoing)
                      InfoInputFactory.build(
                        character: myRole,
                        players: players,
                        actingPlayerId: myPlayer.id,
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
                                gameId: game.id,
                                dayNumber: ref
                                    .read(gameBoardProvider(game.id))
                                    .currentDay,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('我的信息已记录')),
                            );
                          }
                        },
                      )
                    else
                      Text(
                        '对局已结束，信息只读。',
                        style: AppTextStyles.caption
                            .copyWith(color: gameColors.inkViolet),
                      ),
                    // 恶魔私密爪牙名单（7+ 人局，#108）
                    if (myRole == Character.imp && game.playerCount >= 7) ...[
                      const SizedBox(height: 16),
                      _MyMinionsSection(game: game, players: players),
                    ],
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

/// 更换我的座位（issue #86）：选座 → 二次确认 → 写 myPlayerId。
Future<void> _changeSeatDialog(
  BuildContext context,
  WidgetRef ref,
  Game game,
  List<Player> players,
) async {
  var picked = game.myPlayerId;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('更换我的座位'),
        content: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final p in players)
              ChoiceChip(
                label: Text('${p.seatNumber}号 ${p.name}'),
                selected: picked == p.id,
                onSelected: (_) => setState(() => picked = p.id),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: picked == null
                ? null
                : () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    ),
  );
  final id = picked;
  if (confirmed == true && id != null && id != game.myPlayerId) {
    await ref
        .read(appDatabaseProvider)
        .gamesDao
        .updateMyPlayerId(game.id, id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已更换座位')),
      );
    }
  }
}

/// 恶魔私密爪牙名单（issue #108）。
///
/// 官方：7+ 人局恶魔首夜得知爪牙是谁。多选玩家（排除自己），即时写入
/// `Games.myMinionIdsJson`。私密——不进公开推理，仅角色矩阵对我私密展示。
class _MyMinionsSection extends ConsumerWidget {
  const _MyMinionsSection({required this.game, required this.players});

  final Game game;
  final List<Player> players;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameColors = context.gameColors;
    final selected = minionIdsOf(game);
    final expected = PlayerSetup.forCount(game.playerCount).minions;
    // 候选：除我以外的玩家
    final candidates =
        players.where((p) => p.id != game.myPlayerId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '我的爪牙（私密，${game.playerCount} 人局应有 $expected 个）',
          style: AppTextStyles.headline.copyWith(color: gameColors.blood),
        ),
        const SizedBox(height: 4),
        Text(
          '官方：7+ 人局恶魔首夜得知爪牙。仅你可见，不影响公开推理。',
          style: AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final p in candidates)
              ChoiceChip(
                label: Text('${p.seatNumber}号 ${p.name}'),
                selected: selected.contains(p.id),
                onSelected: (_) async {
                  final next = Set<int>.of(selected);
                  if (next.contains(p.id)) {
                    next.remove(p.id);
                  } else {
                    next.add(p.id);
                  }
                  await ref.read(appDatabaseProvider).gamesDao.updateMyMinionIds(
                        game.id,
                        jsonEncode(next.toList()),
                      );
                },
              ),
          ],
        ),
      ],
    );
  }
}
