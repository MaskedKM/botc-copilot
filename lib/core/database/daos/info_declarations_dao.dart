import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart';

part 'info_declarations_dao.g.dart';

/// 信息声明表 DAO。
@DriftAccessor(tables: [InfoDeclarations, DayRecords])
class InfoDeclarationsDao extends DatabaseAccessor<AppDatabase>
    with _$InfoDeclarationsDaoMixin {
  /// 创建 DAO。
  InfoDeclarationsDao(super.db);

  /// 监听某天的全部信息声明。
  Stream<List<InfoDeclaration>> watchByDay(int dayRecordId) =>
      (select(infoDeclarations)
            ..where((i) => i.dayRecordId.equals(dayRecordId)))
          .watch();

  /// 监听一局的全部信息声明（跨天，经每日记录关联）。
  Stream<List<InfoDeclaration>> watchByGame(int gameId) {
    final query = select(infoDeclarations).join([
      innerJoin(
        dayRecords,
        dayRecords.id.equalsExp(infoDeclarations.dayRecordId),
      ),
    ])..where(dayRecords.gameId.equals(gameId));
    return query.watch().map(
          (rows) => rows.map((r) => r.readTable(infoDeclarations)).toList(),
        );
  }

  /// 新建信息声明。
  Future<int> insertDeclaration(InfoDeclarationsCompanion entry) =>
      into(infoDeclarations).insert(entry);

  /// 更新信息可靠性（醉/毒状态变化时）。
  Future<int> updateReliability(int id, Reliability reliability) =>
      (update(infoDeclarations)..where((i) => i.id.equals(id)))
          .write(InfoDeclarationsCompanion(reliability: Value(reliability)));

  /// 删除信息声明。
  Future<int> deleteDeclaration(int id) =>
      (delete(infoDeclarations)..where((i) => i.id.equals(id))).go();
}
