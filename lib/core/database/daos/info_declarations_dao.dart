import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart';

part 'info_declarations_dao.g.dart';

/// 信息声明表 DAO。
@DriftAccessor(tables: [InfoDeclarations, DayRecords])
class InfoDeclarationsDao extends DatabaseAccessor<AppDatabase>
    with _$InfoDeclarationsDaoMixin {
  /// 创建 DAO。
  InfoDeclarationsDao(super.db);

  /// 监听某天的全部信息声明。
  Stream<List<InfoDeclaration>> watchByDay(int dayRecordId) =>
      (select(infoDeclarations)
            ..where((i) => i.dayRecordId.equals(dayRecordId)))
          .watch();

  /// 查询某天的全部信息声明（事务内用，drift 事务不支持 .watch，#150 R2）。
  Future<List<InfoDeclaration>> getByDay(int dayRecordId) =>
      (select(infoDeclarations)
            ..where((i) => i.dayRecordId.equals(dayRecordId)))
          .get();

  /// 监听一局的全部信息声明（跨天，经每日记录关联）。
  Stream<List<InfoDeclaration>> watchByGame(int gameId) {
    final query = select(infoDeclarations).join([
      innerJoin(
        dayRecords,
        dayRecords.id.equalsExp(infoDeclarations.dayRecordId),
      ),
    ])..where(dayRecords.gameId.equals(gameId));
    return query.watch().map(
          (rows) => rows.map((r) => r.readTable(infoDeclarations)).toList(),
        );
  }

  /// 新建信息声明。
  Future<int> insertDeclaration(InfoDeclarationsCompanion entry) =>
      into(infoDeclarations).insert(entry);

  /// 更新信息可靠性（醉/毒状态变化时）。
  Future<int> updateReliability(int id, Reliability reliability) =>
      (update(infoDeclarations)..where((i) => i.id.equals(id)))
          .write(InfoDeclarationsCompanion(reliability: Value(reliability)));

  /// 把某玩家当夜已录的信息声明可靠性降级为 possiblyTainted（issue #122）。
  ///
  /// 用于 Poisoner 毒目标 / 手动标毒的回溯：中毒者当晚获得的信息为假
  /// （官方：能力失效、信息错误）。仅降级 verified / unverified；已
  /// possiblyTainted / invalidated 保持不变（不覆盖更强的判定）。
  Future<void> taintPlayerDeclarations(int dayRecordId, int playerId) async {
    final decls = await (select(infoDeclarations)
          ..where(
            (i) =>
                i.dayRecordId.equals(dayRecordId) & i.playerId.equals(playerId),
          ))
        .get();
    for (final d in decls) {
      if (d.reliability == Reliability.verified ||
          d.reliability == Reliability.unverified) {
        await (update(infoDeclarations)..where((i) => i.id.equals(d.id)))
            .write(const InfoDeclarationsCompanion(
                reliability: Value(Reliability.possiblyTainted)));
      }
    }
  }

  /// 恢复某玩家当夜信息的 reliability（#122 对称：移除毒源时）。
  ///
  /// 仅 possiblyTainted → unverified；verified / invalidated 不变（不无脑升级）。
  /// 仅当 [isPlayerPoisonedFromSources] 为 false（无残留毒源）时调用方才应调用。
  Future<void> restorePlayerDeclarations(int dayRecordId, int playerId) async {
    final decls = await (select(infoDeclarations)
          ..where(
            (i) =>
                i.dayRecordId.equals(dayRecordId) & i.playerId.equals(playerId),
          ))
        .get();
    for (final d in decls) {
      if (d.reliability == Reliability.possiblyTainted) {
        await (update(infoDeclarations)..where((i) => i.id.equals(d.id)))
            .write(const InfoDeclarationsCompanion(
                reliability: Value(Reliability.unverified)));
      }
    }
  }

  /// 该玩家当夜是否被毒（#122）：Poisoner 声明以其为目标，**或**手动标毒，
  /// 任一命中即 true。供「移除单一毒源后判断是否仍有残留毒源」使用。
  Future<bool> isPlayerPoisonedFromSources(
    int dayRecordId,
    int playerId,
  ) async {
    // (a) 当夜 Poisoner 声明以其为目标
    final dayDecls = await (select(infoDeclarations)
          ..where((i) => i.dayRecordId.equals(dayRecordId)))
        .get();
    final poisonerTargeted = dayDecls.any((d) {
      if (d.characterType != Character.poisoner) return false;
      try {
        final p = jsonDecode(d.payloadJson);
        return p is Map && p['playerId'] == playerId;
      } on FormatException {
        return false;
      }
    });
    if (poisonerTargeted) return true;
    // (b) 手动标毒（poison_statuses，按当夜对应天数）
    final day = await (select(dayRecords)..where((d) => d.id.equals(dayRecordId)))
        .getSingleOrNull();
    if (day == null) return false;
    final statuses = await (select(attachedDatabase.poisonStatuses)
          ..where(
            (s) =>
                s.playerId.equals(playerId) &
                s.dayNumber.equals(day.dayNumber) &
                s.isActive,
          ))
        .get();
    return statuses.isNotEmpty;
  }

  /// 按 id 查询信息声明（误录纠错删除前读取，判断是否 Poisoner 声明）。
  Future<InfoDeclaration?> getById(int id) =>
      (select(infoDeclarations)..where((i) => i.id.equals(id)))
          .getSingleOrNull();

  /// 删除信息声明。
  Future<int> deleteDeclaration(int id) =>
      (delete(infoDeclarations)..where((i) => i.id.equals(id))).go();
}
