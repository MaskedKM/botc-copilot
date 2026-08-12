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

void main() {
  group('InfoPayloadFormatter.summarize', () {
    test('数字型', () {
      expect(
        InfoPayloadFormatter.summarize(decl(Character.chef, '{"value": 2}')),
        '厨师：2',
      );
    });

    test('双人 + 是/否', () {
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.fortuneTeller, '{"playerIds": [3, 5], "answer": true}'),
        ),
        '占卜师：3 号 + 5 号 → 是',
      );
    });

    test('角色 + 双人（角色名转中文）', () {
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.investigator,
              '{"character": "poisoner", "playerIds": [2, 4]}'),
        ),
        '调查员：投毒者（2 号、4 号）',
      );
    });

    test('图书管理员报"无"', () {
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.librarian, '{"character": null, "playerIds": []}'),
        ),
        '图书管理员：无',
      );
    });

    test('角色名型', () {
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.undertaker, '{"character": "imp"}'),
        ),
        '掘墓人：小恶魔',
      );
    });

    test('自由文本', () {
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.empath, '{"text": "隔壁两人可疑"}'),
        ),
        '共情者：隔壁两人可疑',
      );
    });

    test('夜间行动目标（角色化动词：Monk 保护 / Butler 主人 / Poisoner 下毒）',
        () {
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.monk, '{"playerId": 3}'),
        ),
        '僧侣：保护 3 号',
      );
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.butler, '{"playerId": 5}'),
        ),
        '管家：主人 5 号',
      );
      expect(
        InfoPayloadFormatter.summarize(
          decl(Character.poisoner, '{"playerId": 2}'),
        ),
        '投毒者：下毒 2 号',
      );
    });
  });
}
