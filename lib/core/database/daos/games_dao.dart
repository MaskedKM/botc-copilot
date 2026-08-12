import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart';

part 'games_dao.g.dart';

/// 对局表 DAO。
@DriftAccessor(tables: [Games])
class GamesDao extends DatabaseAccessor<AppDatabase> with _$GamesDaoMixin {
  /// 创建 DAO。
  GamesDao(super.db);

  /// 按创建时间倒序监听全部对局。
  Stream<List<Game>> watchAll() =>
      (select(games)..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
          .watch();

  /// 按 id 查询对局。
  Future<Game?> getById(int id) =>
      (select(games)..where((g) => g.id.equals(id))).getSingleOrNull();

  /// 按 id 监听单局（只监听该行变化）。
  Stream<Game?> watchById(int id) =>
      (select(games)..where((g) => g.id.equals(id))).watchSingleOrNull();

  /// 新建对局。
  Future<int> insertGame(GamesCompanion entry) => into(games).insert(entry);

  /// 更新对局状态。
  Future<int> updateStatus(int id, GameStatus status) =>
      (update(games)..where((g) => g.id.equals(id)))
          .write(GamesCompanion(status: Value(status)));

  /// 设置"我的角色"。
  Future<int> updateMyRole(int id, Character role) =>
      (update(games)..where((g) => g.id.equals(id)))
          .write(GamesCompanion(myRole: Value(role)));

  /// 设置"我的座位"。
  Future<int> updateMyPlayerId(int id, int playerId) =>
      (update(games)..where((g) => g.id.equals(id)))
          .write(GamesCompanion(myPlayerId: Value(playerId)));

  /// 设置帮助层级。
  Future<int> updateHelpLevel(int id, HelpLevel level) =>
      (update(games)..where((g) => g.id.equals(id)))
          .write(GamesCompanion(helpLevel: Value(level)));

  /// 设置恶魔 Bluff（JSON 字符串）。
  Future<int> updateDemonBluffs(int id, String bluffsJson) =>
      (update(games)..where((g) => g.id.equals(id)))
          .write(GamesCompanion(demonBluffsJson: Value(bluffsJson)));

  /// 设置恶魔私密爪牙名单（JSON 玩家 id 数组字符串，issue #108）。
  Future<int> updateMyMinionIds(int id, String minionIdsJson) =>
      (update(games)..where((g) => g.id.equals(id)))
          .write(GamesCompanion(myMinionIdsJson: Value(minionIdsJson)));

  /// 删除对局（级联删除玩家/每日记录等）。
  Future<int> deleteGame(int id) =>
      (delete(games)..where((g) => g.id.equals(id))).go();
}
