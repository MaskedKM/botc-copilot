import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/reasoning/data/dependency_chain_provider.dart';
import 'package:botc_copilot/feature/reasoning/domain/dependency_chain.dart';
import 'package:botc_copilot/shared/info_references.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

Player _player(int id, int seat, {bool suspectedDrunk = false}) => Player(
      id: id,
      gameId: 1,
      name: 'P$id',
      seatNumber: seat,
      isAlive: true,
      fakeDead: false,
      abilityUsed: false,
      suspectedDrunk: suspectedDrunk,
      deathDay: null,
      deathCause: null,
    );

InfoDeclaration _decl({
  required int id,
  required int playerId,
  required int dayRecordId,
  required Character character,
  required String payload,
  Reliability reliability = Reliability.unverified,
}) =>
    InfoDeclaration(
      id: id,
      playerId: playerId,
      dayRecordId: dayRecordId,
      characterType: character,
      payloadJson: payload,
      reliability: reliability,
      isMine: false,
    );

void main() {
  const dayOf = {1: 1, 2: 2, 3: 3};

  group('extractReferences', () {
    test('Fortune Teller：playerIds + answer', () {
      final r = extractReferences(_decl(
        id: 1,
        playerId: 10,
        dayRecordId: 1,
        character: Character.fortuneTeller,
        payload: '{"playerIds": [20, 30], "answer": true}',
      ));
      expect(r.playerIds, [20, 30]);
      expect(r.character, isNull);
    });

    test('Investigator：character + playerIds', () {
      final r = extractReferences(_decl(
        id: 2,
        playerId: 10,
        dayRecordId: 1,
        character: Character.investigator,
        payload: '{"character": "poisoner", "playerIds": [3, 4]}',
      ));
      expect(r.playerIds, [3, 4]);
      expect(r.character, Character.poisoner);
    });

    test('Monk / Poisoner：单 playerId', () {
      final r = extractReferences(_decl(
        id: 3,
        playerId: 10,
        dayRecordId: 1,
        character: Character.monk,
        payload: '{"playerId": 5}',
      ));
      expect(r.playerIds, [5]);
      expect(r.character, isNull);
    });

    test('Ravenkeeper：playerId + character 同时提取', () {
      final r = extractReferences(_decl(
        id: 4,
        playerId: 10,
        dayRecordId: 1,
        character: Character.ravenkeeper,
        payload: '{"playerId": 6, "character": "imp"}',
      ));
      expect(r.playerIds, [6]);
      expect(r.character, Character.imp);
    });

    test('Undertaker：仅 character，无玩家', () {
      final r = extractReferences(_decl(
        id: 5,
        playerId: 10,
        dayRecordId: 1,
        character: Character.undertaker,
        payload: '{"character": "imp"}',
      ));
      expect(r.playerIds, isEmpty);
      expect(r.character, Character.imp);
    });

    test('Chef / 自由文本：无引用', () {
      expect(
        extractReferences(_decl(
          id: 6,
          playerId: 10,
          dayRecordId: 1,
          character: Character.chef,
          payload: '{"value": 2}',
        )).isEmpty,
        isTrue,
      );
      expect(
        extractReferences(_decl(
          id: 7,
          playerId: 10,
          dayRecordId: 1,
          character: Character.saint,
          payload: '{"text": "x"}',
        )).isEmpty,
        isTrue,
      );
    });

    test('非法 JSON → 空引用（不抛异常）', () {
      expect(
        extractReferences(_decl(
          id: 8,
          playerId: 10,
          dayRecordId: 1,
          character: Character.chef,
          payload: 'not-json',
        )).isEmpty,
        isTrue,
      );
    });
  });

  group('DependencyChainBuilder', () {
    test('沙盒假设醉 → 该作者信息降级为 possiblyTainted', () {
      final byId = {10: _player(10, 1)};
      final nodes = DependencyChainBuilder.build(
        declarations: [
          _decl(
            id: 1,
            playerId: 10,
            dayRecordId: 1,
            character: Character.fortuneTeller,
            payload: '{"playerIds": [20, 30], "answer": true}',
            reliability: Reliability.verified,
          ),
        ],
        playersById: byId,
        dayRecordToDayNumber: dayOf,
        extraDrunkIds: const {10},
      );
      expect(nodes.single.effectiveReliability,
          Reliability.possiblyTainted);
      expect(nodes.single.storedReliability, Reliability.verified);
      expect(nodes.single.isTainted, isTrue);
      expect(nodes.single.authorAssumedDrunk, isTrue);
    });

    test('持久 suspectedDrunk 同样降级', () {
      final byId = {10: _player(10, 1, suspectedDrunk: true)};
      final nodes = DependencyChainBuilder.build(
        declarations: [
          _decl(
            id: 1,
            playerId: 10,
            dayRecordId: 1,
            character: Character.empath,
            payload: '{"value": 1}',
            reliability: Reliability.verified,
          ),
        ],
        playersById: byId,
        dayRecordToDayNumber: dayOf,
      );
      expect(nodes.single.effectiveReliability,
          Reliability.possiblyTainted);
      expect(nodes.single.authorAssumedDrunk, isTrue);
    });

    test('假设 A 醉 不污染另一作者 B 的信息', () {
      final byId = {10: _player(10, 1), 20: _player(20, 2)};
      final nodes = DependencyChainBuilder.build(
        declarations: [
          _decl(
            id: 1,
            playerId: 10,
            dayRecordId: 1,
            character: Character.empath,
            payload: '{"value": 1}',
            reliability: Reliability.verified,
          ),
          _decl(
            id: 2,
            playerId: 20,
            dayRecordId: 1,
            character: Character.empath,
            payload: '{"value": 0}',
            reliability: Reliability.verified,
          ),
        ],
        playersById: byId,
        dayRecordToDayNumber: dayOf,
        extraDrunkIds: const {10},
      );
      final a = nodes.firstWhere((n) => n.authorId == 10);
      final b = nodes.firstWhere((n) => n.authorId == 20);
      expect(a.effectiveReliability, Reliability.possiblyTainted);
      expect(b.effectiveReliability, Reliability.verified); // 兄弟作者不受波及
      expect(b.authorAssumedDrunk, isFalse);
    });

    test('存档 possiblyTainted + 作者清醒 → isTainted 但作者未醉（分歧情形）', () {
      // 作者未被疑醉、也不在沙盒中，但存档 reliability 为 possiblyTainted
      //（如按夜被毒，#122）。此时信息仍不可靠，但责任不在「整局醉」。
      // UI 须据此区分「信息不可靠」与「作者醉」（见详情对话框）。
      final byId = {10: _player(10, 1)};
      final nodes = DependencyChainBuilder.build(
        declarations: [
          _decl(
            id: 1,
            playerId: 10,
            dayRecordId: 1,
            character: Character.fortuneTeller,
            payload: '{"playerIds": [20], "answer": true}',
            reliability: Reliability.possiblyTainted,
          ),
        ],
        playersById: byId,
        dayRecordToDayNumber: dayOf,
      );
      expect(nodes.single.effectiveReliability, Reliability.possiblyTainted);
      expect(nodes.single.isTainted, isTrue);
      expect(nodes.single.authorAssumedDrunk, isFalse);
    });

    test('invalidated 不被醉酒覆盖', () {
      final byId = {10: _player(10, 1, suspectedDrunk: true)};
      final nodes = DependencyChainBuilder.build(
        declarations: [
          _decl(
            id: 1,
            playerId: 10,
            dayRecordId: 1,
            character: Character.chef,
            payload: '{"value": 0}',
            reliability: Reliability.invalidated,
          ),
        ],
        playersById: byId,
        dayRecordToDayNumber: dayOf,
      );
      expect(nodes.single.effectiveReliability, Reliability.invalidated);
      expect(nodes.single.isTainted, isTrue);
    });

    test('已验证且作者清醒 → 保持 verified，isTainted=false', () {
      final byId = {10: _player(10, 1)};
      final nodes = DependencyChainBuilder.build(
        declarations: [
          _decl(
            id: 1,
            playerId: 10,
            dayRecordId: 1,
            character: Character.chef,
            payload: '{"value": 0}',
            reliability: Reliability.verified,
          ),
        ],
        playersById: byId,
        dayRecordToDayNumber: dayOf,
      );
      expect(nodes.single.effectiveReliability, Reliability.verified);
      expect(nodes.single.isTainted, isFalse);
      expect(nodes.single.authorAssumedDrunk, isFalse);
    });

    test('摘要用座位号标注引用玩家（非数据库 id）', () {
      // 作者 id=10(1号)；引用 playerIds [20,30]（座位 2、3）
      final byId = {
        10: _player(10, 1),
        20: _player(20, 2),
        30: _player(30, 3),
      };
      final nodes = DependencyChainBuilder.build(
        declarations: [
          _decl(
            id: 1,
            playerId: 10,
            dayRecordId: 1,
            character: Character.fortuneTeller,
            payload: '{"playerIds": [20, 30], "answer": true}',
          ),
        ],
        playersById: byId,
        dayRecordToDayNumber: dayOf,
      );
      // 摘要应显示座位 2号、3号，而非 id 20、30
      expect(nodes.single.summary, contains('2号'));
      expect(nodes.single.summary, contains('3号'));
      expect(nodes.single.summary, isNot(contains('20')));
      expect(nodes.single.summary, isNot(contains('30')));
      // 节点引用也保留结构化玩家 id
      expect(nodes.single.references.playerIds, [20, 30]);
    });

    test('按天序 → id 排序（天序与 id 序不同时仍正确）', () {
      final byId = {10: _player(10, 1)};
      final nodes = DependencyChainBuilder.build(
        declarations: [
          _decl(
            id: 7,
            playerId: 10,
            dayRecordId: 1,
            character: Character.chef,
            payload: '{"value": 0}',
          ),
          _decl(
            id: 10,
            playerId: 10,
            dayRecordId: 1,
            character: Character.chef,
            payload: '{"value": 0}',
          ),
          _decl(
            id: 5,
            playerId: 10,
            dayRecordId: 2,
            character: Character.chef,
            payload: '{"value": 0}',
          ),
        ],
        playersById: byId,
        dayRecordToDayNumber: dayOf,
      );
      // 第1天（id 7、10 升序）→ 第2天（id 5）。若只按 id 排会得 [5,7,10]。
      expect(nodes.map((n) => n.declarationId), [7, 10, 5]);
    });
  });

  group('DependencySandboxNotifier', () {
    test('toggle 切换 / reset 清空', () {
      final n = DependencySandboxNotifier();
      expect(n.state, isEmpty);

      n.toggleAssumeDrunk(1);
      expect(n.state, {1});

      // 再次切换 → 移除
      n.toggleAssumeDrunk(1);
      expect(n.state, isEmpty);

      // 多人独立切换
      n.toggleAssumeDrunk(2);
      n.toggleAssumeDrunk(3);
      expect(n.state, {2, 3});

      n.reset();
      expect(n.state, isEmpty);
    });

    test('state 不可变（每次产生新集合）', () {
      final n = DependencySandboxNotifier();
      final before = n.state;
      n.toggleAssumeDrunk(1);
      expect(identical(before, n.state), isFalse);
    });
  });
}
