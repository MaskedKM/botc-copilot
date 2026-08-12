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
  /// 查写包在同一事务中，防快速连点产生两条 firstClaim。
  Future<int> claimRole({
    required int playerId,
    required int dayRecordId,
    required Character character,
  }) {
    return _db.transaction(() async {
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
    });
  }

  /// 记录信息声明（payload 已按角色的 InfoInputType 编码为 JSON）。
  ///
  /// 可靠性自动判定（官方：中毒/醉酒者当晚信息为假）：玩家当晚被毒则降级为
  /// possiblyTainted。两个来源——(a) 手动标毒 PoisonStatuses；(b) 当夜有
  /// Poisoner 声明以其为目标（issue #122）。若本条本身是 Poisoner 声明，
  /// 录入后回溯降级其毒目标当夜已录的信息（覆盖「目标先录、Poisoner 后录」）。
  Future<int> declareInfo({
    required int playerId,
    required int dayRecordId,
    required Character character,
    required Map<String, Object?> payload,
    bool isMine = false,
    int? dayNumber,
    int? gameId,
  }) async {
    // (b) 当夜 Poisoner 是否毒了本玩家（#122）
    final dayDecls =
        await _db.infoDeclarationsDao.watchByDay(dayRecordId).first;
    final poisonerTargeted = dayDecls.any((d) {
      if (d.characterType != Character.poisoner) return false;
      try {
        final decoded = jsonDecode(d.payloadJson);
        return decoded is Map && decoded['playerId'] == playerId;
      } on FormatException {
        return false;
      }
    });
    // (a) 手动标毒
    final manualTainted = (dayNumber != null && gameId != null) &&
        (await _db.poisonStatusesDao.watchByGame(gameId).first).any(
          (s) =>
              s.playerId == playerId &&
              s.dayNumber == dayNumber &&
              s.isActive,
        );
    final reliability = (poisonerTargeted || manualTainted)
        ? Reliability.possiblyTainted
        : Reliability.unverified;

    final id = await _db.infoDeclarationsDao.insertDeclaration(
      InfoDeclarationsCompanion(
        playerId: Value(playerId),
        dayRecordId: Value(dayRecordId),
        characterType: Value(character),
        payloadJson: Value(jsonEncode(payload)),
        reliability: Value(reliability),
        isMine: Value(isMine),
      ),
    );

    // 回溯（#122）：本条是 Poisoner 声明 → 毒目标当夜已录信息降级
    if (character == Character.poisoner && payload['playerId'] is int) {
      await _db.infoDeclarationsDao.taintPlayerDeclarations(
        dayRecordId,
        payload['playerId'] as int,
      );
    }
    return id;
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

  /// 删除一条信息声明（误录纠错，issue #83）。
  Future<void> deleteDeclaration(int id) =>
      _db.infoDeclarationsDao.deleteDeclaration(id);
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
