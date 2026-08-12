import 'package:botc_copilot/core/database/app_database.dart';
import 'package:drift/drift.dart';

part 'day_records_dao.g.dart';

/// 每日记录表 DAO。
@DriftAccessor(tables: [DayRecords])
class DayRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$DayRecordsDaoMixin {
  /// 创建 DAO。
  DayRecordsDao(super.db);

  /// 按天数顺序监听一局的所有每日记录。
  Stream<List<DayRecord>> watchByGame(int gameId) => (select(dayRecords)
        ..where((d) => d.gameId.equals(gameId))
        ..orderBy([(d) => OrderingTerm.asc(d.dayNumber)]))
      .watch();

  /// 查询某局某天的记录。
  Future<DayRecord?> getByGameAndDay(int gameId, int dayNumber) =>
      (select(dayRecords)
            ..where(
              (d) => d.gameId.equals(gameId) & d.dayNumber.equals(dayNumber),
            ))
          .getSingleOrNull();

  /// 按 id 查询每日记录。
  Future<DayRecord?> getById(int id) =>
      (select(dayRecords)..where((d) => d.id.equals(id))).getSingleOrNull();

  /// 新建每日记录。
  Future<int> insertDay(DayRecordsCompanion entry) =>
      into(dayRecords).insert(entry);

  /// 更新每日记录。
  Future<int> updateDay(int id, DayRecordsCompanion entry) =>
      (update(dayRecords)..where((d) => d.id.equals(id))).write(entry);

  /// 删除每日记录。
  Future<int> deleteDay(int id) =>
      (delete(dayRecords)..where((d) => d.id.equals(id))).go();
}
