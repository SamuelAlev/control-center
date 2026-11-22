import 'package:control_center/shared/syntax/shiki_tokenizers.dart';
import 'package:control_center/shared/widgets/markdown/code_highlighter.dart';
import 'package:control_center/shared/widgets/markdown/highlighted_code_lines.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

bool _hasColor(List<List<InlineSpan>> lines) => lines.any(
  (line) => line.whereType<TextSpan>().any((s) => s.style?.color != null),
);

void main() {
  setUp(() => debugDisableShikiAsync = true);
  tearDown(() => debugDisableShikiAsync = false);

  testWidgets(
    'a block over the highlight LRU item cap colors once and stays colored',
    (tester) async {
      // ~3000 lines / ~150 KB: past the sync line budget (async path) and
      // past the LRU's 100 KB per-item cap, so only the widget's own state
      // can hold the result.
      final code = List.generate(
        3000,
        (i) => 'final value$i = "string literal number $i"; // note $i',
      ).join('\n');
      expect(code.length, greaterThan(100 * 1024));

      List<List<InlineSpan>>? rendered;
      Widget host() => Directionality(
        textDirection: TextDirection.ltr,
        child: HighlightedCodeLines(
          code: code,
          languageId: 'dart',
          maxChars: 1024 * 1024,
          maxLines: 20000,
          builder: (context, lines) {
            rendered = lines;
            return const SizedBox();
          },
        ),
      );

      final before = debugHighlightParseCount;
      await tester.pumpWidget(host());
      await tester.pump();
      expect(_hasColor(rendered!), isTrue);
      expect(rendered, hasLength(3000));

      // Further frames and rebuilds reuse the held result instead of
      // tokenizing the whole block again.
      for (var i = 0; i < 5; i++) {
        await tester.pumpWidget(host());
        await tester.pump();
      }
      expect(_hasColor(rendered!), isTrue);
      expect(debugHighlightParseCount - before, 1);
    },
  );

  testWidgets('the default caps still render a long block plain', (
    tester,
  ) async {
    final code = List.generate(1000, (i) => 'final value$i = $i;').join('\n');

    List<List<InlineSpan>>? rendered;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: HighlightedCodeLines(
          code: code,
          languageId: 'dart',
          builder: (context, lines) {
            rendered = lines;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();
    expect(_hasColor(rendered!), isFalse);
  });
}
