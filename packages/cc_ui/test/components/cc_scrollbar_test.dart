import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcScrollbar', () {
    testWidgets('renders a square-cornered RawScrollbar with token thumb', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ccTestApp(
          CcScrollbar(
            controller: controller,
            thumbVisibility: true,
            child: ListView(
              controller: controller,
              children: [
                for (var i = 0; i < 50; i++) const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );

      final raw = tester.widget<RawScrollbar>(find.byType(RawScrollbar));
      // Zero-radius geometry: no radius and no shape means RawScrollbar paints
      // an angular thumb.
      expect(raw.radius, isNull);
      expect(raw.shape, isNull);
      expect(raw.thumbColor, DesignSystemTokens.light().lineStrong);
      expect(raw.thickness, 8);
      expect(raw.thumbVisibility, isTrue);
    });

    testWidgets('suppresses the injected app-level scrollbar for its subtree', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ccTestApp(
          ScrollConfiguration(
            behavior: const CcScrollBehavior(),
            child: CcScrollbar(
              controller: controller,
              thumbVisibility: true,
              child: ListView(
                controller: controller,
                children: [
                  for (var i = 0; i < 50; i++) const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      );

      // Only the explicit CcScrollbar's RawScrollbar exists — the behavior
      // must not inject a second one under it.
      expect(find.byType(RawScrollbar), findsOneWidget);
    });

    testWidgets('honors color, thickness and orientation overrides', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ccTestApp(
          CcScrollbar(
            controller: controller,
            color: const Color(0xFF123456),
            thickness: 4,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: ListView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < 50; i++) const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      );

      final raw = tester.widget<RawScrollbar>(find.byType(RawScrollbar));
      expect(raw.thumbColor, const Color(0xFF123456));
      expect(raw.thickness, 4);
      expect(raw.scrollbarOrientation, ScrollbarOrientation.bottom);
    });

    testWidgets(
      'desktop hover does not assert when no controller is passed',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

        await tester.pumpWidget(
          ccTestApp(
            SizedBox(
              width: 400,
              height: 300,
              child: CcScrollbar(
                child: ListView(
                  children: [
                    for (var i = 0; i < 50; i++) const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );

        final raw = tester.widget<RawScrollbar>(find.byType(RawScrollbar));
        expect(raw.controller, isNotNull);
        expect(raw.controller!.hasClients, isTrue);

        // RawScrollbar's MouseRegion covers the whole child; hovering it is
        // what asserted when the thumb fell back to an unattached
        // PrimaryScrollController.
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();
        await gesture.moveTo(tester.getCenter(find.byType(RawScrollbar)));
        await tester.pump();

        // Must be reset in the test body: the binding's invariant check runs
        // before tear-downs.
        debugDefaultTargetPlatformOverride = null;
      },
    );
  });

  group('CcScrollBehavior', () {
    testWidgets(
      'injects an angular scrollbar on vertical desktop scrollables',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

        await tester.pumpWidget(
          ccTestApp(
            ScrollConfiguration(
              behavior: const CcScrollBehavior(),
              child: ListView(
                children: [
                  for (var i = 0; i < 50; i++) const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );

        final raw = tester.widget<RawScrollbar>(find.byType(RawScrollbar));
        expect(raw.radius, isNull);
        expect(raw.shape, isNull);
        // Visible at rest, matching the design-system spec surfaces.
        expect(raw.thumbVisibility, isTrue);

        // Must be reset in the test body: the binding's invariant check runs
        // before tear-downs.
        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('injects nothing on horizontal scrollables', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      await tester.pumpWidget(
        ccTestApp(
          ScrollConfiguration(
            behavior: const CcScrollBehavior(),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < 50; i++) const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(RawScrollbar), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('injects nothing on mobile platforms', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(
        ccTestApp(
          ScrollConfiguration(
            behavior: const CcScrollBehavior(),
            child: ListView(
              children: [
                for (var i = 0; i < 50; i++) const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(RawScrollbar), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
