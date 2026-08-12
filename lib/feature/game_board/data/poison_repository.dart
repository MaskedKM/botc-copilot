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
  Future<void> toggleStatus({
    required int gameId,
    required int playerId,
    required int dayNumber,
    PoisonSource source = PoisonSource.poisoner,
  }) async {
    final hit =
        await _db.poisonStatusesDao.findByPlayerAndDay(playerId, dayNumber);
    if (hit != null) {
      await _db.poisonStatusesDao.deleteStatus(hit.id);
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
