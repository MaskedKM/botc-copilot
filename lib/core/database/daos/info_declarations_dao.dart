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

  /// 把某玩家当夜已录的信息声明可靠性降级为 possiblyTainted（issue #122）。
  ///
  /// 用于 Poisoner 毒目标 / 手动标毒的回溯：中毒者当晚获得的信息为假
  /// （官方：能力失效、信息错误）。仅降级 verified / unverified；已
  /// possiblyTainted / invalidated 保持不变（不覆盖更强的判定）。
  Future<void> taintPlayerDeclarations(int dayRecordId, int playerId) async {
    final decls = await (select(infoDeclarations)
          ..where(
            (i) =>
                i.dayRecordId.equals(dayRecordId) & i.playerId.equals(playerId),
          ))
        .get();
    for (final d in decls) {
      if (d.reliability == Reliability.verified ||
          d.reliability == Reliability.unverified) {
        await (update(infoDeclarations)..where((i) => i.id.equals(d.id)))
            .write(const InfoDeclarationsCompanion(
                reliability: Value(Reliability.possiblyTainted)));
      }
    }
  }

  /// 删除信息声明。
  Future<int> deleteDeclaration(int id) =>
      (delete(infoDeclarations)..where((i) => i.id.equals(id))).go();
}
