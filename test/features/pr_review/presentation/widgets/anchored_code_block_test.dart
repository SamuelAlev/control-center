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
      // lines; the anchored line itself must be visible.
      expect(find.text('line2'), findsOneWidget);
    });
  });
}
