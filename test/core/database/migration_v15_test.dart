import 'dart:io';

import 'package:botc_copilot/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// v14 → v15 迁移（#217 增量4）：day_records 夜死单值 → JSON 数组。
///
/// 用真实文件库模拟 v14 存量（user_version=14 + 旧表结构），验证：
/// 旧值折入数组 / null 保持 null（未录入语义不变）/ 旧列删除。
void main() {
  test('v14 → v15：夜死单值回填 JSON 数组，旧列删除', () async {
    final dir = await Directory.systemTemp.createTemp('botc_v14');
    final file = File('${dir.path}/v14.sqlite');

    // 手工构造 v14 形态的 day_records（列集与 v14 表定义一致）+
    // 最小 games/players 表（后续版本迁移可能 ALTER，如 v16 假死列 / v18 爪牙侧字段）。
    final raw = sqlite3.sqlite3.open(file.path);
    raw.execute('''
      CREATE TABLE games (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        script INTEGER NOT NULL,
        player_count INTEGER NOT NULL,
        status INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    raw.execute('''
      CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        seat_number INTEGER NOT NULL,
        is_alive INTEGER NOT NULL DEFAULT 1
      )
    ''');
    raw.execute('''
      CREATE TABLE day_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        day_number INTEGER NOT NULL,
        night_death_player_id INTEGER NULL,
        night_confirmed INTEGER NOT NULL DEFAULT 0,
        day_execution_player_id INTEGER NULL,
        day_confirmed INTEGER NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');
    raw.execute(
      'INSERT INTO day_records (game_id, day_number, night_death_player_id, '
      'night_confirmed) VALUES (1, 2, 42, 1)',
    );
    raw.execute(
      'INSERT INTO day_records (game_id, day_number, night_death_player_id, '
      'night_confirmed) VALUES (1, 3, NULL, 1)',
    );
    raw.execute('PRAGMA user_version = 14');
    raw.close();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    // 有夜死的天：旧值折入数组。
    final day2 = await db.dayRecordsDao.getByGameAndDay(1, 2);
    expect(nightDeathIdsOf(day2), [42]);
    expect(day2!.nightConfirmed, isTrue);

    // 确认无人死亡的天：null 保持 null（未录入 vs 无人死亡由
    // nightConfirmed 消解，#77 语义不变）。
    final day3 = await db.dayRecordsDao.getByGameAndDay(1, 3);
    expect(nightDeathIdsOf(day3), isEmpty);
    expect(day3!.nightConfirmed, isTrue);

    // 旧列已删除（SQLite DROP COLUMN 后再引用应报错）。
    final cols = await db.customSelect('PRAGMA table_info(day_records)').get();
    final names = cols.map((r) => r.read<String>('name')).toSet();
    expect(names, contains('night_death_player_ids'));
    expect(names, isNot(contains('night_death_player_id')));
  });
}
