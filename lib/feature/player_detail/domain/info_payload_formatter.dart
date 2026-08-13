import 'dart:convert';

import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';

/// 信息声明 payload 的可读摘要（录入回显 / 时间线展示用）。
abstract final class InfoPayloadFormatter {
  /// 把一条信息声明格式化为一句话摘要。
  ///
  /// [labelFor] **必填**：把 payload 里的目标玩家 **db id** 解析为展示标签
  /// （通常是「座位号」，如 `5 号`）。历史上这里有个危险默认值 `'$id 号'`——
  /// 它把 db id 当座位号渲染，多局存档后 db id > 座位数即错乱（issue #145）。
  /// 现改为必填，漏传即编译错误，从机制上杜绝复发。
  static String summarize(
    InfoDeclaration decl, {
    required String Function(int playerId) labelFor,
    String? playerName,
  }) {
    try {
      final decoded = jsonDecode(decl.payloadJson);
      // 类型守卫：损坏 / 非对象 payload 不应崩 UI（#164 B1）。
      if (decoded is! Map<String, dynamic>) {
        return '${decl.characterType.nameCn}（数据异常）';
      }
      final payload = decoded;
      final character = decl.characterType;

      String playerLabel(int id) => labelFor(id);

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
        // {"playerId": n, "character": "..."}（Ravenkeeper：X号 是 Y）
        _ when payload.containsKey('playerId') &&
                payload.containsKey('character') =>
          '${character.nameCn}：${playerLabel(payload['playerId'] as int)} 是 ${charLabel(payload['character'])}',
        // {"character": "..."}
        _ when payload.containsKey('character') =>
          '${character.nameCn}：${charLabel(payload['character'])}',
        // {"playerId": n}（Monk 保护 / Butler 主人 / Poisoner 下毒）
        _ when payload.containsKey('playerId') =>
          '${character.nameCn}：${_nightActionVerb(character)}'
              '${playerLabel(payload['playerId'] as int)}',
        // {"text": "..."}
        _ when payload.containsKey('text') =>
          '${character.nameCn}：${payload['text']}',
        _ => character.nameCn,
      };
    } on Object {
      // 损坏 payload：降级文案，绝不崩 UI（详情 / 时间线 / 依赖链，#164 B1）。
      return '${decl.characterType.nameCn}（数据异常）';
    }
  }

  /// 夜间行动目标的动词（Monk 保护 / Butler 主人 / Poisoner 下毒）。
  static String _nightActionVerb(Character c) => switch (c) {
        Character.monk => '保护 ',
        Character.butler => '主人 ',
        Character.poisoner => '下毒 ',
        _ => '',
      };

  /// 解析 payload 中的角色（适用于 undertaker / ravenkeeper 等
  /// `{"character": "..."}` 结构的声明）。
  ///
  /// payload 里的 character 存的是 enum `.name`（如 `'poisoner'`），
  /// 这里转回 [Character]。无该字段或解析失败返回 null。
  static Character? characterOf(InfoDeclaration decl) {
    try {
      final payload = jsonDecode(decl.payloadJson);
      if (payload is! Map || payload['character'] is! String) return null;
      final name = payload['character'] as String;
      return Character.values.where((c) => c.name == name).firstOrNull;
    } on FormatException {
      return null;
    }
  }
}
