import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/feature/setup/domain/setup_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SetupState.nameValidationError（#163 P1）', () {
    test('默认 A~Z 名字 → 通过，step 2 可前进', () {
      expect(SetupState().nameValidationError, isNull);
      expect(SetupState(step: 2).canProceed, isTrue);
    });

    test('空名（含纯空格）→ 报错 + 阻止前进', () {
      final s = SetupState(step: 2, playerNames: ['Alice', ' ', 'C']);
      expect(s.nameValidationError, '每个座位都需要名字');
      expect(s.canProceed, isFalse);
    });

    test('重名 → 报错 + 阻止前进', () {
      final s = SetupState(step: 2, playerNames: ['Alice', 'Bob', 'Alice']);
      expect(s.nameValidationError, '存在重名，请区分玩家');
      expect(s.canProceed, isFalse);
    });

    test('重名经 trim 判定（前后空格不掩饰重名）', () {
      final s = SetupState(step: 2, playerNames: ['Alice', ' Alice ']);
      expect(s.nameValidationError, '存在重名，请区分玩家');
    });

    test('唯一非空名字 → 通过', () {
      final s = SetupState(step: 2, playerNames: ['张三', '李四', '王五']);
      expect(s.nameValidationError, isNull);
      expect(s.canProceed, isTrue);
    });

    test('其他 step 不受名字校验影响', () {
      // step 3（选角色）即使名字非法也可前进到该步判定 myRole
      final s = SetupState(step: 3, playerNames: ['', '']);
      expect(s.canProceed, isFalse); // myRole == null
    });
  });

  group('SetupState.bluffsComplete（#152 BUG-2）', () {
    test('非恶魔 → 无需 Bluff', () {
      expect(SetupState(myRole: Character.empath).bluffsComplete, isTrue);
    });

    test('恶魔 7+ 人局须选满 3 Bluff', () {
      expect(
        SetupState(playerCount: 7, myRole: Character.imp).bluffsComplete,
        isFalse,
      );
      expect(
        SetupState(
          playerCount: 7,
          myRole: Character.imp,
          demonBluffs: [Character.chef],
        ).bluffsComplete,
        isFalse,
      );
      expect(
        SetupState(
          playerCount: 7,
          myRole: Character.imp,
          demonBluffs: [Character.chef, Character.empath, Character.fortuneTeller],
        ).bluffsComplete,
        isTrue,
      );
    });

    test('恶魔 ≤6 人局无 Bluff（官方）', () {
      expect(
        SetupState(playerCount: 6, myRole: Character.imp).bluffsComplete,
        isTrue,
      );
    });

    test('恶魔 7+ 未选满 Bluff → step 4 不可前进', () {
      final s = SetupState(
        step: 4,
        playerCount: 7,
        myRole: Character.imp,
        demonBluffs: [Character.chef],
      );
      expect(s.canProceed, isFalse);
    });
  });
}
