import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart';

/// 对局表：一局游戏的顶层实体。
class Games extends Table {
  /// 自增主键。
  IntColumn get id => integer().autoIncrement()();

  /// 剧本。
  IntColumn get script => intEnum<Script>()();

  /// 玩家数（5-15）。
  IntColumn get playerCount => integer()();

  /// 对局状态。
  TextColumn get status => textEnum<GameStatus>()();

  /// 创建时间。
  DateTimeColumn get createdAt => dateTime()();

  /// 我的角色（开局设置时可能暂未确定，允许为空）。
  IntColumn get myRole => intEnum<Character>().nullable()();

  /// 我的玩家 id（哪个座位是我；首次录入我的信息时确定）。
  ///
  /// 注意：故意不用 references()——Games↔Players 互相引用会让 Drift
  /// 为打破循环而丢弃 Players.gameId 的 CASCADE 外键。
  /// 该列由应用层维护一致性。
  IntColumn get myPlayerId => integer().nullable()();

  /// 恶魔的 3 个 Bluff 角色（JSON 数组，仅当我是恶魔时录入）。
  TextColumn get demonBluffsJson => text().nullable()();

  /// 我的爪牙名单（JSON 玩家 id 数组，issue #108）。
  ///
  /// 官方：7+ 人局恶魔首夜得知爪牙是谁。这是恶魔**私密知识**——存 Games 列
  /// （与公开声明的 RoleClaims 隔离），不进矛盾检测/角色矩阵公开侧，仅对我
  /// 可见（角色矩阵私密标记）。
  TextColumn get myMinionIdsJson => text().nullable()();

  /// 帮助层级（issue #41）。
  TextColumn get helpLevel =>
      textEnum<HelpLevel>().withDefault(const Constant('normal'))();
}

/// 玩家表：按座位顺序存储。
class Players extends Table {
  /// 自增主键。
  IntColumn get id => integer().autoIncrement()();

  /// 所属对局。
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();

  /// 玩家名。
  TextColumn get name => text()();

  /// 座位号（1-N，顺时针）。
  IntColumn get seatNumber => integer()();

  /// 是否存活。
  BoolColumn get isAlive => boolean().withDefault(const Constant(true))();

  /// 死亡天数（存活则为空）。
  IntColumn get deathDay => integer().nullable()();

  /// 死亡原因（存活则为空）。
  TextColumn get deathCause => textEnum<DeathCause>().nullable()();

  /// 一次性能力是否已消耗（issue #54：Virgin / Slayer）。
  ///
  /// App 追踪的是玩家**声明**角色的能力状态：Virgin 首次被 Townsfolk
  /// 提名（且未醉毒）触发后标记；Slayer 使用猜测后标记。Saint 无需此
  /// 字段（处决时即时判定）。
  BoolColumn get abilityUsed =>
      boolean().withDefault(const Constant(false))();

  /// 疑似醉汉（整局身份推测，issue #109）。
  ///
  /// 官方规则：醉汉是**整局身份**（从头到尾醉酒，非按天毒），其所有天的
  /// 信息都为假。这与「按天的毒」（PoisonStatuses）语义不同——故挂在玩家
  /// 上作整局标记。标记后该玩家全部信息（历史+未来）按可能不可靠处理。
  BoolColumn get suspectedDrunk =>
      boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        // 同一局中座位号唯一。
        {gameId, seatNumber},
      ];
}

/// 每日记录表：一天 = 夜晚 + 白天的聚合记录。
class DayRecords extends Table {
  /// 自增主键。
  IntColumn get id => integer().autoIncrement()();

  /// 所属对局。
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();

  /// 天数（从 1 开始）。
  IntColumn get dayNumber => integer()();

  /// 夜晚死亡玩家（无人死亡为空；TB 单杀，多杀剧本后续扩展）。
  @ReferenceName('nightDeathDays')
  IntColumn get nightDeathPlayerId =>
      integer().nullable().references(Players, #id)();

  /// 夜晚结果是否已确认（issue #77）。
  ///
  /// 解决 `nightDeathPlayerId == null` 的二义性（「尚未录入」vs「确认无人
  /// 死亡」）：预建次日记录时为 false；用户确认夜晚结果（标记死亡或点
  /// 「无人死亡」）后置 true。矛盾规则、时间线、chip 选中态均以此为准。
  BoolColumn get nightConfirmed =>
      boolean().withDefault(const Constant(false))();

  /// 白天被处决玩家（无处决为空）。
  @ReferenceName('executionDays')
  IntColumn get dayExecutionPlayerId =>
      integer().nullable().references(Players, #id)();

  /// @deprecated 掘墓人报出的被处决者角色。
  ///
  /// **此列在生产环境无写入方**（issue #106）：掘墓人信息实际录入通道是
  /// `InfoDeclarations`（characterType == undertaker）。保留此列仅为避免
  /// schema migration 风险，读取/写入一律走 InfoDeclarations。
  IntColumn get undertakerResultRole => intEnum<Character>().nullable()();

  /// 当日备注。
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        // 同一局中天数唯一。
        {gameId, dayNumber},
      ];
}

/// 角色声明表：某玩家在某天声明的角色。
class RoleClaims extends Table {
  /// 自增主键。
  IntColumn get id => integer().autoIncrement()();

  /// 声明者。
  IntColumn get playerId =>
      integer().references(Players, #id, onDelete: KeyAction.cascade)();

  /// 声明发生的当天。
  IntColumn get dayRecordId =>
      integer().references(DayRecords, #id, onDelete: KeyAction.cascade)();

  /// 声明的角色。
  IntColumn get character => intEnum<Character>()();

  /// 声明类型（首次/改口/死亡揭示）。
  TextColumn get claimType => textEnum<ClaimType>()();
}

/// 信息声明表：某玩家在某天报出的具体信息。
class InfoDeclarations extends Table {
  /// 自增主键。
  IntColumn get id => integer().autoIncrement()();

  /// 信息提供者。
  IntColumn get playerId =>
      integer().references(Players, #id, onDelete: KeyAction.cascade)();

  /// 信息报出的当天。
  IntColumn get dayRecordId =>
      integer().references(DayRecords, #id, onDelete: KeyAction.cascade)();

  /// 信息来源角色（决定 payload 结构）。
  IntColumn get characterType => intEnum<Character>()();

  /// 结构化信息内容（JSON，格式由角色的 InfoInputType 决定）。
  TextColumn get payloadJson => text()();

  /// 信息可靠性（醉/毒追踪）。
  TextColumn get reliability => textEnum<Reliability>()();

  /// 是否为我的信息（false = 他人公开声明）。
  BoolColumn get isMine => boolean().withDefault(const Constant(false))();
}

/// 提名表：一次提名 + 完整投票结果（issue #33）。
class Nominations extends Table {
  /// 自增主键。
  IntColumn get id => integer().autoIncrement()();

  /// 所属对局。
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();

  /// 提名发生的当天。
  IntColumn get dayRecordId =>
      integer().references(DayRecords, #id, onDelete: KeyAction.cascade)();

  /// 提名者。
  IntColumn get nominatorPlayerId => integer().references(Players, #id)();

  /// 被提名者。
  IntColumn get nomineePlayerId => integer().references(Players, #id)();

  /// 是否达到处决阈值（赞成票 >= 存活人数一半）。
  BoolColumn get passed => boolean()();

  /// 投票结果 JSON：[{playerId, vote: for/against/abstain, isDeadVote}]。
  TextColumn get voteResultJson => text()();

  /// 被提名者辩护记录（可选，issue #56）。
  TextColumn get defenseText => text().nullable()();
}

/// 醉/毒状态表（issue #35）：某天某玩家被标记为可能被毒/醉。
@DataClassName('PoisonStatus')
class PoisonStatuses extends Table {
  /// 自增主键。
  IntColumn get id => integer().autoIncrement()();

  /// 所属对局。
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();

  /// 玩家。
  IntColumn get playerId =>
      integer().references(Players, #id, onDelete: KeyAction.cascade)();

  /// 生效天数。
  IntColumn get dayNumber => integer()();

  /// 污染来源。
  TextColumn get source => textEnum<PoisonSource>()();

  /// 当前是否生效（毒只在当夜+次日生效，可解除）。
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        // 同一局同一玩家同一天唯一（#150 R1/B1：防 TOCTOU 重复行）。
        {gameId, playerId, dayNumber},
      ];
}

/// 行为备注表（issue #36）：某玩家当天的自由文本备注。
class BehaviorNotes extends Table {
  /// 自增主键。
  IntColumn get id => integer().autoIncrement()();

  /// 所属对局。
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();

  /// 玩家。
  IntColumn get playerId =>
      integer().references(Players, #id, onDelete: KeyAction.cascade)();

  /// 天数。
  IntColumn get dayNumber => integer()();

  /// 备注内容。
  TextColumn get note => text()();

  /// 记录时间。
  DateTimeColumn get createdAt => dateTime()();
}

/// 信任度变更日志：按天记录对每个玩家的信任度判断。
class TrustLogs extends Table {
  /// 自增主键。
  IntColumn get id => integer().autoIncrement()();

  /// 所属对局。
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();

  /// 目标玩家。
  IntColumn get playerId =>
      integer().references(Players, #id, onDelete: KeyAction.cascade)();

  /// 天数。
  IntColumn get dayNumber => integer()();

  /// 信任度等级。
  TextColumn get trustLevel => textEnum<TrustLevel>()();
}

/// 恶魔传承事件表（issue #89 公理5）：恶魔死亡 → 爪牙继承的离散事件。
///
/// 每条记录 = 一次传承（append-only）：
/// - 绯红女优先（SW 存活 + 死前 ≥5 → SW 自动继承，恶魔不可选）；
/// - 否则 Imp 自杀时恶魔/说书人选一名存活爪牙继承；
/// - 处决/Slayer 杀恶魔 + 无 SW → 善良胜（不产生传承记录）。
///
/// [toPlayerId] 为空表示「传承发生但继承人未知」（好人推断视角，App
/// 不知真实爪牙）。最新记录的 `toPlayerId`（非空）= 推理面板「当前恶魔」。
class DemonInheritances extends Table {
  /// 自增主键。
  IntColumn get id => integer().autoIncrement()();

  /// 所属对局。
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();

  /// 传承发生的天数。
  IntColumn get dayNumber => integer()();

  /// 原恶魔（死者）。
  @ReferenceName('successionFromPlayers')
  IntColumn get fromPlayerId =>
      integer().references(Players, #id, onDelete: KeyAction.cascade)();

  /// 继承人（新恶魔）。空 = 传承发生但继承人未知。
  @ReferenceName('successionToPlayers')
  IntColumn get toPlayerId => integer()
      .nullable()
      .references(Players, #id, onDelete: KeyAction.setNull)();

  /// 传承机制（绯红女继承 / 恶魔自杀传位）。
  TextColumn get trigger => textEnum<SuccessionTrigger>()();

  /// 记录时间。
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
