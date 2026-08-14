import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 一次性角色能力追踪结果（Slayer 猜测）。
enum SlayerGuessResult {
  /// 目标是恶魔且 Slayer 未被毒/醉 → 目标死亡。
  killed,

  /// 目标非恶魔，或 Slayer 被毒/醉 → 未击杀，但能力**永久消耗**。
  /// （官方规则：一次性能力在醉/毒时使用则永久消耗，恢复后不返还。）
  missed,
}

/// 教授复活结果（#217 增量4D）。
enum ProfessorResurrectResult {
  /// 目标复活（用户按公开信息确认其回到场上）。
  resurrected,

  /// 未复活（目标非镇民 / 醉毒失效 / 无法确认）——能力仍消耗。
  notResurrected,
}

/// 一次性能力追踪仓库（issue #54：Virgin / Slayer / Saint）。
///
/// App 追踪的是玩家**声明**角色的能力状态，并提供录入动作；
/// 不代替玩家裁决隐藏信息（是否真为恶魔、是否真被毒由用户确认）。
class AbilityRepository {
  /// 创建仓库。
  AbilityRepository(this._db);

  final AppDatabase _db;

  /// 设置一次性能力消耗状态（Virgin 触发 / Slayer 使用 / 撤销误标）。
  Future<void> setAbilityUsed(int playerId, {required bool used}) =>
      _db.playersDao.markAbilityUsed(playerId, used: used);

  /// 录入一次 Slayer 猜测（issue #54）。
  ///
  /// - [targetIsDemon] 用户确认目标是否为恶魔（隐藏信息，由用户判定）。
  /// - [wasPoisoned] 用户确认 Slayer 猜测时是否处于醉/毒状态。
  ///
  /// 能力**总是被消耗**（标记 abilityUsed=true）。仅当 [targetIsDemon]
  /// 且**未**被毒/醉时目标死亡。返回 [SlayerGuessResult] 供 UI 反馈。
  Future<SlayerGuessResult> recordSlayerGuess({
    required int slayerId,
    required int targetId,
    required bool targetIsDemon,
    required bool wasPoisoned,
    required int day,
  }) async {
    // 整体包事务（#150 R4）：markAbilityUsed 与 markDead 须原子——markDead
    // 失败则能力消耗回滚，保一次性能力语义（否则能力已消耗却未击杀）。
    return _db.transaction(() async {
      await _db.playersDao.markAbilityUsed(slayerId, used: true);
      if (targetIsDemon && !wasPoisoned) {
        await _db.playersDao.markDead(
          targetId,
          day,
          DeathCause.other,
        );
        return SlayerGuessResult.killed;
      }
      return SlayerGuessResult.missed;
    });
  }

  /// 录入一次教授复活（#217 增量4D）。
  ///
  /// 官方：每局限一次，夜晚*选择一名已死玩家：若其为镇民则复活。
  /// 教授**不会得知是否成功**——[resurrected] 由用户按公开信息裁决
  /// （目标是否回到场上）。能力总是消耗（公理4：醉/毒时使用也永久消耗）。
  ///
  /// 复活 = 玩家级 `revive`（isAlive=true + 清 deathDay/Cause），**保留**
  /// 死亡当日的 day-record 记录——复活不是撤销死亡，历史事件照旧（区别
  /// 于 [GameBoardNotifier.revivePlayer] 的误标撤销路径）。
  Future<ProfessorResurrectResult> recordProfessorResurrect({
    required int professorId,
    required int targetId,
    required bool resurrected,
  }) async {
    return _db.transaction(() async {
      await _db.playersDao.markAbilityUsed(professorId, used: true);
      if (resurrected) {
        await _db.playersDao.revive(targetId);
        return ProfessorResurrectResult.resurrected;
      }
      return ProfessorResurrectResult.notResurrected;
    });
  }
}

/// 一次性能力仓库 Provider。
final abilityRepositoryProvider = Provider<AbilityRepository>(
  (ref) => AbilityRepository(ref.watch(appDatabaseProvider)),
);
