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
  /// [mySeat] 我的座位号（1-based，可选）：在范围内时写入 games.myPlayerId，
  /// 开局即可在圆环上显示金色描边，无需等 MyInfoSheet 首次设置。
  Future<int> createGame({
    required Script script,
    required List<String> names,
    required Character myRole,
    List<Character> demonBluffs = const [],
    int? mySeat,
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
      // 写入「我的座位」（issue #70）：开局即点亮圆环金色描边。
      if (mySeat != null && mySeat >= 1 && mySeat <= names.length) {
        final players = await _db.playersDao.watchByGame(gameId).first;
        final me = players.where((p) => p.seatNumber == mySeat).firstOrNull;
        if (me != null) {
          await _db.gamesDao.updateMyPlayerId(gameId, me.id);
        }
      }
      return gameId;
    });
  }
}
