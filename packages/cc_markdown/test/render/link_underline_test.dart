import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pin for the custom-painted link underline: it must appear in BOTH plain
/// and selectable documents. The selectable half is the regression — under a
/// SelectionArea the keyed text's first render descendant is a
/// RenderMouseRegion, not the RenderParagraph and the painter used to give
/// up silently (no underline anywhere selectable: PR bodies, comments).
///
/// Structural, not a golden: Linux CI rasterizes text differently from the
/// macOS goldens and the contract is the paint layer, not pixel identity.
void main() {
  testWidgets('link underline paints in plain and selectable documents', (
    tester,
  ) async {
    const style = CcMarkdownStyle(
      paragraph: TextStyle(fontSize: 15, height: 1.45, color: Colors.black),
      link: TextStyle(
        fontSize: 15,
        height: 1.45,
        color: Colors.black,
        decorationColor: Colors.black45,
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CcMarkdown(
                  data: '[jumping gypsy fox](https://example.com) plain.',
                  style: style,
                ),
                SizedBox(height: 12),
                CcMarkdown(
                  data:
                      'Selectable [See analysis details on SonarQube Cloud](https://sonarcloud.io/dashboard) tail.',
                  selectable: true,
                  style: style,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is CustomPaint && w.foregroundPainter != null && w.child is Text,
      ),
      findsNWidgets(2),
      reason:
          'both the plain and selectable documents must wrap the link '
          'paragraph in the offset-underline paint layer',
    );
  });
}
