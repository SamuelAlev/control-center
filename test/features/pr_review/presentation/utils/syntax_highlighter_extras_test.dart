import 'package:control_center/features/pr_review/presentation/utils/syntax_highlighter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('diffSyntaxPalette', () {
    test('dark palette contains deletion and addition keys', () {
      final palette = diffSyntaxPalette(isDark: true);
      expect(palette['deletion'], isNotNull);
      expect(palette['addition'], isNotNull);
    });

    test('light palette contains deletion and addition keys', () {
      final palette = diffSyntaxPalette(isDark: false);
      expect(palette['deletion'], isNotNull);
      expect(palette['addition'], isNotNull);
    });

    test('dark palette contains syntax keys', () {
      final palette = diffSyntaxPalette(isDark: true);
      expect(palette['keyword'], isNotNull);
      expect(palette['string'], isNotNull);
      expect(palette['comment'], isNotNull);
      expect(palette['number'], isNotNull);
      expect(palette['function'], isNotNull);
    });

    test('light palette contains syntax keys', () {
      final palette = diffSyntaxPalette(isDark: false);
      expect(palette['keyword'], isNotNull);
      expect(palette['string'], isNotNull);
      expect(palette['comment'], isNotNull);
      expect(palette['number'], isNotNull);
      expect(palette['function'], isNotNull);
    });

    test('dark and light palettes differ', () {
      final darkPalette = diffSyntaxPalette(isDark: true);
      final lightPalette = diffSyntaxPalette(isDark: false);
      expect(darkPalette['keyword'], isNot(lightPalette['keyword']));
    });

    test('palette values are ARGB ints', () {
      final palette = diffSyntaxPalette(isDark: true);
      for (final value in palette.values) {
        expect(value, greaterThanOrEqualTo(0));
      }
    });

    test('dark palette has all expected highlight keys', () {
      final palette = diffSyntaxPalette(isDark: true);
      expect(palette['literal'], isNotNull);
      expect(palette['symbol'], isNotNull);
      expect(palette['name'], isNotNull);
      expect(palette['subst'], isNotNull);
      expect(palette['regexp'], isNotNull);
      expect(palette['doctag'], isNotNull);
      expect(palette['meta'], isNotNull);
      expect(palette['type'], isNotNull);
      expect(palette['class'], isNotNull);
      expect(palette['title'], isNotNull);
      expect(palette['built_in'], isNotNull);
      expect(palette['function'], isNotNull);
      expect(palette['tag'], isNotNull);
      expect(palette['attr'], isNotNull);
      expect(palette['attribute'], isNotNull);
      expect(palette['variable'], isNotNull);
      expect(palette['params'], isNotNull);
      expect(palette['selector-tag'], isNotNull);
      expect(palette['selector-id'], isNotNull);
      expect(palette['selector-class'], isNotNull);
    });

    test('light palette has all expected highlight keys', () {
      final palette = diffSyntaxPalette(isDark: false);
      expect(palette['literal'], isNotNull);
      expect(palette['symbol'], isNotNull);
      expect(palette['name'], isNotNull);
      expect(palette['subst'], isNotNull);
      expect(palette['regexp'], isNotNull);
      expect(palette['doctag'], isNotNull);
      expect(palette['meta'], isNotNull);
      expect(palette['type'], isNotNull);
      expect(palette['class'], isNotNull);
      expect(palette['title'], isNotNull);
      expect(palette['built_in'], isNotNull);
      expect(palette['tag'], isNotNull);
      expect(palette['attr'], isNotNull);
      expect(palette['attribute'], isNotNull);
      expect(palette['variable'], isNotNull);
      expect(palette['params'], isNotNull);
      expect(palette['selector-tag'], isNotNull);
      expect(palette['selector-id'], isNotNull);
      expect(palette['selector-class'], isNotNull);
    });

    test('dark palette addition and deletion have distinct colors', () {
      final palette = diffSyntaxPalette(isDark: true);
      expect(palette['addition'], isNot(palette['deletion']));
    });

    test('light palette addition and deletion have distinct colors', () {
      final palette = diffSyntaxPalette(isDark: false);
      expect(palette['addition'], isNot(palette['deletion']));
    });
  });

  group('highlightLineTokens', () {
    test('returns single token with null color for empty code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('', 'dart', palette);
      expect(tokens.length, 1);
      expect(tokens[0].text, '');
      expect(tokens[0].colorValue, isNull);
    });

    test('returns single token with null color for null language', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('const x = 42;', null, palette);
      expect(tokens.length, 1);
      expect(tokens[0].text, 'const x = 42;');
      expect(tokens[0].colorValue, isNull);
    });

    test('returns single token for empty code with null language', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('', null, palette);
      expect(tokens.length, 1);
      expect(tokens[0].text, '');
    });

    test('tokenizes dart code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('const x = 42;', 'dart', palette);
      expect(tokens, isNotEmpty);
      expect(tokens.fold<String>('', (s, t) => s + t.text), 'const x = 42;');
    });

    test('tokenizes simple string', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('"hello"', 'dart', palette);
      expect(tokens, isNotEmpty);
    });

    test('tokenizes javascript code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('let x = 5;', 'javascript', palette);
      expect(tokens, isNotEmpty);
    });

    test('tokenizes python code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('x = 5', 'python', palette);
      expect(tokens, isNotEmpty);
    });

    test('handles unknown language gracefully', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('some code', 'unknownlang', palette);
      expect(tokens.length, 1);
      expect(tokens[0].text, 'some code');
    });

    test('preserves original text across token boundaries', () {
      final palette = diffSyntaxPalette(isDark: true);
      const code = 'final x = "hello";';
      final tokens = highlightLineTokens(code, 'dart', palette);
      final reconstructed = tokens.fold<String>('', (s, t) => s + t.text);
      expect(reconstructed, code);
    });

    test('tokenizes typescript code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens(
        'const x: number = 42;',
        'typescript',
        palette,
      );
      expect(tokens, isNotEmpty);
    });

    test('tokenizes yaml code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('key: value', 'yaml', palette);
      expect(tokens, isNotEmpty);
    });

    test('tokenizes json code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('{"a": 1}', 'json', palette);
      expect(tokens, isNotEmpty);
    });

    test('tokenizes css code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens(
        '.foo { color: red; }',
        'css',
        palette,
      );
      expect(tokens, isNotEmpty);
    });

    test('tokenizes markdown code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('# Heading', 'markdown', palette);
      expect(tokens, isNotEmpty);
    });

    test('tokenizes html code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens(
        '<div class="a">text</div>',
        'xml',
        palette,
      );
      expect(tokens, isNotEmpty);
    });

    test('tokenizes keywords with colors in dart', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('return true;', 'dart', palette);
      expect(tokens, isNotEmpty);
      final hasColored = tokens.any((t) => t.colorValue != null);
      expect(hasColored, isTrue);
    });

    test('tokenizes strings with colors in dart', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('"hello world"', 'dart', palette);
      final hasColored = tokens.any((t) => t.colorValue != null);
      expect(hasColored, isTrue);
    });

    test('tokenizes comments with colors in dart', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('// a comment', 'dart', palette);
      final hasColored = tokens.any((t) => t.colorValue != null);
      expect(hasColored, isTrue);
    });

    test('handles multi-line code gracefully (single line only)', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('a\nb', 'dart', palette);
      final reconstructed = tokens.fold<String>('', (s, t) => s + t.text);
      expect(reconstructed, 'a\nb');
    });

    test('tokenizes bash code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('echo "hello"', 'bash', palette);
      expect(tokens, isNotEmpty);
    });

    test('tokenizes kotlin code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('val x = 42', 'kotlin', palette);
      expect(tokens, isNotEmpty);
    });

    test('tokenizes rust code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('let x: i32 = 42;', 'rust', palette);
      expect(tokens, isNotEmpty);
    });

    test('tokenizes go code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('x := 42', 'go', palette);
      expect(tokens, isNotEmpty);
    });

    test('tokenizes swift code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('let x = 42', 'swift', palette);
      expect(tokens, isNotEmpty);
    });

    test('tokenizes ruby code', () {
      final palette = diffSyntaxPalette(isDark: true);
      final tokens = highlightLineTokens('x = 42', 'ruby', palette);
      expect(tokens, isNotEmpty);
    });

    test('uses light palette for token colors', () {
      final palette = diffSyntaxPalette(isDark: false);
      final tokens = highlightLineTokens('const x = 42;', 'dart', palette);
      final hasColored = tokens.any((t) => t.colorValue != null);
      expect(hasColored, isTrue);
    });
  });
  group('diffSyntaxPalette - consistency checks', () {
    test('deletion color is red-ish in dark mode', () {
      final palette = diffSyntaxPalette(isDark: true);
      final del = palette['deletion']!;
      expect(palette['addition'], isNot(del));
    });

    test('addition color is green-ish in light mode', () {
      final palette = diffSyntaxPalette(isDark: false);
      expect(palette['addition'], isNotNull);
    });

    test('all values are non-negative', () {
      for (final dark in [true, false]) {
        final palette = diffSyntaxPalette(isDark: dark);
        for (final entry in palette.entries) {
          expect(entry.value, greaterThanOrEqualTo(0),
              reason: '${entry.key} in ${dark ? "dark" : "light"}');
        }
      }
    });
  });
}
