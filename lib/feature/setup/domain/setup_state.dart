import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/constants/script.dart';

/// 开局设置向导状态。
class SetupState {
  /// 创建设置状态（默认：TB 剧本、7 人局）。
  ///
  /// 玩家名默认 A~Z 字母（省去逐个输入），用户可按需修改。
  SetupState({
    this.step = 0,
    this.script = Script.troubleBrewing,
    int playerCount = 7,
    List<String>? playerNames,
    this.myRole,
    this.demonBluffs = const [],
    this.mySeat,
    this.submitting = false,
  })  : playerCount = playerCount,
        playerNames =
            playerNames ?? [for (var i = 0; i < playerCount; i++) String.fromCharCode(65 + i)];

  /// 当前步骤（0-4）。
  final int step;

  /// 剧本。
  final Script script;

  /// 玩家数（5-15）。
  final int playerCount;

  /// 玩家名（按座位顺序，索引 0 = 1 号位）。
  final List<String> playerNames;

  /// 我的角色。
  final Character? myRole;

  /// 恶魔 Bluff 角色（仅当 myRole 是恶魔时录入，最多 3 个）。
  final List<Character> demonBluffs;

  /// 我的座位号（1-based，null = 未选择）。
  ///
  /// 用于开局即写入 games.myPlayerId，使圆环立刻显示金色描边。
  final int? mySeat;

  /// 是否正在提交（防重复点击）。
  final bool submitting;

  /// 总步数。
  static const int totalSteps = 5;

  /// 当前人数对应的游戏配置。
  PlayerSetup get playerSetup => PlayerSetup.forCount(playerCount);

  /// 玩家名步校验错误（#163 P1），null = 通过。
  ///
  /// 空名（trim 后）显示残缺；重名在提名 / 投票 / 信息录入 / 时间线中歧义。
  String? get nameValidationError {
    final trimmed =
        playerNames.map((n) => n.trim()).toList(growable: false);
    if (trimmed.any((n) => n.isEmpty)) return '每个座位都需要名字';
    if (trimmed.toSet().length != trimmed.length) return '存在重名，请区分玩家';
    return null;
  }

  /// 当前步骤是否可前进。
  bool get canProceed => switch (step) {
        0 => true, // 剧本必有默认选中
        1 => true, // 人数必有默认值
        2 => nameValidationError == null, // 名字：无空名 / 重名（#163 P1）
        3 => myRole != null,
        4 => !submitting,
        _ => false,
      };

  /// 复制并修改部分字段。
  ///
  /// [mySeat] 为哨兵模式：传 `() => null` 显式清除，不传则保留原值。
  SetupState copyWith({
    int? step,
    Script? script,
    int? playerCount,
    List<String>? playerNames,
    Character? myRole,
    List<Character>? demonBluffs,
    int? Function()? mySeat,
    bool? submitting,
  }) {
    return SetupState(
      step: step ?? this.step,
      script: script ?? this.script,
      playerCount: playerCount ?? this.playerCount,
      playerNames: playerNames ?? this.playerNames,
      myRole: myRole ?? this.myRole,
      demonBluffs: demonBluffs ?? this.demonBluffs,
      mySeat: mySeat != null ? mySeat() : this.mySeat,
      submitting: submitting ?? this.submitting,
    );
  }
}
