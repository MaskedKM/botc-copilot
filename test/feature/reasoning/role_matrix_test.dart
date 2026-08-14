import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/reasoning/domain/role_matrix.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

Player _player(int id, int seat) => Player(
      id: id,
      gameId: 1,
      name: 'P$id',
      seatNumber: seat,
      isAlive: true,
      abilityUsed: false, suspectedDrunk: false,
      deathDay: null,
      deathCause: null,
    );

RoleClaim _claim(
  int id,
  int playerId,
  Character c, {
  ClaimType type = ClaimType.firstClaim,
}) =>
    RoleClaim(
      id: id,
      playerId: playerId,
      dayRecordId: 1,
      character: c,
      claimType: type,
    );

void main() {
  final players = [_player(1, 1), _player(2, 2), _player(3, 3)];

  test('基本聚合：列含声明者，行含状态', () {
    final (columns, rows) = RoleMatrixBuilder.build(
      script: Script.troubleBrewing,
      players: players,
      claims: [
        _claim(1, 1, Character.chef),
        _claim(2, 2, Character.monk),
      ],
      demonBluffs: [],
    );

    final chefCol = columns.firstWhere((c) => c.character == Character.chef);
    expect(chefCol.claimantIds, [1]);
    expect(chefCol.hasConflict, isFalse);
    expect(rows[1]![Character.chef], MatrixCellState.claimed);
    expect(rows[3]![Character.chef], isNull); // 3号没声明
  });

  test('多人声明同一角色 → hasConflict', () {
    final (columns, _) = RoleMatrixBuilder.build(
      script: Script.troubleBrewing,
      players: players,
      claims: [
        _claim(1, 1, Character.chef),
        _claim(2, 2, Character.chef),
      ],
      demonBluffs: [],
    );
    final chefCol = columns.firstWhere((c) => c.character == Character.chef);
    expect(chefCol.hasConflict, isTrue);
    expect(chefCol.claimantIds, containsAll([1, 2]));
  });

  test('改口：旧角色 changed，新角色 claimed', () {
    final (columns, rows) = RoleMatrixBuilder.build(
      script: Script.troubleBrewing,
      players: players,
      claims: [
        _claim(1, 1, Character.chef),
        _claim(2, 1, Character.monk, type: ClaimType.changed),
      ],
      demonBluffs: [],
    );
    expect(rows[1]![Character.chef], MatrixCellState.changed);
    expect(rows[1]![Character.monk], MatrixCellState.claimed);
    // 列聚合只算最新声明
    final chefCol = columns.firstWhere((c) => c.character == Character.chef);
    expect(chefCol.claimantIds, isEmpty);
  });

  test('死亡揭示 → confirmed，不被改口覆盖', () {
    final (_, rows) = RoleMatrixBuilder.build(
      script: Script.troubleBrewing,
      players: players,
      claims: [
        _claim(1, 1, Character.virgin, type: ClaimType.revealedOnDeath),
      ],
      demonBluffs: [],
    );
    expect(rows[1]![Character.virgin], MatrixCellState.confirmed);
  });

  test('Bluff 标记 + 无人声明 isUnclaimed', () {
    final (columns, _) = RoleMatrixBuilder.build(
      script: Script.troubleBrewing,
      players: players,
      claims: [_claim(1, 1, Character.chef)],
      demonBluffs: [Character.poisoner, Character.spy],
    );
    final poisonerCol =
        columns.firstWhere((c) => c.character == Character.poisoner);
    expect(poisonerCol.isBluff, isTrue);
    expect(poisonerCol.isUnclaimed, isTrue);

    final monkCol = columns.firstWhere((c) => c.character == Character.monk);
    expect(monkCol.isUnclaimed, isTrue);
    expect(monkCol.isBluff, isFalse);
  });

  test('空输入：所有列 unclaimed，行全空', () {
    final (columns, rows) = RoleMatrixBuilder.build(
      script: Script.troubleBrewing,
      players: players,
      claims: [],
      demonBluffs: [],
    );
    expect(columns.every((c) => c.isUnclaimed), isTrue);
    expect(rows.values.every((r) => r.isEmpty), isTrue);
  });
}
