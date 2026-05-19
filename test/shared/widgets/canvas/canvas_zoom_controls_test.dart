import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/canvas/canvas_zoom_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _viewport = Size(400, 300);

Widget _wrap(
  TransformationController controller, {
  VoidCallback? onReset,
  double minScale = 0.25,
  double maxScale = 4.0,
  ValueGetter<Size>? viewport,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: CcTheme(
    data: CcThemeData.light(),
    child: Scaffold(
      body: Center(
        child: CanvasZoomControls(
          controller: controller,
          viewport: viewport ?? () => _viewport,
          minScale: minScale,
          maxScale: maxScale,
          onReset: onReset ?? () {},
        ),
      ),
    ),
  ),
);

double _scaleOf(TransformationController c) => c.value.getMaxScaleOnAxis();

/// cc_ui buttons carry a [CcTooltip], not a Material one, so `find.byTooltip`
/// never sees them — match the button's own property instead.
Finder _find(String tooltip) =>
    find.byWidgetPredicate((w) => w is CcIconButton && w.tooltip == tooltip);

CcIconButton _button(WidgetTester tester, String tooltip) =>
    tester.widget<CcIconButton>(_find(tooltip));

void main() {
  late TransformationController controller;

  setUp(() => controller = TransformationController());
  tearDown(() => controller.dispose());

  testWidgets('zooms in and out about the viewport centre', (tester) async {
    await tester.pumpWidget(_wrap(controller));

    await tester.tap(_find('Zoom in'));
    await tester.pump();
    expect(_scaleOf(controller), greaterThan(1.0));

    // The scene point under the viewport centre must not move — that is what
    // stops repeated presses walking the content off screen.
    final centre = Offset(_viewport.width / 2, _viewport.height / 2);
    expect(controller.toScene(centre).dx, closeTo(centre.dx, 0.01));
    expect(controller.toScene(centre).dy, closeTo(centre.dy, 0.01));

    await tester.tap(_find('Zoom out'));
    await tester.pump();
    expect(_scaleOf(controller), closeTo(1.0, 0.001));
  });

  testWidgets('each control disables itself at its own limit', (tester) async {
    await tester.pumpWidget(_wrap(controller, minScale: 0.5, maxScale: 2));

    expect(_button(tester, 'Zoom in').onPressed, isNotNull);
    expect(_button(tester, 'Zoom out').onPressed, isNotNull);

    controller.value = Matrix4.identity()..scaleByDouble(2, 2, 2, 1);
    await tester.pump();
    // A button that responds to nothing is indistinguishable from a broken one.
    expect(_button(tester, 'Zoom in').onPressed, isNull);
    expect(_button(tester, 'Zoom out').onPressed, isNotNull);

    controller.value = Matrix4.identity()..scaleByDouble(0.5, 0.5, 0.5, 1);
    await tester.pump();
    expect(_button(tester, 'Zoom in').onPressed, isNotNull);
    expect(_button(tester, 'Zoom out').onPressed, isNull);
  });

  testWidgets('never zooms past the limits it was given', (tester) async {
    await tester.pumpWidget(_wrap(controller, minScale: 0.5, maxScale: 1.5));

    for (var i = 0; i < 10; i++) {
      final button = _button(tester, 'Zoom in');
      if (button.onPressed == null) {
        break;
      }
      await tester.tap(_find('Zoom in'));
      await tester.pump();
    }
    expect(_scaleOf(controller), lessThanOrEqualTo(1.5 + 1e-6));

    for (var i = 0; i < 10; i++) {
      final button = _button(tester, 'Zoom out');
      if (button.onPressed == null) {
        break;
      }
      await tester.tap(_find('Zoom out'));
      await tester.pump();
    }
    expect(_scaleOf(controller), greaterThanOrEqualTo(0.5 - 1e-6));
  });

  testWidgets('reads the viewport when pressed, not when built', (
    tester,
  ) async {
    // A canvas measures its viewport during layout, which is after this control
    // was built: handing over the Size froze Size.zero in and every press hit
    // the empty-viewport guard, so both zoom buttons did nothing all session.
    var measured = Size.zero;
    await tester.pumpWidget(_wrap(controller, viewport: () => measured));

    await tester.tap(_find('Zoom in'));
    await tester.pump();
    expect(_scaleOf(controller), 1.0, reason: 'nothing to zoom about yet');

    measured = _viewport;
    await tester.tap(_find('Zoom in'));
    await tester.pump();
    expect(_scaleOf(controller), greaterThan(1.0));
  });

  testWidgets('reset is the host\'s to define', (tester) async {
    var resets = 0;
    await tester.pumpWidget(_wrap(controller, onReset: () => resets++));

    await tester.tap(_find('Fit to view'));
    await tester.pump();

    expect(resets, 1);
  });

  testWidgets('stacks in, out and reset vertically', (tester) async {
    await tester.pumpWidget(_wrap(controller));

    final zoomIn = tester.getCenter(_find('Zoom in'));
    final zoomOut = tester.getCenter(_find('Zoom out'));
    final reset = tester.getCenter(_find('Fit to view'));

    expect(zoomIn.dy, lessThan(zoomOut.dy));
    expect(zoomOut.dy, lessThan(reset.dy));
    // One column, so the three share an axis.
    expect(zoomOut.dx, closeTo(zoomIn.dx, 0.01));
    expect(reset.dx, closeTo(zoomIn.dx, 0.01));
  });
}
