import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/info_input_factory.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 玩家详情底部弹层（issue #7）。
///
/// 内容：角色声明 + 角色自适应信息录入 + 信任度调整。
/// 通过 [show] 弹出。
class PlayerDetailSheet extends ConsumerWidget {
  /// 创建玩家详情弹层。
  const PlayerDetailSheet({
    required this.gameId,
    required this.player,
    super.key,
  });

  /// 对局 id。
  final int gameId;

  /// 目标玩家。
  final Player player;

  /// 弹出玩家详情。
  static Future<void> show(
    BuildContext context, {
    required int gameId,
    required Player player,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PlayerDetailSheet(gameId: gameId, player: player),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claims =
        ref.watch(playerClaimsProvider(player.id)).valueOrNull ?? [];
    final declared = claims.isEmpty ? null : claims.last.character;
    final day = ref.watch(
      gameBoardProvider(gameId).select((s) => s.currentDay),
    );
    final players =
        ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // 头部：座位号 + 名字 + 存活状态
            Row(
              children: [
                Text(
                  '${player.seatNumber}号 ${player.name}',
                  style: AppTextStyles.title,
                ),
                const SizedBox(width: 8),
                if (!player.isAlive)
                  Text(
                    '☠ 已死亡',
                    style: AppTextStyles.caption
                        .copyWith(color: context.gameColors.blood),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _RoleClaimSection(
              gameId: gameId,
              player: player,
              day: day,
              claims: claims,
            ),
            const SizedBox(height: 16),
            if (declared != null)
              _InfoInputSection(
                gameId: gameId,
                player: player,
                day: day,
                character: declared,
                players: players,
              )
            else
              Text(
                '先声明角色，再录入该角色的信息。',
                style: AppTextStyles.caption
                    .copyWith(color: context.gameColors.inkViolet),
              ),
            const SizedBox(height: 16),
            _TrustSection(gameId: gameId, player: player, day: day),
          ],
        );
      },
    );
  }
}

/// 角色声明区。
class _RoleClaimSection extends ConsumerWidget {
  const _RoleClaimSection({
    required this.gameId,
    required this.player,
    required this.day,
    required this.claims,
  });

  final int gameId;
  final Player player;
  final int day;
  final List<RoleClaim> claims;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimed = claims.isEmpty ? null : claims.last.character;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('角色声明', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final c in Character.values)
              ChoiceChip(
                label: Text(c.nameCn),
                selected: claimed == c,
                onSelected: (_) async {
                  final dayRecordId = await ref
                      .read(gameBoardProvider(gameId).notifier)
                      .ensureCurrentDayRecord();
                  await ref
                      .read(playerDetailRepositoryProvider)
                      .claimRole(
                        playerId: player.id,
                        dayRecordId: dayRecordId,
                        character: c,
                      );
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// 信息录入区（按角色自适应）。
class _InfoInputSection extends ConsumerWidget {
  const _InfoInputSection({
    required this.gameId,
    required this.player,
    required this.day,
    required this.character,
    required this.players,
  });

  final int gameId;
  final Player player;
  final int day;
  final Character character;
  final List<Player> players;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${character.nameCn} 的信息', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        InfoInputFactory.build(
          character: character,
          players: players,
          onSubmit: (payload) async {
            final dayRecordId = await ref
                .read(gameBoardProvider(gameId).notifier)
                .ensureCurrentDayRecord();
            await ref.read(playerDetailRepositoryProvider).declareInfo(
                  playerId: player.id,
                  dayRecordId: dayRecordId,
                  character: character,
                  payload: payload,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('信息已记录')),
              );
            }
          },
        ),
      ],
    );
  }
}

/// 信任度调整区（5 档滑块，实时反映到圆环色环）。
class _TrustSection extends ConsumerWidget {
  const _TrustSection({
    required this.gameId,
    required this.player,
    required this.day,
  });

  final int gameId;
  final Player player;
  final int day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ref.watch(latestTrustLevelsProvider(gameId)).valueOrNull ??
        const <int, TrustLevel>{};
    final current = levels[player.id] ?? TrustLevel.unknown;
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
                onSelected: (_) =>
                    ref.read(playerDetailRepositoryProvider).setTrustLevel(
                          gameId: gameId,
                          playerId: player.id,
                          day: day,
                          level: level,
                        ),
              ),
          ],
        ),
      ],
    );
  }
}
