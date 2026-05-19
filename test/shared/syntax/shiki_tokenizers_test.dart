import 'package:control_center/shared/syntax/shiki_tokenizers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiki_flutter/engine.dart';

String _rejoin(List<List<ThemedToken>> lines) =>
    lines.map((l) => l.map((t) => t.content).join()).join('\n');

void main() {
  final tokenizer = CcShikiTokenizer.instance;

  group('round-trip', () {
    test('token concatenation reproduces the source exactly', () {
      for (final code in <String>[
        'final x = 1;',
        'a\n\nb\n',
        'tail\n\n',
        '// only a comment',
        'multi\nline\nno trailing newline',
      ]) {
        final lines = tokenizer.tokenizeSync(code, langId: 'dart', dark: true);
        expect(lines, isNotNull);
        expect(_rejoin(lines!), code);
      }
    });

    test('CRLF sources round-trip via carriage-return reattachment', () {
      const code = 'final a = 1;\r\nfinal b = 2;\r\nfinal c = 3;';
      final lines = tokenizer.tokenizeSync(code, langId: 'dart', dark: true);
      expect(lines, isNotNull);
      expect(_rejoin(lines!), code);
    });
  });

  group('plain fallbacks (null = render plain)', () {
    test('null language', () {
      expect(tokenizer.tokenizeSync('x', langId: null, dark: true), isNull);
    });

    test('empty code', () {
      expect(tokenizer.tokenizeSync('', langId: 'dart', dark: true), isNull);
    });

    test('unknown language id', () {
      expect(
        tokenizer.tokenizeSync('x', langId: 'not-a-lang', dark: true),
        isNull,
      );
    });
  });

  group('tokenizeAsync', () {
    setUp(() => debugDisableShikiAsync = true);
    tearDown(() => debugDisableShikiAsync = false);

    test('matches sync output under the test hook', () async {
      const code = 'final greeting = "hi";';
      final sync = tokenizer.tokenizeSync(code, langId: 'dart', dark: true);
      final async = await tokenizer.tokenizeAsync(
        code,
        langId: 'dart',
        dark: true,
      );
      expect(async, isNotNull);
      expect(_rejoin(async!), _rejoin(sync!));
    });

    test('null language resolves to null', () async {
      expect(
        await tokenizer.tokenizeAsync('x', langId: null, dark: true),
        isNull,
      );
    });
  });

  group('reattachCarriageReturns', () {
    test('LF-only input is returned identically (no copy)', () {
      final lines = [
        [const ThemedToken(content: 'a', offset: 0)],
      ];
      expect(identical(reattachCarriageReturns('a', lines), lines), isTrue);
    });

    test('reattaches \\r to the last token of each CRLF line', () {
      final lines = [
        [const ThemedToken(content: 'aa', offset: 0, color: '#FF0000')],
        [const ThemedToken(content: 'b', offset: 3)],
      ];
      final result = reattachCarriageReturns('aa\r\nb', lines);
      expect(result[0].last.content, 'aa\r');
      expect(
        result[0].last.color,
        '#FF0000',
        reason: 'reattachment preserves the token color',
      );
      expect(result[1].single.content, 'b');
    });

    test('empty CRLF line grows a bare \\r token', () {
      final lines = [
        [const ThemedToken(content: 'a', offset: 0)],
        <ThemedToken>[],
        [const ThemedToken(content: 'b', offset: 4)],
      ];
      final result = reattachCarriageReturns('a\r\n\r\nb', lines);
      expect(result[1].single.content, '\r');
    });

    test('line-count mismatch returns tokenizer view untouched', () {
      final lines = [
        [const ThemedToken(content: 'a', offset: 0)],
      ];
      expect(
        identical(reattachCarriageReturns('a\r\nb', lines), lines),
        isTrue,
      );
    });
  });

  group('warmUp', () {
    test('is idempotent and tolerates unknown ids', () {
      tokenizer.warmUp(const ['dart', 'not-a-lang']);
      tokenizer.warmUp(const ['dart']);
    });
  });
}
