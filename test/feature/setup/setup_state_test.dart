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
}
