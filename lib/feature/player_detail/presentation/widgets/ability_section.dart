
import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/domain/game_end.dart';
import 'package:botc_copilot/feature/game_board/presentation/succession_handler.dart';
import 'package:botc_copilot/feature/player_detail/data/ability_repository.dart';
import 'package:botc_copilot/feature/player_detail/data/player_detail_repository.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// App 追踪玩家**声明**角色的能力状态，并提供录入动作，不代替裁决隐藏
/// 信息（是否真为恶魔、是否真被毒由用户确认）。
class AbilitySection extends ConsumerStatefulWidget {
  const AbilitySection({
    required this.gameId,
    required this.playerId,
    required this.day,
    required this.character,
    required this.players,
  });

  final int gameId;
  final int playerId;
  final int day;
  final Character character;
  final List<Player> players;

  @override
  ConsumerState<AbilitySection> createState() => AbilitySectionState();
}

class AbilitySectionState extends ConsumerState<AbilitySection> {
  int? _targetId;
  bool _targetIsDemon = false;
  bool _wasPoisoned = false;
  bool _submitting = false;

  Player? get _live => widget.players
      .where((p) => p.id == widget.playerId)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final used = _live?.abilityUsed ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('一次性能力 · ${widget.character.nameCn}',
            style: AppTextStyles.headline),
        const SizedBox(height: 8),
        switch (widget.character) {
          Character.virgin => _buildVirgin(used, gameColors),
          Character.slayer => _buildSlayer(used, gameColors),
          Character.saint => _buildSaint(gameColors),
          // #269②：一次性/限频能力追踪补缺（此前仅 TB 三角色）。
          Character.courtier => _buildCourtier(used, gameColors),
          Character.gambler => _buildGambler(gameColors),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }

  /// Virgin：追踪能力消耗。
  ///
  /// 官方规则（Wiki · Virgin · Summary）：首次被提名后处女即失去能力，
  /// **即使提名者未死、即使处女当时被毒/醉**。被毒/醉时能力不触发
  /// （提名者不被处决），但能力仍已消耗——清醒后再被提名不再触发。
  Widget _buildVirgin(bool used, GameColors gameColors) {
    // Virgin 能力被动触发（首次被提名消耗），此开关是历史记录而非「发动能力」——
    // 死者亦可补录消耗状态。仅 Slayer 主动击杀需门控死者（#154 R-2）。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('能力已消耗'),
          value: used,
          activeTrackColor: gameColors.inkViolet,
          onChanged: (v) async {
            await ref
                .read(abilityRepositoryProvider)
                .setAbilityUsed(widget.playerId, used: v);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(v ? '处女能力已标记消耗' : '处女能力已恢复'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
        Text(
          '官方规则：处女首次被镇民提名时，提名者立即被处决（当天提名结束）。'
          '被非镇民提名不触发，但能力仍失去。'
          '被毒/醉时被提名不触发（无人被处决），但能力同样已消耗——'
          '清醒后再被提名不再触发。',
          style: AppTextStyles.caption
              .copyWith(color: gameColors.inkViolet),
        ),
      ],
    );
  }

  /// Saint：提示（被处决时善良立即战败，处决流程会有提示）。
  Widget _buildSaint(GameColors gameColors) {
    return Text(
      '圣徒被处决时，善良方立即战败。处决此人时 App 会提示「邪恶获胜」。',
      style: AppTextStyles.caption.copyWith(color: gameColors.bloodBright),
    );
  }

  /// Courtier（#269②）：每局限一次——追踪能力消耗，手动开关（同 Virgin
  /// 先例，历史记录而非「发动能力」按钮）。醉/毒时使用也永久消耗（公理4）。
  Widget _buildCourtier(bool used, GameColors gameColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('能力已消耗（每局限一次）'),
          value: used,
          activeTrackColor: gameColors.inkViolet,
          onChanged: (v) async {
            await ref
                .read(abilityRepositoryProvider)
                .setAbilityUsed(widget.playerId, used: v);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(v ? '侍臣能力已标记消耗' : '侍臣能力已恢复'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
        Text(
          '官方规则：每局限一次，夜晚选择一个角色——该角色醉 3 夜 3 天'
          '（固定时长，无时长选择）。信息录入区记录所选角色时会自动标记'
          '消耗；被毒/醉时使用同样永久消耗，不因清醒返还。',
          style: AppTextStyles.caption
              .copyWith(color: gameColors.inkViolet),
        ),
      ],
    );
  }

  /// Gambler（#269②）：每晚限一次（非一次性，无 abilityUsed）——展示当晚
  /// 已录赌注数，多次记录时录入区会二次确认。
  Widget _buildGambler(GameColors gameColors) {
    final decls =
        ref.watch(gameAllDeclarationsProvider(widget.gameId)).valueOrNull ??
            const <InfoDeclaration>[];
    final days =
        ref.watch(gameDayRecordsProvider(widget.gameId)).valueOrNull ??
            const <DayRecord>[];
    final dayIds = {
      for (final d in days.where((d) => d.dayNumber == widget.day)) d.id,
    };
    final count = decls
        .where(
          (d) =>
              d.playerId == widget.playerId &&
              d.characterType == Character.gambler &&
              dayIds.contains(d.dayRecordId),
        )
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count == 0
              ? '今晚尚未记录赌注（每个夜晚*限一次）'
              : '今晚已记录 $count 次赌注（每个夜晚*限一次，再次记录会二次确认）',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 4),
        Text(
          '官方规则：每个夜晚*选择一名玩家并猜测其角色，猜错则你死亡'
          '（死亡标记请走座位死亡入口）。信息录入区记录目标与猜测，'
          '同一晚重复记录会弹出确认。',
          style: AppTextStyles.caption
              .copyWith(color: gameColors.inkViolet),
        ),
      ],
    );
  }

  /// Slayer：一次性猜测录入。
  Widget _buildSlayer(bool used, GameColors gameColors) {
    if (used) {
      return Text(
        '已使用（一次性，不可再用）。即使当时被毒/醉，能力也已永久消耗。',
        style: AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
      );
    }
    // 官方规则：死亡玩家不能发动角色能力（#154 R-2）。
    if (!(_live?.isAlive ?? true)) {
      return Text(
        '已死亡，能力不可用（死者不能发动能力）。',
        style: AppTextStyles.caption.copyWith(color: gameColors.inkViolet),
      );
    }
    final candidates = widget.players
        .where((p) => p.id != widget.playerId && p.isAlive)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('猜测目标是恶魔', style: AppTextStyles.body),
        const SizedBox(height: 4),
        DropdownButton<int>(
          value: _targetId,
          hint: const Text('选择目标'),
          isExpanded: true,
          items: [
            for (final p in candidates)
              DropdownMenuItem(
                value: p.id,
                child: Text('${p.seatNumber}号 ${p.name}'),
              ),
          ],
          onChanged: (v) => setState(() => _targetId = v),
        ),
        CheckboxListTile(
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('目标是恶魔'),
          value: _targetIsDemon,
          onChanged: (v) => setState(() => _targetIsDemon = v ?? false),
        ),
        CheckboxListTile(
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('我此刻被毒/醉'),
          subtitle: const Text('被毒/醉时能力仍永久消耗，但不击杀'),
          value: _wasPoisoned,
          onChanged: (v) => setState(() => _wasPoisoned = v ?? false),
        ),
        FilledButton(
          onPressed: (_targetId != null && !_submitting) ? _submitSlayer : null,
          child: Text(_submitting ? '处理中…' : '使用 Slayer 猜测'),
        ),
      ],
    );
  }

  Future<void> _submitSlayer() async {
    // 僵怖假死裁决（#264 ②）：官方「第一次死亡时你活着但登记为死」覆盖
    // 一切死亡来源——击中恶魔时先问目标是否假死（用户按目标后续表现判定）。
    var targetFakeDied = false;
    if (_targetIsDemon && !_wasPoisoned && mounted) {
      final fake = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('僵怖首次死亡？'),
          content: const Text(
            '官方：僵怖第一次死亡时（无论处决还是能力击杀）活着但登记为死。\n'
            '目标是僵怖且为首次死亡吗？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('真死亡'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('假死（登记为死）'),
            ),
          ],
        ),
      );
      if (fake == null) return; // 取消提交
      targetFakeDied = fake;
    }
    setState(() => _submitting = true);
    final SlayerGuessResult result;
    try {
      result = await ref.read(abilityRepositoryProvider).recordSlayerGuess(
            slayerId: widget.playerId,
            targetId: _targetId!,
            targetIsDemon: _targetIsDemon,
            wasPoisoned: _wasPoisoned,
            day: widget.day,
            targetFakeDied: targetFakeDied,
          );
    } on Object {
      // #164 B9：recordSlayerGuess 已事务化（#150 R4），失败则能力未消耗。
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('提交失败，请重试')));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    // recordSlayerGuess 仅在 targetIsDemon && !wasPoisoned 时返回 killed。
    if (result == SlayerGuessResult.killed) {
      if (targetFakeDied) {
        // 僵怖假死：恶魔未死——无传承/终局，对局继续（#264 ②）。
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('目标为僵怖首次死亡：登记为死但活着，对局继续')),
        );
        return;
      }
      // 击中恶魔 → 查 SW 传承（在场则不终局），否则善良胜（issue #89）
      final notifier = ref.read(gameBoardProvider(widget.gameId).notifier);
      final succ = await notifier.checkDemonDeath(
        _targetId!,
        way: DeathWay.slayer,
      );
      if (!mounted) return;
      if (succ is DemonSuccessionCandidate) {
        await handleSuccession(context, ref, widget.gameId, succ);
      } else {
        await notifier.endGame(goodWin: true, revealedPlayerId: _targetId);
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('未击杀（目标非恶魔 或 你被毒/醉），能力已永久消耗'),
      ),
    );
  }
}
