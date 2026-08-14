import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/timeline/domain/timeline_event.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimelineBuilder 传承事件（issue #89）', () {
    final players = [
      Player(
        id: 1,
        gameId: 1,
        name: 'A',
        seatNumber: 1,
        isAlive: true,
        abilityUsed: false,
        suspectedDrunk: false,
        fakeDead: false,
      ),
      Player(
        id: 2,
        gameId: 1,
        name: 'B',
        seatNumber: 2,
        isAlive: true,
        abilityUsed: false,
        suspectedDrunk: false,
        fakeDead: false,
      ),
    ];
    final playersById = {for (final p in players) p.id: p};

    List<TimelineEvent> build(List<DemonInheritance> successions) {
      final days = [
        DayRecord(id: 10, gameId: 1, dayNumber: 1, notes: '', nightConfirmed: true, dayConfirmed: true),
      ];
      final result = TimelineBuilder.build(
        days: days,
        claims: const [],
        declarations: const [],
        playersById: playersById,
        dayRecordToDayNumber: const {10: 1},
        successions: successions,
      );
      return result.single.events;
    }

    test('from→to 传承：摘要含双方与机制', () {
      final events = build([
        DemonInheritance(
          id: 1,
          gameId: 1,
          dayNumber: 1,
          fromPlayerId: 1,
          toPlayerId: 2,
          trigger: SuccessionTrigger.scarletWoman,
          createdAt: DateTime(2026, 8, 13),
        ),
      ]);
      final event = events.firstWhere(
        (e) => e.type == TimelineEventType.demonSuccession,
      );
      expect(event.summary, contains('1号 A'));
      expect(event.summary, contains('2号 B'));
      expect(event.summary, contains('绯红女继承'));
      expect(event.playerId, 2);
    });

    test('继承人未知：摘要标注未知 + 机制', () {
      final events = build([
        DemonInheritance(
          id: 1,
          gameId: 1,
          dayNumber: 1,
          fromPlayerId: 1,
          toPlayerId: null,
          trigger: SuccessionTrigger.suicideByImp,
          createdAt: DateTime(2026, 8, 13),
        ),
      ]);
      final event = events.firstWhere(
        (e) => e.type == TimelineEventType.demonSuccession,
      );
      expect(event.summary, contains('继承人未知'));
      expect(event.summary, contains('恶魔自杀传位'));
      expect(event.playerId, 1); // 无继承人 → 关联死者
    });

    test('无传承记录 → 无 demonSuccession 事件', () {
      final events = build(const []);
      expect(
        events.where((e) => e.type == TimelineEventType.demonSuccession),
        isEmpty,
      );
    });
  });

  // #147 L2 对抗性守卫：db id ≠ 座位号时，信息声明摘要必须渲染座位号而非 db id
  // （#145 家族的显示层防线——id==seat 的 fixture 会让此类混淆无差别通过）。
  group('TimelineBuilder 信息声明摘要（#145/#147 id≠seat 守卫）', () {
    // 作者 id=1（座位 1）；目标 db id=24 但座位 5 —— id≠seat 的对抗场景。
    final players = [
      Player(
        id: 1,
        gameId: 1,
        name: 'A',
        seatNumber: 1,
        isAlive: true,
        abilityUsed: false,
        suspectedDrunk: false,
        fakeDead: false,
      ),
      Player(
        id: 24,
        gameId: 1,
        name: 'E',
        seatNumber: 5,
        isAlive: true,
        abilityUsed: false,
        suspectedDrunk: false,
        fakeDead: false,
      ),
    ];
    final playersById = {for (final p in players) p.id: p};

    test('目标玩家按座位号渲染，不得出现 db id（#145 回归）', () {
      final days = [
        DayRecord(
          id: 10,
          gameId: 1,
          dayNumber: 1,
          notes: '',
          nightConfirmed: true,
          dayConfirmed: true,
        ),
      ];
      final decl = InfoDeclaration(
        id: 1,
        playerId: 1, // 作者 A（座位 1）
        dayRecordId: 10,
        characterType: Character.poisoner,
        payloadJson: '{"playerId": 24}', // 目标 db id=24，座位 5
        reliability: Reliability.unverified,
        isMine: false,
      );
      final result = TimelineBuilder.build(
        days: days,
        claims: const [],
        declarations: [decl],
        playersById: playersById,
        dayRecordToDayNumber: const {10: 1},
      );
      final event = result.single.events.firstWhere(
        (e) => e.type == TimelineEventType.infoDeclaration,
      );
      // 目标按座位号渲染（seatLabel 输出「5号」无空格）
      expect(event.summary, contains('下毒 5号'));
      // 绝不出现 db id
      expect(event.summary, isNot(contains('24')));
    });
  });
}
