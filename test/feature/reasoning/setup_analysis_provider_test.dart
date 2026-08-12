import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/setup_analysis_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/outsider_analysis.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int gameId;
  late int day1Id;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    gameId = await db.gamesDao.insertGame(
      GamesCompanion(
        script: const Value(Script.troubleBrewing),
        playerCount: const Value(9), // base 外来者 = 2
        status: const Value(GameStatus.ongoing),
        createdAt: Value(DateTime(2026, 8, 12)),
      ),
    );
    await db.playersDao.insertAll([
      for (var i = 1; i <= 9; i++)
        PlayersCompanion(
          gameId: Value(gameId),
          name: Value('玩家$i'),
          seatNumber: Value(i),
        ),
    ]);
    day1Id = await db.dayRecordsDao.insertDay(
      DayRecordsCompanion(gameId: Value(gameId), dayNumber: const Value(1)),
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// 轮询直到分析满足 [test]（底层 game/claims 流需各 emit 一次）。
  Future<OutsiderCountAnalysis> readUntil(
    bool Function(OutsiderCountAnalysis) test,
  ) async {
    for (var i = 0; i < 50; i++) {
      final v = container.read(setupAnalysisProvider(gameId));
      if (v != null && test(v)) return v;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('analysis 未达到期望状态');
  }

  Future<void> claimOutsider(int seatIndex, Character c) async {
    final players = await db.playersDao.watchByGame(gameId).first;
    await db.roleClaimsDao.insertClaim(
      RoleClaimsCompanion(
        playerId: Value(players[seatIndex].id),
        dayRecordId: Value(day1Id),
        character: Value(c),
        claimType: const Value(ClaimType.firstClaim),
      ),
    );
  }

  test('配置字段：9 人局 base=2', () async {
    final a = await readUntil((a) => true);
    expect(a.baseOutsiders, 2);
    expect(a.baronOutsiders, 4);
    expect(a.townsfolk, 5);
  });

  test('声明变化实时重算：standard → partial → baronConsistent', () async {
    // 初始：无声明 → under（0 < base 2）
    var a = await readUntil((x) => x.deviation == OutsiderDeviation.under);
    expect(a.claimedOutsiders, 0);

    // +2 外来者声明 → standard（2 == base 2）
    await claimOutsider(0, Character.butler);
    await claimOutsider(1, Character.saint);
    a = await readUntil((x) => x.deviation == OutsiderDeviation.standard);
    expect(a.claimedOutsiders, 2);

    // +1 → partial（3 介于 2 与 4）
    await claimOutsider(2, Character.drunk);
    a = await readUntil((x) => x.deviation == OutsiderDeviation.partial);
    expect(a.claimedOutsiders, 3);

    // +1 → baronConsistent（4 == base+2）
    await claimOutsider(3, Character.recluse);
    a = await readUntil((x) => x.deviation == OutsiderDeviation.baronConsistent);
    expect(a.claimedOutsiders, 4);
  });

  test('Baron 声明被检测到', () async {
    final players = await db.playersDao.watchByGame(gameId).first;
    await db.roleClaimsDao.insertClaim(
      RoleClaimsCompanion(
        playerId: Value(players[4].id),
        dayRecordId: Value(day1Id),
        character: const Value(Character.baron),
        claimType: const Value(ClaimType.firstClaim),
      ),
    );
    final a = await readUntil((x) => x.baronClaimed);
    expect(a.baronClaimed, isTrue);
  });
}
