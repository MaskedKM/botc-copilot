import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';

/// 一条信息声明在内容上引用的玩家与角色（issue #58）。
///
/// 用于构建信息依赖图：声明 → 引用的玩家（如 Monk 保护 X、占卜师读 A/B、
/// 投毒者下毒 T）。注意这是**内容引用**，与「作者清醒」的可靠性依赖正交——
/// 后者由 [InfoDependencyNode.effectiveReliability] 表达。
class InfoReferences {
  /// 创建引用集。
  const InfoReferences({this.playerIds = const [], this.character});

  /// 引用的玩家 id（payload 中 `playerId`(int) ∪ `playerIds`(List<int>)）。
  final List<int> playerIds;

  /// 引用的角色（payload 中 `character`，存为 enum `.name`）。
  final Character? character;

  /// 无任何引用。
  bool get isEmpty => playerIds.isEmpty && character == null;
}

/// 从 [InfoDeclaration.payloadJson] 提取引用的玩家与角色。
///
/// payload 统一规则：
/// - `playerId`(int) → 单玩家引用（Monk/Butler/Poisoner/Ravenkeeper）。
/// - `playerIds`(List<int>) → 多玩家引用（Fortune Teller/Investigator/
///   Washerwoman/Librarian）。
/// - `character`(enum `.name`) → 角色引用（Undertaker/Ravenkeeper/
///   Investigator/Washerwoman/Librarian）。
///
/// Ravenkeeper 同时含 `playerId` 与 `character`，两者均提取。
/// 解析失败或无对应字段 → 空 [InfoReferences]。
InfoReferences extractReferences(InfoDeclaration decl) {
  try {
    final payload = jsonDecode(decl.payloadJson);
    if (payload is! Map<String, dynamic>) return const InfoReferences();

    final ids = <int>[];
    final single = payload['playerId'];
    if (single is int) ids.add(single);
    final multi = payload['playerIds'];
    if (multi is List) {
      for (final e in multi) {
        if (e is int) ids.add(e);
      }
    }

    Character? character;
    final c = payload['character'];
    if (c is String) {
      character = Character.values.where((x) => x.name == c).firstOrNull;
    }
    return InfoReferences(playerIds: ids, character: character);
  } on FormatException {
    return const InfoReferences();
  }
}
