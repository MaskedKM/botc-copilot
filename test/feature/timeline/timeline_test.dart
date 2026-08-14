import 'dart:convert';

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
        nightDeathPlayerIds: Value(jsonEncode([players[2].id])),
        dayExecutionPlayerId: Value(players[4].id),
      ),
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// 等待组合流首次产出数据（底层 4 个 Drift 流需各 emit 一次）。
  Future<List<TimelineDay>> readTimeline() async {
    for (var i = 0; i < 50; i++) {
      final value = container.read(timelineProvider(gameId)).valueOrNull;
      if (value != null) return value;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('timeline 未产出数据');
  }

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
    // 掘墓人信息（issue #106：改读 info_declarations）
    await db.infoDeclarationsDao.insertDeclaration(
      InfoDeclarationsCompanion(
        playerId: Value(players[0].id),
        dayRecordId: Value(day1Id),
        characterType: const Value(Character.undertaker),
        payloadJson: const Value('{"character": "poisoner"}'),
        reliability: const Value(Reliability.unverified),
      ),
    );

    final timeline = await readTimeline();

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
    expect(summaries, contains('报掘墓人：被处决者是 投毒者'));
    // 掘墓人信息不再走通用 infoDeclaration 通道（避免重复展示，#106）
    expect(summaries, isNot(contains('报 掘墓人')));
    // 时序：掘墓人信息属夜间获知，排在当日处决之前（#106 review）
    final undertakerIdx = events
        .indexWhere((e) => e.type == TimelineEventType.undertakerResult);
    final execIdx = events
        .indexWhere((e) => e.type == TimelineEventType.execution);
    expect(undertakerIdx, greaterThanOrEqualTo(0));
    expect(execIdx, greaterThanOrEqualTo(0));
    expect(undertakerIdx, lessThan(execIdx));
  });

  test('多天排序正确 + 无人死亡事件', () async {
    await db.dayRecordsDao.insertDay(
      DayRecordsCompanion(
        gameId: Value(gameId),
        dayNumber: const Value(2),
        nightConfirmed: const Value(true), // 确认无人死亡（#77）
      ),
    );
    final timeline = await readTimeline();

    expect(timeline.map((d) => d.dayNumber), [1, 2]);
    expect(timeline[1].events.single.summary, '夜晚无人死亡');
  });

  test('未确认的夜晚不显示「无人死亡」（预建记录，issue #77）', () async {
    await db.dayRecordsDao.insertDay(
      DayRecordsCompanion(gameId: Value(gameId), dayNumber: const Value(2)),
      // nightConfirmed 默认 false：进入第 2 天但夜晚未确认
    );
    final timeline = await readTimeline();
    // 第 2 天无任何事件（夜晚未确认 → 不输出「夜晚无人死亡」）
    expect(timeline[1].events, isEmpty);
  });

  test('响应式：录入新声明后时间线自动刷新（PR #29 review 回归）', () async {
    // 先读到初始时间线（无声明事件）
    final before = await readTimeline();
    expect(
      before.single.events
          .where((e) => e.type == TimelineEventType.roleClaim),
      isEmpty,
    );

    // 录入一条角色声明（不改 day_records）
    await db.roleClaimsDao.insertClaim(
      RoleClaimsCompanion(
        playerId: Value(players[5].id),
        dayRecordId: Value(day1Id),
        character: const Value(Character.empath),
        claimType: const Value(ClaimType.firstClaim),
      ),
    );

    // 不换页、不手动刷新——流驱动自动重建
    for (var i = 0; i < 50; i++) {
      final timeline = container.read(timelineProvider(gameId)).valueOrNull;
      final hasClaim = timeline?.single.events.any(
            (e) =>
                e.type == TimelineEventType.roleClaim &&
                e.summary.contains('6号 玩家6'),
          ) ??
          false;
      if (hasClaim) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('时间线未自动刷新新增的角色声明');
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
    final timeline = await readTimeline();
    expect(
      timeline.single.events.map((e) => e.summary).join(),
      contains('2号 玩家2 声明 共情者（改口）'),
    );
  });

  test('提名/投票事件出现在处决之前且含赞成票数与辩护（issue #90）', () async {
    // 4 票赞成（7 人阈值 ceil(7/2)=4）→ 通过；投票者均为存活非被提名人
    final votesJson = jsonEncode([
      for (final id in [
        players[0].id,
        players[3].id,
        players[5].id,
        players[6].id,
      ])
        {'playerId': id, 'vote': 'forVote', 'isDeadVote': false},
    ]);
    await db.nominationsDao.insertNomination(
      NominationsCompanion(
        gameId: Value(gameId),
        dayRecordId: Value(day1Id),
        nominatorPlayerId: Value(players[0].id),
        nomineePlayerId: Value(players[1].id),
        passed: const Value(true),
        voteResultJson: Value(votesJson),
        defenseText: const Value('我是好人'),
      ),
    );

    final timeline = await readTimeline();
    final events = timeline.single.events;
    final summaries = events.map((e) => e.summary).join('\n');

    // 摘要含 提名者→被提名者 / 赞成票数 / 通过 / 辩护
    expect(summaries, contains('1号 玩家1 → 2号 玩家2（赞成4票，通过）'));
    expect(summaries, contains('辩护：我是好人'));

    // 时序：提名事件位于处决之前
    final nomIdx = events
        .indexWhere((e) => e.type == TimelineEventType.nomination);
    final execIdx = events
        .indexWhere((e) => e.type == TimelineEventType.execution);
    expect(nomIdx, greaterThanOrEqualTo(0));
    expect(execIdx, greaterThanOrEqualTo(0));
    expect(nomIdx, lessThan(execIdx));
  });
}
