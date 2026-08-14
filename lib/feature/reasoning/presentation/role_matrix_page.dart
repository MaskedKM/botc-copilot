import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/router.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/player_detail/presentation/player_detail_sheet.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/role_matrix.dart';
import 'package:botc_copilot/shared/game_private.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 角色声明交叉矩阵（issue #40）。
///
/// 行 = 玩家，列 = 角色。回答三个问题：
/// - 哪些角色还没人声明？（可能是 Bluff 或隐藏好人）
/// - 哪些角色被多人声明？（冲突点）
/// - 恶魔 Bluff（若已录入）标为「已知不在场」
class RoleMatrixPage extends ConsumerStatefulWidget {
  /// 创建矩阵页。
  const RoleMatrixPage({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  /// 打开矩阵页（#138：入路由表）。
  static void show(BuildContext context, {required int gameId}) {
    context.push(AppRoutes.roleMatrix(gameId));
  }

  @override
  ConsumerState<RoleMatrixPage> createState() => _RoleMatrixPageState();
}

class _RoleMatrixPageState extends ConsumerState<RoleMatrixPage> {
  /// 是否显示全部 22 个角色（默认只显示有声明/Bluff/已确认的列）。
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final players =
        ref.watch(gamePlayersProvider(widget.gameId)).valueOrNull ?? [];
    final claims =
        ref.watch(gameClaimsProvider(widget.gameId)).valueOrNull ?? [];
    final game = ref.watch(gameByIdProvider(widget.gameId)).valueOrNull;
    final gameColors = context.gameColors;

    // demonBluffsOf 已做类型守卫兜底（#164 review P1），避免内联解析损坏 JSON 致红屏。
    final bluffs = game != null ? demonBluffsOf(game).toList() : <Character>[];

    final (allColumns, rows) = RoleMatrixBuilder.build(
      script: game?.script ?? Script.troubleBrewing,
      players: players,
      claims: claims,
      demonBluffs: bluffs,
      myPlayerId: game?.myPlayerId,
      myRole: game?.myRole,
    );
    // 我的爪牙（仅我是恶魔时，私密标记，#108）
    final myMinionIds =
        game != null && game.myRole == Character.imp ? minionIdsOf(game) : const <int>{};
    // 默认精简：只保留有声明 / Bluff / 有确认的列
    final columns = _showAll
        ? allColumns
        : allColumns
            .where(
              (c) =>
                  !c.isUnclaimed ||
                  c.isBluff ||
                  players.any(
                    (p) => rows[p.id]?[c.character] != null,
                  ),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('声明矩阵'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('全部 ${allColumns.length} 角色'),
              selected: _showAll,
              visualDensity: VisualDensity.compact,
              onSelected: (v) => setState(() => _showAll = v),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 图例
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _legend(gameColors.goldBright, '当前声明'),
                  _legend(gameColors.inkViolet, '曾声明（改口）'),
                  _legend(gameColors.trustConfirmedGood, '已确认'),
                  _legend(gameColors.goldBright, '我的角色（私密）', Icons.stars),
                  _legend(gameColors.blood, '冲突（多人声明）'),
                  _legend(gameColors.trustSuspect, '恶魔 Bluff'),
                  if (myMinionIds.isNotEmpty)
                    _legend(gameColors.blood, '我的爪牙（私密）', Icons.security),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: _MatrixTable(
                    gameId: widget.gameId,
                    players: players,
                    columns: columns,
                    rows: rows,
                    myMinionIds: myMinionIds,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label, [IconData? icon]) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon != null
            ? Icon(icon, size: 12, color: color)
            : Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _MatrixTable extends StatelessWidget {
  const _MatrixTable({
    required this.gameId,
    required this.players,
    required this.columns,
    required this.rows,
    required this.myMinionIds,
  });

  /// 对局 id（行头 drill-down → 玩家详情，#138）。
  final int gameId;

  final List<Player> players;
  final List<MatrixColumn> columns;
  final Map<int, MatrixRow> rows;

  /// 恶魔私密爪牙名单（仅我是恶魔时非空，#108）。
  final Set<int> myMinionIds;

  static const double _nameColWidth = 72;
  static const double _cellWidth = 44;
  static const double _cellHeight = 36;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;

    return Table(
      defaultColumnWidth: const FixedColumnWidth(_cellWidth),
      columnWidths: const {0: FixedColumnWidth(_nameColWidth)},
      border: TableBorder.all(
        color: gameColors.inkViolet.withValues(alpha: 0.15),
      ),
      children: [
        // 表头：角色名（竖排）
        TableRow(
          children: [
            const SizedBox(),
            for (final col in columns) _headerCell(col, gameColors),
          ],
        ),
        // 数据行
        for (final p in players)
          TableRow(
            children: [
              SizedBox(
                height: _cellHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // drill-down：点玩家行头直达玩家详情（#138）。
                  onTap: () =>
                      PlayerDetailSheet.show(context, gameId: gameId, player: p),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (myMinionIds.contains(p.id))
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              Icons.security,
                              size: 10,
                              color: gameColors.blood,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            '${p.seatNumber}${p.name}',
                            style: AppTextStyles.caption.copyWith(
                              color: myMinionIds.contains(p.id)
                                  ? gameColors.bloodBright
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              for (final col in columns)
                _cell(col, rows[p.id]?[col.character], gameColors),
            ],
          ),
      ],
    );
  }

  Widget _headerCell(MatrixColumn col, GameColors gameColors) {
    final color = col.isBluff
        ? gameColors.trustSuspect
        : col.hasConflict
            ? gameColors.bloodBright
            : col.isUnclaimed
                ? gameColors.inkViolet.withValues(alpha: 0.4)
                : gameColors.goldBright;

    return Container(
      height: 64,
      color: col.isBluff
          ? gameColors.trustSuspect.withValues(alpha: 0.15)
          : null,
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 4),
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          col.character.nameCn,
          style: AppTextStyles.caption.copyWith(color: color, fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _cell(
    MatrixColumn col,
    MatrixCellState? state,
    GameColors gameColors,
  ) {
    final (bg, icon) = switch (state) {
      MatrixCellState.claimed => (
          col.hasConflict
              ? gameColors.blood.withValues(alpha: 0.4)
              : gameColors.goldBright.withValues(alpha: 0.3),
          Icons.circle,
        ),
      MatrixCellState.changed => (
          gameColors.inkViolet.withValues(alpha: 0.2),
          Icons.change_circle_outlined,
        ),
      MatrixCellState.confirmed => (
          gameColors.trustConfirmedGood.withValues(alpha: 0.4),
          Icons.verified,
        ),
      MatrixCellState.myRole => (
          gameColors.goldBright.withValues(alpha: 0.5),
          Icons.stars,
        ),
      _ => (null, null),
    };

    return Container(
      height: _cellHeight,
      color: bg,
      child: icon != null
          ? Icon(
              icon,
              size: 12,
              color: switch (state) {
                MatrixCellState.claimed => col.hasConflict
                    ? gameColors.blood
                    : gameColors.goldBright,
                MatrixCellState.changed => gameColors.inkViolet,
                MatrixCellState.confirmed => gameColors.trustConfirmedGood,
                MatrixCellState.myRole => gameColors.goldBright,
                _ => null,
              },
            )
          : null,
    );
  }
}
