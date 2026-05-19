import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('preprocessVideoEmbeds', () {
    const embedAbc = 'https://www.loom.com/embed/abc123';

    test('embeds a bare loom URL on its own line', () {
      expect(
        preprocessVideoEmbeds('https://www.loom.com/share/abc123'),
        '![Loom video]($embedAbc "https://www.loom.com/share/abc123")',
      );
    });

    test('embeds a scheme-less loom URL', () {
      expect(
        preprocessVideoEmbeds('loom.com/share/abc123'),
        '![Loom video]($embedAbc "https://loom.com/share/abc123")',
      );
    });

    test('embeds a markdown link wrapping a loom URL', () {
      const input =
          '[https://www.loom.com/share/abc123](https://www.loom.com/share/abc123)';
      expect(
        preprocessVideoEmbeds(input),
        '![Loom video]($embedAbc "https://www.loom.com/share/abc123")',
      );
    });

    test('embeds a labelled markdown link to loom', () {
      expect(
        preprocessVideoEmbeds('[Watch the demo](https://www.loom.com/share/abc123)'),
        '![Loom video]($embedAbc "https://www.loom.com/share/abc123")',
      );
    });

    test('embeds an autolink to loom', () {
      expect(
        preprocessVideoEmbeds('<https://www.loom.com/share/abc123>'),
        '![Loom video]($embedAbc "https://www.loom.com/share/abc123")',
      );
    });

    test('keeps an already-embed loom URL as embed', () {
      expect(
        preprocessVideoEmbeds('https://www.loom.com/embed/abc123'),
        '![Loom video]($embedAbc "https://www.loom.com/embed/abc123")',
      );
    });

    test('preserves surrounding lines and indentation', () {
      const input =
          'Here is the demo:\n\nhttps://www.loom.com/share/abc123\n\nThanks!';
      const expected =
          'Here is the demo:\n\n![Loom video]($embedAbc "https://www.loom.com/share/abc123")\n\nThanks!';
      expect(preprocessVideoEmbeds(input), expected);
    });

    test('appends a player below a captioned markdown link (keeps the line)', () {
      const input =
          '🎥 Loom walkthrough: [https://www.loom.com/share/abc123](https://www.loom.com/share/abc123)';
      const expected =
          '🎥 Loom walkthrough: [https://www.loom.com/share/abc123](https://www.loom.com/share/abc123)\n\n'
          '![Loom video]($embedAbc "https://www.loom.com/share/abc123")\n';
      expect(preprocessVideoEmbeds(input), expected);
    });

    test('appends a player below an inline bare loom link', () {
      const input = 'See https://www.loom.com/share/abc123 for the walkthrough.';
      const expected =
          'See https://www.loom.com/share/abc123 for the walkthrough.\n\n'
          '![Loom video]($embedAbc "https://www.loom.com/share/abc123")\n';
      expect(preprocessVideoEmbeds(input), expected);
    });

    test('collapses a [url](url) link to a single player', () {
      const input =
          'Demo: [https://www.loom.com/share/abc123](https://www.loom.com/share/abc123) 👀';
      // Exactly one marker — the label URL and target URL dedupe.
      expect(
        '\n'.allMatches(preprocessVideoEmbeds(input)).length,
        // original line + blank + marker + trailing newline = 3 newlines
        3,
      );
      expect(
        preprocessVideoEmbeds(input),
        contains('![Loom video]($embedAbc "https://www.loom.com/share/abc123")'),
      );
    });

    test('leaves loom links inside fenced code blocks untouched', () {
      const input = '```\nhttps://www.loom.com/share/abc123\n```';
      expect(preprocessVideoEmbeds(input), input);
    });

    test('leaves non-loom URLs untouched', () {
      const input = 'https://example.com/share/abc123';
      expect(preprocessVideoEmbeds(input), input);
      const yt = 'https://www.youtube.com/watch?v=abc123';
      expect(preprocessVideoEmbeds(yt), yt);
    });

    test('is a no-op on empty input', () {
      expect(preprocessVideoEmbeds(''), '');
    });
  });
}
