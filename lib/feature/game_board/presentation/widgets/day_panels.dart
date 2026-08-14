import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/data/nomination_repository.dart';
import 'package:botc_copilot/feature/game_board/domain/game_end.dart';
import 'package:botc_copilot/feature/game_board/domain/night_death_rules.dart';
import 'package:botc_copilot/feature/game_board/domain/nomination_rules.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:botc_copilot/shared/widgets/help_tooltip.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/game_board/presentation/succession_handler.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/end_game_dialog.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/night_action_section.dart';
import 'package:botc_copilot/feature/game_board/presentation/widgets/night_order_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 夜晚结果面板：记录今夜死亡。
class NightPanel extends ConsumerWidget {
  /// 创建面板。
  const NightPanel({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(
      gameBoardProvider(gameId).select((s) => s.currentDay),
    );
    final dayRecord =
        ref.watch(currentDayRecordProvider((gameId, day))).valueOrNull;
    final players = ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];
    final notifier = ref.read(gameBoardProvider(gameId).notifier);
    final helpLevel = ref.watch(gameHelpLevelProvider(gameId));
    final ongoing = ref.watch(isGameOngoingProvider(gameId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('第 $day 天 · 夜晚死亡', style: AppTextStyles.headline),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('无人死亡'),
              // 选中态由显式 nightConfirmed 驱动（#77）；onSelected gate ongoing（#81）
              selected: dayRecord?.nightConfirmed == true &&
                  dayRecord?.nightDeathPlayerId == null,
              onSelected: ongoing ? (_) => notifier.recordNightDeath(null) : null,
            ),
            // 含当前夜杀目标（夜杀后已死但保留 chip 可见、可点按撤销，#156 S1）；
            // 往日死者仍排除（不能夜杀已死之人）。
            for (final p in players.where(
                (p) => p.isAlive || p.id == dayRecord?.nightDeathPlayerId))
              ChoiceChip(
                label: Text(
                    '${p.seatNumber}号 ${p.name}${p.isAlive ? '' : ' ☠'}'),
                selected: dayRecord?.nightDeathPlayerId == p.id,
                onSelected: ongoing
                    ? (selected) {
                        // 已选中目标再次点按 → 撤销夜杀（recordNightDeath(null)
                        // 经 _revivePreviousDeath 复活，与「无人死亡」同路径）。
                        if (!selected) {
                          notifier.recordNightDeath(null);
                        } else {
                          _confirmNightDeath(
                            context,
                            ref,
                            player: p,
                            gameId: gameId,
                            day: day,
                            notifier: notifier,
                          );
                        }
                      }
                    : null,
              ),
          ],
        ),
        HelpTooltip(
          level: helpLevel,
          text: '无人死亡可能意味着：Monk 保护成功 / Soldier 能力 / '
              '恶魔自杀传位 / 恶魔被毒。',
        ),
        const SizedBox(height: 8),
        // 夜晚行动顺序参考（issue #61）
        NightOrderSection(currentDay: day, helpLevel: helpLevel),
        const SizedBox(height: 8),
        // 夜间行动记录区（issue #110）
        NightActionSection(gameId: gameId),
      ],
    );
  }
}

/// 白天面板：记录处决。
class DayPanel extends ConsumerWidget {
  /// 创建面板。
  const DayPanel({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(
      gameBoardProvider(gameId).select((s) => s.currentDay),
    );
    final dayRecord =
        ref.watch(currentDayRecordProvider((gameId, day))).valueOrNull;
    final players = ref.watch(gamePlayersProvider(gameId)).valueOrNull ?? [];
    final todayNominations =
        ref.watch(dayNominationsProvider((gameId, day))).valueOrNull ?? [];
    final notifier = ref.read(gameBoardProvider(gameId).notifier);
    final ongoing = ref.watch(isGameOngoingProvider(gameId));

    // 处决合法性参考（issue #85）：当天「即将死亡」者
    final aliveCount = players.where((p) => p.isAlive).length;
    final pending =
        NominationRules.pendingExecution(todayNominations, aliveCount);
    final pendingId =
        pending is PendingExecution ? pending.nomineeId : null;
    // 警告文案用：「3号 玩家3（5 票）」
    String? pendingLabel;
    if (pending is PendingExecution) {
      final nominee = players
          .where((p) => p.id == pending.nomineeId)
          .firstOrNull;
      if (nominee != null) {
        pendingLabel = '${nominee.seatNumber}号 ${nominee.name}'
            '（${pending.forCount} 票）';
      }
    }
    // #149 A-1：平票时无人即将死亡，手动处决应同样提示（原 pendingId=null 跳过告警）。
    final pendingTieForCount = pending is PendingTie ? pending.forCount : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('第 $day 天 · 白天处决', style: AppTextStyles.headline),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('无处决'),
              // #156 S2：选中态由显式 dayConfirmed 驱动（与 NightPanel 的
              // nightConfirmed 对齐），不再「dayRecord 一存在就预选中」。
              selected: dayRecord?.dayConfirmed == true &&
                  dayRecord?.dayExecutionPlayerId == null,
              onSelected: ongoing ? (_) => notifier.recordExecution(null) : null,
            ),
            for (final p in players)
              ChoiceChip(
                // 处决候选含死人（处决死人是合法操作，#80）；死者标 ☠
                label: Text(
                  '${p.seatNumber}号 ${p.name}'
                  '${p.isAlive ? '' : ' ☠'}',
                ),
                selected: dayRecord?.dayExecutionPlayerId == p.id,
                onSelected: ongoing
                    ? (_) => _confirmExecution(
                          context,
                          ref,
                          player: p,
                          gameId: gameId,
                          pendingId: pendingId,
                          pendingLabel: pendingLabel,
                          pendingTieForCount: pendingTieForCount,
                          notifier: notifier,
                        )
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '角色声明与信息录入在玩家详情中（点圆环上的玩家）。',
          style: AppTextStyles.caption
              .copyWith(color: context.gameColors.inkViolet),
        ),
      ],
    );
  }
}

/// 破坏性操作二次确认（防误触原则）。
/// 撤销/改选由 provider 处理：重选「无人死亡」或改选他人会自动复活前者。
///
/// 公开以便投票面板的「即将死亡→处决」复用（issue #85）。
Future<void> confirmDeath(
  BuildContext context,
  WidgetRef ref, {
  required Player player,
  required Future<GameEndSuggestion?> Function() action,
  required String verb,
  required int gameId,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('确认$verb'),
      content: Text('${player.seatNumber}号 ${player.name} $verb？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('确认'),
        ),
      ],
    ),
  );
  if (!(confirmed ?? false)) return;
  final suggestion = await action();
  if (suggestion != null && context.mounted) {
    await handleEndSuggestion(context, ref, gameId, suggestion);
  }
}

/// 处决合法性校验（issue #85）。
///
/// 若当天有「即将死亡」者且选的不是他 → 先警告（不阻止，覆盖 Virgin 等
/// 特殊流程时需要）；确认后再走标准 [confirmDeath] 二次确认 + 结束判定。
Future<void> _confirmExecution(
  BuildContext context,
  WidgetRef ref, {
  required Player player,
  required int gameId,
  required int? pendingId,
  required String? pendingLabel,
  required int? pendingTieForCount,
  required GameBoardNotifier notifier,
}) async {
  if (pendingId != null && pendingId != player.id) {
    final override = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('处决对象非台上即将死亡者'),
        content: Text('当前即将死亡的是 ${pendingLabel ?? '另一玩家'}，不是此人。'
            '仍要处决吗？（Virgin 处决提名者等特殊流程可能需要手动覆盖）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('仍要处决'),
          ),
        ],
      ),
    );
    if (!(override ?? false)) return;
  } else if (pendingTieForCount != null) {
    // #149 A-1：平票 → 无人即将死亡，手动处决提示（与「唯一最高票才提示」对称）。
    final override = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('当前平票，无人即将死亡'),
        content: Text('当天最高票并列 $pendingTieForCount 票，按规则无人被处决。'
            '仍要手动处决此人吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('仍要处决'),
          ),
        ],
      ),
    );
    if (!(override ?? false)) return;
  }
  await confirmDeath(
    context,
    ref,
    player: player,
    action: () => notifier.recordExecution(player.id),
    verb: '处决',
    gameId: gameId,
  );
}

/// 处理结束建议：弹 dialog → 用户确认 → 更新状态。
Future<void> handleEndSuggestion(
  BuildContext context,
  WidgetRef ref,
  int gameId,
  GameEndSuggestion suggestion,
) async {
  final notifier = ref.read(gameBoardProvider(gameId).notifier);
  switch (suggestion) {
    case DemonSuccessionCandidate():
      // 恶魔死亡 → 传承/善良胜确认（issue #89，三路径统一）
      await handleSuccession(context, ref, gameId, suggestion);
    case MayorVictoryCandidate():
      // 市长特殊胜利（issue #88）：3 人存活且当日无人被处决。
      final confirmed = await EndGameDialog.showMayorCheck(context);
      if (confirmed ?? false) {
        await notifier.endGame(goodWin: true);
      }
    case EvilWinCandidate(:final aliveCount):
      final confirmed = await EndGameDialog.showEvilCandidate(
        context,
        aliveCount: aliveCount,
      );
      if (confirmed ?? false) {
        await notifier.endGame(goodWin: false);
      }
    case DemonExecutionCheck(
        :final executedPlayerId,
        :final executedName,
        :final aliveCountAfter,
      ):
      // Saint 处决 → 邪恶立即获胜（issue #54）。
      // App 按玩家**声明**提示：声明圣徒被处决时弹出邪恶胜确认。
      // 用户否认（如恶魔 bluff 圣徒，实际应善良胜）→ 继续走恶魔确认。
      if (await _claimedSaint(ref, gameId, executedPlayerId)) {
        if (!context.mounted) return;
        final evilWin = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('圣徒被处决'),
            content: Text('$executedName 声明为圣徒。处决圣徒会使善良方'
                '立即战败。结束对局？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('邪恶获胜'),
              ),
            ],
          ),
        );
        if (evilWin ?? false) {
          await notifier.endGame(goodWin: false);
          return;
        }
        // 未确认邪恶胜 → 落入下方恶魔确认流程（不 return）
        if (!context.mounted) return;
      }
      final result = await EndGameDialog.showDemonCheck(
        context,
        executedName: executedName,
      );
      if (result == null || !context.mounted) return;
      if (result.goodWin ?? false) {
        // 是恶魔 → 先查 SW 传承（在场则不终局），否则善良胜（issue #89）
        final succ = await notifier.checkDemonDeath(
          executedPlayerId,
          way: DeathWay.execution,
        );
        if (!context.mounted) return;
        if (succ is DemonSuccessionCandidate) {
          await handleSuccession(
            context,
            ref,
            gameId,
            succ,
            revealedRole: result.revealedRole,
          );
        } else {
          await notifier.endGame(
            goodWin: true,
            revealedPlayerId: executedPlayerId,
            revealedRole: result.revealedRole,
          );
        }
        return;
      } else if (result.revealedRole != null) {
        // 不是恶魔但揭示了角色 → 只记死亡揭示
        await notifier.recordRevealOnly(
          playerId: executedPlayerId,
          role: result.revealedRole!,
        );
      }
      if (context.mounted &&
          !(result.goodWin ?? false) &&
          GameEndRules.isEvilWinCandidate(aliveCountAfter)) {
        await _checkEvilWinAfterExecution(context, notifier, aliveCountAfter);
      }
  }
}

/// 处决非恶魔后，若存活 ≤ 2 则级联提示邪恶获胜。
Future<void> _checkEvilWinAfterExecution(
  BuildContext context,
  GameBoardNotifier notifier,
  int aliveCount,
) async {
  final confirmed = await EndGameDialog.showEvilCandidate(
    context,
    aliveCount: aliveCount,
  );
  if (confirmed ?? false) {
    await notifier.endGame(goodWin: false);
  }
}

/// 该玩家是否为圣徒（按声明；或我是圣徒被处决——issue #107 注入 myRole）。
Future<bool> _claimedSaint(WidgetRef ref, int gameId, int playerId) async {
  final db = ref.read(appDatabaseProvider);
  final claims = await db.roleClaimsDao.watchByPlayer(playerId).first;
  if (claims.isNotEmpty && claims.last.character == Character.saint) {
    return true;
  }
  // 我是圣徒（myRole）被处决 → 同样触发（公开声明不含我，须查 myRole）
  final game = await db.gamesDao.getById(gameId);
  return game?.myPlayerId == playerId && game?.myRole == Character.saint;
}

/// 该玩家的有效角色——用于夜晚死亡规则警告（issue #114）。
///
/// 与 [_claimedSaint] 的语义差异是刻意的：警告关注玩家**真实能力**，故
/// 「我」的座位取 myRole（我已知真实角色）；他人只能看最新公开声明。
/// （Saint 处决流程按声明提示、由用户确认，沿用 [_claimedSaint] 不变。）
Future<Character?> _claimedCharacter(
  WidgetRef ref,
  int gameId,
  int playerId,
) async {
  final db = ref.read(appDatabaseProvider);
  // 我是该座位 → 真实角色；他人 → 最新公开声明
  final game = await db.gamesDao.getById(gameId);
  if (game?.myPlayerId == playerId) return game?.myRole;
  final claims = await db.roleClaimsDao.watchByPlayer(playerId).first;
  return claims.isNotEmpty ? claims.last.character : null;
}

/// 夜晚死亡规则警告（issue #114）：首夜死亡 / 声明 Soldier 的玩家夜死等。
///
/// 警告**不阻止**——毒/醉可解释 Soldier 等场景，村规/实验角色也可能覆盖
/// 能力。确认后仍走标准 [confirmDeath] 二次确认 + 结束判定。参考 #85 处决
/// 警告模式。
Future<void> _confirmNightDeath(
  BuildContext context,
  WidgetRef ref, {
  required Player player,
  required int gameId,
  required int day,
  required GameBoardNotifier notifier,
}) async {
  final claimed = await _claimedCharacter(ref, gameId, player.id);
  final monkProtected = await _monkProtectedThisNight(ref, gameId, day, player.id);
  final warnings = NightDeathRules.warnings(
    day: day,
    claimedCharacter: claimed,
    monkProtected: monkProtected,
  );
  if (warnings.isNotEmpty && context.mounted) {
    final override = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('规则提示'),
        content: Text(warnings.join('\n\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('仍要标记'),
          ),
        ],
      ),
    );
    if (!(override ?? false)) return;
  }
  await confirmDeath(
    context,
    ref,
    player: player,
    action: () => notifier.recordNightDeath(player.id),
    verb: '夜晚死亡',
    gameId: gameId,
  );
}

/// 该玩家当晚是否被僧侣保护（#110 夜间行动记录 → #114 任务3）。
///
/// 查当日 InfoDeclaration 中 characterType == monk 且 payload.playerId 命中。
Future<bool> _monkProtectedThisNight(
  WidgetRef ref,
  int gameId,
  int day,
  int playerId,
) async {
  final db = ref.read(appDatabaseProvider);
  final dayRecord = await db.dayRecordsDao.getByGameAndDay(gameId, day);
  if (dayRecord == null) return false;
  final decls = await db.infoDeclarationsDao.watchByDay(dayRecord.id).first;
  for (final d in decls) {
    if (d.characterType != Character.monk) continue;
    try {
      final payload = jsonDecode(d.payloadJson);
      if (payload is Map && payload['playerId'] == playerId) return true;
    } on FormatException {
      continue;
    }
  }
  return false;
}
