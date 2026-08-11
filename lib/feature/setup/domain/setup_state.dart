import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/player_setup.dart';
import 'package:botc_copilot/core/constants/script.dart';

/// 开局设置向导状态。
class SetupState {
  /// 创建设置状态（默认：TB 剧本、7 人局）。
  SetupState({
    this.step = 0,
    this.script = Script.troubleBrewing,
    int playerCount = 7,
    List<String>? playerNames,
    this.myRole,
    this.submitting = false,
  })  : playerCount = playerCount,
        playerNames = playerNames ?? List.filled(playerCount, '');

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

  /// 是否正在提交（防重复点击）。
  final bool submitting;

  /// 总步数。
  static const int totalSteps = 5;

  /// 当前人数对应的游戏配置。
  PlayerSetup get playerSetup => PlayerSetup.forCount(playerCount);

  /// 当前步骤是否可前进。
  bool get canProceed => switch (step) {
        0 => true, // 剧本必有默认选中
        1 => true, // 人数必有默认值
        2 => playerNames.every((n) => n.trim().isNotEmpty),
        3 => myRole != null,
        4 => !submitting,
        _ => false,
      };

  /// 复制并修改部分字段。
  SetupState copyWith({
    int? step,
    Script? script,
    int? playerCount,
    List<String>? playerNames,
    Character? myRole,
    bool? submitting,
  }) {
    return SetupState(
      step: step ?? this.step,
      script: script ?? this.script,
      playerCount: playerCount ?? this.playerCount,
      playerNames: playerNames ?? this.playerNames,
      myRole: myRole ?? this.myRole,
      submitting: submitting ?? this.submitting,
    );
  }
}
