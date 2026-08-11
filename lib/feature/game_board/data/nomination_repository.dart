import 'dart:convert';

import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/domain/nomination_rules.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 某局某天的提名列表。
final dayNominationsProvider =
    StreamProvider.family<List<Nomination>, (int gameId, int day)>(
        (ref, key) {
  final db = ref.watch(appDatabaseProvider);
  final (gameId, day) = key;
  // 经 day_records 关联过滤到某天
  return db.dayRecordsDao.watchByGame(gameId).asyncMap((days) async {
    final dayRecord = days.where((d) => d.dayNumber == day).firstOrNull;
    if (dayRecord == null) return <Nomination>[];
    return db.nominationsDao.watchByDay(dayRecord.id).first;
  });
});

/// 某局的全部提名（死票使用检查用）。
final gameNominationsProvider =
    StreamProvider.family<List<Nomination>, int>((ref, gameId) {
  final db = ref.watch(appDatabaseProvider);
  return db.nominationsDao.watchByGame(gameId);
});

/// 提名操作层。
class NominationRepository {
  /// 创建仓库。
  NominationRepository(this._db);

  final AppDatabase _db;

  /// 录入一次提名 + 投票结果。
  ///
  /// 自动计算 passed（赞成票 ≥ 存活人数一半）。
  /// 返回错误消息（校验失败时），成功返回 null。
  Future<String?> addNomination({
    required int gameId,
    required int dayRecordId,
    required int nominatorId,
    required int nomineeId,
    required List<VoteEntry> votes,
    required List<Player> players,
    required List<Nomination> todayNominations,
    required List<Nomination> allNominations,
  }) async {
    // 规则校验
    if (NominationRules.hasNominatedToday(todayNominations, nominatorId)) {
      return '该玩家今天已提名过';
    }
    if (NominationRules.hasBeenNominatedToday(todayNominations, nomineeId)) {
      return '该玩家今天已被提名过';
    }
    // 死票校验
    for (final v in votes) {
      if (v.isDeadVote &&
          NominationRules.deadVoteUsed(allNominations, v.playerId)) {
        return '该玩家的死票已用过';
      }
    }

    final aliveCount = players.where((p) => p.isAlive).length;
    final passed = NominationRules.isPassed(votes, aliveCount);

    await _db.nominationsDao.insertNomination(
      NominationsCompanion(
        gameId: Value(gameId),
        dayRecordId: Value(dayRecordId),
        nominatorPlayerId: Value(nominatorId),
        nomineePlayerId: Value(nomineeId),
        passed: Value(passed),
        voteResultJson: Value(
          jsonEncode(votes.map((v) => v.toJson()).toList()),
        ),
      ),
    );
    return null;
  }
}

/// 提名仓库 Provider。
final nominationRepositoryProvider = Provider<NominationRepository>(
  (ref) => NominationRepository(ref.watch(appDatabaseProvider)),
);
