import 'package:control_center/shared/syntax/shiki_tokenizers.dart';
import 'package:control_center/shared/syntax/syntax_languages.dart';
import 'package:control_center/shared/widgets/markdown/code_highlighter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

String _textOf(List<InlineSpan> spans) =>
    spans.map((s) => s is TextSpan ? (s.text ?? '') : '').join();

void main() {
  setUp(clearHighlightCache);

  group('highlightCodeSpans', () {
    test('returns a single plain span when languageId is null', () {
      final spans = highlightCodeSpans(
        code: 'final x = 1;',
        languageId: null,
        dark: false,
      );
      expect(spans, hasLength(1));
      expect((spans.single as TextSpan).style, isNull);
    });

    test('returns a single plain span for empty code', () {
      final spans = highlightCodeSpans(
        code: '',
        languageId: 'dart',
        dark: false,
      );
      expect(spans, hasLength(1));
    });

    test('produces multiple spans with color for real Dart code', () {
      final spans = highlightCodeSpans(
        code: 'final greeting = "hello"; // comment',
        languageId: 'dart',
        dark: false,
      );
      expect(spans.length, greaterThan(1));
      expect(
        spans.whereType<TextSpan>().any((s) => s.style?.color != null),
        isTrue,
      );
    });

    test('round-trip: concatenated span text equals the original code', () {
      const code = '''
class TokenBudget<T> {
  final int limit; // trailing
  /* block
     comment */
  String label = 'x';

}''';
      final spans = highlightCodeSpans(
        code: code,
        languageId: 'dart',
        dark: true,
      );
      expect(_textOf(spans), code);
    });

    test('unknown language id degrades to one plain span', () {
      final spans = highlightCodeSpans(
        code: 'whatever',
        languageId: 'not-a-language',
        dark: false,
      );
      expect(spans, hasLength(1));
    });

    test('REGRESSION: real tsx grammar highlights JSX '
        '(highlight 0.7.0 threw and dropped the block to plain)', () {
      const tsx = '''
const Panel = ({ title }: Props) => (
  <section className="panel">
    <Foo.Bar value={42} />
    <h2>{title}</h2>
  </section>
);''';
      expect(shikiLangForFence('tsx'), 'tsx');
      final spans = highlightCodeSpans(
        code: tsx,
        languageId: shikiLangForFence('tsx'),
        dark: true,
      );
      expect(spans.length, greaterThan(5));
      expect(
        spans.whereType<TextSpan>().where((s) => s.style?.color != null),
        isNotEmpty,
      );
      expect(_textOf(spans), tsx, reason: 'round-trip must hold for tsx too');
    });

    test('light and dark themes produce different colors', () {
      const code = 'final x = 1;';
      Color? firstColor(bool dark) =>
          highlightCodeSpans(code: code, languageId: 'dart', dark: dark)
              .whereType<TextSpan>()
              .map((s) => s.style?.color)
              .whereType<Color>()
              .first;
      expect(firstColor(false), isNot(firstColor(true)));
    });

    test('spans are flat and leaf-only with non-null text '
        '(the applyIntralineBackground contract)', () {
      final spans = highlightCodeSpans(
        code: 'void main() { print("x"); } // c',
        languageId: 'dart',
        dark: false,
      );
      for (final span in spans) {
        expect(span, isA<TextSpan>());
        final t = span as TextSpan;
        expect(t.text, isNotNull);
        expect(
          t.children,
          isNull,
          reason: 'no nested spans — offset math walks leaf text only',
        );
      }
    });
  });

  group('highlightCodeLines', () {
    test('splits per source line; blank lines are empty lists', () {
      const code = 'final a = 1;\n\nfinal b = 2;';
      final lines = highlightCodeLines(
        code: code,
        languageId: 'dart',
        dark: false,
      );
      expect(lines, hasLength(3));
      expect(lines[1], isEmpty);
      expect(_textOf(lines[0]), 'final a = 1;');
      expect(_textOf(lines[2]), 'final b = 2;');
    });

    test('multi-line constructs keep their style across lines '
        '(whole-block tokenize, not per-line)', () {
      const code = '/* one\ntwo */\nfinal x = 1;';
      final lines = highlightCodeLines(
        code: code,
        languageId: 'dart',
        dark: true,
      );
      expect(lines, hasLength(3));
      final line2Color = (lines[1].first as TextSpan).style?.color;
      expect(
        line2Color,
        isNotNull,
        reason: 'the second line of a block comment stays comment-colored',
      );
      expect(
        line2Color,
        (lines[0].first as TextSpan).style?.color,
        reason: 'both comment lines share one color',
      );
    });

    test('plain fallback splits per line too', () {
      final lines = highlightCodeLines(
        code: 'a\n\nb',
        languageId: null,
        dark: false,
      );
      expect(lines, hasLength(3));
      expect(lines[1], isEmpty);
    });
  });

  group('caching', () {
    test('repeat calls do not re-tokenize (span cache)', () {
      const code = 'final cached = true;';
      highlightCodeSpans(code: code, languageId: 'dart', dark: false);
      final after = debugHighlightParseCount;
      highlightCodeSpans(code: code, languageId: 'dart', dark: false);
      expect(
        debugHighlightParseCount,
        after,
        reason: 'second identical call must be an LRU hit',
      );
    });

    test('cache: false always re-tokenizes (streaming path)', () {
      const code = 'final streamed = true;';
      highlightCodeSpans(
        code: code,
        languageId: 'dart',
        dark: false,
        cache: false,
      );
      final after = debugHighlightParseCount;
      highlightCodeSpans(
        code: code,
        languageId: 'dart',
        dark: false,
        cache: false,
      );
      expect(debugHighlightParseCount, after + 1);
    });

    test('light and dark are distinct cache entries', () {
      const code = 'final themed = true;';
      highlightCodeSpans(code: code, languageId: 'dart', dark: false);
      final after = debugHighlightParseCount;
      highlightCodeSpans(code: code, languageId: 'dart', dark: true);
      expect(debugHighlightParseCount, after + 1);
    });

    test('clearHighlightCache forces a re-tokenize', () {
      const code = 'final cleared = true;';
      highlightCodeSpans(code: code, languageId: 'dart', dark: false);
      clearHighlightCache();
      final after = debugHighlightParseCount;
      highlightCodeSpans(code: code, languageId: 'dart', dark: false);
      expect(debugHighlightParseCount, after + 1);
    });
  });

  group('peek + async', () {
    setUp(() => debugDisableShikiAsync = true);
    tearDown(() => debugDisableShikiAsync = false);

    test('peek misses before tokenize, hits after async completes', () async {
      const code = 'final peeked = true;';
      expect(
        peekHighlightedLines(code: code, languageId: 'dart', dark: false),
        isNull,
      );
      final lines = await highlightCodeLinesAsync(
        code: code,
        languageId: 'dart',
        dark: false,
      );
      expect(_textOf(lines.single), code);
      final peeked = peekHighlightedLines(
        code: code,
        languageId: 'dart',
        dark: false,
      );
      expect(peeked, isNotNull);
      expect(
        identical(peeked, lines),
        isTrue,
        reason: 'the async result lands in the shared LRU',
      );
    });

    test(
      'async falls back to plain per-line spans on unknown language',
      () async {
        final lines = await highlightCodeLinesAsync(
          code: 'a\nb',
          languageId: 'nope',
          dark: false,
        );
        expect(lines, hasLength(2));
        expect((lines[0].single as TextSpan).style, isNull);
      },
    );
  });

  group('shouldHighlightSynchronously', () {
    test('follows the per-weight line budgets', () {
      expect(
        shouldHighlightSynchronously(languageId: 'dart', lineCount: 300),
        isTrue,
      );
      expect(
        shouldHighlightSynchronously(languageId: 'typescript', lineCount: 300),
        isFalse,
      );
      expect(
        shouldHighlightSynchronously(languageId: 'sql', lineCount: 12),
        isFalse,
      );
      expect(
        shouldHighlightSynchronously(languageId: null, lineCount: 100000),
        isTrue,
        reason: 'plain text is free',
      );
    });
  });
}
