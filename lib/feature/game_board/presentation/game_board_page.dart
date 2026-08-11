import 'package:botc_copilot/core/router.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/data/poison_repository.dart';
import 'package:botc_copilot/feature/game_board/domain/game_end.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/end_game_dialog.dart';
import 'package:botc_copilot/feature/game_board/domain/seat_ring_player.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/day_panels.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/my_info_sheet.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/seat_ring.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/voting_panel.dart';
import 'package:botc_copilot/feature/player_detail/presentation/player_detail_sheet.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/feature/reasoning/presentation/reasoning_dashboard.dart';
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
    final gameColors = context.gameColors;
    final helpLevel = ref.watch(gameHelpLevelProvider(gameId));

    final currentDay =
        ref.watch(gameBoardProvider(gameId).select((s) => s.currentDay));
    final poisoned =
        ref.watch(gamePoisonStatusesProvider(gameId)).valueOrNull ?? [];
    final poisonedToday = {
      for (final p in poisoned)
        if (p.dayNumber == currentDay && p.isActive) p.playerId,
    };
    final contradictions = ref.watch(contradictionsProvider(gameId));
    final contradictionPlayerIds = {
      for (final c in contradictions) ...c.playerIds,
    };
    final ringPlayers = [
      for (final p in players)
        SeatRingPlayer(
          id: p.id,
          name: p.name,
          seatNumber: p.seatNumber,
          isAlive: p.isAlive,
          trustLevel: trustLevels[p.id] ?? TrustLevel.unknown,
          isMe: p.id == game.myPlayerId,
          isPoisoned: poisonedToday.contains(p.id),
          hasContradiction: contradictionPlayerIds.contains(p.id),
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
            itemBuilder: (context) => [
              // 帮助层级切换（issue #41）
              for (final level in HelpLevel.values)
                PopupMenuItem(
                  value: 'help_${level.name}',
                  child: Row(
                    children: [
                      Icon(
                        level == game.helpLevel
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text('帮助：${level.nameCn}'),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'good_win', child: Text('结束：善良获胜')),
              const PopupMenuItem(value: 'evil_win', child: Text('结束：邪恶获胜')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 对局已结束：横幅 + 圆环定格（禁交互）
            if (game.status != GameStatus.ongoing)
              Container(
                width: double.infinity,
                color: game.status == GameStatus.goodWin
                    ? gameColors.trustConfirmedGood
                        .withValues(alpha: 0.15)
                    : gameColors.blood.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '对局已结束 · ${game.status.nameCn}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline.copyWith(
                    color: game.status == GameStatus.goodWin
                        ? gameColors.trustConfirmedGood
                        : gameColors.blood,
                  ),
                ),
              ),
            // 新手引导卡片（仅 beginner/normal 模式显示）
            if (game.status == GameStatus.ongoing &&
                helpLevel != HelpLevel.expert)
              _ContextHint(day: currentDay),
            // 钟面座位圆环（签名组件，直径 ≈ 屏宽 85%）
            Expanded(
              flex: 5,
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.85,
                  child: SeatRing(
                    players: ringPlayers,
                    selectedPlayerId: boardState.selectedPlayerId,
                    onPlayerTap: game.status != GameStatus.ongoing
                        ? null
                        : (id) {
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
                    onPlayerLongPress: game.status != GameStatus.ongoing
                        ? null
                        : (id) => _quickToggleDead(context, ref, id),
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
                          ReasoningDashboard(gameId: gameId),
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
      final wasAlive = player.isAlive;
      final suggestion = await ref
          .read(gameBoardProvider(gameId).notifier)
          .quickToggleDead(player);
      // 标死后提供 SnackBar 撤销（issue #65）
      if (wasAlive && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${player.seatNumber}号 ${player.name} 已标记死亡'),
            action: SnackBarAction(
              label: '撤销',
              onPressed: () {
                ref.read(gameBoardProvider(gameId).notifier).quickToggleDead(
                      // player 已死，再 toggle = 复活
                      player,
                    );
              },
            ),
            duration: const Duration(seconds: 10),
          ),
        );
      }
      if (suggestion is EvilWinCandidate && context.mounted) {
        final evil = await EndGameDialog.showEvilCandidate(
          context,
          aliveCount: suggestion.aliveCount,
        );
        if (evil ?? false) {
          await ref
              .read(gameBoardProvider(gameId).notifier)
              .endGame(goodWin: false);
        }
      }
    }
  }

  Future<void> _onMenu(BuildContext context, WidgetRef ref, String value) {
    if (value.startsWith('help_')) {
      final level = HelpLevel.values.byName(value.substring(5));
      return ref
          .read(appDatabaseProvider)
          .gamesDao
          .updateHelpLevel(game.id, level);
    }
    return ref
        .read(gameBoardProvider(gameId).notifier)
        .endGame(goodWin: value == 'good_win');
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

/// 新手引导卡片：根据当前天数提示下一步操作（issue #64）。
class _ContextHint extends StatelessWidget {
  const _ContextHint({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final hint = day == 1
        ? '首夜信息已发放。点击圆环上的玩家，记录他们声明的角色和信息。'
        : '夜晚结束。在「夜晚」面板记录死亡，然后点击玩家记录角色声明和信息。'
            '白天讨论后到「投票」面板记录提名。';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: gameColors.goldBright.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 14, color: gameColors.goldBright),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hint,
              style: AppTextStyles.caption
                  .copyWith(color: gameColors.goldBright),
            ),
          ),
        ],
      ),
    );
  }
}
