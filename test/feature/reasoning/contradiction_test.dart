import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/reasoning/domain/contradiction.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

Player _player(int id, int seat, {int? deathDay}) => Player(
      id: id,
      gameId: 1,
      name: 'P$id',
      seatNumber: seat,
      isAlive: deathDay == null,
      abilityUsed: false,
      deathDay: deathDay,
      deathCause: deathDay == null ? null : DeathCause.nightKill,
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

  test('规则3：外来者声明数 > 配置 → outsiderCountAnomaly', () {
    // 7人局应有 0 外来者，1 人声明外来者即异常
    final result = ContradictionDetector.detect(
      claims: [_claim(1, Character.butler)],
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
