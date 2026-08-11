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
  Stream<List<PoisonStatuse>> watchByGame(int gameId) {
    return (select(poisonStatuses)..where((p) => p.gameId.equals(gameId)))
        .watch();
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
}
