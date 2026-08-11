import 'dart:convert';
import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart';

/// 开局设置仓库：把设置结果写入数据库。
class SetupRepository {
  /// 创建仓库。
  SetupRepository(this._db);

  final AppDatabase _db;

  /// 创建对局 + 全部玩家（事务）。
  ///
  /// 返回新对局 id。玩家座位号按 [names] 顺序从 1 开始。
  /// [demonBluffs] 仅当我是恶魔时传入（最多 3 个不在场角色）。
  Future<int> createGame({
    required Script script,
    required List<String> names,
    required Character myRole,
    List<Character> demonBluffs = const [],
  }) {
    return _db.transaction(() async {
      final gameId = await _db.gamesDao.insertGame(
        GamesCompanion(
          script: Value(script),
          playerCount: Value(names.length),
          status: const Value(GameStatus.ongoing),
          createdAt: Value(DateTime.now()),
          myRole: Value(myRole),
          demonBluffsJson: demonBluffs.isEmpty
              ? const Value.absent()
              : Value(
                  jsonEncode(demonBluffs.map((c) => c.name).toList()),
                ),
        ),
      );
      await _db.playersDao.insertAll([
        for (var i = 0; i < names.length; i++)
          PlayersCompanion(
            gameId: Value(gameId),
            name: Value(names[i].trim()),
            seatNumber: Value(i + 1),
          ),
      ]);
      return gameId;
    });
  }
}
