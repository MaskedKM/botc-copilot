import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart';

part 'trust_logs_dao.g.dart';

/// 信任度变更日志表 DAO。
@DriftAccessor(tables: [TrustLogs])
class TrustLogsDao extends DatabaseAccessor<AppDatabase>
    with _$TrustLogsDaoMixin {
  /// 创建 DAO。
  TrustLogsDao(super.db);

  /// 监听一局的全部信任度日志（按天数、id 排序）。
  Stream<List<TrustLog>> watchByGame(int gameId) => (select(trustLogs)
        ..where((t) => t.gameId.equals(gameId))
        ..orderBy([
          (t) => OrderingTerm.asc(t.dayNumber),
          (t) => OrderingTerm.asc(t.id),
        ]))
      .watch();

  /// 监听某玩家在一局中的最新信任度。
  Stream<TrustLog?> watchLatestForPlayer(int gameId, int playerId) =>
      (select(trustLogs)
            ..where(
              (t) => t.gameId.equals(gameId) & t.playerId.equals(playerId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .watchSingleOrNull();

  /// 记录一次信任度变更。
  Future<int> insertLog(TrustLogsCompanion entry) =>
      into(trustLogs).insert(entry);

  /// 更新某玩家在某天的信任度。
  Future<int> updateLevel(int id, TrustLevel level) =>
      (update(trustLogs)..where((t) => t.id.equals(id)))
          .write(TrustLogsCompanion(trustLevel: Value(level)));

  /// 删除日志。
  Future<int> deleteLog(int id) =>
      (delete(trustLogs)..where((t) => t.id.equals(id))).go();
}
