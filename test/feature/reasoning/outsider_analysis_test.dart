import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/reasoning/domain/outsider_analysis.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

RoleClaim _claim(
  int playerId,
  Character c, {
  ClaimType type = ClaimType.firstClaim,
}) =>
    RoleClaim(
      id: playerId,
      playerId: playerId,
      dayRecordId: 1,
      character: c,
      claimType: type,
    );

OutsiderCountAnalysis analyze(
  int playerCount,
  List<RoleClaim> claims, {
  Character? myRole,
}) =>
    analyzeOutsiderCount(
      playerCount: playerCount,
      claims: claims,
      myRole: myRole,
    );

void main() {
  group('base = 0（7 人局，无 under 分支）', () {
    test('0 声明 → standard', () {
      final a = analyze(7, []);
      expect(a.deviation, OutsiderDeviation.standard);
      expect(a.claimedOutsiders, 0);
      expect(a.baseOutsiders, 0);
      expect(a.baronOutsiders, 2);
    });

    test('2 声明 → baronConsistent', () {
      final a = analyze(7, [_claim(1, Character.butler), _claim(2, Character.saint)]);
      expect(a.deviation, OutsiderDeviation.baronConsistent);
    });

    test('1 声明 → partial', () {
      final a = analyze(7, [_claim(1, Character.butler)]);
      expect(a.deviation, OutsiderDeviation.partial);
    });

    test('3 声明 → over', () {
      final a = analyze(7, [
        _claim(1, Character.butler),
        _claim(2, Character.saint),
        _claim(3, Character.drunk),
      ]);
      expect(a.deviation, OutsiderDeviation.over);
      expect(a.claimedOutsiders, 3);
    });
  });

  group('base = 2（9 人局）', () {
    test('2 声明 → standard', () {
      final a = analyze(9, [_claim(1, Character.butler), _claim(2, Character.saint)]);
      expect(a.deviation, OutsiderDeviation.standard);
    });

    test('4 声明 → baronConsistent', () {
      final a = analyze(9, [
        _claim(1, Character.butler),
        _claim(2, Character.saint),
        _claim(3, Character.drunk),
        _claim(4, Character.recluse),
      ]);
      expect(a.deviation, OutsiderDeviation.baronConsistent);
      expect(a.baronOutsiders, 4);
    });

    test('3 声明 → partial', () {
      final a = analyze(9, [
        _claim(1, Character.butler),
        _claim(2, Character.saint),
        _claim(3, Character.drunk),
      ]);
      expect(a.deviation, OutsiderDeviation.partial);
    });

    test('1 声明 → under', () {
      final a = analyze(9, [_claim(1, Character.butler)]);
      expect(a.deviation, OutsiderDeviation.under);
    });

    test('0 声明 → under', () {
      final a = analyze(9, []);
      expect(a.deviation, OutsiderDeviation.under);
    });

    test('5 声明 → over', () {
      final a = analyze(9, [
        _claim(1, Character.butler),
        _claim(2, Character.saint),
        _claim(3, Character.drunk),
        _claim(4, Character.recluse),
        _claim(5, Character.butler),
      ]);
      expect(a.deviation, OutsiderDeviation.over);
    });
  });

  group('配置字段', () {
    test('9 人局配置正确', () {
      final a = analyze(9, []);
      expect(a.townsfolk, 5);
      expect(a.minions, 1);
      expect(a.demons, 1);
      expect(a.playerCount, 9);
    });
  });

  group('base = 1（8 人局）', () {
    test('0 声明 → under', () {
      expect(analyze(8, []).deviation, OutsiderDeviation.under);
    });

    test('1 声明 → standard', () {
      expect(
        analyze(8, [_claim(1, Character.butler)]).deviation,
        OutsiderDeviation.standard,
      );
    });

    test('2 声明 → partial', () {
      expect(
        analyze(8, [_claim(1, Character.butler), _claim(2, Character.saint)])
            .deviation,
        OutsiderDeviation.partial,
      );
    });

    test('3 声明 → baronConsistent', () {
      expect(
        analyze(8, [
          _claim(1, Character.butler),
          _claim(2, Character.saint),
          _claim(3, Character.drunk),
        ]).deviation,
        OutsiderDeviation.baronConsistent,
      );
    });

    test('4 声明 → over', () {
      expect(
        analyze(8, [
          _claim(1, Character.butler),
          _claim(2, Character.saint),
          _claim(3, Character.drunk),
          _claim(4, Character.recluse),
        ]).deviation,
        OutsiderDeviation.over,
      );
    });
  });

  group('Baron 信号', () {
    test('有人声明 Baron → baronClaimed', () {
      final a = analyze(9, [_claim(5, Character.baron)]);
      expect(a.baronClaimed, isTrue);
    });

    test('myRole == Baron → baronClaimed', () {
      final a = analyze(9, [], myRole: Character.baron);
      expect(a.baronClaimed, isTrue);
    });

    test('无 Baron 声明 → baronClaimed false', () {
      final a = analyze(9, [_claim(1, Character.butler)]);
      expect(a.baronClaimed, isFalse);
    });
  });

  group('声明来源', () {
    test('死亡揭示外来者 → confirmed 标记', () {
      final a = analyze(9, [
        _claim(1, Character.butler),
        _claim(2, Character.saint, type: ClaimType.revealedOnDeath),
      ]);
      final byId = {for (final c in a.claimers) c.playerId: c};
      expect(byId[1]!.confirmed, isFalse); // 普通声明
      expect(byId[2]!.confirmed, isTrue); // 死亡揭示 = 确认
    });

    test('改口后取最新声明（旧外来者声明不计）', () {
      // 1 号先声明外来者，后改口镇民 → 最新是镇民，不计入外来者
      final a = analyze(9, [
        RoleClaim(
          id: 1,
          playerId: 1,
          dayRecordId: 1,
          character: Character.butler,
          claimType: ClaimType.firstClaim,
        ),
        RoleClaim(
          id: 2, // id 更大 = 最新
          playerId: 1,
          dayRecordId: 1,
          character: Character.chef,
          claimType: ClaimType.changed,
        ),
      ]);
      expect(a.claimedOutsiders, 0);
      expect(a.deviation, OutsiderDeviation.under);
    });

    test('只统计外来者团队（镇民/爪牙/恶魔不计）', () {
      final a = analyze(9, [
        _claim(1, Character.chef), // 镇民
        _claim(2, Character.poisoner), // 爪牙
        _claim(3, Character.butler), // 外来者
      ]);
      expect(a.claimedOutsiders, 1);
    });
  });
}
