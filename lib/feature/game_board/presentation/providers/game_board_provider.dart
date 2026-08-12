import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/domain/game_end.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前进行中的对局（最近创建的一局 ongoing）。
final currentGameProvider = StreamProvider<Game?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.gamesDao.watchAll().map(
        (games) =>
            games.where((g) => g.status == GameStatus.ongoing).firstOrNull,
      );
});

/// 对局是否进行中（只读 gating 用，issue #81）。加载中默认 true（不阻断）。
final isGameOngoingProvider = Provider.family<bool, int>((ref, gameId) {
  final status = ref.watch(gameByIdProvider(gameId)).valueOrNull?.status;
  return (status ?? GameStatus.ongoing) == GameStatus.ongoing;
});

/// 按 id 监听单局（只监听该行变化）。
final gameByIdProvider =
    StreamProvider.family<Game?, int>((ref, gameId) {
  final db = ref.watch(appDatabaseProvider);
  return db.gamesDao.watchById(gameId);
});

/// 全部对局（存档列表用）。
final allGamesProvider = StreamProvider<List<Game>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.gamesDao.watchAll();
});

/// 某局的玩家列表（按座位号）。
final gamePlayersProvider =
    StreamProvider.family<List<Player>, int>((ref, gameId) {
  final db = ref.watch(appDatabaseProvider);
  return db.playersDao.watchByGame(gameId);
});

/// 某局某天的记录（可能尚未创建 → null）。
final currentDayRecordProvider =
    StreamProvider.family<DayRecord?, (int gameId, int day)>((ref, key) {
  final db = ref.watch(appDatabaseProvider);
  final (gameId, day) = key;
  return db.dayRecordsDao.watchByGame(gameId).map(
        (days) =>
            days.where((d) => d.dayNumber == day).firstOrNull,
      );
});

/// 某局全部玩家的最新信任度（playerId → level）。
final latestTrustLevelsProvider =
    StreamProvider.family<Map<int, TrustLevel>, int>((ref, gameId) {
  final db = ref.watch(appDatabaseProvider);
  return db.trustLogsDao.watchByGame(gameId).map((logs) {
    final result = <int, TrustLevel>{};
    for (final log in logs) {
      result[log.playerId] = log.trustLevel; // 按天数+id 升序，后者覆盖前者
    }
    return result;
  });
});

/// 当前对局的帮助层级（issue #41，默认 normal）。
final gameHelpLevelProvider = Provider.family<HelpLevel, int>((ref, gameId) {
  return ref.watch(
        gameByIdProvider(gameId).select((g) => g.valueOrNull?.helpLevel),
      ) ??
      HelpLevel.normal;
});

/// 对局主界面状态。
class GameBoardState {
  /// 创建状态。
  const GameBoardState({this.currentDay = 1, this.selectedPlayerId});

  /// 当前天数（从 1 开始）。
  final int currentDay;

  /// 当前选中玩家 id（null = 未选中）。
  final int? selectedPlayerId;

  /// 复制并修改部分字段。
  GameBoardState copyWith({int? currentDay, int? Function()? selectedPlayerId}) {
    return GameBoardState(
      currentDay: currentDay ?? this.currentDay,
      selectedPlayerId: selectedPlayerId != null
          ? selectedPlayerId()
          : this.selectedPlayerId,
    );
  }
}

/// 对局主界面状态管理。
class GameBoardNotifier extends StateNotifier<GameBoardState> {
  /// 创建 notifier。
  GameBoardNotifier(this._ref, this._gameId) : super(const GameBoardState());

  final Ref _ref;
  final int _gameId;

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  /// 选中/取消选中玩家（再次点同一玩家 = 取消）。
  void selectPlayer(int? playerId) {
    state = state.copyWith(
      selectedPlayerId: () =>
          playerId == state.selectedPlayerId ? null : playerId,
    );
  }

  /// 确保当前天的记录存在（幂等，靠唯一约束兜底），返回记录 id。
  Future<int> ensureCurrentDayRecord() => _ensureDayRecord(state.currentDay);

  /// 确保某天的记录存在（幂等，靠唯一约束兜底）。
  Future<int> _ensureDayRecord(int day) async {
    final existing = await _db.dayRecordsDao.getByGameAndDay(_gameId, day);
    if (existing != null) return existing.id;
    return _db.dayRecordsDao.insertDay(
      DayRecordsCompanion(gameId: Value(_gameId), dayNumber: Value(day)),
    );
  }

  /// 记录夜晚死亡（null = 无人死亡）。
  ///
  /// 事务包裹：当日记录与玩家死亡标记必须同生共死。
  /// 撤销/改选时复活上一个夜晚死亡者，保证「一天至多一个夜晚死亡」。
  /// 返回结束建议：存活 ≤ 2 时为 [EvilWinCandidate]。
  Future<GameEndSuggestion?> recordNightDeath(int? playerId) async {
    final dayId = await _ensureDayRecord(state.currentDay);
    await _db.transaction(() async {
      await _revivePreviousDeath(dayId, (d) => d.nightDeathPlayerId, (d) => d.dayExecutionPlayerId, DeathCause.nightKill);
      await _db.dayRecordsDao.updateDay(
        dayId,
        DayRecordsCompanion(
          nightDeathPlayerId: Value(playerId),
          // 确认夜晚结果（标记死亡或「无人死亡」），消除 null 二义性（#77）。
          nightConfirmed: const Value(true),
        ),
      );
      if (playerId != null) {
        await _db.playersDao.markDead(
          playerId,
          state.currentDay,
          DeathCause.nightKill,
        );
      }
    });
    if (playerId == null) return null;
    return _evilWinCheck();
  }

  /// 记录白天处决（null = 无处决）。
  ///
  /// 事务包裹：当日记录与玩家死亡标记必须同生共死。
  /// 撤销/改选时复活上一个被处决者，保证「一天至多一个处决」。
  /// 返回 [DemonExecutionCheck] 让 UI 确认被处决者是否是恶魔。
  Future<GameEndSuggestion?> recordExecution(int? playerId) async {
    final dayId = await _ensureDayRecord(state.currentDay);
    await _db.transaction(() async {
      await _revivePreviousDeath(dayId, (d) => d.dayExecutionPlayerId, (d) => d.nightDeathPlayerId, DeathCause.execution);
      await _db.dayRecordsDao.updateDay(
        dayId,
        DayRecordsCompanion(dayExecutionPlayerId: Value(playerId)),
      );
      if (playerId != null) {
        await _db.playersDao.markDead(
          playerId,
          state.currentDay,
          DeathCause.execution,
        );
      }
    });
    if (playerId == null) return null;
    final players = await _db.playersDao.watchByGame(_gameId).first;
    final executed = players.where((p) => p.id == playerId).firstOrNull;
    final alive = players.where((p) => p.isAlive).length;
    return DemonExecutionCheck(
      executedPlayerId: playerId,
      executedName: executed != null
          ? '${executed.seatNumber}号 ${executed.name}'
          : '?',
      aliveCountAfter: alive,
    );
  }

  /// 复活当天记录中此前登记的死亡者（撤销/改选时调用）。
  ///
  /// 必须在更新当日记录之前调用，否则取到的是新值。
  ///
  /// 仅当该玩家确实死于「本日 + [expectedCause]」时才复活——处决已死
  /// 玩家时不 markDead，撤销处决不应把早就死了的人复活（#80）。
  Future<void> _revivePreviousDeath(
    int dayId,
    int? Function(DayRecord) getPlayerId,
    int? Function(DayRecord) otherFieldId,
    DeathCause expectedCause,
  ) async {
    final day = await _db.dayRecordsDao.getByGameAndDay(
      _gameId,
      state.currentDay,
    );
    final oldId = day != null && day.id == dayId ? getPlayerId(day) : null;
    if (oldId == null) return;
    // 跨字段守卫（review M1）：若该玩家同时是「另一类」死亡记录的目标
    // （如夜杀 A 后又处决 A），撤销本字段不应复活他——另一字段仍生效。
    if (otherFieldId(day!) == oldId) return;
    final players = await _db.playersDao.watchByGame(_gameId).first;
    final prev = players.where((p) => p.id == oldId).firstOrNull;
    if (prev != null &&
        !prev.isAlive &&
        prev.deathCause == expectedCause &&
        prev.deathDay == state.currentDay) {
      await _db.playersDao.revive(oldId);
    }
  }

  /// 复活玩家（撤销误标死亡，如 SnackBar 撤销）。
  Future<void> revivePlayer(int playerId) => _db.playersDao.revive(playerId);

  /// 存活 ≤ 2 时返回邪恶获胜候选。
  Future<GameEndSuggestion?> _evilWinCheck() async {
    final players = await _db.playersDao.watchByGame(_gameId).first;
    final alive = players.where((p) => p.isAlive).length;
    if (GameEndRules.isEvilWinCandidate(alive)) {
      return EvilWinCandidate(alive);
    }
    return null;
  }

  /// 结束对局：更新状态 + 可选记录被处决者的死亡揭示声明。
  Future<void> endGame({
    required bool goodWin,
    int? revealedPlayerId,
    Character? revealedRole,
  }) async {
    await _db.transaction(() async {
      await _db.gamesDao.updateStatus(
        _gameId,
        goodWin ? GameStatus.goodWin : GameStatus.evilWin,
      );
      if (revealedPlayerId != null && revealedRole != null) {
        final dayId = await _ensureDayRecord(state.currentDay);
        await _db.roleClaimsDao.insertClaim(
          RoleClaimsCompanion(
            playerId: Value(revealedPlayerId),
            dayRecordId: Value(dayId),
            character: Value(revealedRole),
            claimType: const Value(ClaimType.revealedOnDeath),
          ),
        );
      }
    });
  }

  /// 只记录死亡揭示（不结束对局）。
  Future<void> recordRevealOnly({
    required int playerId,
    required Character role,
  }) async {
    final dayId = await _ensureDayRecord(state.currentDay);
    await _db.roleClaimsDao.insertClaim(
      RoleClaimsCompanion(
        playerId: Value(playerId),
        dayRecordId: Value(dayId),
        character: Value(role),
        claimType: const Value(ClaimType.revealedOnDeath),
      ),
    );
  }

  /// 快速切换死亡/复活（长按快捷操作）。
  Future<GameEndSuggestion?> quickToggleDead(Player player) async {
    if (player.isAlive) {
      await _db.playersDao.markDead(
        player.id,
        state.currentDay,
        DeathCause.other,
      );
      return _evilWinCheck();
    } else {
      await _db.playersDao.revive(player.id);
      return null;
    }
  }

  /// 推进到下一天。
  ///
  /// 返回结束建议：推进前若存活 == 3、当天无人被处决、且市长在场
  /// （有人声明市长或我的角色是市长）→ [MayorVictoryCandidate]（issue #88）。
  /// 与邪恶胜（存活 ≤ 2，在 [recordNightDeath] 等死亡记录时触发）天然分离：
  /// 3 人无处决先触发市长，不会走到 2 人。
  Future<GameEndSuggestion?> advanceDay() async {
    final suggestion = await _mayorWinCheck();
    final nextDay = state.currentDay + 1;
    await _ensureDayRecord(nextDay);
    state = state.copyWith(currentDay: nextDay, selectedPlayerId: () => null);
    return suggestion;
  }

  /// 市长胜利检测（issue #88）。
  ///
  /// 在推进当天时检查：存活 == 3、当天无人被处决、且市长在场。
  /// 平票 / 不足阈值也算无人被处决（dayExecutionPlayerId 仍为 null）。
  Future<GameEndSuggestion?> _mayorWinCheck() async {
    final day = await _db.dayRecordsDao.getByGameAndDay(
      _gameId,
      state.currentDay,
    );
    final noExecution = day?.dayExecutionPlayerId == null;
    final players = await _db.playersDao.watchByGame(_gameId).first;
    final alive = players.where((p) => p.isAlive).length;
    if (!GameEndRules.isMayorWinCandidate(
      alive,
      noExecutionToday: noExecution,
    )) {
      return null;
    }
    if (!await _mayorInPlay()) return null;
    return MayorVictoryCandidate(alive);
  }

  /// 市长是否在场（issue #88 门控，review R3/R4 收紧）。
  ///
  /// - 我的角色是市长 → 直接成立（用户自知存活 / 醉毒，对话框二次确认）。
  /// - 否则取每玩家**最新**声明（watchByGame 按 id 升序，后者覆盖前者），
  ///   命中最新为市长且该声明者存活——排除「改口后旧声明」与「声明者已死」。
  Future<bool> _mayorInPlay() async {
    final game = await _db.gamesDao.getById(_gameId);
    if (game?.myRole == Character.mayor) return true;
    final claims = await _db.roleClaimsDao.watchByGame(_gameId).first;
    final players = await _db.playersDao.watchByGame(_gameId).first;
    final aliveById = {for (final p in players) p.id: p.isAlive};
    final latestByPlayer = <int, Character>{};
    for (final c in claims) {
      latestByPlayer[c.playerId] = c.character;
    }
    for (final entry in latestByPlayer.entries) {
      if (entry.value == Character.mayor &&
          (aliveById[entry.key] ?? false)) {
        return true;
      }
    }
    return false;
  }

  /// 撤销最近一次推进（仅当天为预建的空记录时，issue #87）。
  ///
  /// 当天一旦有夜晚结果 / 处决 / 提名即视为已使用，不可静默回退。
  /// 返回是否成功回退。
  Future<bool> revertAdvanceDay() async {
    if (state.currentDay <= 1) return false;
    final day =
        await _db.dayRecordsDao.getByGameAndDay(_gameId, state.currentDay);
    if (day == null) return false;
    final hasNight = day.nightDeathPlayerId != null;
    final hasExec = day.dayExecutionPlayerId != null;
    final hasNoms = (await _db.nominationsDao.watchByDay(day.id).first)
        .isNotEmpty;
    // 角色声明 / 信息声明以 dayRecordId 级联挂在天记录上（onDelete: cascade），
    // 删天记录会静默删掉它们——有任意一条都不可回退（review M1）。
    final hasClaims =
        (await _db.roleClaimsDao.watchByDay(day.id).first).isNotEmpty;
    final hasInfo =
        (await _db.infoDeclarationsDao.watchByDay(day.id).first).isNotEmpty;
    if (hasNight || hasExec || hasNoms || hasClaims || hasInfo) return false;
    await _db.dayRecordsDao.deleteDay(day.id);
    state = state.copyWith(
      currentDay: state.currentDay - 1,
      selectedPlayerId: () => null,
    );
    return true;
  }
}

/// 对局主界面状态 Provider（按对局 id 分族）。
final gameBoardProvider =
    StateNotifierProvider.family<GameBoardNotifier, GameBoardState, int>(
  (ref, gameId) => GameBoardNotifier(ref, gameId),
);
