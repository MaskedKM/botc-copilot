import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/game_board/domain/nomination_rules.dart';
import 'package:botc_copilot/feature/reasoning/domain/latest_claim.dart';
import 'package:botc_copilot/feature/reasoning/domain/role_matrix.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

RoleClaim _claim(int pid, Character c) => RoleClaim(
      id: pid,
      playerId: pid,
      dayRecordId: 1,
      character: c,
      claimType: ClaimType.firstClaim,
    );

Player _player(int id) => Player(
      id: id,
      gameId: 1,
      name: 'P$id',
      seatNumber: id,
      isAlive: true,
      abilityUsed: false,
    );

void main() {
  group('latestClaimWithSelf（#107 注入）', () {
    test('注入我座位的 myRole，标 ClaimType.myRole', () {
      final m = latestClaimWithSelf(
        [_claim(2, Character.chef)],
        myPlayerId: 1,
        myRole: Character.virgin,
      );
      expect(m[1]!.character, Character.virgin);
      expect(m[1]!.claimType, ClaimType.myRole);
      expect(m[2]!.character, Character.chef); // 公开声明保留
    });

    test('myPlayerId / myRole 为空 → 不注入', () {
      final m = latestClaimWithSelf(
        [_claim(1, Character.chef)],
        myPlayerId: null,
        myRole: null,
      );
      expect(m[1]!.claimType, ClaimType.firstClaim); // 原样
      expect(m.containsKey(2), isFalse);
    });

    test('myRole 覆盖我座位的公开自声明（助手视角是真相）', () {
      final m = latestClaimWithSelf(
        [_claim(1, Character.chef)], // 我公开声明了 Chef
        myPlayerId: 1,
        myRole: Character.virgin, // 但我真实是 Virgin
      );
      expect(m[1]!.character, Character.virgin); // 覆盖为真相
      expect(m[1]!.claimType, ClaimType.myRole);
    });
  });

  group('Virgin 触发 + 注入（#107）', () {
    test('我是 Virgin 被镇民提名 → 触发（无需公开声明）', () {
      final players = {for (var i = 1; i <= 3; i++) i: _player(i)};
      final latest = latestClaimWithSelf(
        [_claim(2, Character.chef)], // 2 号声明镇民 Chef
        myPlayerId: 1,
        myRole: Character.virgin, // 我是 Virgin（无公开声明）
      );
      final id = NominationRules.virginTriggerScenario(
        nominatorId: 2, // 镇民提名我
        nomineeId: 1, // 我是 Virgin
        latestClaim: latest,
        playersById: players,
      );
      expect(id, 1); // 触发 → 处决提名者路径识别到我
    });
  });

  group('RoleMatrixBuilder + 注入（#107）', () {
    test('我座位显示 myRole（私密状态）并计入列', () {
      final players = [_player(1), _player(2)];
      final (columns, rows) = RoleMatrixBuilder.build(
        players: players,
        claims: [_claim(2, Character.chef)],
        demonBluffs: const [],
        myPlayerId: 1,
        myRole: Character.empath,
      );
      // 我座位 1 号：empath 格为 myRole 状态
      expect(rows[1]![Character.empath], MatrixCellState.myRole);
      // empath 列含我（1 号）
      final empathCol =
          columns.firstWhere((c) => c.character == Character.empath);
      expect(empathCol.claimantIds, contains(1));
    });

    test('无 myRole → 我座位仍空（不注入）', () {
      final players = [_player(1)];
      final (columns, rows) = RoleMatrixBuilder.build(
        players: players,
        claims: const [],
        demonBluffs: const [],
      );
      expect(rows[1], isEmpty);
    });
  });
}
