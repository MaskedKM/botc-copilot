import 'dart:convert';

import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 对局导出仓储（issue #218）。
///
/// 单局全量导出为 JSON 字符串（对局 / 玩家 / 天记录 / 声明 / 信息 /
/// 提名 / 毒态 / 备注 / 传承 / 信任日志九张表），用于备份与复盘分享，
/// 亦为复盘模式（#17）与 AI 分析（#18）的数据基础。
///
/// **不含**：表间外键 id 关系以外的本地私有信息（如 db 自增 id 保留原值，
/// 导入恢复时须重映射——本 PR 仅导出，导入留待后续）。
class GameExportRepository {
  /// 创建仓储。
  GameExportRepository(this._db);

  final AppDatabase _db;

  /// 导出单局全量 JSON。
  ///
  /// 对局不存在 → null。表行以 drift dataclass 的 toJson 序列化。
  /// 注意：drift 事务内不能用 .watch()/.first（挂起，见 drift gotcha），
  /// 故顺序取各表首帧——本地单用户 App 并发写入窗口极小，可接受。
  Future<String?> exportGameJson(int gameId) async {
    final game = await _db.gamesDao.getById(gameId);
    if (game == null) return null;

    Future<List<T>> all<T>(Stream<List<T>> s) => s.first;
    final players = await all(_db.playersDao.watchByGame(gameId));
    final days = await all(_db.dayRecordsDao.watchByGame(gameId));
    final claims = await all(_db.roleClaimsDao.watchByGame(gameId));
    final declarations = await all(_db.infoDeclarationsDao.watchByGame(gameId));
    final nominations = await all(_db.nominationsDao.watchByGame(gameId));
    final poisons = await all(_db.poisonStatusesDao.watchByGame(gameId));
    final notes = await all(_db.behaviorNotesDao.watchByGame(gameId));
    final successions = await all(_db.demonInheritancesDao.watchByGame(gameId));
    final trustLogs = await all(_db.trustLogsDao.watchByGame(gameId));

    final encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert({
      'format': 'botc-copilot-game-export',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'game': game.toJson(),
      'players': [for (final r in players) r.toJson()],
      'dayRecords': [for (final r in days) r.toJson()],
      'roleClaims': [for (final r in claims) r.toJson()],
      'infoDeclarations': [for (final r in declarations) r.toJson()],
      'nominations': [for (final r in nominations) r.toJson()],
      'poisonStatuses': [for (final r in poisons) r.toJson()],
      'behaviorNotes': [for (final r in notes) r.toJson()],
      'demonInheritances': [for (final r in successions) r.toJson()],
      'trustLogs': [for (final r in trustLogs) r.toJson()],
    });
  }
}

/// 导出仓储 provider。
final gameExportRepositoryProvider = Provider<GameExportRepository>(
  (ref) => GameExportRepository(ref.watch(appDatabaseProvider)),
);
