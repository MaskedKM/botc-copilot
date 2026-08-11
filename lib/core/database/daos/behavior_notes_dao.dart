import 'package:botc_copilot/core/database/app_database.dart';
import 'package:drift/drift.dart';

part 'behavior_notes_dao.g.dart';

/// 行为备注 DAO（issue #36）。
@DriftAccessor(tables: [BehaviorNotes])
class BehaviorNotesDao extends DatabaseAccessor<AppDatabase>
    with _$BehaviorNotesDaoMixin {
  /// 创建 DAO。
  BehaviorNotesDao(super.db);

  /// 监听某对局的全部备注（按天+时间排序）。
  Stream<List<BehaviorNote>> watchByGame(int gameId) {
    return (select(behaviorNotes)
          ..where((n) => n.gameId.equals(gameId))
          ..orderBy([
            (n) => OrderingTerm.asc(n.dayNumber),
            (n) => OrderingTerm.asc(n.createdAt),
          ]))
        .watch();
  }

  /// 监听某玩家的全部备注。
  Stream<List<BehaviorNote>> watchByPlayer(int playerId) {
    return (select(behaviorNotes)
          ..where((n) => n.playerId.equals(playerId))
          ..orderBy([
            (n) => OrderingTerm.asc(n.dayNumber),
            (n) => OrderingTerm.asc(n.createdAt),
          ]))
        .watch();
  }

  /// 监听某玩家当天的备注。
  Stream<List<BehaviorNote>> watchByPlayerAndDay(int playerId, int dayNumber) {
    return (select(behaviorNotes)
          ..where((n) => n.playerId.equals(playerId))
          ..where((n) => n.dayNumber.equals(dayNumber))
          ..orderBy([(n) => OrderingTerm.asc(n.createdAt)]))
        .watch();
  }

  /// 插入备注。
  Future<int> insertNote(BehaviorNotesCompanion entry) {
    return into(behaviorNotes).insert(entry);
  }

  /// 删除备注。
  Future<int> deleteNote(int id) {
    return (delete(behaviorNotes)..where((n) => n.id.equals(id))).go();
  }
}
