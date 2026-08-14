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
  ///
  /// 已死玩家为 no-op（不覆盖原有 deathDay/deathCause），防止处决死人时
  /// 抹掉其真实死亡信息（issue #80）。
  Future<int> markDead(int id, int day, DeathCause cause) =>
      (update(players)
            ..where(
              (p) => p.id.equals(id) & p.isAlive.equals(true),
            ))
          .write(
        PlayersCompanion(
          isAlive: const Value(false),
          deathDay: Value(day),
          deathCause: Value(cause),
        ),
      );

  /// 复活（撤销误标的死亡；同步清僵怖假死标记，#217 增量4B）。
  Future<int> revive(int id) =>
      (update(players)..where((p) => p.id.equals(id))).write(
        const PlayersCompanion(
          isAlive: Value(true),
          deathDay: Value(null),
          deathCause: Value(null),
          fakeDead: Value(false),
        ),
      );

  /// 僵怖假死（BMR，#217 增量4B）：登记为死但活着——`isAlive` 保持 true，
  /// `deathDay/Cause` 照常落库（邻座收缩按死亡重建时自动排除该玩家）。
  /// 仅对存活且未假死过的玩家生效（首次死亡才假死，第二次为真死）。
  Future<int> markFakeDead(int id, int day, DeathCause cause) =>
      (update(players)
            ..where(
              (p) => p.id.equals(id) & p.isAlive.equals(true) & p.fakeDead.equals(false),
            ))
          .write(
        PlayersCompanion(
          deathDay: Value(day),
          deathCause: Value(cause),
          fakeDead: const Value(true),
        ),
      );

  /// 手动标记/清除僵怖假死（详情页入口，#217 增量4B）。
  /// 与 [markFakeDead]（写 deathDay/Cause 的首次死亡路径）不同：只拨旗标，
  /// 供用户表达「我认为此人假死」的推测（官方登记语义由调用方解释）。
  Future<int> setFakeDeadFlag(int id, {required bool fake}) =>
      (update(players)..where((p) => p.id.equals(id)))
          .write(PlayersCompanion(fakeDead: Value(fake)));

  /// 标记一次性能力消耗状态（issue #54：Virgin / Slayer）。
  Future<int> markAbilityUsed(int id, {required bool used}) =>
      (update(players)..where((p) => p.id.equals(id))).write(
        PlayersCompanion(abilityUsed: Value(used)),
      );

  /// 标记/取消「疑似醉汉」（整局身份推测，issue #109）。
  Future<int> markSuspectedDrunk(int id, {required bool suspected}) =>
      (update(players)..where((p) => p.id.equals(id))).write(
        PlayersCompanion(suspectedDrunk: Value(suspected)),
      );

  /// 删除玩家。
  Future<int> deletePlayer(int id) =>
      (delete(players)..where((p) => p.id.equals(id))).go();
}
