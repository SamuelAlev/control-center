import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConversationMode', () {
    test('has all three values: chat, review, plan', () {
      expect(ConversationMode.values, hasLength(3));
      expect(ConversationMode.values,
          containsAll([ConversationMode.chat, ConversationMode.review, ConversationMode.plan]));
    });

    group('fromDbValue', () {
      test('returns chat for "chat"', () {
        expect(ConversationMode.fromDbValue('chat'), ConversationMode.chat);
      });

      test('returns review for "review"', () {
        expect(ConversationMode.fromDbValue('review'), ConversationMode.review);
      });

      test('returns plan for "plan"', () {
        expect(ConversationMode.fromDbValue('plan'), ConversationMode.plan);
      });

      test('returns chat for null (default)', () {
        expect(ConversationMode.fromDbValue(null), ConversationMode.chat);
      });

      test('returns chat for unknown string (default)', () {
        expect(ConversationMode.fromDbValue('unknown'), ConversationMode.chat);
      });

      test('returns chat for empty string (default)', () {
        expect(ConversationMode.fromDbValue(''), ConversationMode.chat);
      });

      test('returns chat for whitespace string (default)', () {
        expect(ConversationMode.fromDbValue(' '), ConversationMode.chat);
      });

      test('different case falls through to default chat', () {
        // fromDbValue uses case-sensitive comparison; 'CHAT' ≠ 'chat'
        // but the default fallback is chat, so it still returns chat.
        expect(ConversationMode.fromDbValue('CHAT'), ConversationMode.chat);
        expect(ConversationMode.fromDbValue('Chat'), ConversationMode.chat);
      });
    });

    group('toDbValue', () {
      test('chat returns "chat"', () {
        expect(ConversationMode.chat.toDbValue(), 'chat');
      });

      test('review returns "review"', () {
        expect(ConversationMode.review.toDbValue(), 'review');
      });

      test('plan returns "plan"', () {
        expect(ConversationMode.plan.toDbValue(), 'plan');
      });
    });

    test('round-trip: toDbValue → fromDbValue preserves value', () {
      for (final mode in ConversationMode.values) {
        expect(ConversationMode.fromDbValue(mode.toDbValue()), mode);
      }
    });
  });
}
