import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/info_input_type.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/player_pair_picker.dart';
import 'package:flutter/material.dart';

/// 信息输入工厂：根据角色的 InfoInputType 返回对应输入组件。
///
/// 每种输入组件产出结构化 payload（Map），由调用方编码为 JSON
/// 写入 info_declarations 表。payload 格式见各 widget 的 dartdoc。
abstract final class InfoInputFactory {
  /// 按角色的输入类型构建对应输入组件。
  ///
  /// [actingPlayerId] 为录入该信息的玩家 id，用于夜间行动目标的自排除
  /// （Monk/Butler 不能选自己）。
  static Widget build({
    required Character character,
    required List<Player> players,
    required void Function(Map<String, Object?> payload) onSubmit,
    int? actingPlayerId,
  }) {
    return switch (character.infoInputType) {
      InfoInputType.none => const _NoInput(),
      InfoInputType.numberRange => _NumberInput(
          max: (players.length / 2).floor(), // Chef 最大对数
          onSubmit: onSubmit,
        ),
      InfoInputType.numberZeroToTwo =>
        _NumberInput(max: 2, onSubmit: onSubmit),
      InfoInputType.twoPlayersYesNo =>
        _TwoPlayersYesNoInput(players: players, onSubmit: onSubmit),
      InfoInputType.minionPlusTwoPlayers => _CharacterPlusTwoPlayersInput(
          team: Team.minion,
          players: players,
          onSubmit: onSubmit,
        ),
      InfoInputType.townsfolkPlusTwoPlayers => _CharacterPlusTwoPlayersInput(
          team: Team.townsfolk,
          players: players,
          onSubmit: onSubmit,
        ),
      InfoInputType.outsiderPlusTwoPlayersOrNone =>
        _CharacterPlusTwoPlayersInput(
          team: Team.outsider,
          players: players,
          allowNone: true,
          onSubmit: onSubmit,
        ),
      InfoInputType.characterName =>
        _CharacterNameInput(onSubmit: onSubmit),
      InfoInputType.playerPlusCharacter =>
        _PlayerPlusCharacterInput(players: players, onSubmit: onSubmit),
      InfoInputType.singlePlayerTarget => _SinglePlayerInput(
          players: players,
          onSubmit: onSubmit,
          // 官方规则：Monk/Butler「不能选自己」；Poisoner 可选任何人。
          excludePlayerId:
              (character == Character.monk || character == Character.butler)
                  ? actingPlayerId
                  : null,
        ),
      InfoInputType.freeText => _FreeTextInput(onSubmit: onSubmit),
    };
  }
}

/// 无信息类能力。
class _NoInput extends StatelessWidget {
  const _NoInput();

  @override
  Widget build(BuildContext context) {
    return Text(
      '该角色无信息类能力，无需录入。',
      style: AppTextStyles.caption,
    );
  }
}

/// 数字输入（Chef 0-N / Empath 0-2）。payload: {"value": n}
class _NumberInput extends StatefulWidget {
  const _NumberInput({required this.max, required this.onSubmit});

  final int max;
  final void Function(Map<String, Object?>) onSubmit;

  @override
  State<_NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<_NumberInput> {
  int _value = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: _value > 0 ? () => setState(() => _value--) : null,
        ),
        Text('$_value', style: AppTextStyles.title),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed:
              _value < widget.max ? () => setState(() => _value++) : null,
        ),
        const Spacer(),
        FilledButton(
          onPressed: () => widget.onSubmit({'value': _value}),
          child: const Text('记录'),
        ),
      ],
    );
  }
}

/// 双人选择 + 是/否（Fortune Teller）。
/// payload: {"playerIds": [a, b], "answer": true}
class _TwoPlayersYesNoInput extends StatefulWidget {
  const _TwoPlayersYesNoInput({required this.players, required this.onSubmit});

  final List<Player> players;
  final void Function(Map<String, Object?>) onSubmit;

  @override
  State<_TwoPlayersYesNoInput> createState() => _TwoPlayersYesNoInputState();
}

class _TwoPlayersYesNoInputState extends State<_TwoPlayersYesNoInput> {
  final Set<int> _selected = {};
  bool _answer = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlayerPairPicker(
          players: widget.players,
          selected: _selected,
          onChanged: (Set<int> s) => setState(() => _selected
            ..clear()
            ..addAll(s)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('结果', style: AppTextStyles.label),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('是'),
              selected: _answer,
              onSelected: (_) => setState(() => _answer = true),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('否'),
              selected: !_answer,
              onSelected: (_) => setState(() => _answer = false),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _selected.length == 2
                  ? () => widget.onSubmit({
                        'playerIds': _selected.toList(),
                        'answer': _answer,
                      })
                  : null,
              child: const Text('记录'),
            ),
          ],
        ),
      ],
    );
  }
}

/// 角色 + 双人选择（Investigator/Washerwoman/Librarian）。
/// payload: {"character": "poisoner", "playerIds": [a, b]}
/// Librarian 允许"无外来者"：payload: {"character": null, "playerIds": []}
class _CharacterPlusTwoPlayersInput extends StatefulWidget {
  const _CharacterPlusTwoPlayersInput({
    required this.team,
    required this.players,
    required this.onSubmit,
    this.allowNone = false,
  });

  final Team team;
  final List<Player> players;
  final bool allowNone;
  final void Function(Map<String, Object?>) onSubmit;

  @override
  State<_CharacterPlusTwoPlayersInput> createState() =>
      _CharacterPlusTwoPlayersInputState();
}

class _CharacterPlusTwoPlayersInputState
    extends State<_CharacterPlusTwoPlayersInput> {
  Character? _character;
  final Set<int> _selected = {};
  bool _isNone = false;

  @override
  Widget build(BuildContext context) {
    final characters = Character.byTeam(widget.team);
    final ready = _isNone || (_character != null && _selected.length == 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final c in characters)
              ChoiceChip(
                label: Text(c.nameCn),
                selected: _character == c && !_isNone,
                onSelected: (_) => setState(() {
                  _character = c;
                  _isNone = false;
                }),
              ),
            if (widget.allowNone)
              ChoiceChip(
                label: const Text('无'),
                selected: _isNone,
                onSelected: (_) => setState(() => _isNone = true),
              ),
          ],
        ),
        if (!_isNone) ...[
          const SizedBox(height: 8),
          PlayerPairPicker(
            players: widget.players,
            selected: _selected,
            onChanged: (Set<int> s) => setState(() => _selected
              ..clear()
              ..addAll(s)),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: ready
                ? () => widget.onSubmit({
                      'character': _isNone ? null : _character!.name,
                      'playerIds': _selected.toList(),
                    })
                : null,
            child: const Text('记录'),
          ),
        ),
      ],
    );
  }
}

/// 角色名选择（Undertaker）。payload: {"character": "imp"}
class _CharacterNameInput extends StatefulWidget {
  const _CharacterNameInput({required this.onSubmit});

  final void Function(Map<String, Object?>) onSubmit;

  @override
  State<_CharacterNameInput> createState() => _CharacterNameInputState();
}

class _CharacterNameInputState extends State<_CharacterNameInput> {
  Character? _character;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final c in Character.values)
              ChoiceChip(
                label: Text(c.nameCn),
                selected: _character == c,
                onSelected: (_) => setState(() => _character = c),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _character != null
                ? () => widget.onSubmit({'character': _character!.name})
                : null,
            child: const Text('记录'),
          ),
        ),
      ],
    );
  }
}

/// 玩家 + 角色名（Ravenkeeper）。
/// payload: {"playerId": 3, "character": "poisoner"}
class _PlayerPlusCharacterInput extends StatefulWidget {
  const _PlayerPlusCharacterInput({
    required this.players,
    required this.onSubmit,
  });

  final List<Player> players;
  final void Function(Map<String, Object?>) onSubmit;

  @override
  State<_PlayerPlusCharacterInput> createState() =>
      _PlayerPlusCharacterInputState();
}

class _PlayerPlusCharacterInputState
    extends State<_PlayerPlusCharacterInput> {
  int? _playerId;
  Character? _character;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final p in widget.players)
              ChoiceChip(
                label: Text('${p.seatNumber}号 ${p.name}'),
                selected: _playerId == p.id,
                onSelected: (_) => setState(() => _playerId = p.id),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final c in Character.values)
              ChoiceChip(
                label: Text(c.nameCn),
                selected: _character == c,
                onSelected: (_) => setState(() => _character = c),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _playerId != null && _character != null
                ? () => widget.onSubmit({
                      'playerId': _playerId,
                      'character': _character!.name,
                    })
                : null,
            child: const Text('记录'),
          ),
        ),
      ],
    );
  }
}

/// 单玩家选择（Monk 保护 / Butler 主人 / Poisoner 下毒）。
/// payload: {"playerId": n}
class _SinglePlayerInput extends StatefulWidget {
  const _SinglePlayerInput({
    required this.players,
    required this.onSubmit,
    this.excludePlayerId,
  });

  final List<Player> players;

  /// 排除的玩家 id（Monk/Butler 不能选自己；null = 不排除）。
  final int? excludePlayerId;

  final void Function(Map<String, Object?>) onSubmit;

  @override
  State<_SinglePlayerInput> createState() => _SinglePlayerInputState();
}

class _SinglePlayerInputState extends State<_SinglePlayerInput> {
  int? _playerId;

  @override
  Widget build(BuildContext context) {
    // 夜间行动目标须为存活玩家（Monk 保护 / Butler 主人 / Poisoner 下毒均针对存活者）
    final candidates = widget.players
        .where((p) => p.isAlive && p.id != widget.excludePlayerId)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final p in candidates)
              ChoiceChip(
                label: Text('${p.seatNumber}号 ${p.name}'),
                selected: _playerId == p.id,
                onSelected: (_) => setState(() => _playerId = p.id),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _playerId != null
                ? () => widget.onSubmit({'playerId': _playerId})
                : null,
            child: const Text('记录'),
          ),
        ),
      ],
    );
  }
}

/// 自由文本。payload: {"text": "..."}
class _FreeTextInput extends StatefulWidget {
  const _FreeTextInput({required this.onSubmit});

  final void Function(Map<String, Object?>) onSubmit;

  @override
  State<_FreeTextInput> createState() => _FreeTextInputState();
}

class _FreeTextInputState extends State<_FreeTextInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: '记录信息…',
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _controller.text.trim().isNotEmpty
              ? () => widget.onSubmit({'text': _controller.text.trim()})
              : null,
          child: const Text('记录'),
        ),
      ],
    );
  }
}
