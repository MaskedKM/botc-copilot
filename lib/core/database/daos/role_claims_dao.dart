import 'package:botc_copilot/core/database/app_database.dart';
import 'package:drift/drift.dart';

part 'role_claims_dao.g.dart';

/// 角色声明表 DAO。
@DriftAccessor(tables: [RoleClaims, DayRecords])
class RoleClaimsDao extends DatabaseAccessor<AppDatabase>
    with _$RoleClaimsDaoMixin {
  /// 创建 DAO。
  RoleClaimsDao(super.db);

  /// 监听某天的全部角色声明。
  Stream<List<RoleClaim>> watchByDay(int dayRecordId) =>
      (select(roleClaims)..where((c) => c.dayRecordId.equals(dayRecordId)))
          .watch();

  /// 监听一局的全部角色声明（跨天，经每日记录关联）。
  Stream<List<RoleClaim>> watchByGame(int gameId) {
    final query = select(roleClaims).join([
      innerJoin(
        dayRecords,
        dayRecords.id.equalsExp(roleClaims.dayRecordId),
      ),
    ])
      ..where(dayRecords.gameId.equals(gameId))
      // 显式按 id 升序，保证「后者覆盖前者」取最新声明语义稳定（review）
      ..orderBy([OrderingTerm.asc(roleClaims.id)]);
    return query.watch().map(
          (rows) => rows.map((r) => r.readTable(roleClaims)).toList(),
        );
  }

  /// 监听某玩家的全部角色声明（按时间顺序）。
  Stream<List<RoleClaim>> watchByPlayer(int playerId) =>
      (select(roleClaims)
            ..where((c) => c.playerId.equals(playerId))
            ..orderBy([(c) => OrderingTerm.asc(c.id)]))
          .watch();

  /// 新建角色声明。
  Future<int> insertClaim(RoleClaimsCompanion entry) =>
      into(roleClaims).insert(entry);

  /// 更新角色声明。
  Future<int> updateClaim(int id, RoleClaimsCompanion entry) =>
      (update(roleClaims)..where((c) => c.id.equals(id))).write(entry);

  /// 删除角色声明。
  Future<int> deleteClaim(int id) =>
      (delete(roleClaims)..where((c) => c.id.equals(id))).go();
}
