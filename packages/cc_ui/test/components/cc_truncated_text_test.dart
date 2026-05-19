import 'package:cc_ui/src/components/cc_tooltip.dart';
import 'package:cc_ui/src/components/cc_truncated_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcTruncatedText', () {
    testWidgets('renders plain text with no tooltip when the text fits', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const Center(
            child: SizedBox(width: 300, child: CcTruncatedText('Short')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Short'), findsOneWidget);
      expect(find.byType(CcTooltip), findsNothing);
    });

    testWidgets('discloses the full text in a tooltip when truncated', (
      tester,
    ) async {
      const label = 'A very long label that cannot possibly fit in the box';
      await tester.pumpWidget(
        ccTestApp(
          const Center(
            child: SizedBox(width: 60, child: CcTruncatedText(label)),
          ),
        ),
      );
      // First frame lays out and detects the truncation; the second frame
      // rebuilds with the tooltip wrapper.
      await tester.pump();
      await tester.pump();

      expect(find.byType(CcTooltip), findsOneWidget);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(CcTruncatedText)));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // The label now renders twice: the truncated original and the tooltip.
      expect(find.text(label), findsNWidgets(2));
    });

    testWidgets('supports intrinsic-sizing parents like IntrinsicWidth', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const Center(
            child: IntrinsicWidth(child: CcTruncatedText('Shrink-wrapped')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Shrink-wrapped'), findsOneWidget);
      // Shrink-wrapping gives the text its natural width — no truncation.
      expect(find.byType(CcTooltip), findsNothing);
    });
  });
}
