import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/domain/game_end.dart';
import 'package:botc_copilot/feature/game_board/domain/succession.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/end_game_dialog.dart';
import 'package:botc_copilot/shared/game_private.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 恶魔传承处理（issue #89）：构建继承人候选 → 确认框 → 记录/终局。
///
/// 三路径（夜死自杀 / 处决恶魔 / Slayer 击杀恶魔）统一入口，由各死亡流程
/// 在检测到 [DemonSuccessionCandidate] 后调用。独立成文件以避免
/// `player_detail` ↔ `game_board` widget 间的循环依赖。
Future<void> handleSuccession(
  BuildContext context,
  WidgetRef ref,
  int gameId,
  DemonSuccessionCandidate candidate, {
  Character? revealedRole,
}) async {
  final db = ref.read(appDatabaseProvider);
  final game = await db.gamesDao.getById(gameId);
  final players = await db.playersDao.watchByGame(gameId).first;
  final claims = await db.roleClaimsDao.watchByGame(gameId).first;
  final latest = <int, Character>{};
  for (final c in claims) {
    latest[c.playerId] = c.character;
  }
  String nameOf(int id) {
    final p = players.where((p) => p.id == id).firstOrNull;
    return p != null ? '${p.seatNumber}号 ${p.name}' : '?';
  }

  // 继承人候选：
  // - SW 满足时**强制 SW**（官方 "passes first"——SW eligible 时必须 SW 继承，
  //   优先于自杀选其他爪牙；#149 S-1 已 WebSearch 核实 Wiki）。
  // - 无 SW + 自杀：我是恶魔→私密爪牙名单；好人→存活声明爪牙。
  // - 处决/Slayer：仅 SW 可继承（checkDemonDeath 保证 SW 在场），无 SW 则善良胜。
  final heirSet = <int>{};
  if (candidate.scarletWomanPlayerId != null) {
    heirSet.add(candidate.scarletWomanPlayerId!);
  } else if (candidate.way == DeathWay.suicide) {
    final isDemonMe = game?.myRole == Character.imp &&
        game?.myPlayerId == candidate.demonPlayerId;
    if (isDemonMe && game != null) {
      for (final id in minionIdsOf(game)) {
        if (players.any((p) => p.id == id && p.isAlive)) heirSet.add(id);
      }
    } else {
      for (final p in players.where((p) => p.isAlive)) {
        if (SuccessionRules.minionClaimCandidates.contains(latest[p.id])) {
          heirSet.add(p.id);
        }
      }
    }
  }
  final heirs = heirSet.map((id) => (playerId: id, name: nameOf(id))).toList();

  if (!context.mounted) return;
  // 处决路径已由 showDemonCheck 收集揭示角色（经 [revealedRole] 传入）；
  // Slayer 路径在此收集；夜死无死亡揭示。避免处决路径重复提问 + 丢失。
  final result = await EndGameDialog.showSuccessionCheck(
    context,
    candidate: candidate,
    heirCandidates: heirs,
    allowDeathReveal: candidate.way == DeathWay.slayer,
    initialRevealedRole: revealedRole,
    script: game?.script ?? Script.troubleBrewing,
  );
  if (result == null || !context.mounted) return;
  // 优先用调用方传入的揭示角色（处决），否则用对话框收集的（Slayer）。
  final reveal = revealedRole ?? result.revealedRole;

  final notifier = ref.read(gameBoardProvider(gameId).notifier);
  if (result.occurred) {
    await notifier.recordSuccession(
      fromPlayerId: candidate.demonPlayerId,
      toPlayerId: result.toPlayerId,
      trigger: result.trigger ??
          (candidate.scarletWomanEligible
              ? SuccessionTrigger.scarletWoman
              : SuccessionTrigger.suicideByImp),
    );
    if (reveal != null) {
      await notifier.recordRevealOnly(
        playerId: candidate.demonPlayerId,
        role: reveal,
      );
    }
    // #149 BUG-1 场景B：传承完成后再判人头邪恶胜（Imp 自杀 + 爪牙传承后
    // 存活 ≤ 2）。SW 传承必在存活 ≥4 时发生（不误触）；仅普通传位（自杀）
    // 可能落到 ≤2，此时恶魔仍在场 → 邪恶胜。recordSuccession 不改存活数，
    // 复用 candidate.aliveCountAfter（恶魔死后存活数）即可。
    final aliveAfter = candidate.aliveCountAfter;
    if (context.mounted && GameEndRules.isEvilWinCandidate(aliveAfter)) {
      final evil = await EndGameDialog.showEvilCandidate(
        context,
        aliveCount: aliveAfter,
      );
      if ((evil ?? false) && context.mounted) {
        await notifier.endGame(goodWin: false);
      }
    }
  } else {
    // 恶魔真死 → 善良胜
    await notifier.endGame(
      goodWin: true,
      revealedPlayerId: candidate.demonPlayerId,
      revealedRole: reveal,
    );
  }
}
