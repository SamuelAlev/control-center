import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  Widget shimmer(Widget child, {bool reduced = false}) => ccTestApp(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Center(child: child),
    ),
  );

  group('CcShimmerText', () {
    testWidgets('reduced motion renders still text in the style colour', (
      tester,
    ) async {
      const color = Color(0xFF123456);
      await tester.pumpWidget(
        shimmer(
          const CcShimmerText('Thinking…', style: TextStyle(color: color)),
          reduced: true,
        ),
      );

      expect(find.byType(ShaderMask), findsNothing);
      expect(tester.widget<Text>(find.text('Thinking…')).style?.color, color);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('sweeps a band across the label, forever', (tester) async {
      await tester.pumpWidget(shimmer(const CcShimmerText('Working…')));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Working…'), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
      // Past one full crossing it starts again rather than settling.
      await tester.pump(const Duration(seconds: 3));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('an empty label still paints', (tester) async {
      await tester.pumpWidget(shimmer(const CcShimmerText('')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('sweeps under RTL', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const Center(child: CcShimmerText('يفكر…')),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ShaderMask), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
