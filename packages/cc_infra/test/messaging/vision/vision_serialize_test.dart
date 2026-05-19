import 'package:cc_infra/src/messaging/vision/vision_normalize.dart';
import 'package:cc_infra/src/messaging/vision/vision_serialize.dart';
import 'package:test/test.dart';

void main() {
  group('serializeEntries', () {
    test('serializes a user entry with a heading', () {
      final out = serializeEntries(<VisionEntry>[
        const VisionEntry(role: 'user', text: 'hello there'),
      ]);
      expect(out, contains('# User'));
      expect(out, contains('hello there'));
    });

    test('serializes assistant prose and reasoning', () {
      final out = serializeEntries(<VisionEntry>[
        const VisionEntry(role: 'assistant', text: 'an answer'),
        const VisionEntry(role: 'reasoning', text: 'let me think'),
      ]);
      expect(out, contains('# Assistant'));
      expect(out, contains('an answer'));
      expect(out, contains('# Assistant (thinking)'));
      // Reasoning is wrapped in underscores (italic-ish prose).
      expect(out, contains('_let me think_'));
    });

    test('merges a tool call and its result into one block, dimming output',
        () {
      final out = serializeEntries(<VisionEntry>[
        const VisionEntry(
          role: 'tool',
          toolName: 'Read',
          toolArgs: <String, dynamic>{'path': 'a.dart'},
          text: 'file contents here',
        ),
      ]);
      expect(out, contains('# Tool call'));
      expect(out, contains('Read('));
      expect(out, contains('path='));
      expect(out, contains('file contents here'));
      // Result body is wrapped in dim ink toggles.
      expect(out.contains(dimOn), isTrue);
      expect(out.contains(dimOff), isTrue);
    });

    test('renders an intent comment above the call', () {
      final out = serializeEntries(<VisionEntry>[
        const VisionEntry(
          role: 'tool',
          toolName: 'Bash',
          intent: 'list files',
          toolArgs: <String, dynamic>{'cmd': 'ls'},
          text: 'a.dart',
        ),
      ]);
      expect(out, contains('//list files'));
    });

    test('drops useless tool pairs entirely', () {
      final out = serializeEntries(<VisionEntry>[
        const VisionEntry(role: 'user', text: 'keep me'),
        const VisionEntry(
          role: 'tool',
          toolName: 'Noise',
          toolArgs: <String, dynamic>{'x': 1},
          text: 'irrelevant noise output',
          useless: true,
        ),
      ]);
      expect(out, contains('keep me'));
      expect(out, isNot(contains('Noise')));
      expect(out, isNot(contains('irrelevant noise output')));
    });

    test('truncates long tool results keeping head and tail', () {
      final long = 'H' * 3000 + 'T' * 3000;
      final out = serializeEntries(<VisionEntry>[
        VisionEntry(
          role: 'tool',
          toolName: 'Cat',
          toolArgs: const <String, dynamic>{},
          text: long,
        ),
      ]);
      expect(out, contains('elided'));
      // The merged block must be far shorter than the raw 6000-char result.
      expect(out.length, lessThan(3000));
      // Head and tail markers survive.
      expect(out, contains('HHH'));
      expect(out, contains('TTT'));
    });

    test('result is normalized for the bitmap font', () {
      final out = serializeEntries(<VisionEntry>[
        const VisionEntry(role: 'user', text: 'smart “quotes” and — dash'),
      ]);
      expect(out, contains('"quotes"'));
      expect(out, contains('- dash'));
    });

    test('empty entry list yields empty string', () {
      expect(serializeEntries(const <VisionEntry>[]), isEmpty);
    });
  });

  group('truncateForSummary', () {
    test('returns text unchanged when within budget', () {
      expect(truncateForSummary('short', 100, 0.6), 'short');
    });

    test('keeps a 60/40 head/tail split by default ratio', () {
      final text = '${'a' * 100}${'b' * 100}';
      final result = truncateForSummary(text, 50, 0.6);
      expect(result, startsWith('a' * 30));
      expect(result, endsWith('b' * 20));
      expect(result, contains('elided'));
    });
  });
}
