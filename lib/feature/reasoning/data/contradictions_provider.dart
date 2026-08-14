import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/contradiction.dart';
import 'package:botc_copilot/shared/game_private.dart';
import 'package:botc_copilot/shared/reliability.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 某对局的全部角色声明流。
final gameClaimsProvider =
    StreamProvider.family<List<RoleClaim>, int>((ref, gameId) {
  return ref.watch(appDatabaseProvider).roleClaimsDao.watchByGame(gameId);
});

final _declarationsProvider =
    StreamProvider.family<List<InfoDeclaration>, int>((ref, gameId) {
  return ref
      .watch(appDatabaseProvider)
      .infoDeclarationsDao
      .watchByGame(gameId);
});

final _daysProvider =
    StreamProvider.family<List<DayRecord>, int>((ref, gameId) {
  return ref.watch(appDatabaseProvider).dayRecordsDao.watchByGame(gameId);
});

/// 矛盾引擎计算结果（issue #211）。
///
/// [failed] = true 表示 [ContradictionDetector.detect] 抛异常被兜底捕获——
/// 此时 [contradictions] 为空但**不代表「无矛盾」**，UI 须展示降级提示，
/// 而非按空成功渲染。原先 release 下 `debugPrint` 是 no-op、直接返回 `[]`，
/// 引擎真出 bug 时会**无信号地关闭全部矛盾检测**（注释「不静默」仅在 debug
/// 成立）。
class ContradictionResult {
  const ContradictionResult(this.contradictions, {this.failed = false});

  /// 检测到的矛盾标记（[failed] 时为空）。
  final List<Contradiction> contradictions;

  /// 引擎是否异常兜底。true → UI 展示「推理引擎暂不可用」。
  final bool failed;
}

/// 当前对局的矛盾标记流（issue #38）。
final contradictionsProvider = Provider.family<ContradictionResult, int>(
  (ref, gameId) {
    try {
      final claims = ref.watch(gameClaimsProvider(gameId)).valueOrNull ?? [];
      final declarations =
          ref.watch(_declarationsProvider(gameId)).valueOrNull ?? [];
      final days = ref.watch(_daysProvider(gameId)).valueOrNull ?? [];
      final players =
          ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];
      final game = ref.watch(gameByIdProvider(gameId)).valueOrNull;
      final setup =
          game != null ? PlayerSetup.forCount(game.playerCount) : null;
      final expectedOutsiders = setup?.outsiders ?? 0;

      // 整局「疑似醉汉」overlay（#109）：被疑醉玩家的声明 reliability 实时降级，
      // 再交给 detect()。按天的毒已在存档 reliability 中（#122）。
      final playersById = {for (final p in players) p.id: p};
      final effectiveDeclarations = [
        for (final d in declarations)
          d.copyWith(
            reliability: effectiveReliability(
              d.reliability,
              playersById[d.playerId]?.suspectedDrunk ?? false,
            ),
          ),
      ];

      return ContradictionResult(
        ContradictionDetector.detect(
          claims: claims,
          declarations: effectiveDeclarations,
          days: days,
          playersById: playersById,
          dayRecordToDayNumber: {for (final d in days) d.id: d.dayNumber},
          expectedOutsiders: expectedOutsiders,
          setup: setup,
          demonBluffs: game != null ? demonBluffsOf(game) : const {},
          myPlayerId: game?.myPlayerId,
          myRole: game?.myRole,
        ),
      );
    } on Object catch (e, st) {
      // 兜底：损坏数据不应让同步 Provider 抛异常致主界面红屏（#164 B5）。
      // #211：release 下 debugPrint 是 no-op，原先返回空 [] 等于无信号关闭全部
      // 检测；现返回 failed=true 让 UI 展示降级横幅。debugPrint 仍保留 debug 诊断。
      if (kDebugMode) {
        debugPrint('contradictionsProvider 兜底捕获异常: $e\n$st');
      }
      return const ContradictionResult([], failed: true);
    }
  },
);
