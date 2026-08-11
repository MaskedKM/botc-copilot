import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart';

part 'players_dao.g.dart';

/// 玩家表 DAO。
@DriftAccessor(tables: [Players])
class PlayersDao extends DatabaseAccessor<AppDatabase>
    with _$PlayersDaoMixin {
  /// 创建 DAO。
  PlayersDao(super.db);

  /// 按座位号顺序监听一局的所有玩家。
  Stream<List<Player>> watchByGame(int gameId) => (select(players)
        ..where((p) => p.gameId.equals(gameId))
        ..orderBy([(p) => OrderingTerm.asc(p.seatNumber)]))
      .watch();

  /// 批量插入玩家（开局设置用）。
  Future<void> insertAll(List<PlayersCompanion> entries) =>
      batch((b) => b.insertAll(players, entries));

  /// 更新玩家信息。
  Future<int> updatePlayer(int id, PlayersCompanion entry) =>
      (update(players)..where((p) => p.id.equals(id))).write(entry);

  /// 标记死亡（记录死亡天数与原因）。
  Future<int> markDead(int id, int day, DeathCause cause) =>
      (update(players)..where((p) => p.id.equals(id))).write(
        PlayersCompanion(
          isAlive: const Value(false),
          deathDay: Value(day),
          deathCause: Value(cause),
        ),
      );

  /// 复活（撤销误标的死亡）。
  Future<int> revive(int id) =>
      (update(players)..where((p) => p.id.equals(id))).write(
        const PlayersCompanion(
          isAlive: Value(true),
          deathDay: Value(null),
          deathCause: Value(null),
        ),
      );

  /// 删除玩家。
  Future<int> deletePlayer(int id) =>
      (delete(players)..where((p) => p.id.equals(id))).go();
}
