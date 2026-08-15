import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';

/// 解析恶魔私密爪牙名单（issue #108）。
///
/// 存于 `Games.myMinionIdsJson`（JSON 玩家 id 数组）；与公开声明的 RoleClaims
/// 隔离，仅对我（恶魔）可见。
Set<int> minionIdsOf(Game game) {
  final json = game.myMinionIdsJson;
  if (json == null) return {};
  try {
    final decoded = jsonDecode(json);
    // 类型守卫：JSON 合法但非数组（null/int/Map）时 as List 抛 TypeError，
    // 逃逸 on FormatException。先 is List 判定（#164 B3/B5）。
    if (decoded is! List) return {};
    return decoded.whereType<int>().toSet();
  } on FormatException {
    return {};
  }
}

/// 解析恶魔的 3 个 Bluff 角色（公理3，issue #136）。
///
/// 存于 `Games.demonBluffsJson`（JSON 角色 name 数组，仅 7+ 人局恶魔录入）。
/// 这 3 个好人角色的「不在场」是确定性事实，可用于矛盾检测/排除法。
Set<Character> demonBluffsOf(Game game) {
  final json = game.demonBluffsJson;
  if (json == null) return {};
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List) return {}; // 同 minionIdsOf（#164 B3/B5）
    return {
      for (final name in decoded.whereType<String>())
        Character.values.where((c) => c.name == name).firstOrNull,
    }.whereType<Character>().toSet();
  } on FormatException {
    return {};
  }
}


/// 解析爪牙侧私密：我的恶魔（#276，7+ 人局爪牙首夜得知）。
int? myDemonPlayerOf(Game game) => game.myDemonPlayerId;

/// 解析爪牙侧私密：我的邪恶队友（不含我/恶魔；损坏 JSON → 空集，
/// 同 minionIdsOf 守卫 #164 B3/B5）。
Set<int> evilTeammateIdsOf(Game game) {
  final json = game.myEvilTeammatesJson;
  if (json == null) return {};
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List) return {};
    return decoded.whereType<int>().toSet();
  } on FormatException {
    return {};
  }
}
