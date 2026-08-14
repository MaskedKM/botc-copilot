import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 某对局的醉/毒状态流。
final gamePoisonStatusesProvider =
    StreamProvider.family<List<PoisonStatus>, int>((ref, gameId) {
  return ref.watch(appDatabaseProvider).poisonStatusesDao.watchByGame(gameId);
});

/// 醉/毒状态仓库（issue #35）。
class PoisonRepository {
  /// 创建仓库。
  PoisonRepository(this._db);

  final AppDatabase _db;

  /// 切换某玩家当天的醉/毒标记：已存在则删除，不存在则插入。
  ///
  /// 整体包事务（#150 R1）：read hit → delete/insert + restore/taint 派生写
  /// 须原子，否则快速连点 / TOCTOU 可插重复行（叠加 #150 B1 唯一约束兜底）。
  Future<void> toggleStatus({
    required int gameId,
    required int playerId,
    required int dayNumber,
    PoisonSource source = PoisonSource.poisoner,
  }) async {
    await _db.transaction(() async {
      final hit =
          await _db.poisonStatusesDao.findByPlayerAndDay(playerId, dayNumber);
      if (hit != null) {
        await _db.poisonStatusesDao.deleteStatus(hit.id);
        // 取消标毒 → 若无残留毒源（Poisoner 声明）则恢复该玩家当夜信息（#122 对称）
        final dayRecord =
            await _db.dayRecordsDao.getByGameAndDay(gameId, dayNumber);
        if (dayRecord != null &&
            !await _db.infoDeclarationsDao
                .isPlayerPoisonedFromSources(dayRecord.id, playerId)) {
          await _db.infoDeclarationsDao.restorePlayerDeclarations(
            dayRecord.id,
            playerId,
          );
        }
      } else {
        await _db.poisonStatusesDao.insertStatus(
          PoisonStatusesCompanion(
            gameId: Value(gameId),
            playerId: Value(playerId),
            dayNumber: Value(dayNumber),
            source: Value(source),
          ),
        );
        // 回溯（#122）：手动标毒 → 该玩家当夜已录信息降级（与 Poisoner 目标对称）
        final dayRecord =
            await _db.dayRecordsDao.getByGameAndDay(gameId, dayNumber);
        if (dayRecord != null) {
          await _db.infoDeclarationsDao.taintPlayerDeclarations(
            dayRecord.id,
            playerId,
          );
        }
      }
    });
  }

  /// 和平主义者醉潮（BMR，#217 增量4C）当日批量开关。
  ///
  /// 官方：爪牙被处决时，其余所有玩家（除旅行者）醉至次日黄昏。
  /// 开 = 为所有尚无醉/毒标记的玩家补一条 [PoisonSource.minstrel] 记录
  /// （已有标记者不覆盖来源）；关 = 删除当日全部醉潮记录并按 #122 对称
  /// 恢复（无其他毒源时）。整体事务（#150 R1 同理）。
  Future<void> setMinstrelTide({
    required int gameId,
    required List<int> playerIds,
    required int dayNumber,
    required bool on,
  }) async {
    await _db.transaction(() async {
      final all = await _db.poisonStatusesDao.watchByGame(gameId).first;
      final dayRows =
          all.where((p) => p.dayNumber == dayNumber).toList();
      final dayRecord =
          await _db.dayRecordsDao.getByGameAndDay(gameId, dayNumber);
      if (on) {
        final marked = dayRows.map((p) => p.playerId).toSet();
        for (final pid in playerIds.where((id) => !marked.contains(id))) {
          await _db.poisonStatusesDao.insertStatus(
            PoisonStatusesCompanion(
              gameId: Value(gameId),
              playerId: Value(pid),
              dayNumber: Value(dayNumber),
              source: Value(PoisonSource.minstrel),
            ),
          );
        }
        if (dayRecord != null) {
          // 回溯（#122）：当日已录信息全部降级（醉=毒，公理4）。
          for (final pid in playerIds) {
            await _db.infoDeclarationsDao
                .taintPlayerDeclarations(dayRecord.id, pid);
          }
        }
      } else {
        final tideRows = dayRows
            .where((p) => p.source == PoisonSource.minstrel)
            .toList();
        for (final row in tideRows) {
          await _db.poisonStatusesDao.deleteStatus(row.id);
        }
        if (dayRecord != null) {
          for (final row in tideRows) {
            if (!await _db.infoDeclarationsDao
                .isPlayerPoisonedFromSources(dayRecord.id, row.playerId)) {
              await _db.infoDeclarationsDao.restorePlayerDeclarations(
                dayRecord.id,
                row.playerId,
              );
            }
          }
        }
      }
    });
  }

  /// 某玩家当天是否有生效的醉/毒标记（供录入信息时自动降级可靠性）。
  Future<bool> isTainted({
    required int gameId,
    required int playerId,
    required int dayNumber,
  }) async {
    final all = await _db.poisonStatusesDao.watchByGame(gameId).first;
    return all.any(
      (p) =>
          p.playerId == playerId &&
          p.dayNumber == dayNumber &&
          p.isActive,
    );
  }
}

/// 醉/毒状态仓库 Provider。
final poisonRepositoryProvider = Provider<PoisonRepository>(
  (ref) => PoisonRepository(ref.watch(appDatabaseProvider)),
);
