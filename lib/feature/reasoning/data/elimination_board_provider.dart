import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/elimination_board.dart';
import 'package:botc_copilot/shared/game_private.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:botc_copilot/shared/reliability.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 排除法棋盘流（issue #214 Part 2）。
///
/// 数据管线与 contradictionsProvider 同源（玩家/声明/信息/天记录/传承），
/// 另注入恶魔私密爪牙名单（仅我=恶魔时有意义，防换座残留名单误当确认）。
/// 弱排除层同样过 #109「疑似醉汉」overlay——被疑醉玩家的信息不用于弱排除。
/// 返回 null = 基础数据未就绪（玩家/对局流加载中），UI 静默不渲染。
final eliminationBoardProvider =
    Provider.family<EliminationBoard?, int>((ref, gameId) {
  final players = ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];
  final game = ref.watch(gameByIdProvider(gameId)).valueOrNull;
  if (players.isEmpty || game == null) return null;

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
    privateMinionIds: game.myRole != null && game.myRole!.team == Team.demon
        ? minionIdsOf(game)
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
});
