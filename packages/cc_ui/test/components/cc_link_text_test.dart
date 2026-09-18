import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CcLinkText', () {
    testWidgets('renders the text with the engine underline stripped', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CcLinkText(
              'https://tuple.app/c/jsqjD6',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black,
                decoration: TextDecoration.underline,
                decorationColor: Colors.black45,
              ),
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, 'https://tuple.app/c/jsqjD6');
      // The engine underline (baseline-hugging, descender-crossing) never
      // paints — the custom below-glyph underline replaces it.
      expect(text.style?.decoration, TextDecoration.none);
    });

    testWidgets('wraps the text in a paint layer for the offset underline', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CcLinkText('alev.dev', style: TextStyle(fontSize: 13)),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.foregroundPainter != null &&
              w.child is Padding,
        ),
        findsOneWidget,
      );
      expect(find.text('alev.dev'), findsOneWidget);
    });

    testWidgets(
      'reserves space below the glyphs so the underline is not clipped',
      (tester) async {
        const style = TextStyle(fontSize: 12, height: 16 / 12);
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: CcLinkText('alev.dev', style: style)),
          ),
        );

        final textSize = tester.getSize(find.byType(Text));
        final linkSize = tester.getSize(find.byType(CcLinkText));
        // gap (10% of 12) + thickness (clamped 1.0) = 2.2
        expect(linkSize.height, closeTo(textSize.height + 2.2, 0.01));
      },
    );

    testWidgets('honours maxLines/overflow pass-through', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CcLinkText(
              'a link',
              style: TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });
}
