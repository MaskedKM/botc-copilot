import 'dart:convert';

import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/game_board/domain/nomination_rules.dart';
import 'package:botc_copilot/feature/reasoning/domain/voting_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

Player _player(int id, int seat, {bool alive = true}) => Player(
      id: id,
      gameId: 1,
      name: 'P$id',
      seatNumber: seat,
      isAlive: alive,
      abilityUsed: false,
      suspectedDrunk: false,
      deathDay: null,
      deathCause: null,
    );

VoteEntry _v(int playerId, Vote vote, {bool dead = false}) => VoteEntry(
      playerId: playerId,
      vote: vote,
      isDeadVote: dead,
    );

String _votesJson(List<VoteEntry> votes) =>
    jsonEncode(votes.map((e) => e.toJson()).toList());

/// 构造一条提名。仅指定参与的投票记录（模拟详细模式：缺席者不列入）。
Nomination _nom({
  required int id,
  required int dayRecordId,
  int nominator = 1,
  int nominee = 2,
  List<VoteEntry> votes = const [],
}) =>
    Nomination(
      id: id,
      gameId: 1,
      dayRecordId: dayRecordId,
      nominatorPlayerId: nominator,
      nomineePlayerId: nominee,
      passed: false,
      voteResultJson: _votesJson(votes),
    );

void main() {
  const dayOf = {1: 1, 2: 2, 3: 3, 4: 4};

  group('details 排序', () {
    test('按天序 → id 排列', () {
      final players = [_player(1, 1), _player(2, 2)];
      final noms = [
        _nom(id: 10, dayRecordId: 2, votes: [_v(1, Vote.forVote)]),
        _nom(id: 5, dayRecordId: 1, votes: [_v(1, Vote.forVote)]),
        _nom(id: 7, dayRecordId: 1, votes: [_v(1, Vote.against)]),
      ];
      final a = VotingAnalyzer.analyze(
        nominations: noms,
        players: players,
        dayRecordToDayNumber: dayOf,
      );
      expect(a.details.map((d) => d.nominationId), [5, 7, 10]);
      expect(a.details.map((d) => d.dayNumber), [1, 1, 2]);
    });
  });

  group('一致性矩阵', () {
    test('同向 = 1.0，反向 = 0.0', () {
      final players = [_player(1, 1), _player(2, 2), _player(3, 3)];
      final noms = [
        _nom(
          id: 1,
          dayRecordId: 1,
          votes: [
            _v(1, Vote.forVote),
            _v(2, Vote.forVote),
            _v(3, Vote.against),
          ],
        ),
        _nom(
          id: 2,
          dayRecordId: 2,
          votes: [
            _v(1, Vote.forVote),
            _v(2, Vote.forVote),
            _v(3, Vote.against),
          ],
        ),
      ];
      final a = VotingAnalyzer.analyze(
        nominations: noms,
        players: players,
        dayRecordToDayNumber: dayOf,
      );
      expect(a.consistency[1]![2]!.ratio, 1.0);
      expect(a.consistency[1]![2]!.participatedTogether, 2);
      expect(a.consistency[1]![3]!.ratio, 0.0);
      expect(a.consistency[2]![3]!.ratio, 0.0);
      // 对称
      expect(a.consistency[2]![1]!.ratio, 1.0);
    });

    test('缺席（无记录）不计入分母，区别于弃权', () {
      final players = [_player(1, 1), _player(2, 2), _player(3, 3)];
      // nom1：P3 缺席；nom2：三人均参与且全赞成
      final noms = [
        _nom(
          id: 1,
          dayRecordId: 1,
          votes: [_v(1, Vote.forVote), _v(2, Vote.forVote)], // P3 无记录
        ),
        _nom(
          id: 2,
          dayRecordId: 2,
          votes: [
            _v(1, Vote.forVote),
            _v(2, Vote.forVote),
            _v(3, Vote.forVote),
          ],
        ),
      ];
      final a = VotingAnalyzer.analyze(
        nominations: noms,
        players: players,
        dayRecordToDayNumber: dayOf,
      );
      // P1-P2：两次共同参与，全同向 → 1.0
      expect(a.consistency[1]![2]!.participatedTogether, 2);
      expect(a.consistency[1]![2]!.ratio, 1.0);
      // P1-P3：仅 nom2 共同参与（nom1 P3 缺席）→ participated 1
      expect(a.consistency[1]![3]!.participatedTogether, 1);
      expect(a.consistency[1]![3]!.agreedCount, 1);
      expect(a.consistency[1]![3]!.ratio, 1.0);
    });
  });

  group('高频同投组', () {
    test('两组各自聚成一团，跨组无边', () {
      // P1,P2,P3 总是赞成；P4,P5 总是反对
      final players = [
        _player(1, 1),
        _player(2, 2),
        _player(3, 3),
        _player(4, 4),
        _player(5, 5),
      ];
      final noms = [
        for (final id in [10, 11, 12])
          _nom(
            id: id,
            dayRecordId: id - 9,
            votes: [
              _v(1, Vote.forVote),
              _v(2, Vote.forVote),
              _v(3, Vote.forVote),
              _v(4, Vote.against),
              _v(5, Vote.against),
            ],
          ),
      ];
      final a = VotingAnalyzer.analyze(
        nominations: noms,
        players: players,
        dayRecordToDayNumber: dayOf,
      );
      expect(a.clusters.length, 2);
      final sizes = a.clusters.map((c) => c.playerIds.length).toList()..sort();
      expect(sizes, [2, 3]);
      // 1/2/3 同组，4/5 同组
      final big = a.clusters.firstWhere((c) => c.playerIds.length == 3);
      expect(big.playerIds, containsAll([1, 2, 3]));
      expect(big.avgRatio, 1.0);
    });

    test('共同提名数 < minData 不建边', () {
      final players = [_player(1, 1), _player(2, 2)];
      final noms = [
        // 仅 1 次共同参与
        _nom(
          id: 1,
          dayRecordId: 1,
          votes: [_v(1, Vote.forVote), _v(2, Vote.forVote)],
        ),
      ];
      final a = VotingAnalyzer.analyze(
        nominations: noms,
        players: players,
        dayRecordToDayNumber: dayOf,
      );
      expect(a.clusters, isEmpty); // minData 默认 2
    });

    test('死者不参与聚类', () {
      final players = [
        _player(1, 1),
        _player(2, 2),
        _player(3, 3, alive: false),
      ];
      final noms = [
        for (final id in [10, 11])
          _nom(
            id: id,
            dayRecordId: id - 9,
            votes: [
              _v(1, Vote.forVote),
              _v(2, Vote.forVote),
              _v(3, Vote.forVote, dead: true),
            ],
          ),
      ];
      final a = VotingAnalyzer.analyze(
        nominations: noms,
        players: players,
        dayRecordToDayNumber: dayOf,
      );
      // 仅 {1,2} 成团，P3（死）即便两次同向也不在
      expect(a.clusters.length, 1);
      expect(a.clusters.single.playerIds, [1, 2]);
    });
  });

  group('异常投票', () {
    test('历史跟随多数后突然背离 → 标记', () {
      final players = [_player(1, 1), _player(2, 2), _player(3, 3)];
      final noms = [
        // nom1,2：多数=赞成，P1/P2 赞成，P3 反对
        _nom(
          id: 10,
          dayRecordId: 1,
          votes: [
            _v(1, Vote.forVote),
            _v(2, Vote.forVote),
            _v(3, Vote.against),
          ],
        ),
        _nom(
          id: 11,
          dayRecordId: 2,
          votes: [
            _v(1, Vote.forVote),
            _v(2, Vote.forVote),
            _v(3, Vote.against),
          ],
        ),
        // nom3：多数=赞成（P2/P3 赞成），P1 突然反对
        _nom(
          id: 12,
          dayRecordId: 3,
          votes: [
            _v(1, Vote.against),
            _v(2, Vote.forVote),
            _v(3, Vote.forVote),
          ],
        ),
      ];
      final a = VotingAnalyzer.analyze(
        nominations: noms,
        players: players,
        dayRecordToDayNumber: dayOf,
      );
      expect(a.anomalies.length, 1);
      expect(a.anomalies.single.voterId, 1);
      expect(a.anomalies.single.nominationId, 12);
      expect(a.anomalies.single.actualVote, Vote.against);
      expect(a.anomalies.single.majorityVote, Vote.forVote);
      expect(a.anomalies.single.historicalMajorityRate, 1.0);
    });

    test('历史样本不足（< minHistory）不标记', () {
      final players = [_player(1, 1), _player(2, 2), _player(3, 3)];
      final noms = [
        // nom1：P1 赞成（跟随多数），仅 1 次历史
        _nom(
          id: 10,
          dayRecordId: 1,
          votes: [
            _v(1, Vote.forVote),
            _v(2, Vote.forVote),
            _v(3, Vote.against),
          ],
        ),
        // nom2：P1 立即背离，但历史仅 1 < 2
        _nom(
          id: 11,
          dayRecordId: 2,
          votes: [
            _v(1, Vote.against),
            _v(2, Vote.forVote),
            _v(3, Vote.forVote),
          ],
        ),
      ];
      final a = VotingAnalyzer.analyze(
        nominations: noms,
        players: players,
        dayRecordToDayNumber: dayOf,
      );
      expect(a.anomalies, isEmpty);
    });

    test('平票（无明确多数）不标记也不计入历史', () {
      final players = [_player(1, 1), _player(2, 2), _player(3, 3), _player(4, 4)];
      final noms = [
        // nom1,2：3 赞成 vs 1 反对 → 多数赞成，P1 跟随 2 次建立模式
        _nom(
          id: 10,
          dayRecordId: 1,
          votes: [
            _v(1, Vote.forVote),
            _v(2, Vote.forVote),
            _v(3, Vote.forVote),
            _v(4, Vote.against),
          ],
        ),
        _nom(
          id: 11,
          dayRecordId: 2,
          votes: [
            _v(1, Vote.forVote),
            _v(2, Vote.forVote),
            _v(3, Vote.forVote),
            _v(4, Vote.against),
          ],
        ),
        // nom3：2 赞成 vs 2 反对 → 平票，无多数。P1 投赞成；若误判多数，
        // 因 P1 历史跟随率 1.0，会误触发异常 → 以此锁定平票短路。
        _nom(
          id: 12,
          dayRecordId: 3,
          votes: [
            _v(1, Vote.forVote),
            _v(2, Vote.forVote),
            _v(3, Vote.against),
            _v(4, Vote.against),
          ],
        ),
      ];
      final a = VotingAnalyzer.analyze(
        nominations: noms,
        players: players,
        dayRecordToDayNumber: dayOf,
      );
      expect(a.anomalies, isEmpty);
    });

    test('死票不参与多数判定', () {
      final players = [
        _player(1, 1),
        _player(2, 2),
        _player(3, 3, alive: false),
      ];
      // 存活 P1 赞成、P2 反对 → 平票（1:1）；死者 P3 赞成被忽略
      final noms = [
        _nom(
          id: 10,
          dayRecordId: 1,
          votes: [
            _v(1, Vote.forVote),
            _v(2, Vote.against),
            _v(3, Vote.forVote, dead: true),
          ],
        ),
      ];
      final a = VotingAnalyzer.analyze(
        nominations: noms,
        players: players,
        dayRecordToDayNumber: dayOf,
      );
      // 存活 1:1 平票 → 无多数 → 无异常
      expect(a.anomalies, isEmpty);
    });
  });

  group('空数据', () {
    test('无提名 → 空结果（provider 侧已短路，这里验证健壮性）', () {
      final a = VotingAnalyzer.analyze(
        nominations: [],
        players: [_player(1, 1)],
        dayRecordToDayNumber: dayOf,
      );
      expect(a.details, isEmpty);
      expect(a.clusters, isEmpty);
      expect(a.anomalies, isEmpty);
      // 矩阵外层仍含所有玩家 key
      expect(a.consistency.containsKey(1), isTrue);
    });
  });
}
