import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/anchored_code_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('CodeLineRow', () {
    testWidgets('uses the design-system mono font, not raw monospace', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: CodeLineRow(
              lineNumber: 7,
              code: 'final x = 1;',
              isAnchored: true,
            ),
          ),
        ),
      );

      // The code text uses the bundled Fira Code family, not the generic
      // 'monospace' fallback the anchored snippet used before unification.
      final codeText = tester.widget<Text>(find.text('final x = 1;'));
      expect(codeText.style?.fontFamily, contains('Fira'));
      expect(codeText.style?.fontFamily, isNot('monospace'));

      // The line-number gutter shares the same mono family.
      final gutter = tester.widget<Text>(find.text('7'));
      expect(gutter.style?.fontFamily, contains('Fira'));
    });
  });

  group('AnchoredCodeBlock', () {
    testWidgets('renders the fetched line range', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AnchoredCodeBlock(
            filePath: 'lib/a.dart',
            lineNumber: 2,
            fetchFileContent: (path) async => 'line1\nline2\nline3\nline4',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Anchor (line 2) plus the ±3 context window surfaces the surrounding
      // lines; the anchored line itself must be visible. `findRichText`
      // because the snippet is highlighted now — the code is a span run, not
      // a flat string.
      expect(find.text('line2', findRichText: true), findsOneWidget);
    });

    testWidgets('colours the snippet from the language its path names', (
      tester,
    ) async {
      // The finding always names its file, so the language is never a guess —
      // this surface used to render every snippet as flat grey text anyway.
      await tester.pumpWidget(
        _wrap(
          AnchoredCodeBlock(
            filePath: 'lib/a.dart',
            lineNumber: 2,
            fetchFileContent: (path) async =>
                'const int answer = 42;\n'
                '// a comment\n'
                "final name = 'world';\n"
                'void main() {}\n',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final coloured = tester
          .widgetList<CodeLineRow>(find.byType(CodeLineRow))
          .expand((row) => row.spans ?? const <InlineSpan>[])
          .whereType<TextSpan>()
          .where((span) => span.style?.color != null);
      expect(
        coloured,
        isNotEmpty,
        reason: 'a .dart anchor must reach the dart grammar, not plain text',
      );
    });

    testWidgets('an unknown extension still renders the snippet', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AnchoredCodeBlock(
            filePath: 'notes/thing.zzz',
            lineNumber: 1,
            fetchFileContent: (path) async => 'alpha\nbeta',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('alpha', findRichText: true), findsOneWidget);
    });
  });
}
