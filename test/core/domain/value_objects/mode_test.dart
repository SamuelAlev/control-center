import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mode', () {
    test('has all four values: chat, review, plan, orchestrate', () {
      expect(Mode.values, hasLength(4));
      expect(
        Mode.values,
        containsAll([Mode.chat, Mode.review, Mode.plan, Mode.orchestrate]),
      );
    });

    group('fromDbValue', () {
      test('returns chat for "chat"', () {
        expect(Mode.fromDbValue('chat'), Mode.chat);
      });

      test('returns review for "review"', () {
        expect(Mode.fromDbValue('review'), Mode.review);
      });

      test('returns plan for "plan"', () {
        expect(Mode.fromDbValue('plan'), Mode.plan);
      });

      test('returns chat for null (default)', () {
        expect(Mode.fromDbValue(null), Mode.chat);
      });

      test('returns chat for unknown string (default)', () {
        expect(Mode.fromDbValue('unknown'), Mode.chat);
      });

      test('returns chat for empty string (default)', () {
        expect(Mode.fromDbValue(''), Mode.chat);
      });

      test('returns chat for whitespace string (default)', () {
        expect(Mode.fromDbValue(' '), Mode.chat);
      });

      test('different case falls through to default chat', () {
        // fromDbValue uses case-sensitive comparison; 'CHAT' ≠ 'chat'
        // but the default fallback is chat, so it still returns chat.
        expect(Mode.fromDbValue('CHAT'), Mode.chat);
        expect(Mode.fromDbValue('Chat'), Mode.chat);
      });
    });

    group('toDbValue', () {
      test('chat returns "chat"', () {
        expect(Mode.chat.toDbValue(), 'chat');
      });

      test('review returns "review"', () {
        expect(Mode.review.toDbValue(), 'review');
      });

      test('plan returns "plan"', () {
        expect(Mode.plan.toDbValue(), 'plan');
      });
    });

    test('round-trip: toDbValue → fromDbValue preserves value', () {
      for (final mode in Mode.values) {
        expect(Mode.fromDbValue(mode.toDbValue()), mode);
      }
    });
  });
}
