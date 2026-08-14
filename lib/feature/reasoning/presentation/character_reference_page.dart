import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/script_definition.dart';
import 'package:botc_copilot/core/constants/character_reference.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/core/theme/game_colors.dart';
import 'package:botc_copilot/feature/game_board/presentation/providers/game_board_provider.dart';
import 'package:botc_copilot/feature/reasoning/data/contradictions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 阵营 → 主题色（统一 token，无散落 hex）。
Color teamColor(Team team, GameColors gc) => switch (team) {
      Team.townsfolk => gc.trustConfirmedGood,
      Team.outsider => gc.goldBright,
      Team.minion => gc.trustSuspect,
      Team.demon => gc.blood,
    };

/// 角色参考页（issue #60）：能力 + 确认路径 + 机械交互，上下文感知高亮
/// 在场声明角色相关规则。全部内容为官方规则可推导。
class CharacterReferencePage extends ConsumerStatefulWidget {
  /// 创建页面。
  const CharacterReferencePage({required this.gameId, super.key});

  /// 对局 id。
  final int gameId;

  /// 推送页面。
  static void show(BuildContext context, {required int gameId}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CharacterReferencePage(gameId: gameId),
      ),
    );
  }

  @override
  ConsumerState<CharacterReferencePage> createState() =>
      _CharacterReferencePageState();
}

class _CharacterReferencePageState
    extends ConsumerState<CharacterReferencePage> {
  bool _claimedOnly = false;

  /// 每玩家最新声明的角色集合（含死亡揭示）= 「在场声明角色」。
  Set<Character> _claimedSet(List<RoleClaim> claims) {
    final latest = <int, Character>{};
    for (final c in claims) {
      latest[c.playerId] = c.character;
    }
    return latest.values.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final claims =
        ref.watch(gameClaimsProvider(widget.gameId)).valueOrNull ?? [];
    final script = ref.watch(
          gameByIdProvider(widget.gameId).select((g) => g.valueOrNull?.script),
        ) ??
        Script.troubleBrewing;
    final claimed = _claimedSet(claims);

    final teams = [
      Team.townsfolk,
      Team.outsider,
      Team.minion,
      Team.demon,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('角色参考'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilterChip(
              label: const Text('只看声明'),
              selected: _claimedOnly,
              onSelected: (v) => setState(() => _claimedOnly = v),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final team in teams)
            ..._teamSection(team, claimed, script),
          if (_claimedOnly && claimed.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                '尚无角色声明。',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _teamSection(
    Team team,
    Set<Character> claimed,
    Script script,
  ) {
    final gameColors = context.gameColors;
    var chars = ScriptDefinition.of(script).byTeam(team);
    if (_claimedOnly) {
      chars = chars.where((c) => claimed.contains(c)).toList();
    }
    if (chars.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          '${team.nameCn}（${chars.length}）',
          style: AppTextStyles.headline
              .copyWith(color: teamColor(team, gameColors)),
        ),
      ),
      for (final c in chars) _CharacterTile(character: c, claimed: claimed),
    ];
  }
}

/// 单个角色条目：点开展示能力 / 确认路径 / 交互。
class _CharacterTile extends StatelessWidget {
  const _CharacterTile({required this.character, required this.claimed});

  final Character character;
  final Set<Character> claimed;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final ref = characterReferences[character] ?? const CharacterReference();
    final isClaimed = claimed.contains(character);

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(Icons.circle, size: 12, color: teamColor(character.team, gameColors)),
      title: Row(
        children: [
          Flexible(child: Text('${character.nameCn}（${character.nameEn}）')),
          if (isClaimed) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: gameColors.goldBright.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '已声明',
                style: AppTextStyles.caption
                    .copyWith(color: gameColors.goldBright),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        character.ability,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('能力：${character.ability}', style: AppTextStyles.body),
              if (ref.confirmPath != null) ...[
                const SizedBox(height: 8),
                Text('确认路径', style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(
                  ref.confirmPath!,
                  style: AppTextStyles.body
                      .copyWith(color: gameColors.trustConfirmedGood),
                ),
              ],
              if (ref.interactions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('关键交互', style: AppTextStyles.label),
                const SizedBox(height: 2),
                for (final it in ref.interactions)
                  _InteractionRow(interaction: it, claimed: claimed),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InteractionRow extends StatelessWidget {
  const _InteractionRow({required this.interaction, required this.claimed});

  final CharacterInteraction interaction;
  final Set<Character> claimed;

  @override
  Widget build(BuildContext context) {
    final gameColors = context.gameColors;
    final active = interactionActive(interaction, claimed);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(
              active ? Icons.bolt : Icons.circle_outlined,
              size: active ? 12 : 8,
              color: active ? gameColors.goldBright : gameColors.inkViolet,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              interaction.text,
              style: AppTextStyles.body.copyWith(
                color: active ? gameColors.goldBright : null,
                fontWeight: active ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
