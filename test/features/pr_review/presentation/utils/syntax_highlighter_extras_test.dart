import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:control_center/features/pr_review/presentation/utils/syntax_highlighter.dart';
import 'package:control_center/shared/utils/syntax_palette.dart';
import 'package:flutter_test/flutter_test.dart';

String _rejoin(List<List<DiffToken>> lines) =>
    lines.map((l) => l.map((t) => t.text).join()).join('\n');

void main() {
  group('diffSyntaxPalette (word-diff slice)', () {
    test('dark palette contains deletion and addition tints', () {
      final palette = diffSyntaxPalette(isDark: true);
      expect(palette['deletion'], isNotNull);
      expect(palette['addition'], isNotNull);
    });

    test('light palette contains deletion and addition tints', () {
      final palette = diffSyntaxPalette(isDark: false);
      expect(palette['deletion'], isNotNull);
      expect(palette['addition'], isNotNull);
    });

    test('dark and light palettes differ', () {
      expect(
        diffSyntaxPalette(isDark: true)['keyword'],
        isNot(diffSyntaxPalette(isDark: false)['keyword']),
      );
    });

    test('addition and deletion have distinct colors (both themes)', () {
      for (final isDark in [true, false]) {
        final palette = diffSyntaxPalette(isDark: isDark);
        expect(palette['addition'], isNot(palette['deletion']));
      }
    });

    test('all values are non-negative ARGB ints', () {
      for (final dark in [true, false]) {
        final palette = diffSyntaxPalette(isDark: dark);
        for (final entry in palette.entries) {
          expect(
            entry.value,
            greaterThanOrEqualTo(0),
            reason: '${entry.key} in ${dark ? "dark" : "light"}',
          );
        }
      }
    });
  });

  group('highlightDiffLines', () {
    test('empty code yields one plain line', () {
      final lines = highlightDiffLines('', 'dart', dark: true);
      expect(lines, hasLength(1));
      expect(lines.single.single.text, '');
      expect(lines.single.single.colorValue, isNull);
    });

    test('null language yields plain per-line tokens', () {
      final lines = highlightDiffLines('a\nb', null, dark: true);
      expect(lines, hasLength(2));
      expect(lines[0].single.colorValue, isNull);
    });

    test('unknown language degrades to plain, never throws', () {
      final lines = highlightDiffLines('x = 1', 'not-a-lang', dark: true);
      expect(lines.single.single.colorValue, isNull);
    });

    test('round-trip: token text reconstructs the source per line', () {
      const code = 'final x = "hi";\n// comment\nclass A {}';
      final lines = highlightDiffLines(code, 'dart', dark: true);
      expect(lines, hasLength(3));
      expect(_rejoin(lines), code);
    });

    test('dart keywords take the CC theme keyword colour', () {
      final lines = highlightDiffLines('final x = 1;', 'dart', dark: true);
      final colors = lines.single.map((t) => t.colorValue).toList();
      expect(colors, contains(darkSyntaxPalette['keyword']));
    });

    test('comments take the CC theme comment colour (both themes)', () {
      for (final (dark, palette) in [
        (true, darkSyntaxPalette),
        (false, lightSyntaxPalette),
      ]) {
        final lines = highlightDiffLines('// note', 'dart', dark: dark);
        expect(
          lines.single.map((t) => t.colorValue),
          contains(palette['comment']),
        );
      }
    });

    test('multi-line constructs stay coloured across lines '
        '(block tokenize, not per-line)', () {
      const code = '/* one\ntwo */';
      final lines = highlightDiffLines(code, 'dart', dark: true);
      expect(lines, hasLength(2));
      expect(
        lines[1].map((t) => t.colorValue),
        contains(darkSyntaxPalette['comment']),
        reason: 'the continuation line of a block comment keeps its colour',
      );
    });

    test('tokenizes a representative language spread without error', () {
      const samples = <(String, String)>[
        ('dart', 'final x = 1;'),
        ('javascript', 'const f = (a) => a * 2;'),
        ('typescript', 'const x: number = 1;'),
        ('tsx', 'const A = () => <div className="x">hi</div>;'),
        ('python', 'def f(x):\n    return x'),
        ('json', '{"a": [1, 2]}'),
        ('yaml', 'key: value'),
        ('css', '.cls { color: red; }'),
        ('diff', '+added\n-removed'),
        ('html', '<div class="x">t</div>'),
        ('go', 'func main() {}'),
        ('rust', 'fn main() {}'),
        ('shellscript', 'echo "hi"'),
        ('kotlin', 'val x = 42'),
        ('swift', 'let x = 42'),
        ('ruby', 'x = 42'),
        ('sql', 'SELECT 1;'),
        ('toml', 'key = "v"'),
      ];
      for (final (lang, code) in samples) {
        final lines = highlightDiffLines(code, lang, dark: true);
        expect(_rejoin(lines), code, reason: '$lang must round-trip');
        expect(
          lines.expand((l) => l).any((t) => t.colorValue != null),
          isTrue,
          reason: '$lang must colour at least one token',
        );
      }
      // Markdown prose scopes (headings, emphasis) are deliberately unmapped
      // in the CC theme — highlight.js left them base-coloured too — so it
      // only pins the round-trip.
      final md = highlightDiffLines('# Title\n*em*', 'markdown', dark: true);
      expect(_rejoin(md), '# Title\n*em*');
    });

    test('every colour comes from the CC palette (no invented colours)', () {
      const code = 'final s = "x\${y}z"; // c\n@override\nclass A<T> {}';
      final lines = highlightDiffLines(code, 'dart', dark: false);
      final palette = lightSyntaxPalette.values.toSet();
      final used = lines
          .expand((l) => l)
          .map((t) => t.colorValue)
          .whereType<int>()
          .toSet();
      expect(used.difference(palette), isEmpty);
    });

    test('light theme colours tokens with the light palette', () {
      final lines = highlightDiffLines('const x = 42;', 'dart', dark: false);
      expect(lines.expand((l) => l).any((t) => t.colorValue != null), isTrue);
    });
  });
}
