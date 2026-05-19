import 'package:cc_domain/core/domain/services/agent_mention_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentMentionParser', () {
    const parser = AgentMentionParser();

    group('parseMentions', () {
      test('extracts @names', () {
        expect(parser.parseMentions('hello @alice world'), ['alice']);
      });

      test('returns lowercase', () {
        expect(parser.parseMentions('hello @Alice'), ['alice']);
      });

      test('handles multiple mentions', () {
        expect(parser.parseMentions('@alice hey @bob and @charlie'), [
          'alice',
          'bob',
          'charlie',
        ]);
      });

      test('handles no mentions', () {
        expect(parser.parseMentions('hello world'), isEmpty);
      });

      test('handles adjacent mentions', () {
        expect(parser.parseMentions('@alice@bob'), ['alice', 'bob']);
      });
    });

    group('parseProseMentions', () {
      test('extracts mentions from prose', () {
        expect(
          parser.parseProseMentions('Open question for @architect — thoughts?'),
          ['architect'],
        );
      });

      test('lowercases and deduplicates, keeping first-seen order', () {
        expect(
          parser.parseProseMentions('@Bob and @alice, then @BOB again'),
          ['bob', 'alice'],
        );
      });

      test('keeps inner hyphens instead of truncating the token', () {
        // parseMentions reads this as "code" and prefix-matches; the prose
        // parser resolves it as itself.
        expect(parser.parseMentions('@code-reviewer'), ['code']);
        expect(parser.parseProseMentions('@code-reviewer'), ['code-reviewer']);
      });

      test('ignores an @ glued to the preceding token', () {
        expect(
          parser.parseProseMentions('mail sam@architect.com about node@20'),
          isEmpty,
        );
        expect(parser.parseProseMentions('see pkg/@scope/thing'), isEmpty);
        expect(parser.parseProseMentions('@@architect'), isEmpty);
      });

      test('ignores mentions inside a fenced code block', () {
        const text = '''
Here is the annotation:

```dart
@override
void build() {}
```

Back to prose, @architect.
''';
        expect(parser.parseProseMentions(text), ['architect']);
      });

      test('ignores mentions inside a tilde fence', () {
        const text = '~~~\n@architect\n~~~\nplain @builder\n';
        expect(parser.parseProseMentions(text), ['builder']);
      });

      test('ignores mentions inside inline code spans', () {
        expect(
          parser.parseProseMentions('use `@override` here, ask @architect'),
          ['architect'],
        );
      });

      test('blanks everything after an unterminated fence', () {
        const text = 'ask @architect\n```\n@builder\nstill open';
        expect(parser.parseProseMentions(text), ['architect']);
      });

      test('handles text with no mentions', () {
        expect(parser.parseProseMentions('nothing to see here'), isEmpty);
      });

      test('accepts a mention at the very start of the text', () {
        expect(parser.parseProseMentions('@architect look'), ['architect']);
      });

      test('accepts mentions after punctuation and newlines', () {
        expect(parser.parseProseMentions('(@architect)\n@builder!'), [
          'architect',
          'builder',
        ]);
      });
    });

    group('stripCodeRegions', () {
      test('preserves line count so prose stays aligned', () {
        const text = 'a\n```\nb\n```\nc';
        expect(parser.stripCodeRegions(text).split('\n').length, 6);
      });
    });

    group('stripMentions', () {
      test('removes @names and trailing whitespace', () {
        expect(parser.stripMentions('hello @alice world'), 'hello world');
      });

      test('handles no mentions', () {
        expect(parser.stripMentions('hello world'), 'hello world');
      });

      test('trims result', () {
        expect(parser.stripMentions('@alice hello @bob '), 'hello');
      });
    });
  });
}
