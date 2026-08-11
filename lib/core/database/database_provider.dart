import 'package:botc_copilot/core/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全局数据库实例 Provider。
///
/// 自动保存原则：所有 DAO 写操作立即持久化，无需手动保存。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
