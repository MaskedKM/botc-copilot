import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/script_definition.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/shared/models/enums.dart';

/// 矩阵单元格状态。
enum MatrixCellState {
  /// 未声明。
  empty,

  /// 当前声明该角色。
  claimed,

  /// 曾声明但改口（历史声明）。
  changed,

  /// 已确认（死亡揭示 / 掘墓人）。
  confirmed,

  /// 我的真实角色（私密，助手视角；issue #107）。
  myRole,
}

/// 角色列的聚合信息。
class MatrixColumn {
  /// 创建列。
  const MatrixColumn({
    required this.character,
    required this.claimantIds,
    required this.isBluff,
  });

  /// 角色。
  final Character character;

  /// 声明该角色的玩家 id（最新声明）。
  final List<int> claimantIds;

  /// 是否为恶魔 Bluff（仅当我是恶魔时录入）。
  final bool isBluff;

  /// 多人声明同一角色 = 冲突。
  bool get hasConflict => claimantIds.length >= 2;

  /// 无人声明（可能是 Bluff 或隐藏好人）。
  bool get isUnclaimed => claimantIds.isEmpty;
}

/// 玩家行的单元格映射：character → 状态。
typedef MatrixRow = Map<Character, MatrixCellState>;

/// 声明矩阵聚合（纯函数，issue #40）。
abstract final class RoleMatrixBuilder {
  /// 构建列聚合 + 每玩家行状态。
  static (List<MatrixColumn>, Map<int, MatrixRow>) build({
    required Script script,
    required List<Player> players,
    required List<RoleClaim> claims,
    required List<Character> demonBluffs,
    int? myPlayerId,
    Character? myRole,
  }) {
    // 每玩家的声明历史（按 id 升序 = 时间序）
    final claimsByPlayer = <int, List<RoleClaim>>{};
    for (final c in claims) {
      claimsByPlayer.putIfAbsent(c.playerId, () => []).add(c);
    }

    // 行：每玩家每角色状态
    final rows = <int, MatrixRow>{};
    final latestByPlayer = <int, RoleClaim>{};
    for (final p in players) {
      final history = claimsByPlayer[p.id] ?? [];
      final row = <Character, MatrixCellState>{};
      for (final c in history) {
        row[c.character] = c.claimType == ClaimType.revealedOnDeath
            ? MatrixCellState.confirmed
            : MatrixCellState.claimed;
      }
      // 同一角色多次声明：最新为准；改口的旧角色标 changed
      if (history.isNotEmpty) {
        final latest = history.last;
        latestByPlayer[p.id] = latest;
        for (final c in history) {
          if (c.character != latest.character &&
              c.claimType != ClaimType.revealedOnDeath &&
              row[c.character] == MatrixCellState.claimed) {
            row[c.character] = MatrixCellState.changed;
          }
        }
      }
      rows[p.id] = row;
    }

    // 注入「我的真实角色」（issue #107）：我座位显示 myRole（私密状态），
    // 并计入对应列（助手视角 myRole 是真相，覆盖任何公开自声明）。
    if (myPlayerId != null && myRole != null) {
      rows.putIfAbsent(myPlayerId, () => {})[myRole] =
          MatrixCellState.myRole;
      latestByPlayer[myPlayerId] = RoleClaim(
        id: -1,
        playerId: myPlayerId,
        dayRecordId: -1,
        character: myRole,
        claimType: ClaimType.myRole,
      );
    }

    // 列：每角色的声明者
    final columns = <MatrixColumn>[
      for (final c in ScriptDefinition.of(script).characters)
        MatrixColumn(
          character: c,
          claimantIds: [
            for (final e in latestByPlayer.entries)
              if (e.value.character == c) e.key,
          ],
          isBluff: demonBluffs.contains(c),
        ),
    ];

    return (columns, rows);
  }
}
