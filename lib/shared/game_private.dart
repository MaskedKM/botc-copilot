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
    return (jsonDecode(json) as List).whereType<int>().toSet();
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
    final names = (jsonDecode(json) as List).cast<String>();
    return {
      for (final name in names)
        Character.values.where((c) => c.name == name).firstOrNull,
    }.whereType<Character>().toSet();
  } on FormatException {
    return {};
  }
}
