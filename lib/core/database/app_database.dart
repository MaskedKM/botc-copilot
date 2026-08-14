import 'dart:io';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/daos/behavior_notes_dao.dart';
import 'package:botc_copilot/core/database/daos/day_records_dao.dart';
import 'package:botc_copilot/core/database/daos/demon_inheritances_dao.dart';
import 'package:botc_copilot/core/database/daos/games_dao.dart';
import 'package:botc_copilot/core/database/daos/info_declarations_dao.dart';
import 'package:botc_copilot/core/database/daos/nominations_dao.dart';
import 'package:botc_copilot/core/database/daos/players_dao.dart';
import 'package:botc_copilot/core/database/daos/poison_statuses_dao.dart';
import 'package:botc_copilot/core/database/daos/role_claims_dao.dart';
import 'package:botc_copilot/core/database/daos/trust_logs_dao.dart';
import 'package:botc_copilot/core/database/tables.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

export 'package:botc_copilot/core/database/tables.dart';

part 'app_database.g.dart';

/// App 主数据库（Drift）。
///
/// schema v1：games / players / day_records / role_claims /
/// info_declarations / trust_logs 六张表。
@DriftDatabase(
  tables: [
    Games,
    Players,
    DayRecords,
    RoleClaims,
    InfoDeclarations,
    TrustLogs,
    Nominations,
    PoisonStatuses,
    BehaviorNotes,
    DemonInheritances,
  ],
  daos: [
    GamesDao,
    PlayersDao,
    DayRecordsDao,
    RoleClaimsDao,
    InfoDeclarationsDao,
    TrustLogsDao,
    NominationsDao,
    PoisonStatusesDao,
    BehaviorNotesDao,
    DemonInheritancesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// 生产实例：打开应用文档目录下的 botc.sqlite。
  AppDatabase() : super(_openConnection());

  /// 测试实例：注入任意 executor（如 [NativeDatabase.memory]）。
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v1 → v2：新增 nominations 表
          if (from < 2) {
            await m.createTable(nominations);
          }
          // v2 → v3：games 加 myPlayerId/demonBluffsJson，
          // info_declarations 加 isMine
          if (from < 3) {
            await m.addColumn(games, games.myPlayerId);
            await m.addColumn(games, games.demonBluffsJson);
            await m.addColumn(infoDeclarations, infoDeclarations.isMine);
          }
          // v3 → v4：新增 poison_statuses 表
          if (from < 4) {
            await m.createTable(poisonStatuses);
          }
          if (from < 5) {
            await m.createTable(behaviorNotes);
          }
          // v5 → v6：games 加 helpLevel
          if (from < 6) {
            await m.addColumn(games, games.helpLevel);
          }
          // v6 → v7：nominations 加 defenseText（被提名者辩护，issue #56）
          if (from < 7) {
            await m.addColumn(nominations, nominations.defenseText);
          }
          // v7 → v8：players 加 abilityUsed（一次性能力消耗，issue #54）
          if (from < 8) {
            await m.addColumn(players, players.abilityUsed);
          }
          // v8 → v9：day_records 加 nightConfirmed（夜晚结果确认，issue #77）
          // 存量数据：有 nightDeathPlayerId 的天视为已确认，其余保持未确认。
          if (from < 9) {
            await m.addColumn(dayRecords, dayRecords.nightConfirmed);
            await customStatement(
              'UPDATE day_records SET night_confirmed = 1 '
              'WHERE night_death_player_id IS NOT NULL',
            );
          }
          // v9 → v10：players 加 suspectedDrunk（整局疑似醉汉，issue #109）
          if (from < 10) {
            await m.addColumn(players, players.suspectedDrunk);
          }
          // v10 → v11：games 加 myMinionIdsJson（恶魔私密爪牙名单，issue #108）
          if (from < 11) {
            await m.addColumn(games, games.myMinionIdsJson);
          }
          // v11 → v12：新增 demon_inheritances 表（恶魔传承事件，issue #89）
          if (from < 12) {
            await m.createTable(demonInheritances);
          }
          // v12 → v13：poison_statuses 加 (game_id, player_id, day_number) 唯一
          // 约束（#150 R1/B1）。事务包装已防新重复行（单连接串行化），此约束为
          // DB 级兜底。SQLite 不能给已有表加表级约束，故建唯一索引；先去重存量。
          if (from < 13) {
            await customStatement(
              'DELETE FROM poison_statuses WHERE id NOT IN ('
              'SELECT MIN(id) FROM poison_statuses '
              'GROUP BY game_id, player_id, day_number)',
            );
            await customStatement(
              'CREATE UNIQUE INDEX poison_statuses_unique_idx '
              'ON poison_statuses (game_id, player_id, day_number)',
            );
          }
          // v13 → v14：day_records 加 day_confirmed（#156 S2，与 night_confirmed
          // 对齐：区分「未录」vs「确认无处决」）。
          if (from < 14) {
            await m.addColumn(dayRecords, dayRecords.dayConfirmed);
          }
        },
        beforeOpen: (details) async {
          // 启用外键约束（SQLite 默认关闭，级联删除依赖它）。
          await customStatement('PRAGMA foreign_keys = ON');
          // WAL 模式：读写并发更好，适配 .watch() 高频 reactive 查询。
          await customStatement('PRAGMA journal_mode = WAL');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'botc.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
