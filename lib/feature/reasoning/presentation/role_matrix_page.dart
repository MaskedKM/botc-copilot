import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/role_matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// 打开矩阵页。
  static void show(BuildContext context, {required int gameId}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoleMatrixPage(gameId: gameId),
      ),
    );
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

    final bluffs = <Character>[];
    if (game?.demonBluffsJson != null) {
      for (final name
          in (jsonDecode(game!.demonBluffsJson!) as List).cast<String>()) {
        final c = Character.values.where((c) => c.name == name).firstOrNull;
        if (c != null) bluffs.add(c);
      }
    }

    final (allColumns, rows) = RoleMatrixBuilder.build(
      players: players,
      claims: claims,
      demonBluffs: bluffs,
    );
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
                  _legend(gameColors.blood, '冲突（多人声明）'),
                  _legend(gameColors.trustSuspect, '恶魔 Bluff'),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: _MatrixTable(
                    players: players,
                    columns: columns,
                    rows: rows,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _MatrixTable extends StatelessWidget {
  const _MatrixTable({
    required this.players,
    required this.columns,
    required this.rows,
  });

  final List<Player> players;
  final List<MatrixColumn> columns;
  final Map<int, MatrixRow> rows;

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
                child: Center(
                  child: Text(
                    '${p.seatNumber}${p.name}',
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
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
            ? gameColors.blood
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
          style: AppTextStyles.caption.copyWith(color: color, fontSize: 10),
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
                _ => null,
              },
            )
          : null,
    );
  }
}
