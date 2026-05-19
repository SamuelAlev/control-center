import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

/// `:shortcode:` emoji coverage. The substitution has to be invisible to
/// everything a colon already means in prose (`Note:`, `12:30`, `http://`,
/// `a:b`) while still resolving the ~1900 names GitHub renders, so most of
/// these tests are about what must NOT change.
void main() {
  const parser = CcParser();
  const noEmoji = CcParser(options: CcParseOptions(emoji: false));

  /// The concatenated literal text of [source]'s single paragraph.
  String text(String source, {CcParser with_ = parser}) {
    final children = (with_.parse(source).single as CcParagraph).children;
    return children.whereType<CcText>().map((t) => t.text).join();
  }

  group('substitution', () {
    test('a known shortcode becomes its emoji', () {
      expect(text(':tada:'), '🎉');
      expect(text(':page_facing_up:'), '📄');
    });

    test('substitutes inside a sentence, keeping the surrounding text', () {
      expect(text('ship it :rocket: now'), 'ship it 🚀 now');
    });

    test('names with digits, + and - resolve', () {
      expect(text(':+1: :-1: :100: :8ball:'), '👍 👎 💯 🎱');
    });

    test('adjacent shortcodes both resolve', () {
      expect(text(':smile::smile:'), '😄😄');
    });

    test('an underscore inside a name is not an emphasis delimiter', () {
      final nodes = (parser.parse(':white_check_mark:').single as CcParagraph)
          .children;
      expect(nodes.whereType<CcEmphasis>(), isEmpty);
      expect(nodes.single, isA<CcText>());
      expect((nodes.single as CcText).text, '✅');
    });

    test('the keycap sequences keep their variation selector', () {
      // `:one:` served from GitHub's emoji IMAGE url is `0031-20e3` — without
      // U+FE0F it renders as a bare "1" on a font that needs the selector.
      expect(text(':one:'), '1️⃣');
    });

    test('resolves in headings and table cells too', () {
      final heading = parser.parse('# :tada: done').single as CcHeading;
      expect(
        heading.children.whereType<CcText>().map((t) => t.text).join(),
        '🎉 done',
      );
      final table =
          parser.parse('| a |\n| - |\n| :tada: |\n').single as CcTable;
      final cell = table.rows.single.single.children;
      expect(cell.whereType<CcText>().map((t) => t.text).join(), '🎉');
    });
  });

  group('what stays literal', () {
    test('an unknown name is left alone', () {
      expect(text(':not_an_emoji_name:'), ':not_an_emoji_name:');
    });

    test("GitHub's custom image shortcodes stay literal", () {
      // `:octocat:` and friends are images on GitHub, not characters — there
      // is nothing to substitute.
      expect(text(':octocat: :shipit:'), ':octocat: :shipit:');
    });

    test('prose colons are untouched', () {
      expect(text('Note: see below'), 'Note: see below');
      expect(text('at 12:30:45 today'), 'at 12:30:45 today');
      expect(text('key:value:pair'), 'key:value:pair');
    });

    test('empty and unclosed runs are untouched', () {
      expect(text('a :: b'), 'a :: b');
      expect(text(':tada'), ':tada');
      expect(text('tada:'), 'tada:');
    });

    test('shortcodes are case-sensitive, as on GitHub', () {
      expect(text(':TADA:'), ':TADA:');
    });

    test('a name longer than the table is not scanned past', () {
      final long = 'a' * (kCcMaxEmojiShortcodeLength + 1);
      expect(text(':$long:'), ':$long:');
    });

    test('a code span keeps the shortcode verbatim', () {
      final nodes = (parser.parse('`:tada:`').single as CcParagraph).children;
      expect(nodes.whereType<CcInlineCode>().single.code, ':tada:');
    });

    test('a fenced code block keeps the shortcode verbatim', () {
      final code = parser.parse('```\n:tada:\n```').single as CcCodeBlock;
      expect(code.code, ':tada:');
    });

    test('a backslash escape suppresses the substitution', () {
      expect(text(r'\:tada:'), ':tada:');
    });

    test('a link destination is not scanned for shortcodes', () {
      final link = (parser.parse('[x](https://e.com/:tada:)').single
              as CcParagraph)
          .children
          .whereType<CcLink>()
          .single;
      expect(link.url, 'https://e.com/:tada:');
    });

    test('a bare autolink keeps its colons', () {
      final link =
          (parser.parse('https://e.com/a:tada:b').single as CcParagraph)
              .children
              .whereType<CcLink>()
              .single;
      expect(link.url, 'https://e.com/a:tada:b');
    });

    test('the option turns the whole feature off', () {
      expect(text(':tada:', with_: noEmoji), ':tada:');
    });
  });

  group('table', () {
    test('the generated table is complete', () {
      expect(ccEmojiShortcodeNames.length, kCcEmojiShortcodeCount);
      // A truncated regeneration is the failure mode worth pinning; the
      // GitHub set has been ~1900 for years.
      expect(kCcEmojiShortcodeCount, greaterThan(1800));
    });

    test('every name fits the scanner look-ahead bound', () {
      for (final name in ccEmojiShortcodeNames) {
        expect(name.length, lessThanOrEqualTo(kCcMaxEmojiShortcodeLength));
      }
    });

    test('every name is within gemoji\'s alias grammar', () {
      final grammar = RegExp(r'^[a-z0-9_+-]+$');
      for (final name in ccEmojiShortcodeNames) {
        expect(grammar.hasMatch(name), isTrue, reason: name);
      }
    });

    test('no packed value contains a separator', () {
      for (final name in ccEmojiShortcodeNames) {
        final emoji = ccEmojiForShortcode(name)!;
        expect(emoji, isNotEmpty);
        expect(emoji.contains(' '), isFalse, reason: name);
        expect(emoji.contains('\n'), isFalse, reason: name);
      }
    });

    test('an unknown name resolves to null', () {
      expect(ccEmojiForShortcode('octocat'), isNull);
      expect(ccEmojiForShortcode(''), isNull);
    });
  });
}
