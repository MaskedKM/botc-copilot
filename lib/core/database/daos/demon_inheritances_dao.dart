import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart';

part 'demon_inheritances_dao.g.dart';

/// 恶魔传承事件表 DAO（issue #89）。
@DriftAccessor(tables: [DemonInheritances])
class DemonInheritancesDao extends DatabaseAccessor<AppDatabase>
    with _$DemonInheritancesDaoMixin {
  /// 创建 DAO。
  DemonInheritancesDao(super.db);

  /// 监听一局的全部传承事件（按 id 升序，append-only）。
  Stream<List<DemonInheritance>> watchByGame(int gameId) =>
      (select(demonInheritances)
            ..where((t) => t.gameId.equals(gameId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  /// 取一局最新一次传承（推理面板「当前恶魔」用）。
  Future<DemonInheritance?> getLatestByGame(int gameId) =>
      (select(demonInheritances)
            ..where((t) => t.gameId.equals(gameId))
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingleOrNull();

  /// 该局是否已发生过绯红女传承（SW 仅首次触发判定）。
  Future<bool> hasScarletWomanSuccession(int gameId) async {
    final result = await (select(demonInheritances)
          ..where(
            (t) =>
                t.gameId.equals(gameId) &
                t.trigger.equals(SuccessionTrigger.scarletWoman.name),
          )
          ..limit(1))
        .get();
    return result.isNotEmpty;
  }

  /// 记录一次传承。
  Future<int> insertSuccession(DemonInheritancesCompanion entry) =>
      into(demonInheritances).insert(entry);
}
