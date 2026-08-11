import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 某对局的全部行为备注流。
final gameBehaviorNotesProvider =
    StreamProvider.family<List<BehaviorNote>, int>((ref, gameId) {
  return ref.watch(appDatabaseProvider).behaviorNotesDao.watchByGame(gameId);
});

/// 某玩家的全部行为备注流。
final playerBehaviorNotesProvider =
    StreamProvider.family<List<BehaviorNote>, int>((ref, playerId) {
  return ref
      .watch(appDatabaseProvider)
      .behaviorNotesDao
      .watchByPlayer(playerId);
});

/// 某玩家当天的行为备注流。
final playerDayNotesProvider =
    StreamProvider.family<List<BehaviorNote>, (int playerId, int day)>(
        (ref, key) {
  final (playerId, day) = key;
  return ref
      .watch(appDatabaseProvider)
      .behaviorNotesDao
      .watchByPlayerAndDay(playerId, day);
});

/// 行为备注仓库（issue #36）。
class BehaviorNoteRepository {
  /// 创建仓库。
  BehaviorNoteRepository(this._db);

  final AppDatabase _db;

  /// 给某玩家当天加一条备注。
  Future<int> addNote({
    required int gameId,
    required int playerId,
    required int dayNumber,
    required String note,
  }) {
    return _db.behaviorNotesDao.insertNote(
      BehaviorNotesCompanion(
        gameId: Value(gameId),
        playerId: Value(playerId),
        dayNumber: Value(dayNumber),
        note: Value(note),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  /// 删除备注。
  Future<int> deleteNote(int id) {
    return _db.behaviorNotesDao.deleteNote(id);
  }
}

/// 行为备注仓库 Provider。
final behaviorNoteRepositoryProvider = Provider<BehaviorNoteRepository>(
  (ref) => BehaviorNoteRepository(ref.watch(appDatabaseProvider)),
);
