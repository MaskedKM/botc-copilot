import 'dart:convert';

import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script_definition.dart';
import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/player_detail/domain/next_unclaimed_player.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/shared/game_private.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 「保存并下一位」按钮（#134 首夜队列加速器）。
///
/// 独立 ConsumerWidget——仅在此按钮渲染时才 watch [gameClaimsProvider]，避免
/// 非链式弹层（默认入口）触发该 provider（widget test 不覆写它会建真实 DB）。
class NextPlayerButton extends ConsumerWidget {
  const NextPlayerButton({
    required this.gameId,
    required this.playerId,
    required this.myPlayerId,
    required this.players,
    required this.saving,
    required this.onNext,
  });

  final int gameId;
  final int playerId;
  final int? myPlayerId;
  final List<Player> players;
  final bool saving;
  final void Function(Player next) onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allClaims =
        ref.watch(gameClaimsProvider(gameId)).valueOrNull ??
            const <RoleClaim>[];
    final next = nextUnclaimedPlayer(
      players: players,
      claimedPlayerIds: allClaims.map((c) => c.playerId).toSet(),
      fromPlayerId: playerId,
      myPlayerId: myPlayerId,
    );
    return FilledButton.icon(
      onPressed: (next != null && !saving) ? () => onNext(next) : null,
      icon: const Icon(Icons.skip_next),
      label: const Text('下一位'),
    );
  }
}

/// 恶魔私密爪牙名单（issue #108）。
///
/// 官方：7+ 人局恶魔首夜得知爪牙是谁。多选玩家（排除自己），即时写入
/// `Games.myMinionIdsJson`。私密——不进公开推理，仅角色矩阵对我私密展示。
///
/// 从 MyInfoSheet 迁入（#131 统一入口）。
class MyMinionsSection extends ConsumerWidget {
  const MyMinionsSection({
    required this.game,
    required this.players,
    this.readOnly = false,
  });

  final Game game;

  /// 全部玩家（用于候选）。
  final List<Player> players;

  /// 只读（复盘）：chip 不可选。
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameColors = context.gameColors;
    final selected = minionIdsOf(game);
    final expected = PlayerSetup.forCount(game.playerCount).minions;
    // 候选：除我以外的玩家
    final candidates =
        players.where((p) => p.id != game.myPlayerId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '我的爪牙（私密，${game.playerCount} 人局应有 $expected 个）',
          style: AppTextStyles.headline.copyWith(color: gameColors.bloodBright),
        ),
        const SizedBox(height: 4),
        Text(
          '官方：7+ 人局恶魔首夜得知爪牙。仅你可见，不影响公开推理。',
          style: AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final p in candidates)
              ChoiceChip(
                label: Text('${p.seatNumber}号 ${p.name}'),
                selected: selected.contains(p.id),
                onSelected: readOnly
                    ? null
                    : (_) async {
                        final next = Set<int>.of(selected);
                        final isAdd = !next.contains(p.id);
                        // #152 BUG-3：爪牙数已达该人数局上限则拒绝添加
                        // （恶魔被告知全部爪牙，不会多于配置数）。
                        if (isAdd && selected.length >= expected) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${game.playerCount} 人局仅有 $expected 个爪牙，已达上限',
                              ),
                            ),
                          );
                          return;
                        }
                        if (isAdd) {
                          next.add(p.id);
                        } else {
                          next.remove(p.id);
                        }
                        await ref
                            .read(appDatabaseProvider)
                            .gamesDao
                            .updateMyMinionIds(
                              game.id,
                              jsonEncode(next.toList()),
                            );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${isAdd ? "已加入" : "已移除"} '
                              '${p.seatNumber}号 ${p.name}',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
              ),
          ],
        ),
      ],
    );
  }
}

/// 更换我的座位（issue #86）：选座 → 二次确认 → 写 myPlayerId。
///
/// 从 MyInfoSheet 迁入（#131 统一入口）。
/// 恶魔 Bluff 补录/修改区（#281，7+ 人局我=恶魔）。
///
/// Bluff（3 个不在场好人角色）是排除法关键约束，此前仅 setup 可录、
/// `updateDemonBluffs` 零调用——漏录则 Bluff 声明检测静默失效。此区
/// 与爪牙名单同族（即时落库，矛盾引擎即时消费）。
class MyBluffsSection extends ConsumerWidget {
  const MyBluffsSection({
    required this.game,
    this.readOnly = false,
    super.key,
  });

  final Game game;

  /// 只读（复盘）。
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameColors = context.gameColors;
    final selected = demonBluffsOf(game);
    final pool = ScriptDefinition.of(game.script)
        .characters
        .where((c) => c.isGood)
        .toList();
    final db = ref.read(appDatabaseProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '恶魔 Bluff（私密，选 3 个不在场好人角色）',
          style:
              AppTextStyles.headline.copyWith(color: gameColors.bloodBright),
        ),
        const SizedBox(height: 4),
        Text(
          '说书人给你的 3 个不在场角色——这是排除法的关键约束。',
          style: AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final c in pool)
              ChoiceChip(
                label: Text(c.nameCn),
                selected: selected.contains(c),
                onSelected: readOnly
                    ? null
                    : (_) async {
                        final next = Set<Character>.of(selected);
                        if (!next.remove(c)) {
                          // #152 BUG-1 同款：恒为 3 个
                          if (next.length >= 3) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bluff 恰为 3 个，先取消一个')),
                            );
                            return;
                          }
                          next.add(c);
                        }
                        await db.gamesDao.updateDemonBluffs(
                          game.id,
                          next.isEmpty
                              ? null
                              : jsonEncode(
                                  next.map((x) => x.name).toList(),
                                ),
                        );
                      },
              ),
          ],
        ),
      ],
    );
  }
}

/// 爪牙侧私密区（#276，7+ 人局我=爪牙）：我的恶魔 + 我的队友。
///
/// 官方（Rules Explanation）：7+ 人局恶魔与爪牙互相认识——爪牙首夜
/// 得知恶魔是谁与全部队友。≤6 人局爪牙不知恶魔，不显示。
/// 队友不含我、不含已选恶魔；恶魔单选（再点取消）。
class MyEvilInfoSection extends ConsumerWidget {
  const MyEvilInfoSection({
    required this.game,
    required this.players,
    this.readOnly = false,
    super.key,
  });

  final Game game;

  /// 全部玩家（候选）。
  final List<Player> players;

  /// 只读（复盘）。
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameColors = context.gameColors;
    final demonId = myDemonPlayerOf(game);
    final teammates = evilTeammateIdsOf(game);
    final db = ref.read(appDatabaseProvider);
    final candidates =
        players.where((p) => p.id != game.myPlayerId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '爪牙私密信息（仅你可见）',
          style:
              AppTextStyles.headline.copyWith(color: gameColors.bloodBright),
        ),
        const SizedBox(height: 8),
        Text('我的恶魔', style: AppTextStyles.label),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final p in candidates)
              ChoiceChip(
                label: Text('${p.seatNumber}号 ${p.name}'),
                selected: demonId == p.id,
                onSelected: readOnly
                    ? null
                    : (_) => db.gamesDao.updateMyDemonPlayerId(
                          game.id,
                          demonId == p.id ? null : p.id,
                        ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('我的队友（邪恶，不含恶魔）', style: AppTextStyles.label),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final p in candidates.where((p) => p.id != demonId))
              ChoiceChip(
                label: Text('${p.seatNumber}号 ${p.name}'),
                selected: teammates.contains(p.id),
                onSelected: readOnly
                    ? null
                    : (_) async {
                        final next = Set<int>.of(teammates);
                        if (!next.remove(p.id)) next.add(p.id);
                        await db.gamesDao.updateMyEvilTeammates(
                          game.id,
                          jsonEncode(next.toList()),
                        );
                      },
              ),
          ],
        ),
      ],
    );
  }
}

/// 修正「我的角色」对话框（#277：myRole 此前开局后不可变——误选或
/// 传承未联动均无法纠正）。带确认（对话框即二次确认，防误触原则）。
Future<void> changeMyRoleDialog(
  BuildContext context,
  WidgetRef ref,
  Game game,
) async {
  final pool = ScriptDefinition.of(game.script).characters;
  var picked = game.myRole;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('修正我的角色'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in pool)
                  ChoiceChip(
                    label: Text(c.nameCn),
                    selected: picked == c,
                    onSelected: (_) => setState(() => picked = c),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '仅用于纠正误选或未联动的传承——角色影响你的信息表单、'
              '私密名单与推理引擎，改动立即生效。',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed:
                picked == null ? null : () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    ),
  );
  final role = picked;
  if (confirmed == true && role != null && role != game.myRole) {
    try {
      await ref
          .read(gameBoardProvider(game.id).notifier)
          .correctMyRole(role);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('我的角色已修正为「${role.nameCn}」')),
      );
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请重试')),
        );
      }
    }
  }
}

Future<void> changeSeatDialog(
  BuildContext context,
  WidgetRef ref,
  Game game,
  List<Player> players,
) async {
  var picked = game.myPlayerId;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('更换我的座位'),
        content: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            // #163 P2：仅存活者候选——不能把「我」换到已死座位。
            for (final p in players.where((p) => p.isAlive))
              ChoiceChip(
                label: Text('${p.seatNumber}号 ${p.name}'),
                selected: picked == p.id,
                onSelected: (_) => setState(() => picked = p.id),
              ),
            // #163 P2：提示私密数据迁移语义。
            const Text(
              '换座后：私密信息（isMine）按新座位重标记，私密爪牙名单清空。',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed:
                picked == null ? null : () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    ),
  );
  final id = picked;
  if (confirmed == true && id != null && id != game.myPlayerId) {
    // #163 P2：换座迁移私密数据（重标记 isMine + 清空爪牙名单），事务内完成。
    try {
      await ref
          .read(appDatabaseProvider)
          .gamesDao
          .reassignMySeat(game.id, id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已更换座位（私密信息已随新座位迁移）')),
      );
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('更换失败，请重试')));
      }
    }
  }
}
