import 'package:cc_domain/features/meetings/domain/services/meeting_outcome.dart';
import 'package:test/test.dart';

/// Exercises [MeetingOutcome.parse] — the single normalizer for a meeting-
/// summary agent's output. It must accept a structured Map, a `{result: ...}`
/// wrapper, a JSON string, fenced markdown JSON and a plain-text fallback.
void main() {
  group('MeetingOutcome.parse', () {
    test('null yields an empty outcome', () {
      final o = MeetingOutcome.parse(null);
      expect(o.title, isNull);
      expect(o.summary, isNull);
      expect(o.enhancedNotes, isNull);
      expect(o.isStructured, isFalse);
    });

    test('a plain string falls back to enhancedNotes', () {
      final o = MeetingOutcome.parse('just some notes');
      expect(o.enhancedNotes, 'just some notes');
      expect(o.isStructured, isFalse);
    });

    test('a blank string yields null enhancedNotes', () {
      final o = MeetingOutcome.parse('   ');
      expect(o.enhancedNotes, isNull);
    });

    test('a structured map reads camelCase keys', () {
      final o = MeetingOutcome.parse({
        'title': 'Standup',
        'summary': 'Quick sync',
        'enhancedNotes': 'Notes here',
        'actionItems': [
          {'text': 'Ship it', 'owner': 'Sam'},
        ],
        'decisions': ['Go with option A'],
        'speakerNames': {'s1': 'Sam'},
      });
      expect(o.isStructured, isTrue);
      expect(o.title, 'Standup');
      expect(o.summary, 'Quick sync');
      expect(o.enhancedNotes, 'Notes here');
      expect(o.actionItems.length, 1);
      expect(o.actionItems.first.text, 'Ship it');
      expect(o.actionItems.first.owner, 'Sam');
      expect(o.decisions, ['Go with option A']);
      expect(o.speakerNames['s1'], 'Sam');
    });

    test('reads snake_case and Title aliases', () {
      final o = MeetingOutcome.parse({
        'Title': 'T',
        'Summary': 'S',
        'enhanced_notes': 'N',
        'action_items': ['do thing'],
        'Decisions': ['decided'],
      });
      expect(o.title, 'T');
      expect(o.summary, 'S');
      expect(o.enhancedNotes, 'N');
      expect(o.actionItems.first.text, 'do thing');
      expect(o.decisions, ['decided']);
    });

    test('unwraps a {result: <inner>} wrapper', () {
      final o = MeetingOutcome.parse({
        'result': {'title': 'Inner', 'summary': 'inner summary'},
      });
      expect(o.title, 'Inner');
      expect(o.summary, 'inner summary');
    });

    test('parses a JSON string', () {
      final o = MeetingOutcome.parse('{"title":"From JSON","summary":"s"}');
      expect(o.title, 'From JSON');
      expect(o.summary, 's');
      expect(o.isStructured, isTrue);
    });

    test('parses fenced markdown JSON', () {
      final o = MeetingOutcome.parse('''
```json
{"title":"Fenced","summary":"f"}
```
''');
      expect(o.title, 'Fenced');
      expect(o.summary, 'f');
    });

    test('parses JSON embedded in prose (extracts the {...} substring)', () {
      final o = MeetingOutcome.parse(
        'Here is the summary: {"title":"Extracted"}',
      );
      expect(o.title, 'Extracted');
    });

    test('action items accept string or map elements with alias keys', () {
      final o = MeetingOutcome.parse({
        'actionItems': [
          'string action',
          {'action': 'map action', 'assignee': 'Alice'},
          {'task': 'task action', 'who': 'Bob'},
        ],
      });
      expect(o.actionItems.length, 3);
      expect(o.actionItems[0].text, 'string action');
      expect(o.actionItems[1].text, 'map action');
      expect(o.actionItems[1].owner, 'Alice');
      expect(o.actionItems[2].text, 'task action');
      expect(o.actionItems[2].owner, 'Bob');
    });

    test('blank action-item text is dropped', () {
      final o = MeetingOutcome.parse({
        'actionItems': [
          '   ',
          {'text': '   '},
        ],
      });
      expect(o.actionItems, isEmpty);
    });

    test('non-list actionItems/decisions yield empty lists', () {
      final o = MeetingOutcome.parse({'actionItems': 'not a list'});
      expect(o.actionItems, isEmpty);
    });
  });

  group('MeetingOutcome.fromValidatedJson', () {
    test('reads the canonical schema keys', () {
      final o = MeetingOutcome.fromValidatedJson({
        'title': 'Validated',
        'summary': 's',
        'enhancedNotes': 'n',
        'actionItems': [
          {'text': 'a', 'owner': 'o'},
        ],
      });
      expect(o.isStructured, isTrue);
      expect(o.title, 'Validated');
      expect(o.actionItems.first.text, 'a');
      expect(o.actionItems.first.owner, 'o');
    });
  });

  group('ParsedActionItem equality', () {
    test('equal when text and owner match', () {
      expect(
        const ParsedActionItem('x', owner: 'o'),
        const ParsedActionItem('x', owner: 'o'),
      );
    });

    test('unequal when owner differs', () {
      expect(
        const ParsedActionItem('x', owner: 'a'),
        isNot(const ParsedActionItem('x', owner: 'b')),
      );
    });
  });
}
