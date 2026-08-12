import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/reasoning/domain/contradiction.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

Player _player(
  int id,
  int seat, {
  int? deathDay,
  DeathCause? deathCause,
}) =>
    Player(
      id: id,
      gameId: 1,
      name: 'P$id',
      seatNumber: seat,
      isAlive: deathDay == null,
      abilityUsed: false,
      deathDay: deathDay,
      deathCause: deathCause ??
          (deathDay == null ? null : DeathCause.nightKill),
    );

RoleClaim _claim(int playerId, Character c, {ClaimType type = ClaimType.firstClaim}) =>
    RoleClaim(
      id: playerId,
      playerId: playerId,
      dayRecordId: 1,
      character: c,
      claimType: type,
    );

void main() {
  final players = {for (var i = 1; i <= 7; i++) i: _player(i, i)};

  test('规则1：两人声明同一镇民 → duplicateRoleClaim', () {
    final result = ContradictionDetector.detect(
      claims: [_claim(1, Character.chef), _claim(2, Character.chef)],
      declarations: [],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {},
      expectedOutsiders: 0,
    );
    expect(result, hasLength(1));
    expect(result[0].type, ContradictionType.duplicateRoleClaim);
    expect(result[0].playerIds, containsAll([1, 2]));
    expect(result[0].severity, ContradictionSeverity.warning);
    // 不输出身份结论
    expect(result[0].description, isNot(contains('是恶魔')));
    expect(result[0].description, isNot(contains('是爪牙')));
  });

  test('规则1：恶魔/爪牙重复声明不算矛盾（邪恶角色唯一性不由声明检测）', () {
    final result = ContradictionDetector.detect(
      claims: [_claim(1, Character.imp), _claim(2, Character.imp)],
      declarations: [],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {},
      expectedOutsiders: 0,
    );
    expect(result, isEmpty);
  });

  test('规则2：死亡揭示确认后他人再声明 → confirmedRoleConflict', () {
    final result = ContradictionDetector.detect(
      claims: [
        _claim(1, Character.virgin, type: ClaimType.revealedOnDeath),
        _claim(2, Character.virgin),
      ],
      declarations: [],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {},
      expectedOutsiders: 0,
    );
    expect(result, hasLength(1));
    expect(result[0].type, ContradictionType.confirmedRoleConflict);
    expect(result[0].playerIds, containsAll([1, 2]));
  });

  test('规则2：被确认者自己的声明不冲突', () {
    final result = ContradictionDetector.detect(
      claims: [_claim(1, Character.virgin, type: ClaimType.revealedOnDeath)],
      declarations: [],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {},
      expectedOutsiders: 0,
    );
    expect(result, isEmpty);
  });

  // issue #82：掘墓人信息可污染，降级为 info，不输出确定性结论。
  DayRecord _dayWithUndertaker(int executedId, Character reported) =>
      DayRecord(
        id: 1,
        gameId: 1,
        dayNumber: 2,
        nightDeathPlayerId: null,
        nightConfirmed: true,
        dayExecutionPlayerId: executedId,
        undertakerResultRole: reported,
        notes: '',
      );

  test('掘墓人信息冲突 → info（可污染，#82）', () {
    final result = ContradictionDetector.detect(
      claims: [
        _claim(1, Character.undertaker), // 掘墓人
        _claim(2, Character.chef), // 2 号声明厨师，与掘墓人报出的角色冲突
      ],
      declarations: [],
      days: [_dayWithUndertaker(3, Character.chef)],
      playersById: players,
      dayRecordToDayNumber: {1: 2},
      expectedOutsiders: 0,
    );
    final conflict = result
        .where((c) => c.type == ContradictionType.confirmedRoleConflict)
        .single;
    expect(conflict.severity, ContradictionSeverity.info); // 降级
    expect(conflict.description, contains('掘墓人'));
    expect(conflict.description, contains('毒'));
  });

  test('掘墓人当天被毒 → 信息不可靠，不触发冲突（#82）', () {
    final result = ContradictionDetector.detect(
      claims: [
        _claim(1, Character.undertaker),
        _claim(2, Character.chef),
      ],
      declarations: [],
      days: [_dayWithUndertaker(3, Character.chef)],
      playersById: players,
      dayRecordToDayNumber: {1: 2},
      expectedOutsiders: 0,
      poisonStatuses: const [
        PoisonStatus(
          id: 1,
          gameId: 1,
          playerId: 1, // 掘墓人第 2 天被毒
          dayNumber: 2,
          source: PoisonSource.poisoner,
          isActive: true,
        ),
      ],
    );
    expect(
      result.where((c) => c.type == ContradictionType.confirmedRoleConflict),
      isEmpty,
    );
  });

  test('规则3：声明数 > base+2（即便 Baron 也无法解释）→ outsiderCountAnomaly', () {
    // 7 人局 base=0，Baron 局最多 2；3 人声明外来者即硬矛盾
    final result = ContradictionDetector.detect(
      claims: [
        _claim(1, Character.butler),
        _claim(2, Character.saint),
        _claim(3, Character.drunk),
      ],
      declarations: [],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {},
      expectedOutsiders: 0,
    );
    expect(result, hasLength(1));
    expect(result[0].type, ContradictionType.outsiderCountAnomaly);
    expect(result[0].description, contains('Baron'));
  });

  test('规则3：声明数 == base+2（Baron 局一致）→ 不报警（#59 收紧）', () {
    // 7 人局 base=0，Baron 局 2 个；2 人声明不报警（旧逻辑会误报）
    final result = ContradictionDetector.detect(
      claims: [_claim(1, Character.butler), _claim(2, Character.saint)],
      declarations: [],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {},
      expectedOutsiders: 0,
    );
    expect(result, isEmpty);
  });

  test('规则3：声明数 ≤ 配置不报警', () {
    final result = ContradictionDetector.detect(
      claims: [_claim(1, Character.butler), _claim(2, Character.saint)],
      declarations: [],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {},
      expectedOutsiders: 2,
    );
    expect(result, isEmpty);
  });

  test('规则4：Empath 报 1 但邻居都声明好人 → empathMismatch', () {
    final decl = InfoDeclaration(
      id: 1,
      playerId: 2, // 2号的邻居是 1号和3号
      dayRecordId: 10,
      characterType: Character.empath,
      payloadJson: '{"value": 1}',
      reliability: Reliability.unverified,
      isMine: false,
    );
    final result = ContradictionDetector.detect(
      claims: [
        _claim(2, Character.empath),
        _claim(1, Character.chef),
        _claim(3, Character.monk),
      ],
      declarations: [decl],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {10: 2},
      expectedOutsiders: 0,
    );
    expect(result, hasLength(1));
    expect(result[0].type, ContradictionType.empathMismatch);
    expect(result[0].description, contains('污染'));
    expect(result[0].dayNumber, 2);
  });

  test('规则4：Empath 报 0 不报警', () {
    final decl = InfoDeclaration(
      id: 1,
      playerId: 2,
      dayRecordId: 10,
      characterType: Character.empath,
      payloadJson: '{"value": 0}',
      reliability: Reliability.unverified,
      isMine: false,
    );
    final result = ContradictionDetector.detect(
      claims: [_claim(1, Character.chef), _claim(3, Character.monk)],
      declarations: [decl],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {10: 2},
      expectedOutsiders: 0,
    );
    expect(result, isEmpty);
  });

  test('规则4：邻居死亡后按座位收缩计算', () {
    // 3号死于第1天，第2天2号的邻居收缩为 1号和4号
    final deadPlayers = {
      ...players,
      3: _player(3, 3, deathDay: 1),
    };
    final decl = InfoDeclaration(
      id: 1,
      playerId: 2,
      dayRecordId: 10,
      characterType: Character.empath,
      payloadJson: '{"value": 1}',
      reliability: Reliability.unverified,
      isMine: false,
    );
    final result = ContradictionDetector.detect(
      claims: [
        _claim(2, Character.empath),
        _claim(1, Character.chef),
        _claim(4, Character.monk), // 收缩后的右邻居
      ],
      declarations: [decl],
      days: [],
      playersById: deadPlayers,
      dayRecordToDayNumber: {10: 2},
      expectedOutsiders: 0,
    );
    expect(result, hasLength(1));
    expect(result[0].playerIds, containsAll([2, 1, 4]));
  });

  // issue #78：当天被处决者仍是 Empath 邻居；当夜被杀者不是。
  InfoDeclaration _empathDecl(int playerId, int dayRecordId, int value) =>
      InfoDeclaration(
        id: playerId,
        playerId: playerId,
        dayRecordId: dayRecordId,
        characterType: Character.empath,
        payloadJson: '{"value": $value}',
        reliability: Reliability.unverified,
        isMine: false,
      );

  test('规则4：当天被处决的邻居仍算存活邻居（#78）', () {
    // 3 号当天被处决（execution）→ Empath 读取时仍存活，邻居仍为 1、3
    final deadPlayers = {
      ...players,
      3: _player(3, 3, deathDay: 2, deathCause: DeathCause.execution),
    };
    final result = ContradictionDetector.detect(
      claims: [
        _claim(2, Character.empath),
        _claim(1, Character.chef), // 左邻居好人
        _claim(3, Character.butler), // 处决的右邻居好人
        _claim(4, Character.poisoner), // 不会被取为邻居
      ],
      declarations: [_empathDecl(2, 10, 1)], // 报 1 个邪恶
      days: [],
      playersById: deadPlayers,
      dayRecordToDayNumber: {10: 2},
      expectedOutsiders: 1, // 3 号声明 butler（外来者）
    );
    // 邻居 1、3 都是好人 → 报 1 邪恶 → mismatch，涉及 2、1、3（非 4）
    expect(result, hasLength(1));
    expect(result[0].playerIds, containsAll([2, 1, 3]));
    expect(result[0].playerIds, isNot(contains(4)));
  });

  test('规则4：当夜被杀的邻居不算存活邻居（收缩，#78）', () {
    // 3 号当夜被杀（nightKill）→ Empath 读取时已死，邻居收缩为 1、4。
    // 给 3 号好人声明（monk）作判别器：若 3 被错误算入，邻居[1,3]皆好人
    // → 报 1 邪恶会触发 mismatch（非空），从而守住「必须按 cause 排除 nightKill」。
    final deadPlayers = {
      ...players,
      3: _player(3, 3, deathDay: 2, deathCause: DeathCause.nightKill),
    };
    final result = ContradictionDetector.detect(
      claims: [
        _claim(2, Character.empath),
        _claim(1, Character.chef), // 左邻居好人
        _claim(3, Character.monk), // 被杀者：好人（判别器）
        _claim(4, Character.poisoner), // 收缩后的右邻居邪恶
      ],
      declarations: [_empathDecl(2, 10, 1)], // 报 1 个邪恶
      days: [],
      playersById: deadPlayers,
      dayRecordToDayNumber: {10: 2},
      expectedOutsiders: 0,
    );
    // 正确排除 3 → 邻居 1（好）、4（邪）→ 报 1 邪恶 → 匹配，不报警
    expect(result, isEmpty);
  });

  test('规则5：无人死亡夜晚 → noDeathNight 提示', () {
    final result = ContradictionDetector.detect(
      claims: [],
      declarations: [],
      days: [
        DayRecord(
          id: 1,
          gameId: 1,
          dayNumber: 2,
          nightDeathPlayerId: null,
          nightConfirmed: true,
          dayExecutionPlayerId: null,
          undertakerResultRole: null,
          notes: '',
        ),
      ],
      playersById: players,
      dayRecordToDayNumber: {1: 2},
      expectedOutsiders: 0,
    );
    expect(result, hasLength(1));
    expect(result[0].type, ContradictionType.noDeathNight);
    expect(result[0].severity, ContradictionSeverity.info);
    expect(result[0].description, contains('Monk'));
  });

  test('规则5：未确认的夜晚（预建记录）不报警（issue #77）', () {
    final result = ContradictionDetector.detect(
      claims: [],
      declarations: [],
      days: [
        DayRecord(
          id: 1,
          gameId: 1,
          dayNumber: 2,
          nightDeathPlayerId: null,
          nightConfirmed: false, // 进入第 2 天但夜晚未确认
          dayExecutionPlayerId: null,
          undertakerResultRole: null,
          notes: '',
        ),
      ],
      playersById: players,
      dayRecordToDayNumber: {1: 2},
      expectedOutsiders: 0,
    );
    expect(result, isEmpty);
  });

  test('规则5：第 1 天无人死亡不报警（恶魔首夜不杀人）', () {
    final result = ContradictionDetector.detect(
      claims: [],
      declarations: [],
      days: [
        DayRecord(
          id: 1,
          gameId: 1,
          dayNumber: 1,
          nightDeathPlayerId: null,
          nightConfirmed: true,
          dayExecutionPlayerId: null,
          undertakerResultRole: null,
          notes: '',
        ),
      ],
      playersById: players,
      dayRecordToDayNumber: {1: 1},
      expectedOutsiders: 0,
    );
    expect(result, isEmpty);
  });

  test('组合：多条规则同时触发', () {
    final result = ContradictionDetector.detect(
      claims: [_claim(1, Character.chef), _claim(2, Character.chef)],
      declarations: [],
      days: [
        DayRecord(
          id: 1,
          gameId: 1,
          dayNumber: 2,
          nightDeathPlayerId: null,
          nightConfirmed: true,
          dayExecutionPlayerId: null,
          undertakerResultRole: null,
          notes: '',
        ),
      ],
      playersById: players,
      dayRecordToDayNumber: {1: 2},
      expectedOutsiders: 0,
    );
    expect(result, hasLength(2));
    expect(
      result.map((c) => c.type),
      containsAll([
        ContradictionType.duplicateRoleClaim,
        ContradictionType.noDeathNight,
      ]),
    );
  });

  test('空输入 → 空输出（不误报）', () {
    final result = ContradictionDetector.detect(
      claims: [],
      declarations: [],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {},
      expectedOutsiders: 0,
    );
    expect(result, isEmpty);
  });
}
