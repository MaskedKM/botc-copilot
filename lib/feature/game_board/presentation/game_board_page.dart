import 'package:botc_copilot/core/router.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/app_theme.dart';
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
import 'package:botc_copilot/feature/player_detail/data/behavior_note_repository.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/feature/player_detail/presentation/player_detail_sheet.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/feature/reasoning/presentation/reasoning_dashboard.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:botc_copilot/shared/widgets/loading_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(
        body: ErrorRetryView(
          onRetry: () => ref.invalidate(gameByIdProvider(gameId)),
        ),
      ),
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

    // 玩家流未就绪 / currentDay 未恢复（#154 ISSUE-3）时不渲染圆环
    // （0 人会违反布局的 5-15 断言；未恢复天数时禁用交互避免对错误天数操作）。
    final players = playersAsync.valueOrNull;
    if (players == null || players.isEmpty || !boardState.initialized) {
      return const Scaffold(body: LoadingView());
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
          suspectedDrunk: p.suspectedDrunk,
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
            onPressed: () => _openMyInfo(context, ref, game),
          ),
          IconButton(
            tooltip: '事件时间线',
            icon: const Icon(Icons.timeline),
            onPressed: () => context.push(AppRoutes.timeline(gameId)),
          ),
          IconButton(
            tooltip: '推进到下一天',
            icon: const Icon(Icons.skip_next),
            // #81：对局结束后禁用；#87：推进后提供撤销
            onPressed: game.status != GameStatus.ongoing
                ? null
                : () async {
                    final notifier =
                        ref.read(gameBoardProvider(gameId).notifier);
                    final suggestion = await notifier.advanceDay();
                    if (!context.mounted) return;
                    if (suggestion != null) {
                      await handleEndSuggestion(
                        context,
                        ref,
                        gameId,
                        suggestion,
                      );
                      if (!context.mounted) return;
                      // 对局可能在 handleEndSuggestion 中结束（如市长胜利确认）
                      final game = await ref
                          .read(appDatabaseProvider)
                          .gamesDao
                          .getById(gameId);
                      if (game?.status != GameStatus.ongoing) return;
                    }
                    final advancedDay = ref.read(
                      gameBoardProvider(gameId).select((s) => s.currentDay),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已推进到第 $advancedDay 天'),
                        action: SnackBarAction(
                          label: '撤销',
                          onPressed: () async {
                            final ok = await notifier.revertAdvanceDay();
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('当天已有记录，无法回退'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
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
                        : gameColors.bloodBright,
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
                    onPlayerTap: (id) {
                      // 结束局仍可点开玩家详情（只读复盘，#134）；
                      // 长按/推进保持禁用。
                      ref
                          .read(gameBoardProvider(gameId).notifier)
                          .selectPlayer(id);
                      final player = players
                          .where((p) => p.id == id)
                          .firstOrNull;
                      if (player != null) {
                        _openDetailChain(context, player);
                      }
                    },
                    onPlayerLongPress: game.status != GameStatus.ongoing
                        ? null
                        : (id) => _showQuickActions(context, ref, id),
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
                    // #160 #8：推理 Tab 加矛盾计数 badge，提升核心卖点可发现性。
                    TabBar(
                      tabs: [
                        const Tab(text: '夜晚'),
                        const Tab(text: '白天'),
                        const Tab(text: '投票'),
                        Tab(
                          child: Badge(
                            isLabelVisible: contradictions.isNotEmpty,
                            label: Text('${contradictions.length}'),
                            child: const Text('推理'),
                          ),
                        ),
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

  /// 打开「我的信息」（issue #131 统一入口）。
  ///
  /// 已设座位 → 直接进 [PlayerDetailSheet] 的 isMe 分支（含换座 #86、私密
  /// 爪牙名单 #108）；未设 → 首夜 onboarding 选座弹层，选完顺势打开详情。
  Future<void> _openMyInfo(
    BuildContext context,
    WidgetRef ref,
    Game game,
  ) async {
    final players = ref.read(gamePlayersProvider(gameId)).valueOrNull ?? [];
    final myPlayer =
        players.where((p) => p.id == game.myPlayerId).firstOrNull;
    if (game.myPlayerId != null && myPlayer != null) {
      await PlayerDetailSheet.show(
        context,
        gameId: gameId,
        player: myPlayer,
      );
      return;
    }
    final selectedId = await MyInfoSheet.show(context, game: game);
    if (selectedId != null && context.mounted) {
      final selected =
          players.where((p) => p.id == selectedId).firstOrNull;
      if (selected != null) {
        await PlayerDetailSheet.show(
          context,
          gameId: gameId,
          player: selected,
        );
      }
    }
  }

  /// 长按座位 → 快捷操作菜单（UI-STYLE §6.1，issue #134）。
  ///
  /// 信任度直选 / 快速备注 / 标记死亡（含 #136 传承检测），免去开整个玩家
  /// 详情滚 6 段。
  /// 圆环点按 → 玩家详情链（#134 首夜队列）。
  ///
  /// 循环 `await PlayerDetailSheet.show`：sheet 返回下一个待开玩家（点
  /// 「下一位」时）则继续打开，否则退出。await 保证上一弹层动画结束再开
  /// 下一弹层，无堆叠/闪烁。
  Future<void> _openDetailChain(
    BuildContext context,
    Player start,
  ) async {
    Player? current = start;
    while (current != null) {
      current = await PlayerDetailSheet.show(
        context,
        gameId: gameId,
        player: current,
        enableChain: true,
      );
    }
  }

  Future<void> _showQuickActions(
    BuildContext context,
    WidgetRef ref,
    int playerId,
  ) async {
    final players = ref.read(gamePlayersProvider(gameId)).valueOrNull ?? [];
    final player = players.where((p) => p.id == playerId).firstOrNull;
    if (player == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _QuickActionsSheet(
          game: game,
          player: player,
          onDeath: () => _quickToggleDead(context, ref, playerId),
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

    // 复活：简单确认（无需天数）。
    if (!player.isAlive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认复活'),
          content: Text('将 ${player.seatNumber} 号 ${player.name} 复活？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认复活'),
            ),
          ],
        ),
      );
      if (confirmed ?? false) {
        await ref
            .read(gameBoardProvider(gameId).notifier)
            .quickToggleDead(player);
      }
      return;
    }

    // 标死：选天数（补记历史死亡需准确 deathDay，否则污染 Empath 邻座
    // 判定 / 矛盾检测；范围 1..currentDay，默认当前天）。
    final currentDay = ref.read(
      gameBoardProvider(gameId).select((s) => s.currentDay),
    );
    var selectedDay = currentDay;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('确认标记死亡'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('将 ${player.seatNumber} 号 ${player.name} 标记为死亡'),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedDay,
                decoration: const InputDecoration(labelText: '死亡天数'),
                items: [
                  for (var d = 1; d <= currentDay; d++)
                    DropdownMenuItem(value: d, child: Text('第 $d 天')),
                ],
                onChanged: (v) => setState(
                  () => selectedDay = v ?? currentDay,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认标记死亡'),
            ),
          ],
        ),
      ),
    );
    if (!(confirmed ?? false)) return;
    final suggestion = await ref
        .read(gameBoardProvider(gameId).notifier)
        .quickToggleDead(player, deathDay: selectedDay);
    // 标死后提供 SnackBar 撤销（issue #65）。仅当无终局候选（suggestion == null）
    // 时提供——quickToggleDead 的非空返回必为终局候选，而撤销（revivePlayer）
    // 无法回退其副作用：DemonSuccessionCandidate 确认传承则 recordSuccession 已
    // 写新恶魔（撤销留双恶魔），拒绝则 endGame(善良胜)；EvilWinCandidate 确认则
    // endGame(邪恶胜)——在已结束对局里复活玩家，状态不可自愈（#156 BUG-A）。
    // 故非空时撤销语义本身损坏，不提供。用户直接关闭对话框（未传承/终局）的罕见
    // 情况下撤销本可用但被一并抑制，可长按该座复活。终局由随后的对话框接管反馈。
    if (context.mounted && suggestion == null) {
      // 只捕获 id：player 对象是标死前的快照（isAlive 仍为 true），
      // 若再传给 quickToggleDead 会误判为「再标死一次」而非复活。
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.seatNumber}号 ${player.name} 已标记死亡'),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () {
              ref
                  .read(gameBoardProvider(gameId).notifier)
                  .revivePlayer(playerId);
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
    } else if (suggestion is DemonSuccessionCandidate && context.mounted) {
      // 长按标死疑似恶魔 → 传承确认（#136 公理5，与夜死/处决/Slayer 统一）
      await handleEndSuggestion(context, ref, gameId, suggestion);
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
    // 结束对局是唯一缺确认的破坏操作（#138）→ 二次确认。
    final goodWin = value == 'good_win';
    return _confirmEndGame(context, ref, goodWin: goodWin);
  }

  /// 结束对局二次确认（不可撤销，#138）。
  Future<void> _confirmEndGame(
    BuildContext context,
    WidgetRef ref, {
    required bool goodWin,
  }) async {
    final side = goodWin ? '善良' : '邪恶';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('结束对局'),
        content: Text('确认结束对局为$side方获胜？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: AppTheme.dangerButtonStyle,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认结束'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(gameBoardProvider(gameId).notifier).endGame(goodWin: goodWin);
    }
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
          style: TextStyle(color: AppColors.lineGold, fontSize: 11),
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
            '长按座位可快速标记死亡 / 信任度 / 备注。'
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

/// 长按快捷操作弹层（issue #134，UI-STYLE §6.1）。
///
/// 信任度直选 / 快速备注 / 标记死亡——首夜高频操作不必打开完整玩家详情。
class _QuickActionsSheet extends ConsumerStatefulWidget {
  const _QuickActionsSheet({
    required this.game,
    required this.player,
    required this.onDeath,
  });

  /// 当前对局。
  final Game game;

  /// 目标玩家。
  final Player player;

  /// 「标记死亡/复活」回调（关闭快捷菜单后由父级走 [_GameBoardBody._quickToggleDead]）。
  final VoidCallback onDeath;

  @override
  ConsumerState<_QuickActionsSheet> createState() =>
      _QuickActionsSheetState();
}

class _QuickActionsSheetState extends ConsumerState<_QuickActionsSheet> {
  final _noteController = TextEditingController();
  bool _noteOpen = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int get _gameId => widget.game.id;

  int get _day =>
      ref.read(gameBoardProvider(_gameId).select((s) => s.currentDay));

  Future<void> _setTrust(TrustLevel level) async {
    try {
      await ref.read(playerDetailRepositoryProvider).setTrustLevel(
            gameId: _gameId,
            playerId: widget.player.id,
            day: _day,
            level: level,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.player.seatNumber}号 → ${level.nameCn}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } on Object {
      // #164 B9：fire-and-forget 写失败兜底提示。
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
      }
    }
  }

  Future<void> _addNote() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;
    try {
      await ref.read(behaviorNoteRepositoryProvider).addNote(
            gameId: _gameId,
            playerId: widget.player.id,
            dayNumber: _day,
            note: note,
          );
      // #164：await 后 controller.clear 须在 mounted 守卫内，否则下拉关闭 sheet
      // 致 dispose → .clear() 命中已 dispose 抛 FlutterError。
      if (mounted) {
        _noteController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('备注已添加'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } on Object {
      // #164 B9：备注写失败兜底提示。
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('添加失败，请重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final trustMap =
        ref.watch(latestTrustLevelsProvider(_gameId)).valueOrNull ??
            const <int, TrustLevel>{};
    final current = trustMap[widget.player.id] ?? TrustLevel.unknown;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.player.seatNumber}号 ${widget.player.name}',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 12),
            const Text('信任度', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final level in TrustLevel.values)
                  ChoiceChip(
                    label: Text(level.nameCn),
                    selected: current == level,
                    selectedColor: gameColors.ofTrustLevel(level),
                    onSelected: (_) => _setTrust(level),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text('快速备注', style: AppTextStyles.headline),
                ),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _noteOpen = !_noteOpen),
                  icon: Icon(
                    _noteOpen ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  label: const Text('备注'),
                ),
              ],
            ),
            if (_noteOpen) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: '如：投票犹豫 / 主动带票冲 X号',
                        isDense: true,
                      ),
                      inputFormatters: [LengthLimitingTextInputFormatter(500)],
                      onSubmitted: (_) => _addNote(),
                    ),
                  ),
                  IconButton(
                    tooltip: '添加',
                    icon: const Icon(Icons.add),
                    onPressed: _addNote,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Divider(),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                widget.player.isAlive
                    ? Icons.dangerous_outlined
                    : Icons.favorite,
                color: gameColors.blood,
              ),
              title: Text(
                widget.player.isAlive ? '标记死亡…' : '复活…',
                style: TextStyle(color: gameColors.bloodBright),
              ),
              onTap: () {
                Navigator.of(context).pop();
                widget.onDeath();
              },
            ),
          ],
        ),
      ),
    );
  }
}
