import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

/// Behavioral RTL coverage: components whose input handling or visual anchoring
/// must MIRROR under `TextDirection.rtl`, asserted against physical geometry
/// rather than just the directional types they use.
void main() {
  group('CcSlider under RTL', () {
    testWidgets('pointer position maps mirrored (left edge = max)', (
      tester,
    ) async {
      double? received;
      await tester.pumpWidget(
        ccTestApp(
          textDirection: TextDirection.rtl,
          Center(
            child: SizedBox(
              width: 200,
              child: CcSlider(value: 0.2, onChanged: (v) => received = v),
            ),
          ),
        ),
      );

      final track = tester.getRect(find.byKey(CcSlider.trackKey));
      // Physical left of the track is fraction 0 in LTR, so max under RTL.
      await tester.tapAt(Offset(track.left + 1, track.center.dy));
      await tester.pump();

      expect(received, isNotNull);
      expect(received!, closeTo(1.0, 0.001));
    });

    testWidgets('arrow keys track visual motion (left increases)', (
      tester,
    ) async {
      double? received;
      await tester.pumpWidget(
        ccTestApp(
          textDirection: TextDirection.rtl,
          Center(
            child: SizedBox(
              width: 200,
              child: CcSlider(
                value: 0.5,
                autofocus: true,
                onChanged: (v) => received = v,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(received, isNotNull);
      expect(received!, closeTo(0.51, 0.001), reason: 'left = forward in RTL');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(received!, closeTo(0.49, 0.001), reason: 'right = back in RTL');
    });
  });

  group('CcSwitch under RTL', () {
    testWidgets('the "on" thumb rests at the physical LEFT (the end)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          textDirection: TextDirection.rtl,
          Center(child: CcSwitch(value: true, onChanged: (_) {})),
        ),
      );
      await tester.pumpAndSettle();

      final thumb = find.descendant(
        of: find.byType(AnimatedAlign),
        matching: find.byType(Container),
      );
      final track = tester.getCenter(find.byType(CcSwitch));
      expect(
        tester.getCenter(thumb).dx,
        lessThan(track.dx),
        reason: 'end-of-reading-direction is the left edge in RTL',
      );
    });
  });

  group('CcProgressBar under RTL', () {
    testWidgets('determinate fill grows from the physical RIGHT edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          textDirection: TextDirection.rtl,
          const Center(
            child: SizedBox(width: 200, child: CcProgressBar(value: 0.25)),
          ),
        ),
      );

      final bar = tester.getRect(find.byType(CcProgressBar));
      final fill = tester.getRect(
        find.descendant(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(Container),
        ),
      );
      expect(fill.right, closeTo(bar.right, 0.01));
      expect(fill.width, closeTo(50, 0.01));
    });
  });

  group('CcTooltip under RTL', () {
    testWidgets('placement end opens toward the physical LEFT', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          textDirection: TextDirection.rtl,
          const Center(
            child: CcTooltip(
              message: 'Tooltip body',
              placement: CcTooltipPlacement.end,
              showDelay: Duration(milliseconds: 100),
              child: SizedBox(width: 32, height: 32),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      final target = find.byType(SizedBox).first;
      await gesture.moveTo(tester.getCenter(target));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('Tooltip body'), findsOneWidget);
      expect(
        tester.getCenter(find.text('Tooltip body')).dx,
        lessThan(tester.getCenter(target).dx),
        reason: 'the end side is the left of the trigger in RTL',
      );
    });
  });

  group('CcResizable under RTL', () {
    testWidgets('dragging toward the physical RIGHT shrinks the start region', (
      tester,
    ) async {
      final regions = [
        CcResizableRegion.child(
          child: const Text('start'),
          initialExtent: 200,
          minExtent: 100,
          maxExtent: 280,
        ),
        CcResizableRegion.child(
          child: const Text('end'),
          initialExtent: 200,
          minExtent: 100,
          maxExtent: 280,
        ),
      ];
      final controller = CcResizableController(regions);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ccTestApp(
          textDirection: TextDirection.rtl,
          Center(
            child: SizedBox(
              width: 400,
              height: 200,
              child: CcResizable(
                axis: Axis.horizontal,
                controller: controller,
                regions: regions,
              ),
            ),
          ),
        ),
      );

      // In RTL the start region sits on the physical right. A drag toward
      // the right is toward the start edge, so it shrinks that region.
      final divider = find.byType(MouseRegion).first;
      final gesture = await tester.startGesture(tester.getCenter(divider));
      await gesture.moveBy(const Offset(40, 0));
      await gesture.up();
      await tester.pump();

      expect(controller.extents[0], 160);
      expect(controller.extents[1], 240);
    });
  });

  group('CcOverlayAnchor under RTL', () {
    testWidgets('directional start anchors pin to the physical RIGHT', (
      tester,
    ) async {
      final controller = CcOverlayController();
      addTearDown(controller.dispose);
      const targetKey = Key('target');
      const overlayKey = Key('overlay');

      await tester.pumpWidget(
        ccTestApp(
          textDirection: TextDirection.rtl,
          Center(
            child: CcOverlayAnchor(
              controller: controller,
              target: const SizedBox(key: targetKey, width: 80, height: 24),
              overlayBuilder: (context, size) =>
                  const SizedBox(key: overlayKey, width: 80, height: 40),
            ),
          ),
        ),
      );

      controller.show();
      await tester.pumpAndSettle();

      final target = tester.getRect(find.byKey(targetKey));
      final overlay = tester.getRect(find.byKey(overlayKey));
      expect(
        overlay.right,
        closeTo(target.right, 1),
        reason: 'bottomStart/topStart share the right edge in RTL',
      );
      expect(overlay.top, closeTo(target.bottom + 4, 1));
    });
  });

  group('directional icons', () {
    test('chevrons mirror; semantic glyphs do not', () {
      expect(CcIcons.chevronRight.matchTextDirection, isTrue);
      expect(CcIcons.house.matchTextDirection, isFalse);
    });
  });
}
