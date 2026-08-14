import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/info_input_type.dart';
import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/constants/team.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/script_definition.dart';
import 'package:botc_copilot/core/theme/app_text_styles.dart';
import 'package:botc_copilot/feature/player_detail/presentation/widgets/player_pair_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    required Script script,
    int? actingPlayerId,
  }) {
    // 剧本角色池（#230）：多剧本后角色 chips 只列本局剧本的角色。
    final pool = ScriptDefinition.of(script);
    return switch (character.infoInputType) {
      InfoInputType.none => const _NoInput(),
      // Chef：相邻邪恶对数。用 evilCount（容纳 Recluse 注册为邪恶的边缘——
      // TB 唯一幻影邪恶来源，可能使相邻对 +1；基础 max=evilCount−1）。
      // clamp 防御首帧 players 为空（forCount 对越界人数抛异常）。
      InfoInputType.numberRange => _NumberInput(
          max: PlayerSetup.forCount(players.length.clamp(5, 15)).evilCount,
          onSubmit: onSubmit,
        ),
      InfoInputType.numberZeroToTwo =>
        _NumberInput(max: 2, onSubmit: onSubmit),
      InfoInputType.twoPlayersYesNo =>
        _TwoPlayersYesNoInput(players: players, onSubmit: onSubmit),
      InfoInputType.minionPlusTwoPlayers => _CharacterPlusTwoPlayersInput(
          characters: pool.byTeam(Team.minion),
          players: players,
          onSubmit: onSubmit,
        ),
      InfoInputType.townsfolkPlusTwoPlayers => _CharacterPlusTwoPlayersInput(
          characters: pool.byTeam(Team.townsfolk),
          players: players,
          onSubmit: onSubmit,
        ),
      InfoInputType.outsiderPlusTwoPlayersOrNone =>
        _CharacterPlusTwoPlayersInput(
          characters: pool.byTeam(Team.outsider),
          players: players,
          allowNone: true,
          onSubmit: onSubmit,
        ),
      InfoInputType.characterName =>
        _CharacterNameInput(characters: pool.characters, onSubmit: onSubmit),
      InfoInputType.playerPlusCharacter => _PlayerPlusCharacterInput(
          characters: pool.characters,
          players: players,
          onSubmit: onSubmit,
        ),
      InfoInputType.singlePlayerTarget => _SinglePlayerInput(
          players: players,
          onSubmit: onSubmit,
          // 官方规则：Monk/Butler「不能选自己」（canTargetSelf 数据化，#230）。
          excludePlayerId:
              character.canTargetSelf ? null : actingPlayerId,
          // 官方规则：Professor 复活目标须为已死玩家，其余为存活目标。
          deadOnly: character.requiresDeadTarget,
        ),
      InfoInputType.twoPlayersNumber => _TwoPlayersNumberInput(
          players: players,
          onSubmit: onSubmit,
          // 官方规则：Chambermaid「不能选自己」。
          excludePlayerId:
              character.canTargetSelf ? null : actingPlayerId,
        ),
      InfoInputType.twoPlayersTarget => _TwoPlayersTargetInput(
          players: players,
          onSubmit: onSubmit,
          excludePlayerId:
              character.canTargetSelf ? null : actingPlayerId,
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
    required this.characters,
    required this.players,
    required this.onSubmit,
    this.allowNone = false,
  });

  /// 剧本角色池子集（#230，按阵营预过滤）。
  final List<Character> characters;
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
    final characters = widget.characters;
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
  const _CharacterNameInput({
    required this.characters,
    required this.onSubmit,
  });

  /// 剧本角色池（#230）。
  final List<Character> characters;
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
            for (final c in widget.characters)
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
    required this.characters,
    required this.players,
    required this.onSubmit,
  });

  /// 剧本角色池（#230）。
  final List<Character> characters;
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
            for (final c in widget.characters)
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
    this.deadOnly = false,
  });

  final List<Player> players;

  /// 排除的玩家 id（Monk/Butler 不能选自己；null = 不排除）。
  final int? excludePlayerId;

  /// 只列死亡玩家（Professor 复活目标；否则只列存活玩家）。
  final bool deadOnly;

  final void Function(Map<String, Object?>) onSubmit;

  @override
  State<_SinglePlayerInput> createState() => _SinglePlayerInputState();
}

class _SinglePlayerInputState extends State<_SinglePlayerInput> {
  int? _playerId;

  @override
  Widget build(BuildContext context) {
    // 夜间行动目标默认为存活玩家（Monk/Butler/Poisoner 均针对存活者）；
    // Professor 复活目标相反，须为已死玩家（官方 choose a dead player）。
    final candidates = widget.players
        .where((p) => p.isAlive != widget.deadOnly)
        .where((p) => p.id != widget.excludePlayerId)
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
            inputFormatters: [LengthLimitingTextInputFormatter(500)],
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

/// 双人 + 0-2 数字（BMR 侍女：得知两人中几人夜间醒来）。
/// payload: {"playerIds": [a, b], "value": n}
class _TwoPlayersNumberInput extends StatefulWidget {
  const _TwoPlayersNumberInput({
    required this.players,
    required this.onSubmit,
    this.excludePlayerId,
  });

  final List<Player> players;

  /// 排除的玩家 id（侍女不能选自己；null = 不排除）。
  final int? excludePlayerId;

  final void Function(Map<String, Object?>) onSubmit;

  @override
  State<_TwoPlayersNumberInput> createState() => _TwoPlayersNumberInputState();
}

class _TwoPlayersNumberInputState extends State<_TwoPlayersNumberInput> {
  final Set<int> _selected = {};
  int? _value;

  @override
  Widget build(BuildContext context) {
    final ready = _selected.length == 2 && _value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlayerPairPicker(
          players: widget.players,
          selected: _selected,
          excludePlayerId: widget.excludePlayerId,
          onChanged: (s) => setState(() {
            _selected
              ..clear()
              ..addAll(s);
          }),
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('0 人')),
            ButtonSegment(value: 1, label: Text('1 人')),
            ButtonSegment(value: 2, label: Text('2 人')),
          ],
          selected: {_value ?? -1},
          onSelectionChanged: (s) => setState(() => _value = s.first),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: ready
                ? () => widget.onSubmit({
                      'playerIds': _selected.toList(),
                      'value': _value,
                    })
                : null,
            child: const Text('记录'),
          ),
        ),
      ],
    );
  }
}

/// 双人保护目标（BMR 旅店老板）。
/// payload: {"playerIds": [a, b]}
class _TwoPlayersTargetInput extends StatefulWidget {
  const _TwoPlayersTargetInput({
    required this.players,
    required this.onSubmit,
    this.excludePlayerId,
  });

  final List<Player> players;

  /// 排除的玩家 id（null = 不排除）。
  final int? excludePlayerId;

  final void Function(Map<String, Object?>) onSubmit;

  @override
  State<_TwoPlayersTargetInput> createState() => _TwoPlayersTargetInputState();
}

class _TwoPlayersTargetInputState extends State<_TwoPlayersTargetInput> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final ready = _selected.length == 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlayerPairPicker(
          players: widget.players,
          selected: _selected,
          excludePlayerId: widget.excludePlayerId,
          onChanged: (s) => setState(() {
            _selected
              ..clear()
              ..addAll(s);
          }),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: ready
                ? () => widget.onSubmit({'playerIds': _selected.toList()})
                : null,
            child: const Text('记录'),
          ),
        ),
      ],
    );
  }
}
