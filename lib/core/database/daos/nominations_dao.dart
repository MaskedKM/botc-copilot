import 'package:botc_copilot/core/database/app_database.dart';
import 'package:drift/drift.dart';

part 'nominations_dao.g.dart';

/// 提名表 DAO。
@DriftAccessor(tables: [Nominations])
class NominationsDao extends DatabaseAccessor<AppDatabase>
    with _$NominationsDaoMixin {
  /// 创建 DAO。
  NominationsDao(super.db);

  /// 监听某天的全部提名（按创建顺序）。
  Stream<List<Nomination>> watchByDay(int dayRecordId) =>
      (select(nominations)
            ..where((n) => n.dayRecordId.equals(dayRecordId))
            ..orderBy([(n) => OrderingTerm.asc(n.id)]))
          .watch();

  /// 监听一局的全部提名。
  Stream<List<Nomination>> watchByGame(int gameId) =>
      (select(nominations)
            ..where((n) => n.gameId.equals(gameId))
            ..orderBy([(n) => OrderingTerm.asc(n.id)]))
          .watch();

  /// 新建提名。
  Future<int> insertNomination(NominationsCompanion entry) =>
      into(nominations).insert(entry);

  /// 更新提名（如补记投票）。
  Future<int> updateNomination(int id, NominationsCompanion entry) =>
      (update(nominations)..where((n) => n.id.equals(id))).write(entry);

  /// 删除提名。
  Future<int> deleteNomination(int id) =>
      (delete(nominations)..where((n) => n.id.equals(id))).go();
}
