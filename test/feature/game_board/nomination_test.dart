import 'dart:convert';

import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/data/nomination_repository.dart';
import 'package:botc_copilot/feature/game_board/domain/nomination_rules.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late NominationRepository repo;
  late int gameId;
  late int dayRecordId;
  late List<Player> players;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    repo = NominationRepository(db);
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
    // 7 号死亡（有死票）
    await db.playersDao.markDead(players[6].id, 1, DeathCause.nightKill);
    players = await db.playersDao.watchByGame(gameId).first;
    dayRecordId = await db.dayRecordsDao.insertDay(
      DayRecordsCompanion(gameId: Value(gameId), dayNumber: const Value(1)),
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  List<VoteEntry> votesFor(List<int> forIds) => [
        for (final p in players)
          VoteEntry(
            playerId: p.id,
            vote: forIds.contains(p.id) ? Vote.forVote : Vote.against,
            isDeadVote: !p.isAlive && forIds.contains(p.id),
          ),
      ];

  /// 构造一条提名（前 [forCount] 个玩家赞成，其余反对）。存活 6 人 → 阈值 3。
  Nomination nominationWithVotes({
    required int nominatorIndex,
    required int nomineeIndex,
    required int forCount,
  }) {
    final votes = [
      for (var i = 0; i < players.length; i++)
        VoteEntry(
          playerId: players[i].id,
          vote: i < forCount ? Vote.forVote : Vote.against,
        ),
    ];
    return Nomination(
      id: 0,
      gameId: gameId,
      dayRecordId: dayRecordId,
      nominatorPlayerId: players[nominatorIndex].id,
      nomineePlayerId: players[nomineeIndex].id,
      passed: forCount >= 3,
      voteResultJson: jsonEncode(votes.map((v) => v.toJson()).toList()),
    );
  }

  group('NominationRules', () {
    test('处决阈值：存活人数一半向上取整', () {
      expect(NominationRules.threshold(7), 4);
      expect(NominationRules.threshold(6), 3);
      expect(NominationRules.threshold(5), 3);
    });

    test('isPassed：达到阈值才通过', () {
      // 存活 6 人，阈值 3
      expect(NominationRules.isPassed(votesFor([1, 2, 3]), 6), isTrue);
      expect(NominationRules.isPassed(votesFor([1, 2]), 6), isFalse);
    });
  });

  group('pendingExecution（最高票替换 + 平票，issue #53）', () {
    test('唯一最高票 → 该被提名者即将死亡', () {
      final noms = [
        nominationWithVotes(nominatorIndex: 0, nomineeIndex: 1, forCount: 5),
      ];
      final result = NominationRules.pendingExecution(noms, 6);
      expect(result, isA<PendingExecution>());
      expect((result as PendingExecution).nomineeId, players[1].id);
      expect(result.forCount, 5);
    });

    test('更高票出现 → 替换为新的即将死亡者', () {
      final noms = [
        nominationWithVotes(nominatorIndex: 0, nomineeIndex: 1, forCount: 5),
        nominationWithVotes(nominatorIndex: 2, nomineeIndex: 3, forCount: 6),
      ];
      final result = NominationRules.pendingExecution(noms, 6);
      expect(result, isA<PendingExecution>());
      expect((result as PendingExecution).nomineeId, players[3].id);
      expect(result.forCount, 6);
    });

    test('最高票并列 → 平票，无人即将死亡', () {
      final noms = [
        nominationWithVotes(nominatorIndex: 0, nomineeIndex: 1, forCount: 4),
        nominationWithVotes(nominatorIndex: 2, nomineeIndex: 3, forCount: 4),
      ];
      final result = NominationRules.pendingExecution(noms, 6);
      expect(result, isA<PendingTie>());
      expect((result as PendingTie).forCount, 4);
    });

    test('无人达到阈值 → PendingNone', () {
      final noms = [
        nominationWithVotes(nominatorIndex: 0, nomineeIndex: 1, forCount: 2),
      ];
      final result = NominationRules.pendingExecution(noms, 6);
      expect(result, isA<PendingNone>());
    });
  });

  group('addNomination', () {
    test('正常提名写入 + passed 正确计算', () async {
      final error = await repo.addNomination(
        gameId: gameId,
        dayRecordId: dayRecordId,
        nominatorId: players[0].id,
        nomineeId: players[1].id,
        votes: votesFor([1, 2, 3]), // 3 票赞成 ≥ 阈值 3 → 通过
        players: players,
        todayNominations: [],
        allNominations: [],
      );

      expect(error, isNull);
      final noms = await db.nominationsDao.watchByGame(gameId).first;
      expect(noms, hasLength(1));
      expect(noms.single.passed, isTrue);
    });

    test('每人每天只能提名一次', () async {
      await repo.addNomination(
        gameId: gameId,
        dayRecordId: dayRecordId,
        nominatorId: players[0].id,
        nomineeId: players[1].id,
        votes: votesFor([1]),
        players: players,
        todayNominations: [],
        allNominations: [],
      );

      final existing = await db.nominationsDao.watchByDay(dayRecordId).first;
      final error = await repo.addNomination(
        gameId: gameId,
        dayRecordId: dayRecordId,
        nominatorId: players[0].id, // 同一提名者
        nomineeId: players[2].id,
        votes: votesFor([1]),
        players: players,
        todayNominations: existing,
        allNominations: existing,
      );
      expect(error, '该玩家今天已提名过');
    });

    test('每人每天只能被提名一次', () async {
      await repo.addNomination(
        gameId: gameId,
        dayRecordId: dayRecordId,
        nominatorId: players[0].id,
        nomineeId: players[1].id,
        votes: votesFor([1]),
        players: players,
        todayNominations: [],
        allNominations: [],
      );

      final existing = await db.nominationsDao.watchByDay(dayRecordId).first;
      final error = await repo.addNomination(
        gameId: gameId,
        dayRecordId: dayRecordId,
        nominatorId: players[2].id,
        nomineeId: players[1].id, // 同一被提名者
        votes: votesFor([1]),
        players: players,
        todayNominations: existing,
        allNominations: existing,
      );
      expect(error, '该玩家今天已被提名过');
    });

    test('今日已处决 → 拒绝提名（#79）', () async {
      // 标记今日已处决
      await db.dayRecordsDao.updateDay(
        dayRecordId,
        DayRecordsCompanion(dayExecutionPlayerId: Value(players[4].id)),
      );
      final error = await repo.addNomination(
        gameId: gameId,
        dayRecordId: dayRecordId,
        nominatorId: players[0].id,
        nomineeId: players[1].id,
        votes: votesFor([1, 2, 3]),
        players: players,
        todayNominations: [],
        allNominations: [],
      );
      expect(error, '今日已处决，提名阶段已结束');
    });

    test('死票用过后不可再用', () async {
      // 第一次：7 号用死票
      await repo.addNomination(
        gameId: gameId,
        dayRecordId: dayRecordId,
        nominatorId: players[0].id,
        nomineeId: players[1].id,
        votes: votesFor([1, 7]), // 7 号赞成 = 死票
        players: players,
        todayNominations: [],
        allNominations: [],
      );

      // 第二天：7 号再投赞成 → 报错
      final day2 = await db.dayRecordsDao.insertDay(
        DayRecordsCompanion(
          gameId: Value(gameId),
          dayNumber: const Value(2),
        ),
      );
      final all = await db.nominationsDao.watchByGame(gameId).first;
      final error = await repo.addNomination(
        gameId: gameId,
        dayRecordId: day2,
        nominatorId: players[2].id,
        nomineeId: players[3].id,
        votes: votesFor([2, 7]),
        players: players,
        todayNominations: [],
        allNominations: all,
      );
      expect(error, '该玩家的死票已用过');
    });

    test('平票/不足阈值：不通过（无人处决）', () async {
      final error = await repo.addNomination(
        gameId: gameId,
        dayRecordId: dayRecordId,
        nominatorId: players[0].id,
        nomineeId: players[1].id,
        votes: votesFor([1, 2]), // 2 票 < 阈值 3
        players: players,
        todayNominations: [],
        allNominations: [],
      );
      expect(error, isNull);
      final noms = await db.nominationsDao.watchByGame(gameId).first;
      expect(noms.single.passed, isFalse);
    });

    test('辩护记录持久化（issue #56）', () async {
      await repo.addNomination(
        gameId: gameId,
        dayRecordId: dayRecordId,
        nominatorId: players[0].id,
        nomineeId: players[1].id,
        votes: votesFor([1, 2, 3]),
        players: players,
        todayNominations: [],
        allNominations: [],
        defenseText: '  我不是恶魔，X 号更可疑  ',
      );
      var noms = await db.nominationsDao.watchByGame(gameId).first;
      expect(noms.single.defenseText, '我不是恶魔，X 号更可疑'); // 已 trim

      // 不传或空 → null
      await repo.addNomination(
        gameId: gameId,
        dayRecordId: dayRecordId,
        nominatorId: players[2].id,
        nomineeId: players[3].id,
        votes: votesFor([1]),
        players: players,
        todayNominations: noms,
        allNominations: noms,
        defenseText: '   ',
      );
      noms = await db.nominationsDao.watchByGame(gameId).first;
      expect(noms.last.defenseText, isNull);
    });
  });

  group('deleteNomination（误录纠错，issue #83）', () {
    test('删除提名后死票释放', () async {
      await repo.addNomination(
        gameId: gameId,
        dayRecordId: dayRecordId,
        nominatorId: players[0].id,
        nomineeId: players[1].id,
        votes: votesFor([1, 7]), // 7 号（死）赞成 = 消耗死票
        players: players,
        todayNominations: [],
        allNominations: [],
      );
      var all = await db.nominationsDao.watchByGame(gameId).first;
      expect(NominationRules.deadVoteUsed(all, players[6].id), isTrue);

      await repo.deleteNomination(all.single.id);
      all = await db.nominationsDao.watchByGame(gameId).first;
      expect(all, isEmpty);
      // 死票已释放：实时计算，删后自动正确
      expect(NominationRules.deadVoteUsed(all, players[6].id), isFalse);
    });

    test('删除即将死亡者的提名后最高票重算', () {
      final noms = [
        nominationWithVotes(nominatorIndex: 0, nomineeIndex: 1, forCount: 5),
        nominationWithVotes(nominatorIndex: 2, nomineeIndex: 3, forCount: 4),
      ];
      // 删除前：5 票者即将死亡
      expect(
        (NominationRules.pendingExecution(noms, 6) as PendingExecution)
            .nomineeId,
        players[1].id,
      );
      // 删除 5 票那条 → 4 票者成为即将死亡
      final afterDelete = noms
          .where((n) => n.nomineePlayerId != players[1].id)
          .toList();
      expect(
        (NominationRules.pendingExecution(afterDelete, 6) as PendingExecution)
            .nomineeId,
        players[3].id,
      );
    });
  });
}
