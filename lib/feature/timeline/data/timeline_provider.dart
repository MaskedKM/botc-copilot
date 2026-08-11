import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/timeline/domain/timeline_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 某局的时间线数据（按天分组）。
final timelineProvider =
    StreamProvider.family<List<TimelineDay>, int>((ref, gameId) async* {
  final db = ref.watch(appDatabaseProvider);

  // 三个流任一变化都重建时间线（数据量小，直接全量重算）。
  final daysStream = db.dayRecordsDao.watchByGame(gameId);
  await for (final days in daysStream) {
    final players = await db.playersDao.watchByGame(gameId).first;
    final claims = await db.roleClaimsDao.watchByGame(gameId).first;
    final declarations =
        await db.infoDeclarationsDao.watchByGame(gameId).first;

    yield TimelineBuilder.build(
      days: days,
      claims: claims,
      declarations: declarations,
      playersById: {for (final p in players) p.id: p},
      dayRecordToDayNumber: {for (final d in days) d.id: d.dayNumber},
    );
  }
});
