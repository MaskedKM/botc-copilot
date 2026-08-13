import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/player_detail/domain/info_payload_formatter.dart';
import 'package:botc_copilot/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

InfoDeclaration decl(Character c, String payload) => InfoDeclaration(
      id: 1,
      playerId: 1,
      dayRecordId: 1,
      characterType: c,
      payloadJson: payload,
      reliability: Reliability.unverified,
      isMine: false,
    );

/// 测试用 labelFor：把 id 原样作座位号（这些用例关注格式而非 id→座位映射）。
String labelFor(int id) => '$id 号';

void main() {
  group('InfoPayloadFormatter.summarize', () {
    test('数字型', () {
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.chef, '{"value": 2}'),
          labelFor: labelFor,
        ),
        '厨师：2',
      );
    });

    test('双人 + 是/否', () {
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.fortuneTeller, '{"playerIds": [3, 5], "answer": true}'),
          labelFor: labelFor,
        ),
        '占卜师：3 号 + 5 号 → 是',
      );
    });

    test('角色 + 双人（角色名转中文）', () {
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.investigator,
              '{"character": "poisoner", "playerIds": [2, 4]}'),
          labelFor: labelFor,
        ),
        '调查员：投毒者（2 号、4 号）',
      );
    });

    test('图书管理员报"无"', () {
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.librarian, '{"character": null, "playerIds": []}'),
          labelFor: labelFor,
        ),
        '图书管理员：无',
      );
    });

    test('角色名型', () {
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.undertaker, '{"character": "imp"}'),
          labelFor: labelFor,
        ),
        '掘墓人：小恶魔',
      );
    });

    test('自由文本', () {
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.empath, '{"text": "隔壁两人可疑"}'),
          labelFor: labelFor,
        ),
        '共情者：隔壁两人可疑',
      );
    });

    test('夜间行动目标（角色化动词：Monk 保护 / Butler 主人 / Poisoner 下毒）',
        () {
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.monk, '{"playerId": 3}'),
          labelFor: labelFor,
        ),
        '僧侣：保护 3 号',
      );
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.butler, '{"playerId": 5}'),
          labelFor: labelFor,
        ),
        '管家：主人 5 号',
      );
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.poisoner, '{"playerId": 2}'),
          labelFor: labelFor,
        ),
        '投毒者：下毒 2 号',
      );
    });

    test('Ravenkeeper：玩家 + 角色（不得丢失玩家）', () {
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.ravenkeeper, '{"playerId": 5, "character": "spy"}'),
          labelFor: labelFor,
        ),
        '渡鸦守护者：5 号 是 间谍',
      );
    });

    // #145 回归：payload 存的是 db id，必须经 labelFor 解析为座位号，
    // 不可直接把 db id 当座位号（否则 db id=24 会显示成「24 号」）。
    test('labelFor 把 db id 解析为座位号（#145 回归）', () {
      String seatLabel(int id) => id == 24 ? '5 号' : '$id 号';
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.poisoner, '{"playerId": 24}'),
          labelFor: seatLabel,
        ),
        '投毒者：下毒 5 号',
      );
      // 多目标同理
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.fortuneTeller,
              '{"playerIds": [24, 30], "answer": false}'),
          labelFor: seatLabel,
        ),
        '占卜师：5 号 + 30 号 → 否',
      );
      // Ravenkeeper：玩家 + 角色（labelFor 解析座位号，不丢失玩家）
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.ravenkeeper, '{"playerId": 24, "character": "spy"}'),
          labelFor: seatLabel,
        ),
        '渡鸦守护者：5 号 是 间谍',
      );
    });
  });
}
