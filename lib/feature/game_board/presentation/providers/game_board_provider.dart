import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/core/database/database_provider.dart';
import 'package:botc_copilot/feature/game_board/domain/game_end.dart';
import 'package:botc_copilot/feature/game_board/domain/nomination_rules.dart';
import 'package:botc_copilot/feature/game_board/domain/succession.dart';
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

/// 某局的恶魔传承事件（issue #89）。
final gameSuccessionsProvider =
    StreamProvider.family<List<DemonInheritance>, int>((ref, gameId) {
  final db = ref.watch(appDatabaseProvider);
  return db.demonInheritancesDao.watchByGame(gameId);
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
    // #149 BUG-1：恶魔死亡时**先**解析传承（公理5：有爪牙→传承/继续，
    // 无爪牙→善良胜），**再**判人头邪恶胜。原先先 _evilWinCheck 短路会跳过
    // 传承——Imp 自杀且无爪牙时误判邪恶胜（应善良胜），取消则卡死。
    final claimed = await _effectiveCharacter(playerId);
    if (SuccessionRules.isDemonDeath(claimed) ||
        await _isDemonCandidate(playerId)) {
      return checkDemonDeath(playerId, way: DeathWay.suicide);
    }
    // 非恶魔死亡 → 判人头邪恶胜（存活 ≤ 2）。
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
    if (otherFieldId(day!) == oldId) {
      // #154 BUG-1 根治：重对齐 deathCause 到「存活的那条记录」的 cause。
      // markDead 对已死者 no-op（不覆盖 cause），夜杀+处决同一人后依次清空两
      // 字段时 cause 锁定先记录者；若不重对齐，最后一条清空会被 deathCause
      // 守卫误挡 → 孤立致死。另一字段 cause 由字段类型决定
      // （night→nightKill / exec→execution）。
      final otherCause = expectedCause == DeathCause.nightKill
          ? DeathCause.execution
          : DeathCause.nightKill;
      final players = await _db.playersDao.watchByGame(_gameId).first;
      final prev = players.where((p) => p.id == oldId).firstOrNull;
      if (prev != null && !prev.isAlive && prev.deathCause != otherCause) {
        await _db.playersDao.updatePlayer(
          oldId,
          PlayersCompanion(deathCause: Value(otherCause)),
        );
      }
      return;
    }
    final players = await _db.playersDao.watchByGame(_gameId).first;
    final prev = players.where((p) => p.id == oldId).firstOrNull;
    // 复活守卫：!isAlive + 同日 + cause 匹配。cause 匹配确认本字段是致命记录
    // （非对已死者的 no-op markDead）——长按/Slayer 等无字段致死者撤销本字段
    // 不应复活（#154 review Finding 1）；跨日由 deathDay 守卫覆盖（#80）。
    if (prev != null &&
        !prev.isAlive &&
        prev.deathCause == expectedCause &&
        prev.deathDay == state.currentDay) {
      await _db.playersDao.revive(oldId);
    }
  }

  /// 复活玩家（撤销误标死亡，如 SnackBar 撤销 / 长按复活）。
  ///
  /// 同步清当天指向该玩家的 day-record 死亡字段（#154 BUG-2）——否则
  /// `dayExecutionPlayerId` 残留会锁死投票面板（恒 executed）、timeline 仍
  /// 渲染处决、矛盾检测按旧 day-record 判定。复活与记录路径同源（记录写
  /// day-record + 玩家，撤销须两者皆清）。
  Future<void> revivePlayer(int playerId) async {
    final players = await _db.playersDao.watchByGame(_gameId).first;
    final target = players.where((p) => p.id == playerId).firstOrNull;
    final deathDay = target?.deathDay;
    await _db.transaction(() async {
      await _db.playersDao.revive(playerId);
      if (deathDay == null) return;
      final dayRec =
          await _db.dayRecordsDao.getByGameAndDay(_gameId, deathDay);
      if (dayRec == null) return;
      // 仅清指向该玩家的字段（另一字段可能指向别人，不动）。
      // 若清的是夜死字段，同步置 nightConfirmed=false（撤销夜死 = 夜晚不再
      // 视为已结算，否则残留 true + 无夜死会被误判「无人死亡夜晚」，#154 review）。
      final clearedNight = dayRec.nightDeathPlayerId == playerId;
      await _db.dayRecordsDao.updateDay(
        dayRec.id,
        DayRecordsCompanion(
          nightDeathPlayerId: clearedNight
              ? const Value<int?>(null)
              : const Value<int?>.absent(),
          dayExecutionPlayerId: dayRec.dayExecutionPlayerId == playerId
              ? const Value<int?>(null)
              : const Value<int?>.absent(),
          nightConfirmed: clearedNight
              ? const Value(false)
              : const Value<bool>.absent(),
        ),
      );
    });
  }

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
  ///
  /// [deathDay] 指定死亡天数（补记历史死亡时需准确，否则污染 Empath 邻座
  /// 判定/矛盾检测）；默认当前天。
  Future<GameEndSuggestion?> quickToggleDead(
    Player player, {
    int? deathDay,
  }) async {
    if (player.isAlive) {
      // 防御纵深：clamp 到 [1, currentDay]，避免越界值污染 Empath 判定。
      final day = deathDay?.clamp(1, state.currentDay) ?? state.currentDay;
      // 死亡阶段判定（#151 C1 review）：该日夜晚尚未确认 → 视为夜死
      // （nightKill，Empath 当夜读取前已死 → 排除出邻座）；已确认 → 白天死
      // （other，Slayer/白天标死，读取时仍存活 → 算邻座）。避免长按记录夜死
      // 却被「deathCause != nightKill」误算为存活邻居。
      final dayRec = await _db.dayRecordsDao.getByGameAndDay(_gameId, day);
      final cause = (dayRec?.nightConfirmed ?? false)
          ? DeathCause.other
          : DeathCause.nightKill;
      await _db.playersDao.markDead(player.id, day, cause);
      // #149 BUG-1：恶魔死亡先传承（与 recordNightDeath 路径统一），非恶魔
      // 死亡才判人头邪恶胜。原先先 _evilWinCheck 短路会跳过传承。
      // 仅当天标死触发传承——补记历史死亡（deathDay < currentDay）时，存活/
      // SW 阈值/毒查均需按死亡时点算，App 无历史快照，故补记不自动检测。
      final claimed = await _effectiveCharacter(player.id);
      final isToday = deathDay == null || deathDay == state.currentDay;
      if (isToday &&
          (SuccessionRules.isDemonDeath(claimed) ||
              await _isDemonCandidate(player.id))) {
        return checkDemonDeath(player.id, way: DeathWay.suicide);
      }
      return _evilWinCheck();
    } else {
      // 复活：走 revivePlayer（同步清 day-record，#154 BUG-2）。
      await revivePlayer(player.id);
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
    // alive 取推进时刻（#136）：录提名与推进间若有人死亡，阈值重算偏保守
    //（alive 减→阈值降→更易判待执行→更倾向抑制市长）。
    final alive = players.where((p) => p.isAlive).length;
    if (!GameEndRules.isMayorWinCandidate(
      alive,
      noExecutionToday: noExecution,
    )) {
      return null;
    }
    // #136：达阈值的待执行提名 = execution 应发生（官方：达阈值即处决，非可选），
    // 市长条件「no execution occurs」不满足——避免终局假阳性善良胜。
    if (day != null) {
      final noms = await _db.nominationsDao.watchByDay(day.id).first;
      if (NominationRules.pendingExecution(noms, alive) is PendingExecution) {
        return null;
      }
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

  /// 玩家有效角色（我是该座位→myRole 真身，他人→最新公开声明）。
  ///
  /// 用于规则判定：夜死警告、传承触发等关注**真实能力**的场景。
  Future<Character?> _effectiveCharacter(int playerId) async {
    final game = await _db.gamesDao.getById(_gameId);
    if (game?.myPlayerId == playerId) return game?.myRole;
    final claims = await _db.roleClaimsDao.watchByPlayer(playerId).first;
    return claims.isNotEmpty ? claims.last.character : null;
  }

  /// 玩家是否被标记为恶魔候选（夜死传承触发的兜底）。
  ///
  /// 好人视角下真恶魔不会声明 Imp，单靠声明/真身会漏判；信任度被标为
  /// demonCandidate 的玩家夜死时也提示传承，由用户在确认框裁决。
  Future<bool> _isDemonCandidate(int playerId) async {
    final logs = await _db.trustLogsDao.watchByGame(_gameId).first;
    TrustLevel? latest;
    for (final l in logs) {
      if (l.playerId == playerId) latest = l.trustLevel;
    }
    return latest == TrustLevel.demonCandidate;
  }

  /// 恶魔死亡后的传承检测（issue #89 公理5，三路径统一入口）。
  ///
  /// [way]：[DeathWay.suicide]（Imp 夜间自杀）/ [DeathWay.execution]
  /// （处决恶魔，用户已确认）/ [DeathWay.slayer]（Slayer 击杀恶魔）。
  ///
  /// 返回 [DemonSuccessionCandidate] 让 UI 弹确认框：
  /// - SW 满足（在场存活 + 死前 ≥5 + 首次）→ 绯红女优先继承；
  /// - 自杀 + 无 SW → 普通传位（选存活爪牙）；
  /// - 处决/Slayer + 无 SW → 返回 null（善良胜，不传位）。
  Future<GameEndSuggestion?> checkDemonDeath(
    int demonPlayerId, {
    required DeathWay way,
  }) async {
    final players = await _db.playersDao.watchByGame(_gameId).first;
    final aliveAfter = players.where((p) => p.isAlive).length;
    final thresholdMet =
        SuccessionRules.isScarletWomanThreshold(aliveAfter);
    final firstTime = !await _db.demonInheritancesDao
        .hasScarletWomanSuccession(_gameId);
    int? swId;
    var swTainted = false;
    if (thresholdMet && firstTime) {
      final sw = await _scarletWomanInPlay();
      if (sw != null) {
        swId = sw.playerId;
        swTainted = sw.tainted;
      }
    }
    final swHappens = swId != null;
    // 处决/Slayer 仅在 SW 在场时才产生候选；自杀总有候选（普通传位 or SW）。
    if (!swHappens && way != DeathWay.suicide) return null;
    final demon = players.where((p) => p.id == demonPlayerId).firstOrNull;
    return DemonSuccessionCandidate(
      demonPlayerId: demonPlayerId,
      demonName: demon != null ? '${demon.seatNumber}号 ${demon.name}' : '?',
      way: way,
      aliveCountAfter: aliveAfter,
      scarletWomanEligible: swHappens,
      scarletWomanPlayerId: swId,
      scarletWomanTainted: swTainted,
    );
  }

  /// 绯红女是否在场存活（issue #89 门控）。
  ///
  /// 返回 SW 的 playerId 与 tainted（被标毒/醉）：「我」是 SW 取 myRole；
  /// 否则取最新声明 == SW 且存活。tainted = suspectedDrunk（整局醉）或当日
  /// 活跃毒（Poisoner）——仅作提示，App 不能确认真身毒/醉。
  Future<({int playerId, bool tainted})?> _scarletWomanInPlay() async {
    final game = await _db.gamesDao.getById(_gameId);
    final players = await _db.playersDao.watchByGame(_gameId).first;
    final byId = {for (final p in players) p.id: p};
    // 我是 SW 且存活
    final myId = game?.myPlayerId;
    if (game?.myRole == Character.scarletWoman &&
        myId != null &&
        byId[myId]?.isAlive == true) {
      return (playerId: myId, tainted: await _tainted(myId, byId));
    }
    // 最新声明 SW 且存活
    final claims = await _db.roleClaimsDao.watchByGame(_gameId).first;
    final latestByPlayer = <int, Character>{};
    for (final c in claims) {
      latestByPlayer[c.playerId] = c.character;
    }
    for (final entry in latestByPlayer.entries) {
      if (entry.value == Character.scarletWoman &&
          byId[entry.key]?.isAlive == true) {
        return (
          playerId: entry.key,
          tainted: await _tainted(entry.key, byId),
        );
      }
    }
    return null;
  }

  /// 玩家是否被标记毒/醉（整局 suspectedDrunk 或当日活跃毒）。
  ///
  /// 注：按天毒（PoisonStatuses）的精确时序（当夜+次日生效）见 issue #109，
  /// 此处仅查当日 isActive 作近似——传承的 tainted 只作「警告不阻止」提示，
  /// App 无法确认真身毒/醉，由用户在确认框最终裁决。
  Future<bool> _tainted(int playerId, Map<int, Player> byId) async {
    final drunk = byId[playerId]?.suspectedDrunk ?? false;
    if (drunk) return true;
    final ps = await _db.poisonStatusesDao.findByPlayerAndDay(
      playerId,
      state.currentDay,
    );
    return ps?.isActive ?? false;
  }

  /// 记录传承事件 + 更新恶魔候选（issue #89）。
  ///
  /// 写入 DemonInheritances（fromPlayerId → toPlayerId）；若 [toPlayerId]
  /// 非空，标记其为恶魔候选（TrustLog），使推理面板恶魔池反映继承人。
  Future<void> recordSuccession({
    required int fromPlayerId,
    int? toPlayerId,
    required SuccessionTrigger trigger,
  }) async {
    await _db.transaction(() async {
      await _db.demonInheritancesDao.insertSuccession(
        DemonInheritancesCompanion(
          gameId: Value(_gameId),
          dayNumber: Value(state.currentDay),
          fromPlayerId: Value(fromPlayerId),
          toPlayerId:
              toPlayerId != null ? Value(toPlayerId) : const Value.absent(),
          trigger: Value(trigger),
        ),
      );
      if (toPlayerId != null) {
        await _db.trustLogsDao.insertLog(
          TrustLogsCompanion(
            gameId: Value(_gameId),
            playerId: Value(toPlayerId),
            dayNumber: Value(state.currentDay),
            trustLevel: const Value(TrustLevel.demonCandidate),
          ),
        );
      }
    });
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
