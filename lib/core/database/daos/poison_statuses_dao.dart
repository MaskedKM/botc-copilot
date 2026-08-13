import 'package:botc_copilot/core/database/app_database.dart';
import 'package:drift/drift.dart';

part 'poison_statuses_dao.g.dart';

/// 醉/毒状态 DAO（issue #35）。
@DriftAccessor(tables: [PoisonStatuses])
class PoisonStatusesDao extends DatabaseAccessor<AppDatabase>
    with _$PoisonStatusesDaoMixin {
  /// 创建 DAO。
  PoisonStatusesDao(super.db);

  /// 监听某对局的全部醉/毒状态。
  Stream<List<PoisonStatus>> watchByGame(int gameId) {
    return (select(poisonStatuses)..where((p) => p.gameId.equals(gameId)))
        .watch();
  }

  /// 查询某玩家当天的醉/毒标记。
  Future<PoisonStatus?> findByPlayerAndDay(int playerId, int dayNumber) {
    return (select(poisonStatuses)
          ..where((p) => p.playerId.equals(playerId))
          ..where((p) => p.dayNumber.equals(dayNumber)))
        .getSingleOrNull();
  }

  /// 插入醉/毒标记。
  Future<int> insertStatus(PoisonStatusesCompanion entry) {
    return into(poisonStatuses).insert(entry);
  }

  /// 解除（isActive=false）。
  Future<int> deactivate(int id) =>
      (update(poisonStatuses)..where((p) => p.id.equals(id)))
          .write(const PoisonStatusesCompanion(isActive: Value(false)));

  /// 删除。
  Future<int> deleteStatus(int id) {
    return (delete(poisonStatuses)..where((p) => p.id.equals(id))).go();
  }

  /// 删除某局某天的全部醉/毒标记（回退当天时清理孤儿，#154 R-1）。
  Future<int> deleteByGameAndDay(int gameId, int dayNumber) {
    return (delete(poisonStatuses)
          ..where(
            (p) => p.gameId.equals(gameId) & p.dayNumber.equals(dayNumber),
          ))
        .go();
  }
}
