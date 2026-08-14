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
  // asyncExpand 保持两层流都是活的：天记录或提名任一变化都刷新。
  return db.dayRecordsDao.watchByGame(gameId).asyncExpand((days) {
    final dayRecord = days.where((d) => d.dayNumber == day).firstOrNull;
    if (dayRecord == null) return Stream.value(<Nomination>[]);
    return db.nominationsDao.watchByDay(dayRecord.id);
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
  /// [defenseText] 为被提名者的辩护记录（可选，issue #56）。
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
    String? defenseText,
  }) async {
    final error = _validate(
      dayRecordId: dayRecordId,
      nominatorId: nominatorId,
      nomineeId: nomineeId,
      votes: votes,
      players: players,
      todayNominations: todayNominations,
      allNominations: allNominations,
      dayRecord: await _db.dayRecordsDao.getById(dayRecordId),
    );
    if (error != null) return error;

    await _db.nominationsDao.insertNomination(
      _buildCompanion(
        gameId: gameId,
        dayRecordId: dayRecordId,
        nominatorId: nominatorId,
        nomineeId: nomineeId,
        votes: votes,
        players: players,
        defenseText: defenseText,
      ),
    );
    return null;
  }

  /// 就地编辑一次提名（#160 #2 纠错闭环）。
  ///
  /// 校验时**排除 [existingId] 自身**（编辑同一提名者/被提名者不算重复，
  /// 其死票也不算已用），通过后在事务内删旧 + 插新（派生数据实时重算）。
  /// 返回错误消息，成功返回 null。
  Future<String?> replaceNomination({
    required int existingId,
    required int gameId,
    required int dayRecordId,
    required int nominatorId,
    required int nomineeId,
    required List<VoteEntry> votes,
    required List<Player> players,
    required List<Nomination> todayNominations,
    required List<Nomination> allNominations,
    String? defenseText,
  }) async {
    final error = _validate(
      dayRecordId: dayRecordId,
      nominatorId: nominatorId,
      nomineeId: nomineeId,
      votes: votes,
      players: players,
      todayNominations: todayNominations,
      allNominations: allNominations,
      dayRecord: await _db.dayRecordsDao.getById(dayRecordId),
      excludeNominationId: existingId,
    );
    if (error != null) return error;

    final companion = _buildCompanion(
      gameId: gameId,
      dayRecordId: dayRecordId,
      nominatorId: nominatorId,
      nomineeId: nomineeId,
      votes: votes,
      players: players,
      defenseText: defenseText,
    );
    await _db.transaction(() async {
      await _db.nominationsDao.deleteNomination(existingId);
      await _db.nominationsDao.insertNomination(companion);
    });
    return null;
  }

  /// 删除一条提名（误录纠错，issue #83）。
  ///
  /// 派生数据（当天最高票 `pendingExecution`、死票 `deadVoteUsed`、
  /// 提名次数限制）均为**实时计算**，删除后自动正确重算，无需级联。
  Future<void> deleteNomination(int id) =>
      _db.nominationsDao.deleteNomination(id);

  /// 校验一次提名（新增 / 编辑共用）。
  ///
  /// [excludeNominationId] 编辑时排除自身，避免「与旧版本冲突」误判。
  /// [dayRecord] 已查好的天记录（处决检查），调用方负责 async 查询。
  String? _validate({
    required int dayRecordId,
    required int nominatorId,
    required int nomineeId,
    required List<VoteEntry> votes,
    required List<Player> players,
    required List<Nomination> todayNominations,
    required List<Nomination> allNominations,
    required DayRecord? dayRecord,
    int? excludeNominationId,
  }) {
    final today = excludeNominationId == null
        ? todayNominations
        : todayNominations.where((n) => n.id != excludeNominationId).toList();
    final all = excludeNominationId == null
        ? allNominations
        : allNominations.where((n) => n.id != excludeNominationId).toList();

    // 防御纵深：提名者必须存活（官方死者不可提名，仅死票投票权）。
    final nominator = players.where((p) => p.id == nominatorId).firstOrNull;
    if (nominator != null && !nominator.isAlive) {
      return '提名者已死亡，不可提名';
    }
    if (NominationRules.hasNominatedToday(today, nominatorId)) {
      return '该玩家今天已提名过';
    }
    if (NominationRules.hasBeenNominatedToday(today, nomineeId)) {
      return '该玩家今天已被提名过';
    }
    // 处决已执行 → 当天提名阶段结束（#79，防御纵深）
    if (dayRecord != null && dayRecord.dayExecutionPlayerId != null) {
      return '今日已处决，提名阶段已结束';
    }
    // 死票校验
    for (final v in votes) {
      if (v.isDeadVote &&
          NominationRules.deadVoteUsed(all, v.playerId)) {
        return '该玩家的死票已用过';
      }
    }
    return null;
  }

  /// 构造一条提名的 companion（计算 passed + 序列化票 + 防御文案）。
  NominationsCompanion _buildCompanion({
    required int gameId,
    required int dayRecordId,
    required int nominatorId,
    required int nomineeId,
    required List<VoteEntry> votes,
    required List<Player> players,
    String? defenseText,
  }) {
    final aliveCount = players.where((p) => p.isAlive).length;
    final passed = NominationRules.isPassed(votes, aliveCount);
    final defense = defenseText?.trim();
    final hasDefense = defense != null && defense.isNotEmpty;
    return NominationsCompanion(
      gameId: Value(gameId),
      dayRecordId: Value(dayRecordId),
      nominatorPlayerId: Value(nominatorId),
      nomineePlayerId: Value(nomineeId),
      passed: Value(passed),
      voteResultJson: Value(
        jsonEncode(votes.map((v) => v.toJson()).toList()),
      ),
      defenseText: hasDefense ? Value(defense) : const Value.absent(),
    );
  }
}

/// 提名仓库 Provider。
final nominationRepositoryProvider = Provider<NominationRepository>(
  (ref) => NominationRepository(ref.watch(appDatabaseProvider)),
);
