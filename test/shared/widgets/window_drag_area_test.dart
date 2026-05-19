import 'package:cc_ui/cc_ui.dart';
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

  testWidgets('a trackpad pan over the area never moves the window', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(onButtonTap: () {}));

    // Two-finger scrolling arrives as a pan/zoom pointer, which reaches a
    // recognizer through `addPointerPanZoom` and never consults
    // `isPointerAllowed` — so the guard has to refuse the lane outright.
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.trackpad,
    );
    await gesture.panZoomStart(const Offset(50, 25));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.panZoomUpdate(const Offset(50, 25), pan: const Offset(6, 12));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.panZoomEnd();
    await tester.pumpAndSettle();

    expect(dragStarts, 0);
  });

  group('design-system controls', () {
    Widget ccHarness(Widget child) => CcTheme(
      data: CcThemeData.light(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: WindowDragArea(
            enableDoubleClickMaximize: true,
            child: SizedBox(
              width: 300,
              height: 40,
              child: Row(
                children: [child, const SizedBox(width: 200, height: 40)],
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets('an enabled CcIconButton takes the press', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        ccHarness(
          CcIconButton(
            icon: CcIcons.chevronRight,
            size: CcButtonSize.sm,
            tooltip: 'go forward',
            onPressed: () => taps++,
          ),
        ),
      );

      await drag(tester, const Offset(16, 20));

      expect(dragStarts, 0);
      expect(taps, 1);
    });

    testWidgets('a DISABLED CcIconButton still refuses the drag', (
      tester,
    ) async {
      // The title bar's back button is disabled whenever there is no history,
      // and a disabled control paints `basic` — indistinguishable from inert
      // chrome by cursor alone. Its button *role* survives being disabled, and
      // that is what the guard reads.
      await tester.pumpWidget(
        ccHarness(
          const CcIconButton(
            icon: CcIcons.chevronRight,
            size: CcButtonSize.sm,
            tooltip: 'go forward',
            onPressed: null,
          ),
        ),
      );

      await drag(tester, const Offset(16, 20));

      expect(dragStarts, 0);
    });
  });

  group('manual window move', () {
    late List<Offset> moves;

    setUp(() {
      moves = <Offset>[];
      WindowDragArea.debugCursorPosition = () => const Offset(200, 100);
      WindowDragArea.debugOnMoveTo = moves.add;
    });

    tearDown(() {
      WindowDragArea.debugCursorPosition = null;
      WindowDragArea.debugOnMoveTo = null;
    });

    Widget harness({required bool moveWindowManually}) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: WindowDragArea(
          moveWindowManually: moveWindowManually,
          child: const SizedBox(width: 300, height: 50),
        ),
      ),
    );

    /// A press that crosses the slop (starting the drag) and then travels
    /// [then] further, which is the part a correction has to answer for.
    Future<void> dragFurther(WidgetTester tester, Offset then) async {
      final gesture = await tester.startGesture(
        const Offset(50, 25),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(6, 3));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(then);
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('places the grabbed pixel under the cursor, absolutely', (
      tester,
    ) async {
      await tester.pumpWidget(harness(moveWindowManually: true));

      await dragFurther(tester, const Offset(12, -4));

      // The press landed at (50, 25) in window coordinates and the cursor sits
      // at (200, 100), so the window's top-left must land at cursor - grab.
      // Every update derives that target the same way, from live cursor state
      // — never from the window-local event positions, whose staleness
      // against the moving origin is what used to shake the window — so the
      // travel in between is simply irrelevant to the answer.
      expect(moves, isNotEmpty);
      expect(moves.last, const Offset(150, 75));
    });

    testWidgets('leaves the window alone when the system moves it', (
      tester,
    ) async {
      // The HUD windows stay system-movable and opt out: dragging them must
      // not also reposition anything from Dart.
      await tester.pumpWidget(harness(moveWindowManually: false));

      await dragFurther(tester, const Offset(12, -4));

      expect(moves, isEmpty);
      expect(dragStarts, 1);
    });
  });

  group('controls that announce nothing', () {
    Widget bareHarness(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: WindowDragArea(
          enableDoubleClickMaximize: true,
          child: SizedBox(
            width: 300,
            height: 40,
            child: Row(
              children: [
                SizedBox(width: 100, height: 40, child: child),
                const SizedBox(width: 200, height: 40),
              ],
            ),
          ),
        ),
      ),
    );

    testWidgets('a bare GestureDetector takes the press', (tester) async {
      // No `MouseRegion` and no `Semantics` wrapper: the cursor stays `basic`
      // and there is no pressable role to read. This is what a popover/menu
      // target looks like — it must stay inert as a control so the popover
      // owns the toggle — and the title bar's presence rail, notification bell
      // and usage pill are all popovers.
      var taps = 0;
      await tester.pumpWidget(
        bareHarness(
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
          ),
        ),
      );

      await drag(tester, const Offset(50, 20));

      expect(dragStarts, 0);
      expect(taps, 1);
    });

    testWidgets('a bare Listener takes the press', (tester) async {
      // A raw `Listener` has no semantics at all, so the role check cannot see
      // it either — subscribing to pointer-down is the only signal there is.
      var downs = 0;
      await tester.pumpWidget(
        bareHarness(
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => downs++,
            child: const SizedBox.expand(),
          ),
        ),
      );

      await drag(tester, const Offset(50, 20));

      expect(dragStarts, 0);
      expect(downs, 1);
    });

    testWidgets('an inert child next to one still drags', (tester) async {
      // The guard must stay narrow: hit-testing the child subtree (rather than
      // this widget, whose own gesture plumbing would veto everything) is what
      // keeps the gaps between controls draggable.
      await tester.pumpWidget(
        bareHarness(GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {})),
      );

      await drag(tester, const Offset(200, 20));

      expect(dragStarts, 1);
    });
  });
}
