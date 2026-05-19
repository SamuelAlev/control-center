import 'package:control_center/router/splash_screen.dart';
import 'package:control_center/shared/widgets/window_drag_area.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The splash is the first surface a cold start shows and it renders outside
/// the shell, so it carries no title bar — and the primary window is not
/// system-movable (see `styleWindowOnShow`). The wait can be long (the local
/// server's ready banner allows 20s), so a window pinned wherever it was
/// restored is a real cost, not a blink.
void main() {
  testWidgets('the splash moves the window', (tester) async {
    var dragStarts = 0;
    WindowDragArea.debugOnStartDrag = () => dragStarts++;
    // The manual-move path reads the OS cursor and repositions the window on
    // every update; neither exists under `flutter_tester`.
    WindowDragArea.debugCursorPosition = () => Offset.zero;
    WindowDragArea.debugOnMoveTo = (_) {};
    addTearDown(() {
      WindowDragArea.debugOnStartDrag = null;
      WindowDragArea.debugCursorPosition = null;
      WindowDragArea.debugOnMoveTo = null;
    });

    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    final gesture = await tester.startGesture(
      const Offset(24, 24),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(8, 6));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    // The spinner animates forever, so the tree never settles.
    await tester.pump();

    expect(dragStarts, 1);
  });
}
