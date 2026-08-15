import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/constants/player_setup.dart';
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
      abilityUsed: false, suspectedDrunk: false,
      fakeDead: false,
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

  test('规则1：他人声明我的真实角色 → duplicate（#107 注入 myRole）', () {
    // 我（1 号）真实是 Chef，无公开声明；2 号声明 Chef → 注入后两人重复
    final result = ContradictionDetector.detect(
      claims: [_claim(2, Character.chef)],
      declarations: [],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {},
      expectedOutsiders: 0,
      myPlayerId: 1,
      myRole: Character.chef,
    );
    expect(
      result.any((c) => c.type == ContradictionType.duplicateRoleClaim),
      isTrue,
    );
    // 描述区分「你的真实角色」与公开声明，且用中性「指向」而非「声明」（R1）
    final dup = result.firstWhere(
      (c) => c.type == ContradictionType.duplicateRoleClaim,
    );
    expect(dup.description, contains('你的真实角色'));
    expect(dup.description, isNot(contains('声明')));
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

  // issue #106：掘墓人信息改读 info_declarations（DayRecord 字段无写入方）。
  // 官方时序：掘墓人在第 N+1 夜得知第 N 日的处决，故声明落在处决日的次日。
  DayRecord _executionDay(int id, int dayNumber, int executedId) => DayRecord(
        id: id,
        gameId: 1,
        dayNumber: dayNumber,
        nightConfirmed: true,
        dayExecutionPlayerId: executedId,
        dayConfirmed: true,
        undertakerResultRole: null,
        notes: '',
      );

  DayRecord _emptyDay(int id, int dayNumber) => DayRecord(
        id: id,
        gameId: 1,
        dayNumber: dayNumber,
        nightConfirmed: true,
        dayExecutionPlayerId: null,
        dayConfirmed: false,
        undertakerResultRole: null,
        notes: '',
      );

  InfoDeclaration _undertakerDecl(
    int undertakerPlayerId,
    int dayRecordId,
    Character reported, {
    Reliability reliability = Reliability.unverified,
  }) =>
      InfoDeclaration(
        id: 100,
        playerId: undertakerPlayerId,
        dayRecordId: dayRecordId,
        characterType: Character.undertaker,
        payloadJson: '{"character": "${reported.name}"}',
        reliability: reliability,
        isMine: false,
      );

  test('掘墓人信息冲突 → info（可污染，#106 改读 declarations）', () {
    // 第 1 天处决 3 号；1 号（掘墓人）第 2 天报：被处决者是厨师。
    // 2 号声明厨师 → 与掘墓人报出的角色冲突。
    final result = ContradictionDetector.detect(
      claims: [_claim(2, Character.chef)],
      declarations: [_undertakerDecl(1, 2, Character.chef)],
      days: [_executionDay(1, 1, 3), _emptyDay(2, 2)],
      playersById: players,
      dayRecordToDayNumber: {1: 1, 2: 2},
      expectedOutsiders: 0,
    );
    final conflict = result
        .where((c) => c.type == ContradictionType.confirmedRoleConflict)
        .single;
    expect(conflict.severity, ContradictionSeverity.info); // 降级
    expect(conflict.playerIds, containsAll([2, 3])); // 声明者 + 被处决者
    expect(conflict.description, contains('掘墓人'));
    expect(conflict.description, contains('毒'));
  });

  test('掘墓人 reliability 为污染 → 信息不可靠，不触发冲突（#106）', () {
    final result = ContradictionDetector.detect(
      claims: [_claim(2, Character.chef)],
      declarations: [
        _undertakerDecl(1, 2, Character.chef,
            reliability: Reliability.possiblyTainted),
      ],
      days: [_executionDay(1, 1, 3), _emptyDay(2, 2)],
      playersById: players,
      dayRecordToDayNumber: {1: 1, 2: 2},
      expectedOutsiders: 0,
    );
    expect(
      result.where((c) => c.type == ContradictionType.confirmedRoleConflict),
      isEmpty,
    );
  });

  test('掘墓人信息关联声明日之前最近处决（官方时序，#106）', () {
    // 第 1 天处决 3 号、第 2 天处决 4 号；掘墓人第 3 天报：被处决者是共情者。
    // 官方规则——掘墓人次夜得知当日处决，故应关联第 2 天处决者（4 号）。
    // 注：用好人角色（共情者）触发冲突——恶魔角色因传承可合法重复，已被 #151 S2 抑制。
    final result = ContradictionDetector.detect(
      claims: [_claim(5, Character.empath)],
      declarations: [_undertakerDecl(1, 3, Character.empath)],
      days: [
        _executionDay(1, 1, 3),
        _executionDay(2, 2, 4),
        _emptyDay(3, 3),
      ],
      playersById: players,
      dayRecordToDayNumber: {1: 1, 2: 2, 3: 3},
      expectedOutsiders: 0,
    );
    final conflict = result
        .where((c) => c.type == ContradictionType.confirmedRoleConflict)
        .single;
    // 关联第 2 天处决者（4 号），而非第 1 天（3 号）
    expect(conflict.playerIds, containsAll([5, 4]));
    expect(conflict.playerIds, isNot(contains(3)));
  });

  // #151 S2：恶魔角色（Imp）传承后可合法重复，掘墓人/确认冲突不报。
  test('掘墓人报 Imp + 他人声明 Imp → 不报冲突（传承合法，#151 S2）', () {
    final result = ContradictionDetector.detect(
      claims: [_claim(5, Character.imp)],
      declarations: [_undertakerDecl(1, 2, Character.imp)],
      days: [_executionDay(1, 1, 4), _emptyDay(2, 2)],
      playersById: players,
      dayRecordToDayNumber: {1: 1, 2: 2},
      expectedOutsiders: 0,
    );
    expect(
      result.where((c) => c.type == ContradictionType.confirmedRoleConflict),
      isEmpty,
    );
  });

  // #151 S1：被处决者本人声明与掘墓人对本人的报告冲突（原 skip 漏判）。
  test('被处决者本人声明 ≠ 掘墓人报告 → 报冲突（#151 S1）', () {
    // 3 号被处决；掘墓人报其为共情者；3 号自己声明厨师。
    final result = ContradictionDetector.detect(
      claims: [_claim(3, Character.chef)],
      declarations: [_undertakerDecl(1, 2, Character.empath)],
      days: [_executionDay(1, 1, 3), _emptyDay(2, 2)],
      playersById: players,
      dayRecordToDayNumber: {1: 1, 2: 2},
      expectedOutsiders: 0,
    );
    final self = result.where((c) =>
        c.type == ContradictionType.confirmedRoleConflict &&
        c.playerIds.contains(3) &&
        c.playerIds.length == 1);
    expect(self, isNotEmpty); // 仅 3 号（本人 vs 报告）
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
    expect(result[0].description, contains('修正角色'));
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

  test('规则6：声明 ∈ 恶魔 Bluff → bluffClaim（公理3，#136）', () {
    final result = ContradictionDetector.detect(
      claims: [_claim(1, Character.chef)], // chef 在 Bluff 名单
      declarations: [],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {},
      expectedOutsiders: 0,
      demonBluffs: {Character.chef},
    );
    final bluff = result
        .where((c) => c.type == ContradictionType.bluffClaim)
        .single;
    expect(bluff.playerIds, [1]);
    expect(bluff.severity, ContradictionSeverity.warning);
    expect(bluff.description, contains('Bluff'));
  });

  test('规则6：demonBluffs 为空（非恶魔视角）→ 不检测', () {
    final result = ContradictionDetector.detect(
      claims: [_claim(1, Character.chef)],
      declarations: [],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {},
      expectedOutsiders: 0,
      // demonBluffs 默认空集
    );
    expect(
      result.where((c) => c.type == ContradictionType.bluffClaim),
      isEmpty,
    );
  });

  test('规则4：Empath 醉/毒（possiblyTainted）→ 信息为假，不报（#136 公理4）', () {
    final decl = InfoDeclaration(
      id: 1,
      playerId: 2,
      dayRecordId: 10,
      characterType: Character.empath,
      payloadJson: '{"value": 1}',
      reliability: Reliability.possiblyTainted, // 醉/毒
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
    expect(
      result.where((c) => c.type == ContradictionType.empathMismatch),
      isEmpty,
    );
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

  test('规则4：当天 Slayer/长按标死的邻居仍算存活（#151 C1）', () {
    // 3 号当天死于 other（Slayer 击杀 / 长按标死，均白天）→ Empath 当夜
    // 读取时仍存活，邻居仍为 1、3（与 execution 同）。旧代码漏算 other 会
    // 把 3 排除 → 邻居 [1,4] → 报 1 匹配 → 不报警（错误）。
    final deadPlayers = {
      ...players,
      3: _player(3, 3, deathDay: 2, deathCause: DeathCause.other),
    };
    final result = ContradictionDetector.detect(
      claims: [
        _claim(2, Character.empath),
        _claim(1, Character.chef),
        _claim(3, Character.butler),
        _claim(4, Character.poisoner), // 若 3 被错误排除，会成为右邻居
      ],
      declarations: [_empathDecl(2, 10, 1)],
      days: [],
      playersById: deadPlayers,
      dayRecordToDayNumber: {10: 2},
      expectedOutsiders: 1,
    );
    // 3 仍算邻居 → 邻居 1、3 皆好人 → 报 1 邪恶 → mismatch，涉及 2、1、3
    expect(result, hasLength(1));
    expect(result[0].playerIds, containsAll([2, 1, 3]));
    expect(result[0].playerIds, isNot(contains(4)));
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
          nightConfirmed: true,
          dayExecutionPlayerId: null,
          dayConfirmed: false,
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
          nightConfirmed: false, // 进入第 2 天但夜晚未确认
          dayExecutionPlayerId: null,
          dayConfirmed: false,
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
          nightConfirmed: true,
          dayExecutionPlayerId: null,
          dayConfirmed: false,
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

  test('规则5：无人死亡夜晚 + 当晚 Monk 保护记录 → 提示指向保护成功（#110）', () {
    final result = ContradictionDetector.detect(
      claims: [_claim(1, Character.monk)],
      declarations: [
        InfoDeclaration(
          id: 1,
          playerId: 1,
          dayRecordId: 1,
          characterType: Character.monk,
          payloadJson: '{"playerId": 3}',
          reliability: Reliability.unverified,
          isMine: false,
        ),
      ],
      days: [
        DayRecord(
          id: 1,
          gameId: 1,
          dayNumber: 2,
          nightConfirmed: true,
          dayExecutionPlayerId: null,
          dayConfirmed: false,
          undertakerResultRole: null,
          notes: '',
        ),
      ],
      playersById: players,
      dayRecordToDayNumber: {1: 2},
      expectedOutsiders: 0,
    );
    final noDeath = result.firstWhere(
      (c) => c.type == ContradictionType.noDeathNight,
    );
    expect(noDeath.description, contains('僧侣保护'));
    expect(noDeath.description, contains('保护成功'));
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
          nightConfirmed: true,
          dayExecutionPlayerId: null,
          dayConfirmed: false,
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

  // 占卜师 payload：{"playerIds": [a,b], "answer": bool}（true=是/有恶魔）。
  InfoDeclaration _ftDecl(
    int playerId,
    int dayRecordId,
    List<int> pair,
    bool demonPresent, {
    Reliability reliability = Reliability.unverified,
  }) =>
      InfoDeclaration(
        id: playerId,
        playerId: playerId,
        dayRecordId: dayRecordId,
        characterType: Character.fortuneTeller,
        payloadJson:
            '{"playerIds": [${pair.join(',')}], "answer": $demonPresent}',
        reliability: reliability,
        isMine: false,
      );

  test('规则5(FT)：读「否」但 pair 含已确认 Imp → mismatch（#159 G1）', () {
    final result = ContradictionDetector.detect(
      claims: [_claim(2, Character.imp, type: ClaimType.revealedOnDeath)],
      declarations: [_ftDecl(1, 10, [2, 3], false)],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {10: 2},
      expectedOutsiders: 0,
    );
    expect(result, hasLength(1));
    expect(result[0].type, ContradictionType.fortuneTellerMismatch);
    expect(result[0].playerIds, containsAll([1, 2]));
    expect(result[0].dayNumber, 2);
    expect(result[0].severity, ContradictionSeverity.info);
  });

  test('规则5(FT)：读「是」但 pair 两人都确认好人 → mismatch（#159 G1）', () {
    final result = ContradictionDetector.detect(
      claims: [
        _claim(2, Character.chef, type: ClaimType.revealedOnDeath),
        _claim(3, Character.monk, type: ClaimType.revealedOnDeath),
      ],
      declarations: [_ftDecl(1, 10, [2, 3], true)],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {10: 2},
      expectedOutsiders: 0,
    );
    expect(result, hasLength(1));
    expect(result[0].type, ContradictionType.fortuneTellerMismatch);
    expect(result[0].playerIds, containsAll([1, 2, 3]));
  });

  test('规则5(FT)：醉/毒（possiblyTainted）→ 信息不可靠，不报（公理4）', () {
    final result = ContradictionDetector.detect(
      claims: [_claim(2, Character.imp, type: ClaimType.revealedOnDeath)],
      declarations: [
        _ftDecl(1, 10, [2, 3], false, reliability: Reliability.possiblyTainted),
      ],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {10: 2},
      expectedOutsiders: 0,
    );
    expect(
      result.where(
        (c) => c.type == ContradictionType.fortuneTellerMismatch,
      ),
      isEmpty,
    );
  });

  test('规则5(FT)：读「是」+ pair 含已确认 Recluse → 不报（登记为邪恶，合法）',
      () {
    // Recluse 登记为邪恶 → FT 读「是」是合法解释，不构成矛盾。
    final result = ContradictionDetector.detect(
      claims: [
        _claim(2, Character.recluse, type: ClaimType.revealedOnDeath),
        _claim(3, Character.chef, type: ClaimType.revealedOnDeath),
      ],
      declarations: [_ftDecl(1, 10, [2, 3], true)],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {10: 2},
      expectedOutsiders: 0,
    );
    expect(
      result.where(
        (c) => c.type == ContradictionType.fortuneTellerMismatch,
      ),
      isEmpty,
    );
  });

  test('规则5(FT)：读「否」+ 我座位真实 Imp 在 pair → mismatch（myRole 注入）',
      () {
    final result = ContradictionDetector.detect(
      claims: [],
      declarations: [_ftDecl(1, 10, [2, 3], false)],
      days: [],
      playersById: players,
      dayRecordToDayNumber: {10: 2},
      expectedOutsiders: 0,
      myPlayerId: 2,
      myRole: Character.imp,
    );
    expect(result, hasLength(1));
    expect(result[0].type, ContradictionType.fortuneTellerMismatch);
    expect(result[0].playerIds, containsAll([1, 2]));
  });

  group('规则3b：阵营人数硬约束（#212）', () {
    // 7 人局：TF=5 / 外=0 / 爪=1 / 恶=1。
    final setup = PlayerSetup.forCount(7);

    test('镇民声明 > base+1（Drunk 容差）→ teamCountOverflow', () {
      // 7 个不同镇民声明（无重复）。7 人局 TF=5 +1 Drunk 容差=6，7>6 报。
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.chef),
          _claim(2, Character.empath),
          _claim(3, Character.fortuneTeller),
          _claim(4, Character.undertaker),
          _claim(5, Character.monk),
          _claim(6, Character.ravenkeeper),
          _claim(7, Character.virgin),
        ],
        declarations: [],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
        setup: setup,
      );
      final overflow = result.where(
        (c) => c.type == ContradictionType.teamCountOverflow,
      );
      expect(overflow, hasLength(1));
      expect(overflow.first.severity, ContradictionSeverity.warning);
      expect(overflow.first.playerIds, containsAll([1, 2, 3, 4, 5, 6, 7]));
      expect(overflow.first.description, contains('镇民'));
    });

    test('镇民声明 == base+1 → 不报（Drunk 可能误声明镇民，#212 容差）', () {
      // 8 人局 TF=5/外=1。6 个镇民声明 = 5 真镇民 + 1 Drunk（以镇民 bluff
      // 自居，latestClaimWithSelf 不识破——见其 dartdoc）。这是正常场景，
      // 不应误报为「阵营人数超限」。
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.chef),
          _claim(2, Character.empath),
          _claim(3, Character.fortuneTeller),
          _claim(4, Character.undertaker),
          _claim(5, Character.monk),
          _claim(6, Character.ravenkeeper),
        ],
        declarations: [],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
        setup: PlayerSetup.forCount(8),
      );
      expect(
        result.where((c) => c.type == ContradictionType.teamCountOverflow),
        isEmpty,
      );
    });

    test('爪牙声明 > 爪牙槽 → teamCountOverflow', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.poisoner),
          _claim(2, Character.scarletWoman),
        ],
        declarations: [],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
        setup: setup,
      );
      final overflow = result.where(
        (c) => c.type == ContradictionType.teamCountOverflow,
      );
      expect(overflow, hasLength(1));
      expect(overflow.first.playerIds, containsAll([1, 2]));
      expect(overflow.first.description, contains('爪牙'));
    });

    test('恶魔声明 > 恶魔槽（在世）→ teamCountOverflow', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.imp),
          _claim(2, Character.imp),
        ],
        declarations: [],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
        setup: setup,
      );
      final overflow = result.where(
        (c) => c.type == ContradictionType.teamCountOverflow,
      );
      expect(overflow, hasLength(1));
      expect(overflow.first.description, contains('恶魔'));
    });

    test('恶魔传承：死揭示 Imp + 在世声明 Imp → 不报（排除 revealedOnDeath）',
        () {
      // 1 号死亡揭示为 Imp（原恶魔），2 号在世声明 Imp（继承人）——传承下合法。
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.imp, type: ClaimType.revealedOnDeath),
          _claim(2, Character.imp),
        ],
        declarations: [],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
        setup: setup,
      );
      expect(
        result.where((c) => c.type == ContradictionType.teamCountOverflow),
        isEmpty,
      );
    });

    test('正好等于槽位 → 不报（边界）', () {
      // 5 个不同镇民声明 == TF 槽，不超。
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.chef),
          _claim(2, Character.empath),
          _claim(3, Character.fortuneTeller),
          _claim(4, Character.undertaker),
          _claim(5, Character.monk),
        ],
        declarations: [],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
        setup: setup,
      );
      expect(
        result.where((c) => c.type == ContradictionType.teamCountOverflow),
        isEmpty,
      );
    });

    test('不传 setup → 不检测（向后兼容，现有调用零改动）', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.chef),
          _claim(2, Character.empath),
          _claim(3, Character.fortuneTeller),
          _claim(4, Character.undertaker),
          _claim(5, Character.monk),
          _claim(6, Character.ravenkeeper),
        ],
        declarations: [],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
      );
      expect(
        result.where((c) => c.type == ContradictionType.teamCountOverflow),
        isEmpty,
      );
    });
  });

  // ---- #213：信息角色交叉验证 ----

  InfoDeclaration _pingDecl(
    int playerId,
    Character type,
    String yName,
    List<int> pair,
  ) =>
      InfoDeclaration(
        id: playerId,
        playerId: playerId,
        dayRecordId: 1,
        characterType: type,
        payloadJson:
            '{"character": "$yName", "playerIds": ${jsonEncode(pair)}}',
        reliability: Reliability.unverified,
        isMine: false,
      );

  InfoDeclaration _noneOutsiderDecl(int playerId) => InfoDeclaration(
        id: playerId,
        playerId: playerId,
        dayRecordId: 1,
        characterType: Character.librarian,
        payloadJson: '{"character": null, "playerIds": []}',
        reliability: Reliability.unverified,
        isMine: false,
      );

  InfoDeclaration _chefInfoDecl(int playerId, int value) => InfoDeclaration(
        id: playerId,
        playerId: playerId,
        dayRecordId: 1,
        characterType: Character.chef,
        payloadJson: '{"value": $value}',
        reliability: Reliability.unverified,
        isMine: false,
      );

  group('规则7：开局指认交叉验证（#213）', () {
    test('洗衣妇 ping chef{1,2} + chef 死亡揭示在 4 号 → info（Spy 逃生舱）',
        () {
      final result = ContradictionDetector.detect(
        claims: [_claim(4, Character.chef, type: ClaimType.revealedOnDeath)],
        declarations: [
          _pingDecl(7, Character.washerwoman, 'chef', [1, 2]),
        ],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
      );
      final ping = result.where(
        (c) => c.type == ContradictionType.startInfoPingConflict,
      );
      expect(ping, hasLength(1));
      // pair 未确认 → 无法排除 Spy 登记冒充 → info
      expect(ping.first.severity, ContradictionSeverity.info);
      expect(ping.first.playerIds, containsAll([7, 1, 2]));
      expect(ping.first.description, contains('间谍'));
    });

    test('pair 全员已确认非 Spy → 升级 warning', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(4, Character.chef, type: ClaimType.revealedOnDeath),
          _claim(1, Character.monk, type: ClaimType.revealedOnDeath),
          _claim(2, Character.empath, type: ClaimType.revealedOnDeath),
        ],
        declarations: [
          _pingDecl(7, Character.washerwoman, 'chef', [1, 2]),
        ],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
      );
      final ping = result.where(
        (c) => c.type == ContradictionType.startInfoPingConflict,
      );
      expect(ping, hasLength(1));
      expect(ping.first.severity, ContradictionSeverity.warning);
    });

    test('Y 确认者本人在 pair 内 → 自洽，不报', () {
      final result = ContradictionDetector.detect(
        claims: [_claim(1, Character.chef, type: ClaimType.revealedOnDeath)],
        declarations: [
          _pingDecl(7, Character.washerwoman, 'chef', [1, 2]),
        ],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
      );
      expect(
        result.where((c) => c.type == ContradictionType.startInfoPingConflict),
        isEmpty,
      );
    });

    test('pair 成员已确认是 Y（Y 被双重揭示）→ ping 自洽，不报（review 修复）',
        () {
      // chef 被揭示在 1 号（pair 内）与 4 号（冲突数据）——ping{1,2} 经由
      // 1 号自洽；数据冲突由规则 2 处理，ping 本身不应误报。
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.chef, type: ClaimType.revealedOnDeath),
          _claim(4, Character.chef, type: ClaimType.revealedOnDeath),
        ],
        declarations: [
          _pingDecl(7, Character.washerwoman, 'chef', [1, 2]),
        ],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
      );
      expect(
        result.where((c) => c.type == ContradictionType.startInfoPingConflict),
        isEmpty,
      );
    });

    test('调查员 ping 爪牙：逃生舱是隐士（Recluse），不是间谍', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(5, Character.poisoner, type: ClaimType.revealedOnDeath),
        ],
        declarations: [
          _pingDecl(7, Character.investigator, 'poisoner', [1, 2]),
        ],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
      );
      final ping = result.where(
        (c) => c.type == ContradictionType.startInfoPingConflict,
      );
      expect(ping, hasLength(1));
      expect(ping.first.severity, ContradictionSeverity.info);
      // 爪牙 Y 的登记冒充者只能是 Recluse
      expect(ping.first.description, contains('隐士'));
      expect(ping.first.description, isNot(contains('间谍')));
    });

    test('ping 角色 ∈ 恶魔 Bluff（确定性不在场）→ 冲突', () {
      final result = ContradictionDetector.detect(
        claims: [],
        declarations: [
          _pingDecl(7, Character.washerwoman, 'chef', [1, 2]),
        ],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
        demonBluffs: {Character.chef},
      );
      final ping = result.where(
        (c) => c.type == ContradictionType.startInfoPingConflict,
      );
      expect(ping, hasLength(1));
      expect(ping.first.severity, ContradictionSeverity.info);
      expect(ping.first.description, contains('Bluff'));
    });

    test('pair 含已确认间谍（善良 Y）→ 逃生舱坐实，保持 info', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(4, Character.chef, type: ClaimType.revealedOnDeath),
          _claim(1, Character.spy, type: ClaimType.revealedOnDeath),
        ],
        declarations: [
          _pingDecl(7, Character.washerwoman, 'chef', [1, 2]),
        ],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
      );
      final ping = result.where(
        (c) => c.type == ContradictionType.startInfoPingConflict,
      );
      expect(ping, hasLength(1));
      expect(ping.first.severity, ContradictionSeverity.info);
    });

    test('醉/毒 ping（possiblyTainted）→ 公理4 不报', () {
      final result = ContradictionDetector.detect(
        claims: [_claim(4, Character.chef, type: ClaimType.revealedOnDeath)],
        declarations: [
          InfoDeclaration(
            id: 7,
            playerId: 7,
            dayRecordId: 1,
            characterType: Character.washerwoman,
            payloadJson: '{"character": "chef", "playerIds": [1, 2]}',
            reliability: Reliability.possiblyTainted,
            isMine: false,
          ),
        ],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
      );
      expect(
        result.where((c) => c.type == ContradictionType.startInfoPingConflict),
        isEmpty,
      );
    });

    test('我的真实角色是 Y 且不在 pair → 冲突（myRole 证据）', () {
      final result = ContradictionDetector.detect(
        claims: [],
        declarations: [
          _pingDecl(7, Character.washerwoman, 'chef', [2, 3]),
        ],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
        myPlayerId: 5,
        myRole: Character.chef,
      );
      expect(
        result.where((c) => c.type == ContradictionType.startInfoPingConflict),
        hasLength(1),
      );
    });

    test('图书管理员「无外来者」+ butler 死亡揭示 → zeroOutsider warning', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(3, Character.butler, type: ClaimType.revealedOnDeath),
        ],
        declarations: [_noneOutsiderDecl(7)],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 1,
      );
      final zero = result.where(
        (c) => c.type == ContradictionType.zeroOutsiderConflict,
      );
      expect(zero, hasLength(1));
      expect(zero.first.severity, ContradictionSeverity.warning);
      expect(zero.first.playerIds, [3]);
    });

    test('「无外来者」+ 无已确认外来者 → 不报', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(3, Character.butler), // 仅声明，非确认
        ],
        declarations: [_noneOutsiderDecl(7)],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 1,
      );
      expect(
        result.where((c) => c.type == ContradictionType.zeroOutsiderConflict),
        isEmpty,
      );
    });

    test('「无外来者」+ 我的真实角色是外来者 → 证伪（myRole）', () {
      final result = ContradictionDetector.detect(
        claims: [],
        declarations: [_noneOutsiderDecl(7)],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 1,
        myPlayerId: 5,
        myRole: Character.saint,
      );
      expect(
        result.where((c) => c.type == ContradictionType.zeroOutsiderConflict),
        hasLength(1),
      );
    });
  });

  group('规则8：厨师计数交叉验证（#213）', () {
    test('厨师 3 > 7人局 evilCount 2 → warning（物理不可能）', () {
      final result = ContradictionDetector.detect(
        claims: [],
        declarations: [_chefInfoDecl(7, 3)],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
        setup: PlayerSetup.forCount(7),
      );
      final chef = result.where(
        (c) => c.type == ContradictionType.chefCountMismatch,
      );
      expect(chef, hasLength(1));
      expect(chef.first.severity, ContradictionSeverity.warning);
      expect(chef.first.description, contains('至多 2'));
    });

    test('厨师 0 + imp@1/poisoner@2 已确认相邻 → warning（下界）', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.imp, type: ClaimType.revealedOnDeath),
          _claim(2, Character.poisoner, type: ClaimType.revealedOnDeath),
        ],
        declarations: [_chefInfoDecl(7, 0)],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
      );
      final chef = result.where(
        (c) => c.type == ContradictionType.chefCountMismatch,
      );
      expect(chef, hasLength(1));
      expect(chef.first.severity, ContradictionSeverity.warning);
      expect(chef.first.playerIds, containsAll([7, 1, 2]));
    });

    test('厨师 0 + 邪恶不相邻（1号/3号）→ 不报', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.imp, type: ClaimType.revealedOnDeath),
          _claim(3, Character.poisoner, type: ClaimType.revealedOnDeath),
        ],
        declarations: [_chefInfoDecl(7, 0)],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
      );
      expect(
        result.where((c) => c.type == ContradictionType.chefCountMismatch),
        isEmpty,
      );
    });

    test('厨师 0 + 间谍相邻（Spy 登记弹性）→ 不报', () {
      // Spy 是爪牙但「可能登记为善良」→ 不作下界证据。
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.imp, type: ClaimType.revealedOnDeath),
          _claim(2, Character.spy, type: ClaimType.revealedOnDeath),
        ],
        declarations: [_chefInfoDecl(7, 0)],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
      );
      expect(
        result.where((c) => c.type == ContradictionType.chefCountMismatch),
        isEmpty,
      );
    });

    test('厨师 1 + 一对相邻严格邪恶 → 自洽，不报', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.imp, type: ClaimType.revealedOnDeath),
          _claim(2, Character.poisoner, type: ClaimType.revealedOnDeath),
        ],
        declarations: [_chefInfoDecl(7, 1)],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
      );
      expect(
        result.where((c) => c.type == ContradictionType.chefCountMismatch),
        isEmpty,
      );
    });
  });

  group('规则4反向：Empath 0 + 已确认邪恶邻座（#213）', () {
    test('empath 0 + 邻座 imp 死亡揭示 → warning', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.imp, type: ClaimType.revealedOnDeath),
        ],
        declarations: [_empathDecl(2, 10, 0)],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {10: 2},
        expectedOutsiders: 0,
      );
      final empath = result.where(
        (c) => c.type == ContradictionType.empathMismatch,
      );
      expect(empath, hasLength(1));
      expect(empath.first.severity, ContradictionSeverity.warning);
      expect(empath.first.playerIds, containsAll([2, 1]));
    });

    test('empath 0 + 邻座是 Spy（登记弹性）→ 不报', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.spy, type: ClaimType.revealedOnDeath),
        ],
        declarations: [_empathDecl(2, 10, 0)],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {10: 2},
        expectedOutsiders: 0,
      );
      expect(
        result.where((c) => c.type == ContradictionType.empathMismatch),
        isEmpty,
      );
    });

    test('empath 0 + 邻座是 Recluse（默认善良登记）→ 不报', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.recluse, type: ClaimType.revealedOnDeath),
        ],
        declarations: [_empathDecl(2, 10, 0)],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {10: 2},
        expectedOutsiders: 1,
      );
      expect(
        result.where((c) => c.type == ContradictionType.empathMismatch),
        isEmpty,
      );
    });

    test('empath 0 + 邻座当夜被杀（读取时已死）→ 不报（#78 时序）', () {
      final deadPlayers = {
        ...players,
        1: _player(1, 1, deathDay: 2, deathCause: DeathCause.nightKill),
      };
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.imp, type: ClaimType.revealedOnDeath),
        ],
        declarations: [_empathDecl(2, 10, 0)],
        days: [],
        playersById: deadPlayers,
        dayRecordToDayNumber: {10: 2},
        expectedOutsiders: 0,
      );
      expect(
        result.where((c) => c.type == ContradictionType.empathMismatch),
        isEmpty,
      );
    });

    test('empath 0 + 我是相邻的恶魔（myRole 证据）→ warning', () {
      final result = ContradictionDetector.detect(
        claims: [],
        declarations: [_empathDecl(2, 10, 0)],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {10: 2},
        expectedOutsiders: 0,
        myPlayerId: 1,
        myRole: Character.imp,
      );
      expect(
        result.where((c) => c.type == ContradictionType.empathMismatch),
        hasLength(1),
      );
    });

    test('empath 1 + 两邻座均确认善良（非隐士）→ warning（review 补强）', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.monk, type: ClaimType.revealedOnDeath),
          _claim(3, Character.chef, type: ClaimType.revealedOnDeath),
        ],
        declarations: [_empathDecl(2, 10, 1)],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {10: 2},
        expectedOutsiders: 0,
      );
      final empath = result.where(
        (c) => c.type == ContradictionType.empathMismatch,
      );
      expect(empath, hasLength(1));
      expect(empath.first.severity, ContradictionSeverity.warning);
      expect(empath.first.playerIds, containsAll([2, 1, 3]));
    });

    test('empath 1 + 邻座确认隐士 → 可登记邪恶，不报', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.recluse, type: ClaimType.revealedOnDeath),
          _claim(3, Character.chef, type: ClaimType.revealedOnDeath),
        ],
        declarations: [_empathDecl(2, 10, 1)],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {10: 2},
        expectedOutsiders: 1,
      );
      expect(
        result.where((c) => c.type == ContradictionType.empathMismatch),
        isEmpty,
      );
    });

    test('empath 1 + 邻座确认 Spy → 默认邪恶登记可解释，不报', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(1, Character.spy, type: ClaimType.revealedOnDeath),
          _claim(3, Character.chef, type: ClaimType.revealedOnDeath),
        ],
        declarations: [_empathDecl(2, 10, 1)],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {10: 2},
        expectedOutsiders: 0,
      );
      expect(
        result.where((c) => c.type == ContradictionType.empathMismatch),
        isEmpty,
      );
    });
  });
  group('#215 传承 × 死亡揭示冲突（跨剧本通用规则）', () {
    DemonInheritance inh(int id, int from, int? to) => DemonInheritance(
          id: id,
          gameId: 1,
          dayNumber: 2,
          fromPlayerId: from,
          toPlayerId: to,
          trigger: SuccessionTrigger.suicideByImp,
          createdAt: DateTime(2026, 8, 15),
        );

    List<RoleClaim> baseClaims() => [
          _claim(1, Character.washerwoman),
          _claim(2, Character.chef),
          _claim(3, Character.monk),
        ];

    List<Contradiction> detect215({
      List<DemonInheritance> successions = const [],
      List<RoleClaim> extraClaims = const [],
    }) =>
        ContradictionDetector.detect(
          claims: [...baseClaims(), ...extraClaims],
          declarations: [],
          days: [],
          playersById: players,
          dayRecordToDayNumber: {},
          expectedOutsiders: 0,
          successions: successions,
        );

    test('继承人死亡揭示为非恶魔 → warning 冲突', () {
      final result = detect215(
        successions: [inh(1, 2, 3)],
        extraClaims: [
          RoleClaim(
            id: 10,
            playerId: 3,
            dayRecordId: 1,
            character: Character.chef,
            claimType: ClaimType.revealedOnDeath,
          ),
        ],
      );
      final hit = result.where(
        (c) => c.type == ContradictionType.successionRevealConflict,
      ).toList();
      expect(hit, hasLength(1));
      expect(hit.single.severity, ContradictionSeverity.warning);
      expect(hit.single.playerIds, [3]);
      expect(hit.single.description, contains('厨师')); // 揭示角色入文案
    });

    test('继承人死亡揭示为恶魔 → 不报（正常传承链）', () {
      final result = detect215(
        successions: [inh(1, 2, 3)],
        extraClaims: [
          RoleClaim(
            id: 10,
            playerId: 3,
            dayRecordId: 1,
            character: Character.imp,
            claimType: ClaimType.revealedOnDeath,
          ),
        ],
      );
      expect(
        result.where((c) => c.type == ContradictionType.successionRevealConflict),
        isEmpty,
      );
    });

    test('恶魔生前声明好人角色不构成矛盾（bluff 合法）', () {
      // 3 号是继承人，最新**公开声明**为镇民——合法 bluff，不报
      final result = detect215(successions: [inh(1, 2, 3)]);
      expect(
        result.where((c) => c.type == ContradictionType.successionRevealConflict),
        isEmpty,
      );
    });

    test('继承人为空（暂不指定）→ 不报', () {
      final result = detect215(successions: [inh(1, 2, null)]);
      expect(
        result.where((c) => c.type == ContradictionType.successionRevealConflict),
        isEmpty,
      );
    });

    test('S&V 剧本同样适用（跨剧本通用）', () {
      final result = ContradictionDetector.detect(
        claims: [
          ...baseClaims(),
          RoleClaim(
            id: 10,
            playerId: 3,
            dayRecordId: 1,
            character: Character.clockmaker,
            claimType: ClaimType.revealedOnDeath,
          ),
        ],
        declarations: [],
        days: [],
        playersById: players,
        dayRecordToDayNumber: {},
        expectedOutsiders: 0,
        script: Script.sectsAndViolets,
        successions: [inh(1, 2, 3)],
      );
      expect(
        result.where((c) => c.type == ContradictionType.successionRevealConflict),
        hasLength(1),
      );
    });
  });

  group('#264 ④ 复活者的历史死亡重建（aliveOn）', () {
    // 2 号 Empath；1/3 号为邻座。1 号夜 2 死、夜 4 被教授复活。
    InfoDeclaration empathDecl(int dayRecordId) => InfoDeclaration(
          id: 1,
          playerId: 2,
          dayRecordId: dayRecordId,
          characterType: Character.empath,
          payloadJson: '{"value": 1}',
          reliability: Reliability.unverified,
          isMine: false,
        );
    DayRecord rec(int id, int day, {List<int> nightDeaths = const []}) =>
        DayRecord(
          id: id,
          gameId: 1,
          dayNumber: day,
          nightDeathPlayerIds:
              nightDeaths.isEmpty ? null : jsonEncode(nightDeaths),
          nightConfirmed: true,
          dayExecutionPlayerId: null,
          dayConfirmed: false,
          notes: '',
        );

    test('夜 3 读数：夜 2 已死未复活的邻座按死邻居排除 → 无矛盾', () {
      final result = ContradictionDetector.detect(
        claims: [
          _claim(2, Character.empath),
          _claim(1, Character.chef),
          _claim(3, Character.monk),
          _claim(7, Character.monk), // 1 号死后邻座收缩：2 号邻座 = 3/7
        ],
        declarations: [empathDecl(30)],
        days: [rec(20, 2, nightDeaths: [1]), rec(30, 3)],
        playersById: players,
        dayRecordToDayNumber: {30: 3},
        expectedOutsiders: 0,
      );
      // 1 号死邻居不算存活邻座 → 存活邻座只剩 3 号（声明僧侣=好人）
      // → 报 1 邪恶与「全好存活邻居」矛盾应触发？
      // 不——邻座只剩一人且声明好人 → 正向矛盾应触发（1 邪恶无处安放）。
      expect(
        result.where((c) => c.type == ContradictionType.empathMismatch),
        isNotEmpty,
      );
    });

    test('夜 4 起复活（revivedDay=4）：夜 4 读数把 1 号算回活邻居', () {
      // revivedDay 需在 Player 上——直接构造新 Player（copyWith 不含该字段）
      final p1 = Player(
        id: 1,
        gameId: 1,
        name: '玩家1',
        seatNumber: 1,
        isAlive: true,
        abilityUsed: false,
        suspectedDrunk: false,
        fakeDead: false,
        revivedDay: 4,
      );
      final result = ContradictionDetector.detect(
        claims: [
          _claim(2, Character.empath),
          _claim(1, Character.chef),
          _claim(3, Character.monk),
          _claim(7, Character.monk),
        ],
        declarations: [empathDecl(40)],
        days: [rec(20, 2, nightDeaths: [1]), rec(40, 4)],
        playersById: {...players, 1: p1},
        dayRecordToDayNumber: {40: 4},
        expectedOutsiders: 0,
      );
      // 复活后两个活邻居都声明好人 → 报 1 邪恶仍是矛盾（重建应包含 1 号）
      expect(
        result.where((c) => c.type == ContradictionType.empathMismatch),
        isNotEmpty,
      );
    });
  });
}
