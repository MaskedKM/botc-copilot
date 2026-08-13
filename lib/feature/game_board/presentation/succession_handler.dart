import 'package:botc_copilot/core/constants/character.dart';
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
  DemonSuccessionCandidate candidate,
) async {
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

  // 继承人候选：我是恶魔→私密爪牙名单；好人→存活声明爪牙。
  final heirSet = <int>{};
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
  // SW 满足时确保 SW 在候选（用于预选 / 改选）。
  if (candidate.scarletWomanPlayerId != null) {
    heirSet.add(candidate.scarletWomanPlayerId!);
  }
  final heirs = heirSet.map((id) => (playerId: id, name: nameOf(id))).toList();

  if (!context.mounted) return;
  final result = await EndGameDialog.showSuccessionCheck(
    context,
    candidate: candidate,
    heirCandidates: heirs,
    allowDeathReveal: candidate.way != DeathWay.suicide,
  );
  if (result == null || !context.mounted) return;

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
    if (result.revealedRole != null) {
      await notifier.recordRevealOnly(
        playerId: candidate.demonPlayerId,
        role: result.revealedRole!,
      );
    }
  } else {
    // 恶魔真死 → 善良胜
    await notifier.endGame(
      goodWin: true,
      revealedPlayerId: candidate.demonPlayerId,
      revealedRole: result.revealedRole,
    );
  }
}
