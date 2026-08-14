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
    // 整体包事务（#150 R2）：reliability 决策 → 插入 → 回溯降级须原子。
    // 用 get 查询（事务内 await stream 的 .first 会挂起，须用 .get）。
    return _db.transaction(() async {
      // (b) 当夜 Poisoner 是否毒了本玩家（#122）
      final dayDecls = await _db.infoDeclarationsDao.getByDay(dayRecordId);
      final poisonerTargeted = dayDecls.any((d) {
        if (d.characterType != Character.poisoner) return false;
        try {
          final decoded = jsonDecode(d.payloadJson);
          return decoded is Map && decoded['playerId'] == playerId;
        } on FormatException {
          return false;
        }
      });
      // (a) 手动标毒：findByPlayerAndDay 按 (player,day) 查（playerId 全局唯一，
      // 叠加唯一约束保证单行，getSingleOrNull 不会多行抛异常，#150 B1）。
      final manualTainted = (dayNumber != null && gameId != null) &&
          ((await _db.poisonStatusesDao.findByPlayerAndDay(
                playerId,
                dayNumber,
              ))?.isActive ??
              false);
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
    });
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

  /// 标记/取消「疑似醉汉」（整局身份推测，issue #109）。
  Future<int> setSuspectedDrunk(int playerId, {required bool suspected}) =>
      _db.playersDao.markSuspectedDrunk(playerId, suspected: suspected);

  /// 标记/清除僵怖假死（BMR，#217 增量4B；详情页即时落库）。
  Future<int> setFakeDead(int playerId, {required bool fake}) =>
      _db.playersDao.setFakeDeadFlag(playerId, fake: fake);

  /// 删除一条信息声明（误录纠错，issue #83）。
  ///
  /// 若删除的是 Poisoner 声明，且其毒目标当夜无残留毒源（无其他 Poisoner
  /// 声明 / 手动标毒），则恢复毒目标当夜信息的 reliability（#122 对称）。
  Future<void> deleteDeclaration(int id) async {
    // 整体包事务（#150 R3）：删 Poisoner 声明中断 → 毒目标 reliability 不恢复。
    await _db.transaction(() async {
      final decl = await _db.infoDeclarationsDao.getById(id);
      await _db.infoDeclarationsDao.deleteDeclaration(id);
      if (decl != null && decl.characterType == Character.poisoner) {
        try {
          final decoded = jsonDecode(decl.payloadJson);
          if (decoded is Map && decoded['playerId'] is int) {
            final target = decoded['playerId'] as int;
            if (!await _db.infoDeclarationsDao
                .isPlayerPoisonedFromSources(decl.dayRecordId, target)) {
              await _db.infoDeclarationsDao.restorePlayerDeclarations(
                decl.dayRecordId,
                target,
              );
            }
          }
        } on FormatException {
          // payload 异常，跳过恢复
        }
      }
    });
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

/// 某对局全部天数记录流。
///
/// 信息声明只存 [InfoDeclaration.dayRecordId]（外键），无直接天数；
/// 信息历史视图需据此把 dayRecordId 解析为「第 N 天」展示（issue #71）。
final gameDayRecordsProvider =
    StreamProvider.family<List<DayRecord>, int>((ref, gameId) {
  return ref.watch(appDatabaseProvider).dayRecordsDao.watchByGame(gameId);
});
