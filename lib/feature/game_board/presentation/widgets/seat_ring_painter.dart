import 'package:botc_copilot/core/theme/app_colors.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/domain/seat_ring_layout.dart';
import 'package:botc_copilot/feature/game_board/domain/seat_ring_player.dart';
import 'package:flutter/material.dart';

/// 座位圆环 CustomPainter（UI-STYLE §6.1 签名组件）。
///
/// 绘制：金色刻度环 → 邻座连线 → 玩家节点（信任度色环 / 死亡标记 /
/// 自己标记 / 选中与邻座高亮）。
///
/// 动画通过 [progress]（0→1）驱动：调用方在玩家状态变化时
/// 传入 [previousPlayers] 并从 0 重启动画，painter 对每个玩家
/// 在旧状态 → 新状态间插值（信任度颜色过渡、死亡淡出）。
class SeatRingPainter extends CustomPainter {
  /// 创建 painter。
  SeatRingPainter({
    required this.players,
    required this.centers,
    required this.gameColors,
    this.previousPlayers = const {},
    this.progress = 1.0,
    this.selectedPlayerId,
  });

  /// 当前玩家列表（按座位顺序）。
  final List<SeatRingPlayer> players;

  /// 各座位圆心（由 SeatRingLayout.computeCenters 计算）。
  final List<Offset> centers;

  /// 语义色板。
  final GameColors gameColors;

  /// 上一帧玩家状态（id → player），用于过渡插值。
  final Map<int, SeatRingPlayer> previousPlayers;

  /// 过渡进度 0→1（1 = 到达当前状态）。
  final double progress;

  /// 当前选中玩家 id（高亮其存活邻座）。
  final int? selectedPlayerId;

  static const double _r = SeatRingLayout.nodeRadius;

  @override
  void paint(Canvas canvas, Size size) {
    _paintTickRing(canvas, size);
    _paintNeighborLinks(canvas);
    for (var i = 0; i < players.length; i++) {
      _paintNode(canvas, i);
    }
  }

  /// 金色刻度环（细线 + 每座位一个小刻度）。
  void _paintTickRing(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ringRadius =
        (centers.first - center).distance + _r + SeatRingLayout.outerPadding;

    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color = AppColors.lineGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    final tickPaint = Paint()
      ..color = gameColors.goldBright
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final c in centers) {
      final dir = (c - center).direction;
      final outer = center + Offset.fromDirection(dir, ringRadius);
      final inner = center + Offset.fromDirection(dir, ringRadius - 6);
      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  /// 存活相邻玩家之间的半透明连线（含座位收缩：跳过死亡者）。
  void _paintNeighborLinks(Canvas canvas) {
    final alive = players.map((p) => p.isAlive).toList();
    if (!alive.any((a) => a)) return;
    final paint = Paint()
      ..color = AppColors.lineGold
      ..strokeWidth = 1;

    // 找第一个存活者作为起点，沿顺时针连接所有存活者形成收缩环。
    final first = alive.indexOf(true);
    var current = first;
    while (true) {
      final next = SeatRingLayout.nextAliveClockwise(alive, current);
      if (next == first) {
        // 仅 1 人存活时不画（起点即终点，零长度线无意义）。
        if (current != first) {
          canvas.drawLine(centers[current], centers[first], paint);
        }
        break;
      }
      canvas.drawLine(centers[current], centers[next], paint);
      current = next;
    }
  }

  void _paintNode(Canvas canvas, int index) {
    final player = players[index];
    final prev = previousPlayers[player.id] ?? player;
    final t = progress;

    // 过渡插值：存活度（1=活, 0=死）与信任度颜色。
    final aliveT = _lerpDouble(prev.isAlive ? 1 : 0, player.isAlive ? 1 : 0, t);
    final trustColor = Color.lerp(
      gameColors.ofTrustLevel(prev.trustLevel),
      gameColors.ofTrustLevel(player.trustLevel),
      t,
    )!;

    final center = centers[index];
    final nodeOpacity = 1 - 0.65 * (1 - aliveT); // 死亡压暗至 35%

    // 信任度色环（2.5px）。
    canvas.drawCircle(
      center,
      _r,
      Paint()
        ..color = trustColor.withValues(alpha: nodeOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // 节点底。
    canvas.drawCircle(
      center,
      _r - 2,
      Paint()..color = AppColors.bgSurface2.withValues(alpha: nodeOpacity),
    );

    // 自己标记：goldBright 实线 + 微光晕（唯一允许发光处）。
    if (player.isMe) {
      canvas.drawCircle(
        center,
        _r + 3,
        Paint()
          ..color = gameColors.goldBright.withValues(alpha: 0.3 * nodeOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        center,
        _r + 3,
        Paint()
          ..color = gameColors.goldBright.withValues(alpha: nodeOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // 醉/毒标记：紫色微光（issue #35）。
    if (player.isPoisoned) {
      canvas.drawCircle(
        center,
        _r + 6,
        Paint()
          ..color = AppColors.inkViolet.withValues(alpha: 0.45 * nodeOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        center,
        _r + 6,
        Paint()
          ..color = AppColors.inkViolet.withValues(alpha: 0.8 * nodeOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // 矛盾微标记：琥珀色小三角在节点外侧（issue #38，不改信任度颜色）。
    if (player.hasContradiction) {
      final markerPaint = Paint()
        ..color = gameColors.blood.withValues(alpha: nodeOpacity);
      final markerCenter = Offset(
        center.dx,
        center.dy - _r - 12,
      );
      final path = Path()
        ..moveTo(markerCenter.dx, markerCenter.dy - 4)
        ..lineTo(markerCenter.dx - 4, markerCenter.dy + 3)
        ..lineTo(markerCenter.dx + 4, markerCenter.dy + 3)
        ..close();
      canvas.drawPath(path, markerPaint);
    }

    // 选中玩家的存活邻座高亮。
    if (selectedPlayerId != null && _isLivingNeighborOfSelected(index)) {
      canvas.drawCircle(
        center,
        _r + 1.5,
        Paint()
          ..color = gameColors.goldBright.withValues(alpha: nodeOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // 名字首字符。
    final textPainter = TextPainter(
      text: TextSpan(
        text: player.initial,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary.withValues(alpha: nodeOpacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );

    // 死亡标记：斜向细划线 + 骷髅角标（随 aliveT 渐显）。
    if (aliveT < 1) {
      final deathT = 1 - aliveT;
      final slashPaint = Paint()
        ..color = AppColors.blood.withValues(alpha: deathT)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      final d = _r * 0.7 * deathT;
      canvas.drawLine(
        center + Offset(-d, -d),
        center + Offset(d, d),
        slashPaint,
      );
      if (deathT > 0.6) {
        _paintSkullBadge(canvas, center, deathT);
      }
    }
  }

  /// 骷髅角标（节点右上小圆点 + ☠ 字符）。
  void _paintSkullBadge(Canvas canvas, Offset center, double deathT) {
    final badgeCenter = center + Offset(_r * 0.75, -_r * 0.75);
    canvas.drawCircle(
      badgeCenter,
      9,
      Paint()..color = AppColors.blood.withValues(alpha: deathT),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '☠',
        style: TextStyle(
          fontSize: 10,
          color: AppColors.textPrimary.withValues(alpha: deathT),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, badgeCenter - Offset(tp.width / 2, tp.height / 2));
  }

  bool _isLivingNeighborOfSelected(int index) {
    final selectedIndex =
        players.indexWhere((p) => p.id == selectedPlayerId);
    if (selectedIndex < 0) return false;
    final alive = players.map((p) => p.isAlive).toList();
    if (!alive[index] || index == selectedIndex) return false;
    return SeatRingLayout.nextAliveClockwise(alive, selectedIndex) == index ||
        SeatRingLayout.nextAliveCounterClockwise(alive, selectedIndex) ==
            index;
  }

  double _lerpDouble(num a, num b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(SeatRingPainter oldDelegate) =>
      oldDelegate.players != players ||
      oldDelegate.progress != progress ||
      oldDelegate.selectedPlayerId != selectedPlayerId;
}
