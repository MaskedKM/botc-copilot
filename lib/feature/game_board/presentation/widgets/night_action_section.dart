import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/info_input_type.dart';
import 'package:botc_copilot/core/constants/night_order.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/info_input_factory.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 夜间行动记录区（issue #110）：按当晚夜序列出在场夜行动作的录入入口。
///
/// 对每个声称（或我是）的「有录入模板」夜行动作角色，按官方夜序展示一行
/// 录入，写入 [InfoDeclaration]（我的座位 isMine=true），复用
/// [InfoInputFactory]。与玩家详情的录入同源，此处提供「一屏按夜序速记」
/// 的聚合入口。
class NightActionSection extends ConsumerWidget {
  /// 创建夜间行动记录区。
  const NightActionSection({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(
      gameBoardProvider(gameId).select((s) => s.currentDay),
    );
    final players = ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];
    final claims = ref.watch(gameClaimsProvider(gameId)).valueOrNull ?? [];
    final game = ref.watch(gameByIdProvider(gameId)).valueOrNull;
    final ongoing = ref.watch(isGameOngoingProvider(gameId));

    // 每玩家最新声明；我座位注入真实角色（myRole，与 #107/#105 一致）
    final latestByPlayer = <int, Character>{};
    for (final c in claims) {
      latestByPlayer[c.playerId] = c.character;
    }
    final myPlayerId = game?.myPlayerId;
    if (game != null && myPlayerId != null && game.myRole != null) {
      latestByPlayer[myPlayerId] = game.myRole!;
    }

    // 当夜可记录的夜行动作角色（按夜序，排除被动 / 无录入模板的）
    final recordable = nightStepsForDay(day)
        .where(
          (s) =>
              s.character != null &&
              s.character!.infoInputType != InfoInputType.none,
        )
        .toList();

    // 每个可记录角色 → 在场声称者（保持夜序）。
    // 仅保留存活者 + 当夜死亡者（夜间行动在死亡结算之前发生；前夜已死者不再行动）。
    final entries = <({Player player, Character character})>[];
    for (final step in recordable) {
      final ch = step.character!;
      for (final p in players) {
        if ((p.deathDay == null || p.deathDay! >= day) &&
            latestByPlayer[p.id] == ch) {
          entries.add((player: p, character: ch));
        }
      }
    }

    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('夜间行动', style: AppTextStyles.headline),
        const SizedBox(height: 4),
        Text(
          '按夜序记录当晚行动（按声明角色；我的座位走真实角色）。',
          style: AppTextStyles.caption
              .copyWith(color: context.gameColors.inkViolet),
        ),
        const SizedBox(height: 12),
        if (!ongoing)
          Text(
            '对局已结束，行动只读。',
            style: AppTextStyles.caption
                .copyWith(color: context.gameColors.inkViolet),
          )
        else
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _NightActionEntry(
                gameId: gameId,
                player: e.player,
                character: e.character,
                isMine: e.player.id == myPlayerId,
              ),
            ),
      ],
    );
  }
}

/// 单条夜间行动录入（标签 + InfoInputFactory）。
class _NightActionEntry extends ConsumerWidget {
  const _NightActionEntry({
    required this.gameId,
    required this.player,
    required this.character,
    required this.isMine,
  });

  final int gameId;
  final Player player;
  final Character character;
  final bool isMine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${character.nameCn}（${player.seatNumber}号 ${player.name}'
          '${isMine ? ' · 我' : ''}）',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 6),
        InfoInputFactory.build(
          character: character,
          players: players,
          actingPlayerId: player.id,
          onSubmit: (payload) async {
            try {
              final notifier = ref.read(gameBoardProvider(gameId).notifier);
              final dayRecordId = await notifier.ensureCurrentDayRecord();
              await ref.read(playerDetailRepositoryProvider).declareInfo(
                    playerId: player.id,
                    dayRecordId: dayRecordId,
                    character: character,
                    payload: payload,
                    isMine: isMine,
                    gameId: gameId,
                    dayNumber: ref.read(gameBoardProvider(gameId)).currentDay,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isMine ? '我的信息已记录' : '信息已记录')),
                );
              }
            } on Object {
              // #164 B9：信息写失败兜底提示。
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
              }
            }
          },
        ),
      ],
    );
  }
}
