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
  }
}

/// 一次性能力仓库 Provider。
final abilityRepositoryProvider = Provider<AbilityRepository>(
  (ref) => AbilityRepository(ref.watch(appDatabaseProvider)),
);
