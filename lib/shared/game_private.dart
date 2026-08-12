import 'dart:convert';

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
