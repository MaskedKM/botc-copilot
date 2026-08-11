import 'package:botc_copilot/core/theme/app_motion.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/domain/seat_ring_layout.dart';
import 'package:botc_copilot/feature/game_board/domain/seat_ring_player.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/seat_ring_painter.dart';
import 'package:flutter/material.dart';

/// 座位圆环组件（签名组件，UI-STYLE §6.1）。
///
/// - 玩家按座位等分圆周（1 号位 12 点方向，顺时针）
/// - 点按 → [onPlayerTap]；长按 → [onPlayerLongPress]
/// - 玩家状态变化（信任度/死亡）自动播放过渡动画
/// - 选中玩家时高亮其存活邻座（座位收缩规则）
class SeatRing extends StatefulWidget {
  /// 创建座位圆环。
  const SeatRing({
    required this.players,
    super.key,
    this.onPlayerTap,
    this.onPlayerLongPress,
    this.selectedPlayerId,
    this.centerChild,
  });

  /// 玩家列表（按座位顺序）。
  final List<SeatRingPlayer> players;

  /// 点按玩家回调（参数为玩家 id）。
  final ValueChanged<int>? onPlayerTap;

  /// 长按玩家回调（参数为玩家 id）。
  final ValueChanged<int>? onPlayerLongPress;

  /// 当前选中玩家 id。
  final int? selectedPlayerId;

  /// 圆环中心内容（如"第 N 天 · 昼/夜"）。
  final Widget? centerChild;

  @override
  State<SeatRing> createState() => SeatRingState();
}

/// SeatRing 的 State（暴露给测试）。
class SeatRingState extends State<SeatRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Map<int, SeatRingPlayer> _previousPlayers = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.normal,
    )..value = 1.0;
    _previousPlayers = {for (final p in widget.players) p.id: p};
  }

  @override
  void didUpdateWidget(SeatRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = _hasPlayerChanges(oldWidget.players, widget.players);
    if (changed) {
      _previousPlayers = {for (final p in oldWidget.players) p.id: p};
      // 死亡是签名时刻（400ms），其余状态变化用常规 250ms。
      _controller.duration = _hasDeathChange(oldWidget.players, widget.players)
          ? AppMotion.death
          : AppMotion.normal;
      _controller.forward(from: 0);
    }
  }

  bool _hasDeathChange(
    List<SeatRingPlayer> oldPlayers,
    List<SeatRingPlayer> newPlayers,
  ) {
    for (final p in newPlayers) {
      final old = oldPlayers.where((o) => o.id == p.id).firstOrNull;
      if (old != null && old.isAlive && !p.isAlive) return true;
    }
    return false;
  }

  bool _hasPlayerChanges(
    List<SeatRingPlayer> oldPlayers,
    List<SeatRingPlayer> newPlayers,
  ) {
    if (oldPlayers.length != newPlayers.length) return true;
    for (final p in newPlayers) {
      final old = oldPlayers.where((o) => o.id == p.id).firstOrNull;
      if (old == null || old != p) return true;
    }
    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 当前圆环中心坐标（供测试/调试命中计算）。
  @visibleForTesting
  List<Offset> centersForSize(Size size) => SeatRingLayout.computeCenters(
        size: size,
        count: widget.players.length,
      );

  void _handleTap(Offset localPosition, List<Offset> centers) {
    final index = SeatRingLayout.hitTest(
      position: localPosition,
      centers: centers,
    );
    if (index != null) widget.onPlayerTap?.call(widget.players[index].id);
  }

  void _handleLongPress(Offset localPosition, List<Offset> centers) {
    final index = SeatRingLayout.hitTest(
      position: localPosition,
      centers: centers,
    );
    if (index != null) {
      widget.onPlayerLongPress?.call(widget.players[index].id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          // centers 每次布局只算一次，手势回调与 painter 共用。
          final centers = centersForSize(size);
          return GestureDetector(
            onTapDown: (d) => _handleTap(d.localPosition, centers),
            onLongPressStart: (d) =>
                _handleLongPress(d.localPosition, centers),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: SeatRingPainter(
                    players: widget.players,
                    previousPlayers: _previousPlayers,
                    progress: _controller.value,
                    centers: centers,
                    gameColors: gameColors,
                    selectedPlayerId: widget.selectedPlayerId,
                  ),
                  child: widget.centerChild != null
                      ? Center(child: widget.centerChild)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
