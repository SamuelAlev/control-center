import 'package:cc_domain/features/meetings/domain/services/meeting_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeetingOutcome.parse', () {
    test('reads a structured map with all four keys', () {
      final outcome = MeetingOutcome.parse({
        'summary': 'We shipped it.',
        'enhancedNotes': '# Notes\nLong narrative.',
        'actionItems': [
          {'text': 'Email the client', 'owner': 'Sam'},
          'Update the docs',
        ],
        'decisions': ['Ship Friday', 'Drop the legacy flow'],
      });

      expect(outcome.summary, 'We shipped it.');
      expect(outcome.enhancedNotes, '# Notes\nLong narrative.');
      expect(outcome.actionItems.length, 2);
      expect(outcome.actionItems[0].text, 'Email the client');
      expect(outcome.actionItems[0].owner, 'Sam');
      expect(outcome.actionItems[1].text, 'Update the docs');
      expect(outcome.actionItems[1].owner, isNull);
      expect(outcome.decisions, ['Ship Friday', 'Drop the legacy flow']);
    });

    test('reads an optional content-derived title', () {
      final outcome = MeetingOutcome.parse({
        'title': 'Q3 roadmap planning',
        'enhancedNotes': 'notes',
      });
      expect(outcome.title, 'Q3 roadmap planning');
      // A blank/absent title parses to null (so it never clobbers a real name).
      expect(MeetingOutcome.parse({'enhancedNotes': 'n'}).title, isNull);
    });

    test('unwraps a {result: <structured>} envelope', () {
      final outcome = MeetingOutcome.parse({
        'result': {
          'summary': 'S',
          'decisions': ['D'],
        },
      });
      expect(outcome.summary, 'S');
      expect(outcome.decisions, ['D']);
    });

    test('accepts snake_case keys', () {
      final outcome = MeetingOutcome.parse({
        'enhanced_notes': 'notes',
        'action_items': ['a'],
      });
      expect(outcome.enhancedNotes, 'notes');
      expect(outcome.actionItems.single.text, 'a');
    });

    test('parses a JSON string', () {
      final outcome = MeetingOutcome.parse(
        '{"summary":"S","decisions":["D1","D2"]}',
      );
      expect(outcome.summary, 'S');
      expect(outcome.decisions, ['D1', 'D2']);
    });

    test('parses a fenced ```json block with leading prose', () {
      const raw = 'Here you go:\n'
          '```json\n'
          '{"summary":"S","actionItems":[{"text":"do it"}]}\n'
          '```';
      final outcome = MeetingOutcome.parse(raw);
      expect(outcome.summary, 'S');
      expect(outcome.actionItems.single.text, 'do it');
    });

    test('falls back to markdown as enhancedNotes for a plain string', () {
      final outcome = MeetingOutcome.parse('# Just notes\n- a bullet');
      expect(outcome.enhancedNotes, '# Just notes\n- a bullet');
      expect(outcome.summary, isNull);
      expect(outcome.actionItems, isEmpty);
      expect(outcome.decisions, isEmpty);
      // Markdown fallback is NOT structured → persist steps will skip.
      expect(outcome.isStructured, isFalse);
    });

    test('isStructured is true for maps/JSON, false for markdown/empty', () {
      expect(MeetingOutcome.parse({'summary': 'S'}).isStructured, isTrue);
      expect(MeetingOutcome.parse('{"summary":"S"}').isStructured, isTrue);
      expect(MeetingOutcome.parse('plain prose').isStructured, isFalse);
      expect(MeetingOutcome.parse(null).isStructured, isFalse);
      // A structured map with empty lists is still structured (legit clear).
      expect(
        MeetingOutcome.parse(const {'actionItems': <Object>[]}).isStructured,
        isTrue,
      );
    });

    test('a {result: "<markdown>"} envelope becomes enhancedNotes', () {
      // The engine unwraps `result`; a string result is markdown, not data.
      final outcome = MeetingOutcome.parse('# notes only');
      expect(outcome.enhancedNotes, '# notes only');
      expect(outcome.actionItems, isEmpty);
    });

    test('decisions given as objects use their text field', () {
      final outcome = MeetingOutcome.parse({
        'decisions': [
          {'decision': 'Use Drift'},
          {'text': 'Skip Hive'},
        ],
      });
      expect(outcome.decisions, ['Use Drift', 'Skip Hive']);
    });

    test('drops blank / malformed entries', () {
      final outcome = MeetingOutcome.parse({
        'actionItems': ['', '  ', 42, {'owner': 'no text'}, 'real'],
        'decisions': ['', 'keep'],
      });
      expect(outcome.actionItems.map((a) => a.text), ['real']);
      expect(outcome.decisions, ['keep']);
    });

    test('null / empty input yields the empty outcome', () {
      expect(MeetingOutcome.parse(null).enhancedNotes, isNull);
      expect(MeetingOutcome.parse('').enhancedNotes, isNull);
      expect(MeetingOutcome.parse('   ').actionItems, isEmpty);
    });
  });

  group('MeetingOutcome speakerNames', () {
    test('parse reads a label→name map (camelCase and snake_case)', () {
      expect(
        MeetingOutcome.parse({
          'speakerNames': {'Person 1': 'Dana', 'Person 2': 'Jordan'},
        }).speakerNames,
        {'Person 1': 'Dana', 'Person 2': 'Jordan'},
      );
      expect(
        MeetingOutcome.parse({
          'speaker_names': {'Person 1': 'Dana'},
        }).speakerNames,
        {'Person 1': 'Dana'},
      );
    });

    test('parse drops non-string and empty entries, trims values', () {
      final outcome = MeetingOutcome.parse({
        'speakerNames': {
          'Person 1': '  Dana  ',
          'Person 2': '',
          'Person 3': 42,
          '': 'NoLabel',
        },
      });
      expect(outcome.speakerNames, {'Person 1': 'Dana'});
    });

    test('parse defaults to an empty map when the key is missing or not a map',
        () {
      expect(MeetingOutcome.parse({'summary': 'S'}).speakerNames, isEmpty);
      expect(
        MeetingOutcome.parse({'speakerNames': 'nope'}).speakerNames,
        isEmpty,
      );
    });

    test('fromValidatedJson reads speakerNames too', () {
      final outcome = MeetingOutcome.fromValidatedJson({
        'enhancedNotes': 'n',
        'speakerNames': {'Person 1': 'Dana'},
      });
      expect(outcome.speakerNames, {'Person 1': 'Dana'});
      // Absent key → empty map (never null).
      expect(
        MeetingOutcome.fromValidatedJson({'enhancedNotes': 'n'}).speakerNames,
        isEmpty,
      );
    });
  });
}
