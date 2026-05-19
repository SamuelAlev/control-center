import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_image_viewer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

const _labels = CcImageViewerLabels(
  expand: 'Expand',
  zoomIn: 'Zoom in',
  zoomOut: 'Zoom out',
  resetZoom: 'Reset zoom',
  close: 'Close',
);

/// A stand-in visual — the viewer never decodes anything itself, it transforms
/// whatever widget it was handed.
const _sample = ColoredBox(color: Color(0xFF336699), child: SizedBox.expand());

Matrix4 _matrixOf(WidgetTester tester) => tester
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!
    .value;

Offset _translationOf(WidgetTester tester) {
  final t = _matrixOf(tester).getTranslation();
  return Offset(t.x, t.y);
}

double _scaleOf(WidgetTester tester) => tester
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!
    .value
    .getMaxScaleOnAxis();

Future<void> _pumpViewer(WidgetTester tester) => tester.pumpWidget(
  ccTestApp(
    const SizedBox(
      width: 400,
      height: 300,
      child: CcImageViewer(labels: _labels, child: _sample),
    ),
  ),
);

void main() {
  group('CcImageViewer', () {
    testWidgets('opens at fit and reports 100%', (tester) async {
      await _pumpViewer(tester);

      expect(_scaleOf(tester), 1.0);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('the zoom-in control scales up and the readout follows', (
      tester,
    ) async {
      await _pumpViewer(tester);

      await tester.tap(find.bySemanticsLabel('Zoom in'));
      await tester.pumpAndSettle();

      expect(_scaleOf(tester), closeTo(1.5, 0.001));
      expect(find.text('150%'), findsOneWidget);
    });

    testWidgets('zooms OUT below fit — 1 is the resting point, not the floor', (
      tester,
    ) async {
      await _pumpViewer(tester);

      await tester.tap(find.bySemanticsLabel('Zoom out'));
      await tester.pumpAndSettle();

      expect(_scaleOf(tester), closeTo(1 / 1.5, 0.001));
      expect(find.text('67%'), findsOneWidget);
    });

    testWidgets('never zooms out past minScale', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(
            width: 400,
            height: 300,
            child: CcImageViewer(
              labels: _labels,
              minScale: 0.5,
              child: _sample,
            ),
          ),
        ),
      );

      for (var i = 0; i < 8; i++) {
        final zoomOut = find.bySemanticsLabel('Zoom out');
        if (zoomOut.evaluate().isEmpty) {
          break;
        }
        await tester.tap(zoomOut);
        await tester.pumpAndSettle();
      }

      expect(_scaleOf(tester), greaterThanOrEqualTo(0.5));
    });

    testWidgets('reset is live from BELOW fit too', (tester) async {
      await _pumpViewer(tester);

      await tester.tap(find.bySemanticsLabel('Zoom out'));
      await tester.pumpAndSettle();
      expect(_scaleOf(tester), lessThan(1));

      await tester.tap(find.bySemanticsLabel('Reset zoom'));
      await tester.pumpAndSettle();

      expect(_scaleOf(tester), 1.0);
    });

    testWidgets('below fit the content is centered, not parked at a corner', (
      tester,
    ) async {
      await _pumpViewer(tester);

      await tester.tap(find.bySemanticsLabel('Zoom out'));
      await tester.pumpAndSettle();

      // Measured, not assumed: the overlay hands its entry TIGHT constraints,
      // so the viewer is window-sized whatever SizedBox wraps it.
      final viewport = tester.getSize(find.byType(InteractiveViewer));
      final scale = _scaleOf(tester);
      final t = _translationOf(tester);
      expect(t.dx, closeTo(viewport.width * (1 - scale) / 2, 0.5));
      expect(t.dy, closeTo(viewport.height * (1 - scale) / 2, 0.5));
    });

    testWidgets('reset returns a zoomed viewer to fit', (tester) async {
      await _pumpViewer(tester);

      await tester.tap(find.bySemanticsLabel('Zoom in'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Zoom in'));
      await tester.pumpAndSettle();
      expect(_scaleOf(tester), greaterThan(2));

      await tester.tap(find.bySemanticsLabel('Reset zoom'));
      await tester.pumpAndSettle();

      expect(_scaleOf(tester), 1.0);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('never zooms past maxScale', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(
            width: 400,
            height: 300,
            child: CcImageViewer(labels: _labels, maxScale: 2, child: _sample),
          ),
        ),
      );

      for (var i = 0; i < 6; i++) {
        final zoomIn = find.bySemanticsLabel('Zoom in');
        if (zoomIn.evaluate().isEmpty) {
          break;
        }
        await tester.tap(zoomIn);
        await tester.pumpAndSettle();
      }

      expect(_scaleOf(tester), lessThanOrEqualTo(2.0));
    });

    testWidgets('double-tap toggles between fit and a closer look', (
      tester,
    ) async {
      await _pumpViewer(tester);

      final center = tester.getCenter(find.byType(InteractiveViewer));
      Future<void> doubleTap() async {
        await tester.tapAt(center);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tapAt(center);
        await tester.pumpAndSettle();
      }

      await doubleTap();
      expect(_scaleOf(tester), greaterThan(1.0));

      await doubleTap();
      expect(_scaleOf(tester), 1.0);
    });

    group('scroll', () {
      Future<void> scroll(
        WidgetTester tester, {
        required Offset delta,
        PointerDeviceKind kind = PointerDeviceKind.mouse,
      }) async {
        final at = tester.getCenter(find.byType(InteractiveViewer));
        final pointer = TestPointer(1, kind);
        pointer.hover(at);
        await tester.sendEventToBinding(pointer.scroll(delta));
        await tester.pumpAndSettle();
      }

      testWidgets('a plain wheel PANS — it must not zoom', (tester) async {
        await _pumpViewer(tester);
        await tester.tap(find.bySemanticsLabel('Zoom in'));
        await tester.pumpAndSettle();
        final before = _scaleOf(tester);

        await scroll(tester, delta: const Offset(0, 80));

        // The whole complaint: `InteractiveViewer` hardwires the wheel to zoom,
        // so a two-finger flick over a lightbox lurched instead of scrolling.
        expect(_scaleOf(tester), closeTo(before, 0.001));
        expect(_translationOf(tester).dy, lessThan(0));
      });

      testWidgets('a plain wheel cannot pan past the edge', (tester) async {
        await _pumpViewer(tester);

        // At fit there is nowhere to pan to, so the clamp holds it still
        // rather than sliding the image off its own frame.
        await scroll(tester, delta: const Offset(0, 400));

        expect(_scaleOf(tester), 1.0);
        expect(_translationOf(tester).dy, 0);
      });

      testWidgets('option + wheel zooms', (tester) async {
        await _pumpViewer(tester);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        addTearDown(() => tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft));

        await scroll(tester, delta: const Offset(0, -120));

        expect(_scaleOf(tester), greaterThan(1.0));
      });

      testWidgets('command + wheel zooms — the app canvas convention', (
        tester,
      ) async {
        await _pumpViewer(tester);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        addTearDown(() => tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft));

        await scroll(tester, delta: const Offset(0, -120));

        expect(_scaleOf(tester), greaterThan(1.0));
      });

      testWidgets('a plain trackpad scroll pans without zooming', (
        tester,
      ) async {
        await _pumpViewer(tester);
        await tester.tap(find.bySemanticsLabel('Zoom in'));
        await tester.pumpAndSettle();
        final before = _scaleOf(tester);

        await scroll(
          tester,
          delta: const Offset(0, 60),
          kind: PointerDeviceKind.trackpad,
        );

        expect(_scaleOf(tester), closeTo(before, 0.001));
      });
    });

    testWidgets('renders host-supplied toolbar actions', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(
            width: 400,
            height: 300,
            child: CcImageViewer(
              labels: _labels,
              actions: [Text('open original')],
              child: _sample,
            ),
          ),
        ),
      );

      expect(find.text('open original'), findsOneWidget);
    });
  });

  group('CcExpandableImage', () {
    Widget host({bool enabled = true}) => ccTestApp(
      Navigator(
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) => Center(
            child: SizedBox(
              width: 200,
              height: 120,
              child: CcExpandableImage(
                labels: _labels,
                title: 'screenshot.png',
                enabled: enabled,
                viewerBuilder: (_) => const Text('full size'),
                child: const Text('inline'),
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets('tapping the image opens the viewer on the full rendition', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(find.text('full size'), findsNothing);

      await tester.tap(find.text('inline'));
      await tester.pumpAndSettle();

      // The lightbox shows the FULL rendition, not the inline one it was
      // opened from — that separation is the whole point of the two builders.
      expect(find.text('full size'), findsOneWidget);
      expect(find.text('screenshot.png'), findsOneWidget);
      expect(find.byType(CcImageViewer), findsOneWidget);
    });

    testWidgets('the expand chip is hidden until the pointer is over it', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      AnimatedOpacity chip() =>
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(chip().opacity, 0);

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(location: Offset.zero);
      addTearDown(pointer.removePointer);
      await pointer.moveTo(tester.getCenter(find.text('inline')));
      await tester.pumpAndSettle();

      expect(chip().opacity, 1);
    });

    // A labelled chip is ~90px wide. On a small thumbnail the Stack would clip
    // it, which reads as a rendering bug rather than an affordance — so the
    // chip measures the box it decorates and drops to the glyph alone.
    //
    // One size per test on purpose: `ccTestApp` mounts its child through
    // `Overlay(initialEntries:)`, which captures the entry builder once, so a
    // second `pumpWidget` in the same test re-measures the FIRST tree.
    Widget sized(double w, double h) => ccTestApp(
      Center(
        child: SizedBox(
          width: w,
          height: h,
          child: CcExpandableImage(
            labels: _labels,
            viewerBuilder: (_) => const Text('full size'),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    testWidgets('a roomy box gets the labelled chip', (tester) async {
      await tester.pumpWidget(sized(300, 200));
      await tester.pumpAndSettle();

      expect(find.text('Expand'), findsOneWidget);
    });

    testWidgets('a box too small for the label gets the glyph alone', (
      tester,
    ) async {
      await tester.pumpWidget(sized(80, 80));
      await tester.pumpAndSettle();

      expect(find.text('Expand'), findsNothing);
      expect(find.byIcon(CcIcons.maximize2), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disabled renders the child bare — no tap target', (
      tester,
    ) async {
      await tester.pumpWidget(host(enabled: false));
      await tester.pumpAndSettle();

      expect(find.text('inline'), findsOneWidget);
      await tester.tap(find.text('inline'));
      await tester.pumpAndSettle();

      expect(find.text('full size'), findsNothing);
    });
  });
}
