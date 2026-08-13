import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/player_detail/domain/info_payload_formatter.dart';
import 'package:botc_copilot/shared/info_references.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:botc_copilot/shared/reliability.dart';

/// 信息依赖链中的一个节点：一条声明 + 当前假设下的有效可靠性（issue #58）。
class InfoDependencyNode {
  /// 创建节点。
  const InfoDependencyNode({
    required this.declarationId,
    required this.authorId,
    required this.characterType,
    required this.dayNumber,
    required this.storedReliability,
    required this.effectiveReliability,
    required this.references,
    required this.summary,
    required this.isMine,
    required this.authorAssumedDrunk,
  });

  /// 声明 id。
  final int declarationId;

  /// 作者（信息提供者）id。
  final int authorId;

  /// 来源角色（决定 payload 结构与摘要）。
  final Character characterType;

  /// 报出当天的序号（从 1 起）。
  final int dayNumber;

  /// 存档原始可靠性（反映按天的毒，#122）。
  final Reliability storedReliability;

  /// 当前假设下的有效可靠性（叠加整局醉 overlay + 沙盒假设）。
  final Reliability effectiveReliability;

  /// 内容引用的玩家与角色。
  final InfoReferences references;

  /// 人类可读摘要（座位号标注）。
  final String summary;

  /// 是否为我的信息。
  final bool isMine;

  /// 作者是否在当前假设下被视为醉（持久 suspectedDrunk ∪ 沙盒）。
  final bool authorAssumedDrunk;

  /// 当前假设下信息不可靠（可能醉/毒或已失效）。
  bool get isTainted =>
      effectiveReliability == Reliability.possiblyTainted ||
      effectiveReliability == Reliability.invalidated;
}

/// 信息依赖链聚合（纯函数，issue #58）。
///
/// 在既有 [InfoDeclaration] + [Player] 之上派生：每条声明的有效可靠性
/// （复用 [effectiveReliability]，叠加沙盒假设）、内容引用、座位号摘要。
/// 不写入数据库。原则：展示依赖与假设影响，不判定谁一定是 Drunk。
abstract final class DependencyChainBuilder {
  /// 构建依赖节点列表（按天序 → id）。
  ///
  /// [extraDrunkIds] 为沙盒假设的额外「醉」玩家（不动存档）；持久
  /// `suspectedDrunk` 直接从 [playersById] 读取。两者并集作为作者醉酒判定。
  static List<InfoDependencyNode> build({
    required List<InfoDeclaration> declarations,
    required Map<int, Player> playersById,
    required Map<int, int> dayRecordToDayNumber,
    Set<int> extraDrunkIds = const {},
  }) {
    String seatLabel(int id) {
      final p = playersById[id];
      return p == null ? '$id 号' : '${p.seatNumber}号';
    }

    bool isDrunk(int playerId) =>
        (playersById[playerId]?.suspectedDrunk ?? false) ||
        extraDrunkIds.contains(playerId);

    final nodes = <InfoDependencyNode>[
      for (final d in declarations)
        InfoDependencyNode(
          declarationId: d.id,
          authorId: d.playerId,
          characterType: d.characterType,
          dayNumber: dayRecordToDayNumber[d.dayRecordId] ?? 0,
          storedReliability: d.reliability,
          effectiveReliability:
              effectiveReliability(d.reliability, isDrunk(d.playerId)),
          references: extractReferences(d),
          summary: InfoPayloadFormatter.summarize(d, labelFor: seatLabel),
          isMine: d.isMine,
          authorAssumedDrunk: isDrunk(d.playerId),
        ),
    ];

    nodes.sort((a, b) {
      final cmp = a.dayNumber.compareTo(b.dayNumber);
      return cmp != 0 ? cmp : a.declarationId.compareTo(b.declarationId);
    });
    return nodes;
  }
}
