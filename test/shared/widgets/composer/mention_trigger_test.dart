import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectMentionQuery', () {
    test('returns null on empty text', () {
      expect(detectMentionQuery('', 0), isNull);
    });

    test('returns null when caret is out of range', () {
      expect(detectMentionQuery('hello', -1), isNull);
      expect(detectMentionQuery('hello', 999), isNull);
    });

    test('detects @ at start of text', () {
      final q = detectMentionQuery('@ag', 3);
      expect(q, isNotNull);
      expect(q!.trigger, MentionTrigger.at);
      expect(q.partial, 'ag');
      expect(q.start, 0);
      expect(q.end, 3);
    });

    test('detects @ after a space', () {
      final q = detectMentionQuery('hi @sam', 7);
      expect(q!.trigger, MentionTrigger.at);
      expect(q.partial, 'sam');
      expect(q.start, 3);
    });

    test('detects @ after a newline', () {
      final q = detectMentionQuery('line one\n@bob', 13);
      expect(q!.partial, 'bob');
      expect(q.start, 9);
    });

    test('does not trigger mid-word (email-like)', () {
      // The "@" inside an email shouldn't open a popup.
      expect(detectMentionQuery('foo@bar', 7), isNull);
    });

    test('partial closes on whitespace', () {
      // After the space the query ends; caret right after space → no popup.
      expect(detectMentionQuery('@bob ', 5), isNull);
    });

    test('slash only triggers at offset 0', () {
      final atZero = detectMentionQuery('/help', 5);
      expect(atZero!.trigger, MentionTrigger.slash);
      expect(atZero.partial, 'help');

      // Slash later in the line is NOT a slash command.
      expect(detectMentionQuery('hi /help', 8), isNull);
    });

    test('hash triggers after whitespace', () {
      final q = detectMentionQuery('see #pr', 7);
      expect(q!.trigger, MentionTrigger.hash);
      expect(q.partial, 'pr');
    });

    test('only the closest trigger to the caret wins', () {
      // Earlier @foo is closed; the active one is @bar.
      final q = detectMentionQuery('@foo and @bar', 13);
      expect(q!.partial, 'bar');
      expect(q.start, 9);
    });

    test('empty partial at trigger char is valid', () {
      final q = detectMentionQuery('@', 1);
      expect(q!.partial, '');
      expect(q.start, 0);
    });
  });
}
