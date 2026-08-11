import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';

/// 信息声明 payload 的可读摘要（录入回显 / 时间线展示用）。
abstract final class InfoPayloadFormatter {
  /// 把一条信息声明格式化为一句话摘要。
  static String summarize(InfoDeclaration decl, {String? playerName}) {
    final payload = jsonDecode(decl.payloadJson) as Map<String, dynamic>;
    final character = decl.characterType;

    String playerLabel(int id) => '$id 号';

    // payload 里的 character 存的是 enum .name（如 'poisoner'），回显时转中文。
    String charLabel(Object? name) {
      if (name == null) return '无';
      final c = Character.values.where((c) => c.name == name).firstOrNull;
      return c?.nameCn ?? '$name';
    }

    return switch (character.infoInputType) {
      // {"value": n}
      _ when payload.containsKey('value') =>
        '${character.nameCn}：${payload['value']}',
      // {"playerIds": [a,b], "answer": bool}
      _ when payload.containsKey('answer') =>
        '${character.nameCn}：${(payload['playerIds'] as List).map((id) => playerLabel(id as int)).join(' + ')}'
            ' → ${payload['answer'] == true ? '是' : '否'}',
      // {"character": ..., "playerIds": [...]}
      _ when payload.containsKey('playerIds') =>
        '${character.nameCn}：${charLabel(payload['character'])}'
            '${(payload['playerIds'] as List).isEmpty ? '' : '（${(payload['playerIds'] as List).map((id) => playerLabel(id as int)).join('、')}）'}',
      // {"character": "..."}
      _ when payload.containsKey('character') =>
        '${character.nameCn}：${charLabel(payload['character'])}',
      // {"text": "..."}
      _ when payload.containsKey('text') =>
        '${character.nameCn}：${payload['text']}',
      _ => character.nameCn,
    };
  }
}
