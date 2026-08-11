import 'package:botc_copilot/core/router.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:go_router/go_router.dart';
import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/domain/seat_ring_player.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/day_panels.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/my_info_sheet.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/seat_ring.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/voting_panel.dart';
import 'package:botc_copilot/feature/player_detail/presentation/player_detail_sheet.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 对局主界面（issue #6）：座位圆环 + 当日面板。
///
/// 布局：上半部钟面座位圆环（含第 N 天中心显示），下半部当日面板
/// （夜晚结果 / 白天处决 / 投票 / 推理 Tab）。
class GameBoardPage extends ConsumerWidget {
  /// 创建对局主界面。
  const GameBoardPage({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameByIdProvider(gameId));

    return gameAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('加载失败：$e'))),
      data: (game) {
        if (game == null) {
          return const Scaffold(
            body: Center(child: Text('对局不存在或已删除')),
          );
        }
        return _GameBoardBody(game: game);
      },
    );
  }
}

class _GameBoardBody extends ConsumerWidget {
  const _GameBoardBody({required this.game});

  final Game game;

  int get gameId => game.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardState = ref.watch(gameBoardProvider(gameId));
    final playersAsync = ref.watch(gamePlayersProvider(gameId));
    final trustLevels =
        ref.watch(latestTrustLevelsProvider(gameId)).valueOrNull ?? {};

    // 玩家流未就绪时不渲染圆环（0 人会违反布局的 5-15 断言）。
    final players = playersAsync.valueOrNull;
    if (players == null || players.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final aliveCount = players.where((p) => p.isAlive).length;

    final ringPlayers = [
      for (final p in players)
        SeatRingPlayer(
          id: p.id,
          name: p.name,
          seatNumber: p.seatNumber,
          isAlive: p.isAlive,
          trustLevel: trustLevels[p.id] ?? TrustLevel.unknown,
          isMe: p.id == game.myPlayerId,
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('第 ${boardState.currentDay} 天'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${game.script.nameCn} · 存活 $aliveCount/${players.length} 人',
              style: AppTextStyles.caption,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: '我的信息',
            icon: const Icon(Icons.person_outline),
            onPressed: () => MyInfoSheet.show(context, game: game),
          ),
          IconButton(
            tooltip: '事件时间线',
            icon: const Icon(Icons.timeline),
            onPressed: () => context.push(AppRoutes.timeline(gameId)),
          ),
          IconButton(
            tooltip: '推进到下一天',
            icon: const Icon(Icons.skip_next),
            onPressed: () =>
                ref.read(gameBoardProvider(gameId).notifier).advanceDay(),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => _onMenu(context, ref, v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'good_win', child: Text('结束：善良获胜')),
              PopupMenuItem(value: 'evil_win', child: Text('结束：邪恶获胜')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 钟面座位圆环（签名组件，直径 ≈ 屏宽 85%）
            Expanded(
              flex: 5,
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.85,
                  child: SeatRing(
                    players: ringPlayers,
                    selectedPlayerId: boardState.selectedPlayerId,
                    onPlayerTap: (id) {
                      ref
                          .read(gameBoardProvider(gameId).notifier)
                          .selectPlayer(id);
                      final player = players
                          .where((p) => p.id == id)
                          .firstOrNull;
                      if (player != null) {
                        PlayerDetailSheet.show(
                          context,
                          gameId: gameId,
                          player: player,
                        );
                      }
                    },
                    onPlayerLongPress: (id) =>
                        _quickToggleDead(context, ref, id),
                    centerChild: _DayBadge(day: boardState.currentDay),
                  ),
                ),
              ),
            ),
            // 当日面板
            Expanded(
              flex: 4,
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: '夜晚'),
                        Tab(text: '白天'),
                        Tab(text: '投票'),
                        Tab(text: '推理'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          NightPanel(gameId: gameId),
                          DayPanel(gameId: gameId),
                          VotingPanel(gameId: gameId),
                          const ComingSoonPanel(
                            title: '我的推理',
                            hint: '信任度与排除法追踪开发中（issue #13）',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickToggleDead(
    BuildContext context,
    WidgetRef ref,
    int playerId,
  ) async {
    final players = ref.read(gamePlayersProvider(gameId)).valueOrNull ?? [];
    final player = players.where((p) => p.id == playerId).firstOrNull;
    if (player == null) return;
    final verb = player.isAlive ? '标记死亡' : '复活';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认$verb'),
        content: Text('将 ${player.seatNumber} 号 ${player.name} $verb？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('确认$verb'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref
          .read(gameBoardProvider(gameId).notifier)
          .quickToggleDead(player);
    }
  }

  Future<void> _onMenu(BuildContext context, WidgetRef ref, String value) {
    final status = value == 'good_win' ? GameStatus.goodWin : GameStatus.evilWin;
    return ref.read(gameBoardProvider(gameId).notifier).endGame(status);
  }
}

/// 圆环中心的天数徽章。
class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '第 $day 天',
          style: AppTextStyles.title.copyWith(
            color: context.gameColors.goldBright,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          '◆',
          style: TextStyle(color: AppColors.lineGold, fontSize: 10),
        ),
      ],
    );
  }
}
