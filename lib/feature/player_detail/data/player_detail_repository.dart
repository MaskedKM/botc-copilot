import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 玩家详情操作层：角色声明 / 信息声明 / 信任度写入。
class PlayerDetailRepository {
  /// 创建仓库。
  PlayerDetailRepository(this._db);

  final AppDatabase _db;

  /// 声明角色。
  ///
  /// 自动判定 claimType：该玩家此前无声明 = firstClaim，有 = changed。
  Future<int> claimRole({
    required int playerId,
    required int dayRecordId,
    required Character character,
  }) async {
    final existing = await (_db.select(_db.roleClaims)
          ..where((c) => c.playerId.equals(playerId)))
        .get();
    final type = existing.isEmpty ? ClaimType.firstClaim : ClaimType.changed;
    return _db.roleClaimsDao.insertClaim(
      RoleClaimsCompanion(
        playerId: Value(playerId),
        dayRecordId: Value(dayRecordId),
        character: Value(character),
        claimType: Value(type),
      ),
    );
  }

  /// 记录信息声明（payload 已按角色的 InfoInputType 编码为 JSON）。
  Future<int> declareInfo({
    required int playerId,
    required int dayRecordId,
    required Character character,
    required Map<String, Object?> payload,
  }) {
    return _db.infoDeclarationsDao.insertDeclaration(
      InfoDeclarationsCompanion(
        playerId: Value(playerId),
        dayRecordId: Value(dayRecordId),
        characterType: Value(character),
        payloadJson: Value(jsonEncode(payload)),
        reliability: const Value(Reliability.unverified),
      ),
    );
  }

  /// 调整信任度（追加一条 trust log）。
  Future<int> setTrustLevel({
    required int gameId,
    required int playerId,
    required int day,
    required TrustLevel level,
  }) {
    return _db.trustLogsDao.insertLog(
      TrustLogsCompanion(
        gameId: Value(gameId),
        playerId: Value(playerId),
        dayNumber: Value(day),
        trustLevel: Value(level),
      ),
    );
  }
}

/// 玩家详情仓库 Provider。
final playerDetailRepositoryProvider = Provider<PlayerDetailRepository>(
  (ref) => PlayerDetailRepository(ref.watch(appDatabaseProvider)),
);

/// 某玩家的角色声明历史。
final playerClaimsProvider =
    StreamProvider.family<List<RoleClaim>, int>((ref, playerId) {
  final db = ref.watch(appDatabaseProvider);
  return db.roleClaimsDao.watchByPlayer(playerId);
});

/// 某玩家的全部信息声明。
final playerDeclarationsProvider =
    StreamProvider.family<List<InfoDeclaration>, int>((ref, playerId) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.infoDeclarations)
        ..where((i) => i.playerId.equals(playerId))
        ..orderBy([(i) => OrderingTerm.asc(i.id)]))
      .watch();
});
