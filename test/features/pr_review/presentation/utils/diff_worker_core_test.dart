import 'package:control_center/features/pr_review/presentation/utils/diff_worker_core.dart';
import 'package:control_center/shared/utils/syntax_palette.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises the Flutter-free diff compute core directly (the same entrypoint
/// the native isolate and the generated `web/diffWorker.js` Web Worker run).
/// Guards the primitive wire protocol and the streaming contract.
void main() {
  // The word-diff palette slice (background washes derive from these tints).
  const palette = <String, int>{'deletion': 0xFFCF222E, 'addition': 0xFF2DA44E};

  List<Map<String, dynamic>> run(
    String patch, {
    String? language,
    bool dark = true,
  }) {
    final events = <Map<String, dynamic>>[];
    runDiffJob(
      buildDiffJob(
        patch: patch,
        language: language,
        dark: dark,
        palette: palette,
      ),
      events.add,
    );
    return events;
  }

  test('emits a single done for an empty/unparseable patch', () {
    final events = run('');
    expect(events, hasLength(1));
    expect(events.single[DiffWire.type], DiffWire.done);
  });

  test('emits one or more token chunks, then a single done', () {
    const patch = '''
@@ -1,2 +1,2 @@
-final int x = 1;
+final int x = 2;
 print(x);
''';
    final events = run(patch, language: 'dart');

    expect(
      events.last[DiffWire.type],
      DiffWire.done,
      reason: 'terminal done last',
    );
    expect(
      events.where((e) => e[DiffWire.type] == DiffWire.done),
      hasLength(1),
      reason: 'exactly one terminal event',
    );
    expect(
      events.where((e) => e[DiffWire.type] == DiffWire.tok),
      isNotEmpty,
      reason: 'pass-2 streams at least one token chunk',
    );
    expect(
      events.any((e) => e[DiffWire.type] == DiffWire.err),
      isFalse,
      reason: 'no error on a well-formed patch',
    );
  });

  test('tokenization colours keywords with the CC theme '
      '(syntax highlighting survives the swap to shiki)', () {
    const patch = '''
@@ -1,1 +1,1 @@
-final int x = 1;
+final int x = 2;
''';
    final events = run(patch, language: 'dart', dark: true);
    final colors = <int>[];
    for (final tok in events.where((e) => e[DiffWire.type] == DiffWire.tok)) {
      for (final c in tok[DiffWire.colors] as List) {
        if (c is int) {
          colors.add(c);
        }
      }
    }
    expect(
      colors,
      isNotEmpty,
      reason: 'expected at least one CC-theme-coloured token',
    );
    expect(
      colors,
      contains(darkSyntaxPalette['keyword']),
      reason: '`final` must take the dark keyword colour',
    );
  });

  test('light and dark jobs produce different colours', () {
    const patch = '''
@@ -1,1 +1,1 @@
-final int x = 1;
+final int x = 2;
''';
    Set<int> colorsOf({required bool dark}) {
      final out = <int>{};
      for (final tok in run(
        patch,
        language: 'dart',
        dark: dark,
      ).where((e) => e[DiffWire.type] == DiffWire.tok)) {
        for (final c in tok[DiffWire.colors] as List) {
          if (c is int) {
            out.add(c);
          }
        }
      }
      return out;
    }

    expect(colorsOf(dark: true), contains(darkSyntaxPalette['keyword']));
    expect(colorsOf(dark: false), contains(lightSyntaxPalette['keyword']));
  });

  test('per-row token text reconstructs each diff row exactly '
      '(hunk tokenization stays row-aligned)', () {
    const patch = '''
@@ -1,3 +1,3 @@
 /* multi
-   line comment */ final a = 1;
+   line comment */ final b = 2;
 print(a);
''';
    final events = run(patch, language: 'dart');
    final rowTexts = <String>[];
    for (final tok in events.where((e) => e[DiffWire.type] == DiffWire.tok)) {
      final lineLens = (tok[DiffWire.lineLens] as List).cast<int>();
      final texts = (tok[DiffWire.texts] as List).cast<String>();
      var offset = 0;
      for (final len in lineLens) {
        rowTexts.add(texts.sublist(offset, offset + len).join());
        offset += len;
      }
    }
    // Row 0 is the hunk header; content rows follow in patch order.
    expect(rowTexts[1], '/* multi');
    expect(rowTexts[2], '   line comment */ final a = 1;');
    expect(rowTexts[3], '   line comment */ final b = 2;');
    expect(rowTexts[4], 'print(a);');
  });

  test(
    'null language still runs word-diff (plain tokens, coloured washes)',
    () {
      const patch = '''
@@ -1,1 +1,1 @@
-hello old world
+hello new world
''';
      final events = run(patch, language: null);
      expect(events.last[DiffWire.type], DiffWire.done);
      final bgs = <int>[];
      for (final tok in events.where((e) => e[DiffWire.type] == DiffWire.tok)) {
        for (final b in tok[DiffWire.bgs] as List) {
          if (b is int) {
            bgs.add(b);
          }
        }
      }
      expect(
        bgs,
        isNotEmpty,
        reason:
            'word-diff backgrounds must apply to language-less files '
            '(they used to be skipped entirely)',
      );
    },
  );

  test('unknown language degrades to plain tokens, not an error', () {
    const patch = '''
@@ -1,1 +1,1 @@
-x
+y
''';
    final events = run(patch, language: 'definitely-not-a-language');
    expect(events.last[DiffWire.type], DiffWire.done);
    expect(events.any((e) => e[DiffWire.type] == DiffWire.err), isFalse);
  });

  test(
    'token chunks reconstruct into per-line token lists (parallel arrays align)',
    () {
      const patch = '''
@@ -1,1 +1,1 @@
-final int x = 1;
+final int x = 2;
''';
      final tokEvents = run(
        patch,
        language: 'dart',
      ).where((e) => e[DiffWire.type] == DiffWire.tok);
      expect(tokEvents, isNotEmpty);

      for (final tok in tokEvents) {
        final lineLens = (tok[DiffWire.lineLens] as List).cast<int>();
        final texts = tok[DiffWire.texts] as List;
        final colors = tok[DiffWire.colors] as List;
        final bgs = tok[DiffWire.bgs] as List;
        final total = lineLens.fold<int>(0, (a, b) => a + b);
        expect(
          texts,
          hasLength(total),
          reason: 'flattened texts match summed line lengths',
        );
        expect(colors, hasLength(total));
        expect(bgs, hasLength(total));
      }
    },
  );
}
