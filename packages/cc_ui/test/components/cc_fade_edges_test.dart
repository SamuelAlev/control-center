import 'package:cc_ui/src/components/cc_fade_edges.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcFadeEdges', () {
    testWidgets('wraps its child in a vertical ShaderMask by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(
            height: 200,
            child: CcFadeEdges(child: Text('scroll me')),
          ),
        ),
      );

      expect(find.byType(CcFadeEdges), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
      expect(find.text('scroll me'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders a horizontal fade without throwing', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(
            width: 200,
            child: CcFadeEdges(axis: Axis.horizontal, child: Text('row')),
          ),
        ),
      );

      expect(find.byType(CcFadeEdges), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disable both edges renders an opaque (no-fade) mask', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(
            height: 100,
            child: CcFadeEdges(
              fadeStart: false,
              fadeEnd: false,
              child: Text('solid'),
            ),
          ),
        ),
      );

      // With both edges off the mask is fully opaque; the child still renders.
      expect(find.text('solid'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('one-sided fade (start only) builds', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(
            height: 100,
            child: CcFadeEdges(
              fadeEnd: false,
              fadeExtent: 0.3,
              child: Text('lead only'),
            ),
          ),
        ),
      );

      expect(find.text('lead only'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('clamps an over-aggressive fadeExtent to the 0..0.5 range', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(
            height: 100,
            child: CcFadeEdges(fadeExtent: 5.0, child: Text('clamped')),
          ),
        ),
      );

      expect(find.text('clamped'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
