import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/shared/widgets/transcript/widgets/code_preview.dart';
import 'package:control_center/shared/widgets/transcript/widgets/inline_diff_view.dart';
import 'package:control_center/shared/widgets/transcript/widgets/shimmer_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  final tokens = DesignSystemTokens.light();

  group('InlineDiffView', () {
    testWidgets('renders added and removed lines', (tester) async {
      await tester.pumpWidget(_host(
        InlineDiffView(
          oldText: 'line one\nold line',
          newText: 'line one\nnew line',
          codeFont: 'monospace',
          tokens: tokens,
        ),
      ));
      expect(find.textContaining('old line'), findsOneWidget);
      expect(find.textContaining('new line'), findsOneWidget);
      // +/- gutter markers.
      expect(find.text('+'), findsWidgets);
      expect(find.text('-'), findsWidgets);
    });
  });

  group('CodePreview', () {
    testWidgets('renders code with a line-number gutter', (tester) async {
      await tester.pumpWidget(_host(
        CodePreview(
          code: 'final x = 1;\nfinal y = 2;',
          codeFont: 'monospace',
          tokens: tokens,
          startLine: 10,
        ),
      ));
      expect(find.textContaining('final x = 1;'), findsOneWidget);
      // Gutter shows the original starting line number.
      expect(find.text('10'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
    });
  });

  group('ShimmerText', () {
    testWidgets('reduced motion renders static text and settles', (tester) async {
      await tester.pumpWidget(_host(
        const ShimmerText('Thinking…'),
        reduceMotion: true,
      ));
      expect(find.text('Thinking…'), findsOneWidget);
      // No perpetual animation: the tree settles.
      await tester.pumpAndSettle();
      expect(find.text('Thinking…'), findsOneWidget);
    });

    testWidgets('animated variant still shows the label', (tester) async {
      await tester.pumpWidget(_host(const ShimmerText('Working…')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Working…'), findsOneWidget);
    });
  });
}
