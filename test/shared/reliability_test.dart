import 'package:botc_copilot/shared/models/enums.dart';
import 'package:botc_copilot/shared/reliability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('effectiveReliability（#109 整局醉 overlay）', () {
    test('未被醉、未存档污染 → 保持存档值', () {
      expect(
        effectiveReliability(Reliability.unverified, false),
        Reliability.unverified,
      );
      expect(
        effectiveReliability(Reliability.verified, false),
        Reliability.verified,
      );
    });

    test('作者被疑醉 → possiblyTainted（覆盖历史+未来，整局生效）', () {
      expect(
        effectiveReliability(Reliability.unverified, true),
        Reliability.possiblyTainted,
      );
      expect(
        effectiveReliability(Reliability.verified, true),
        Reliability.possiblyTainted,
      );
    });

    test('存档已 possiblyTainted（按天毒）→ 保持 possiblyTainted', () {
      expect(
        effectiveReliability(Reliability.possiblyTainted, false),
        Reliability.possiblyTainted,
      );
    });

    test('按天毒 + 整局醉叠加 → possiblyTainted', () {
      expect(
        effectiveReliability(Reliability.possiblyTainted, true),
        Reliability.possiblyTainted,
      );
    });

    test('invalidated 不被覆盖（更强判定）——即使作者被疑醉', () {
      expect(
        effectiveReliability(Reliability.invalidated, true),
        Reliability.invalidated,
      );
      expect(
        effectiveReliability(Reliability.invalidated, false),
        Reliability.invalidated,
      );
    });
  });
}
