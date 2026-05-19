import 'package:control_center/shared/widgets/window_drag_area.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A slab of the drag area laid out as three side-by-side 100x50 zones:
/// inert filler, a pressable button and a grip handle. Their centers sit at
/// x = 50, 150 and 250 respectively.
Widget _harness({required VoidCallback onButtonTap}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: WindowDragArea(
        enableDoubleClickMaximize: true,
        child: SizedBox(
          width: 300,
          height: 50,
          child: Row(
            children: [
              const SizedBox(width: 100, height: 50),
              SizedBox(
                width: 100,
                height: 50,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onButtonTap,
                  ),
                ),
              ),
              const SizedBox(
                width: 100,
                height: 50,
                child: MouseRegion(cursor: SystemMouseCursors.grab),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  late int dragStarts;
  late int maximizeToggles;

  setUp(() {
    dragStarts = 0;
    maximizeToggles = 0;
    WindowDragArea.debugOnStartDrag = () => dragStarts++;
    WindowDragArea.debugOnToggleMaximize = () => maximizeToggles++;
  });

  tearDown(() {
    WindowDragArea.debugOnStartDrag = null;
    WindowDragArea.debugOnToggleMaximize = null;
  });

  /// Presses at [from] and jitters by ~6.7px: past the 1px pan slop a mouse
  /// gets ([kPrecisePointerPanSlop]) but well inside the 18px [kTouchSlop] a
  /// tap tolerates — the exact window where the two gestures both remain live
  /// and the arena decides.
  Future<void> drag(WidgetTester tester, Offset from) async {
    final gesture = await tester.startGesture(
      from,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(6, 3));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<void> doubleClick(WidgetTester tester, Offset at) async {
    await tester.tapAt(at, kind: PointerDeviceKind.mouse);
    await tester.pump(kDoubleTapMinTime);
    await tester.tapAt(at, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
  }

  testWidgets('drags the window from inert areas', (tester) async {
    await tester.pumpWidget(_harness(onButtonTap: () {}));

    await drag(tester, const Offset(50, 25));

    expect(dragStarts, 1);
  });

  testWidgets('does not drag from a pressable child', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_harness(onButtonTap: () => taps++));

    await drag(tester, const Offset(150, 25));

    expect(dragStarts, 0);
    // The pan recognizer never joined the arena, so the button's own tap still
    // resolves despite the press wandering past the drag slop.
    expect(taps, 1);
  });

  testWidgets('still drags from a grip handle', (tester) async {
    await tester.pumpWidget(_harness(onButtonTap: () {}));

    await drag(tester, const Offset(250, 25));

    expect(dragStarts, 1);
  });

  testWidgets('double-click zooms from inert areas but not from a button', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(_harness(onButtonTap: () => taps++));

    await doubleClick(tester, const Offset(50, 25));
    expect(maximizeToggles, 1);

    await doubleClick(tester, const Offset(150, 25));
    expect(maximizeToggles, 1);
    expect(taps, 2);
  });
}
