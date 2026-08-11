import 'dart:io';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/daos/day_records_dao.dart';
import 'package:botc_copilot/core/database/daos/games_dao.dart';
import 'package:botc_copilot/core/database/daos/info_declarations_dao.dart';
import 'package:botc_copilot/core/database/daos/nominations_dao.dart';
import 'package:botc_copilot/core/database/daos/players_dao.dart';
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
  ],
  daos: [
    GamesDao,
    PlayersDao,
    DayRecordsDao,
    RoleClaimsDao,
    InfoDeclarationsDao,
    TrustLogsDao,
    NominationsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// 生产实例：打开应用文档目录下的 botc.sqlite。
  AppDatabase() : super(_openConnection());

  /// 测试实例：注入任意 executor（如 [NativeDatabase.memory]）。
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

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
