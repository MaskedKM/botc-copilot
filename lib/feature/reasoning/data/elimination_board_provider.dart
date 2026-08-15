import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/elimination_board.dart';
import 'package:botc_copilot/shared/game_private.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:botc_copilot/shared/reliability.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 排除法棋盘流（issue #214 Part 2）。
///
/// 数据管线与 contradictionsProvider 同源（玩家/声明/信息/天记录/传承），
/// 另注入恶魔私密爪牙名单（仅 7+ 人局且我=恶魔时有效——官方规则 6 人及
/// 以下局恶魔不得知爪牙，换座残留名单不得误当确认）。
/// 弱排除层同样过 #109「疑似醉汉」overlay——被疑醉玩家的信息不用于弱排除。
/// 返回 null = 基础数据未就绪（加载中）或引擎异常兜底，UI 静默不渲染。
final eliminationBoardProvider =
    Provider.family<EliminationBoard?, int>((ref, gameId) {
  final players = ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];
  final game = ref.watch(gameByIdProvider(gameId)).valueOrNull;
  if (players.isEmpty || game == null) return null;

  try {
    final claims = ref.watch(gameClaimsProvider(gameId)).valueOrNull ?? [];
    final successions =
        ref.watch(gameSuccessionsProvider(gameId)).valueOrNull ?? [];
    final declarations =
        ref.watch(gameAllDeclarationsProvider(gameId)).valueOrNull ?? [];
    final days = ref.watch(gameAllDaysProvider(gameId)).valueOrNull ?? [];

    // 死亡揭示（村规确认）→ 确认角色视图。
    final confirmedRoles = <int, Character>{
      for (final c in claims)
        if (c.claimType == ClaimType.revealedOnDeath)
          c.playerId: c.character,
    };

    // #109 overlay：疑似醉汉的信息 reliability 降级后才进弱排除（与矛盾
    // 引擎同口径）。
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

    return EliminationEngine.evaluate(
      players: players,
      setup: PlayerSetup.forCount(game.playerCount),
      confirmedRoles: confirmedRoles,
      successions: successions,
      // 官方规则（#214 review F2）：仅 7+ 人局且我=恶魔时名单有效。
      privateMinionIds:
          game.playerCount >= 7 && game.myRole?.team == Team.demon
              ? minionIdsOf(game)
              : const <int>{},
      // #276：爪牙侧私密（同样仅 7+——官方 ≤6 人局爪牙不知恶魔）。
      privateDemonPlayerId:
          game.playerCount >= 7 && game.myRole?.team == Team.minion
              ? myDemonPlayerOf(game)
              : null,
      privateEvilTeammateIds:
          game.playerCount >= 7 && game.myRole?.team == Team.minion
              ? evilTeammateIdsOf(game)
              : const <int>{},
      declarations: effectiveDeclarations,
      dayRecordToDayNumber: {for (final d in days) d.id: d.dayNumber},
      myPlayerId: game.myPlayerId,
      myRole: game.myRole,
      labelFor: (pid) {
        final p = playersById[pid];
        return p == null ? '?' : '${p.seatNumber}号 ${p.name}';
      },
    );
  } on Object catch (e, st) {
    // 兜底（#214 review F3，同 #211 教训）：如 playerCount 损坏致
    // PlayerSetup.forCount 抛 ArgumentError，不能让推理页红屏。与矛盾引擎
    // 的降级横幅不同——棋盘是辅助视图，静默隐藏 + debug 诊断的代价更小；
    // 矛盾检测是核心信号故其用 failed 标记，此处刻意从简。
    if (kDebugMode) debugPrint('eliminationBoardProvider 兜底: $e\n$st');
    return null;
  }
});
