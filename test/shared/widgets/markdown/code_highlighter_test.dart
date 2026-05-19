import 'package:control_center/shared/utils/syntax_palette.dart';
import 'package:control_center/shared/widgets/markdown/code_highlighter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveHighlightLanguage', () {
    test('maps canonical language names', () {
      expect(resolveHighlightLanguage('dart'), 'dart');
      expect(resolveHighlightLanguage('python'), 'python');
      expect(resolveHighlightLanguage('rust'), 'rust');
      expect(resolveHighlightLanguage('bash'), 'bash');
    });

    test('maps common aliases and extensions', () {
      expect(resolveHighlightLanguage('js'), 'javascript');
      expect(resolveHighlightLanguage('py'), 'python');
      expect(resolveHighlightLanguage('rs'), 'rust');
      expect(resolveHighlightLanguage('sh'), 'bash');
      expect(resolveHighlightLanguage('zsh'), 'bash');
      expect(resolveHighlightLanguage('yml'), 'yaml');
      expect(resolveHighlightLanguage('c++'), 'cpp');
      expect(resolveHighlightLanguage('c#'), 'cs');
      expect(resolveHighlightLanguage('html'), 'xml');
    });

    test('routes all TS/JS/JSX/TSX variants to the javascript grammar', () {
      // highlight 0.7.0's `typescript` grammar throws on JSX, so the whole
      // family is routed to the robust `javascript` grammar instead.
      for (final hint in ['ts', 'tsx', 'typescript', 'mts', 'cts', 'jsx']) {
        expect(resolveHighlightLanguage(hint), 'javascript', reason: hint);
      }
    });

    test('is case-insensitive', () {
      expect(resolveHighlightLanguage('Dart'), 'dart');
      expect(resolveHighlightLanguage('TypeScript'), 'javascript');
    });

    test('ignores fence attributes after the language token', () {
      expect(resolveHighlightLanguage('js title="example.js"'), 'javascript');
      expect(resolveHighlightLanguage('dart {1,3}'), 'dart');
    });

    test('returns null for null, empty, or unknown hints', () {
      expect(resolveHighlightLanguage(null), isNull);
      expect(resolveHighlightLanguage(''), isNull);
      expect(resolveHighlightLanguage('   '), isNull);
      expect(resolveHighlightLanguage('not-a-language'), isNull);
      expect(resolveHighlightLanguage('plaintext'), isNull);
    });
  });

  group('highlightCodeSpans', () {
    final palette = syntaxPaletteFor(Brightness.light);

    test('returns a single plain span when language is null', () {
      final spans = highlightCodeSpans(
        code: 'final x = 1;',
        languageId: null,
        palette: palette,
      );
      expect(spans, hasLength(1));
      expect((spans.single as TextSpan).text, 'final x = 1;');
      expect((spans.single as TextSpan).style, isNull);
    });

    test('returns a single plain span for empty code', () {
      final spans = highlightCodeSpans(
        code: '',
        languageId: 'dart',
        palette: palette,
      );
      expect(spans, hasLength(1));
      expect((spans.single as TextSpan).text, '');
    });

    test('produces multiple coloured spans for real code', () {
      final spans = highlightCodeSpans(
        code: 'final greeting = "hello";',
        languageId: 'dart',
        palette: palette,
      );
      // Tokenized into more than one span...
      expect(spans.length, greaterThan(1));
      // ...and at least one span carries a syntax colour.
      final coloured = spans
          .whereType<TextSpan>()
          .where((s) => s.style?.color != null)
          .toList();
      expect(coloured, isNotEmpty);
    });

    test('concatenated span text reproduces the original code', () {
      const code = 'void main() {\n  print("hi");\n}';
      final spans = highlightCodeSpans(
        code: code,
        languageId: 'dart',
        palette: palette,
      );
      final rebuilt = spans
          .whereType<TextSpan>()
          .map((s) => s.text ?? '')
          .join();
      expect(rebuilt, code);
    });

    test('falls back to plain text for an unregistered language', () {
      final spans = highlightCodeSpans(
        code: 'some text',
        languageId: 'definitely-not-a-real-language',
        palette: palette,
      );
      expect(spans, hasLength(1));
      expect((spans.single as TextSpan).text, 'some text');
    });

    test('highlights a TSX snippet containing JSX (regression)', () {
      // Regression: `typescript` throws on JSX, dropping the whole block to
      // plain text. `tsx` must resolve to a grammar that highlights JSX.
      const tsx = '''
import { type ReactElement } from 'react';
import { Dropdown, Button } from '@frontify/fondue/components';

export const BrandActionsMenu = (): ReactElement => {
    return (
        <Dropdown.Root>
            <Dropdown.Trigger>
                <Button aria-label="menu" />
            </Dropdown.Trigger>
        </Dropdown.Root>
    );
};''';
      final spans = highlightCodeSpans(
        code: tsx,
        languageId: resolveHighlightLanguage('tsx'),
        palette: palette,
      );
      // Must be richly tokenized, not the single plain-text fallback span.
      expect(spans.length, greaterThan(5));
      final coloured = spans
          .whereType<TextSpan>()
          .where((s) => s.style?.color != null);
      expect(coloured, isNotEmpty);
    });

    test('keyword colour differs between light and dark palettes', () {
      const code = 'class A {}';
      final light = highlightCodeSpans(
        code: code,
        languageId: 'dart',
        palette: syntaxPaletteFor(Brightness.light),
      );
      final dark = highlightCodeSpans(
        code: code,
        languageId: 'dart',
        palette: syntaxPaletteFor(Brightness.dark),
      );
      Color? firstColour(List<InlineSpan> spans) => spans
          .whereType<TextSpan>()
          .map((s) => s.style?.color)
          .firstWhere((c) => c != null, orElse: () => null);
      expect(firstColour(light), isNotNull);
      expect(firstColour(dark), isNotNull);
      expect(firstColour(light), isNot(firstColour(dark)));
    });
  });
}
