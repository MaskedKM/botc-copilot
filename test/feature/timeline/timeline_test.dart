import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/timeline/data/timeline_provider.dart';
import 'package:botc_copilot/feature/timeline/domain/timeline_event.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int gameId;
  late List<Player> players;
  late int day1Id;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    gameId = await db.gamesDao.insertGame(
      GamesCompanion(
        script: const Value(Script.troubleBrewing),
        playerCount: const Value(7),
        status: const Value(GameStatus.ongoing),
        createdAt: Value(DateTime(2026, 8, 12)),
      ),
    );
    await db.playersDao.insertAll([
      for (var i = 1; i <= 7; i++)
        PlayersCompanion(
          gameId: Value(gameId),
          name: Value('玩家$i'),
          seatNumber: Value(i),
        ),
    ]);
    players = await db.playersDao.watchByGame(gameId).first;
    day1Id = await db.dayRecordsDao.insertDay(
      DayRecordsCompanion(
        gameId: Value(gameId),
        dayNumber: const Value(1),
        nightDeathPlayerId: Value(players[2].id),
        dayExecutionPlayerId: Value(players[4].id),
        undertakerResultRole: const Value(Character.poisoner),
      ),
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('时间线按天分组 + 事件类型齐全', () async {
    await db.roleClaimsDao.insertClaim(
      RoleClaimsCompanion(
        playerId: Value(players[0].id),
        dayRecordId: Value(day1Id),
        character: const Value(Character.chef),
        claimType: const Value(ClaimType.firstClaim),
      ),
    );
    await db.infoDeclarationsDao.insertDeclaration(
      InfoDeclarationsCompanion(
        playerId: Value(players[0].id),
        dayRecordId: Value(day1Id),
        characterType: const Value(Character.chef),
        payloadJson: const Value('{"value": 1}'),
        reliability: const Value(Reliability.unverified),
      ),
    );

    final timeline = await container.read(timelineProvider(gameId).future);

    expect(timeline, hasLength(1));
    final events = timeline.single.events;
    final types = events.map((e) => e.type).toSet();
    expect(types, containsAll([
      TimelineEventType.nightDeath,
      TimelineEventType.roleClaim,
      TimelineEventType.infoDeclaration,
      TimelineEventType.execution,
      TimelineEventType.undertakerResult,
    ]));

    // 事件文案
    final summaries = events.map((e) => e.summary).join('\n');
    expect(summaries, contains('3号 玩家3 夜晚死亡'));
    expect(summaries, contains('1号 玩家1 声明 厨师'));
    expect(summaries, contains('厨师：1'));
    expect(summaries, contains('5号 玩家5 被处决'));
    expect(summaries, contains('掘墓人：被处决者是 投毒者'));
  });

  test('多天排序正确 + 无人死亡事件', () async {
    await db.dayRecordsDao.insertDay(
      DayRecordsCompanion(gameId: Value(gameId), dayNumber: const Value(2)),
    );
    final timeline = await container.read(timelineProvider(gameId).future);

    expect(timeline.map((d) => d.dayNumber), [1, 2]);
    expect(timeline[1].events.single.summary, '夜晚无人死亡');
  });

  test('改口声明带标记', () async {
    await db.roleClaimsDao.insertClaim(
      RoleClaimsCompanion(
        playerId: Value(players[1].id),
        dayRecordId: Value(day1Id),
        character: const Value(Character.empath),
        claimType: const Value(ClaimType.changed),
      ),
    );
    final timeline = await container.read(timelineProvider(gameId).future);
    expect(
      timeline.single.events.map((e) => e.summary).join(),
      contains('2号 玩家2 声明 共情者（改口）'),
    );
  });
}
