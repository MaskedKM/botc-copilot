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

  /// 白天被处决玩家（无处决为空）。
  @ReferenceName('executionDays')
  IntColumn get dayExecutionPlayerId =>
      integer().nullable().references(Players, #id)();

  /// 掘墓人报出的被处决者角色。
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
