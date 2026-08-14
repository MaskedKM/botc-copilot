import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/game_board/domain/night_death_rules.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NightDeathRules.warnings（issue #114）', () {
    test('首夜（第 1 天）→ 警告首夜无人死亡', () {
      final w = NightDeathRules.warnings(
        day: 1,
        claimedCharacter: Character.chef,
      );
      expect(w, hasLength(1));
      expect(w.first, contains('首夜'));
      expect(w.first, contains('Imp'));
    });

    test('非首夜不触发首夜警告', () {
      final w = NightDeathRules.warnings(
        day: 2,
        claimedCharacter: Character.chef,
      );
      expect(w, isEmpty);
    });

    test('声明 Soldier → 警告免疫恶魔能力', () {
      final w = NightDeathRules.warnings(
        day: 3,
        claimedCharacter: Character.soldier,
      );
      expect(w, hasLength(1));
      expect(w.first, contains('士兵'));
      expect(w.first, contains('毒'));
    });

    test('首夜 + Soldier 叠加 → 两条警告', () {
      final w = NightDeathRules.warnings(
        day: 1,
        claimedCharacter: Character.soldier,
      );
      expect(w, hasLength(2));
    });

    test('无声明角色 + 非首夜 → 空', () {
      final w = NightDeathRules.warnings(day: 3, claimedCharacter: null);
      expect(w, isEmpty);
    });

    test('被 Monk 保护者夜死 → 警告保护未生效（#110/#114任务3）', () {
      final w = NightDeathRules.warnings(
        day: 3,
        claimedCharacter: Character.chef,
        monkProtected: true,
      );
      expect(w, hasLength(1));
      expect(w.first, contains('僧侣保护'));
      expect(w.first, contains('毒'));
    });

    test('monkProtected 默认 false → 不触发', () {
      final w = NightDeathRules.warnings(
        day: 3,
        claimedCharacter: Character.chef,
      );
      expect(w, isEmpty);
    });

    test('声明 Mayor 夜死 → 警告转移机制（#220）', () {
      final w = NightDeathRules.warnings(
        day: 3,
        claimedCharacter: Character.mayor,
      );
      expect(w, hasLength(1));
      expect(w.first, contains('市长'));
      expect(w.first, contains('改杀他人'));
    });
  });

  group('hasAliveMayorClaim（#220 面板提示）', () {
    Player _p(int id, {bool alive = true}) => Player(
          id: id,
          gameId: 1,
          name: 'P$id',
          seatNumber: id,
          isAlive: alive,
          abilityUsed: false,
          suspectedDrunk: false,
          deathDay: alive ? null : 2,
          deathCause: alive ? null : DeathCause.nightKill,
        );

    RoleClaim _c(int id, Character ch) => RoleClaim(
          id: id,
          playerId: id,
          dayRecordId: 1,
          character: ch,
          claimType: ClaimType.firstClaim,
        );

    test('存活市长声明者 → true', () {
      expect(
        NightDeathRules.hasAliveMayorClaim({1: _c(1, Character.mayor)}, {1: _p(1)}),
        isTrue,
      );
    });

    test('市长已死（揭示）→ false（转移机制不再触发）', () {
      expect(
        NightDeathRules.hasAliveMayorClaim(
          {1: _c(1, Character.mayor)},
          {1: _p(1, alive: false)},
        ),
        isFalse,
      );
    });

    test('无市长声明 / 声明其他角色 → false', () {
      expect(
        NightDeathRules.hasAliveMayorClaim(
          {1: _c(1, Character.chef), 2: _c(2, Character.monk)},
          {1: _p(1), 2: _p(2)},
        ),
        isFalse,
      );
    });
  });
}
