import 'package:cc_ui/src/components/cc_menu.dart';
import 'package:cc_ui/src/components/cc_tooltip.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcTooltip', () {
    testWidgets('renders its child without showing the message at rest', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const Center(
            child: CcTooltip(
              message: 'Tooltip body',
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );

      expect(find.text('Tooltip body'), findsNothing);
    });

    testWidgets('shows the message after the hover dwell elapses', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const Center(
            child: CcTooltip(
              message: 'Tooltip body',
              showDelay: Duration(milliseconds: 100),
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(SizedBox).first));
      await tester.pump();

      expect(find.text('Tooltip body'), findsNothing);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('Tooltip body'), findsOneWidget);
    });

    testWidgets('shows on keyboard focus of a focusable child', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcTooltip(
              message: 'Tooltip body',
              child: Focus(
                focusNode: node,
                child: const SizedBox(width: 40, height: 40),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tooltip body'), findsNothing);

      // Arm keyboard modality before the focus change. A bare requestFocus
      // is what a click does, and that must not reveal the tooltip.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      node.requestFocus();
      await tester.pumpAndSettle();

      expect(find.text('Tooltip body'), findsOneWidget);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
    });

    testWidgets('Escape dismisses the tooltip while focused', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcTooltip(
              message: 'Tooltip body',
              child: Focus(
                focusNode: node,
                child: const SizedBox(width: 40, height: 40),
              ),
            ),
          ),
        ),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Tooltip body'), findsOneWidget);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Tooltip body'), findsNothing);
    });

    testWidgets('renders a caret when shown', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const Center(
            child: CcTooltip(
              message: 'Tooltip body',
              showDelay: Duration(milliseconds: 100),
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(SizedBox).first));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // The caret is painted with a CustomPaint alongside the message panel.
      expect(find.text('Tooltip body'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets(
      'right-placed caret centers on the trigger, not the panel edge',
      (tester) async {
        // Regression: the caret clamp reserved a fixed rounded-corner inset, but
        // the design system's panels are square — on a short one-line panel the
        // clamp window inverted and pinned the caret to the panel's bottom edge
        // instead of tracking the trigger's centre.
        await tester.pumpWidget(
          ccTestApp(
            const Center(
              child: CcTooltip(
                message: 'Pull requests',
                placement: CcTooltipPlacement.end,
                showDelay: Duration(milliseconds: 100),
                child: SizedBox(width: 32, height: 32),
              ),
            ),
          ),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();
        final target = find.byType(SizedBox).first;
        await gesture.moveTo(tester.getCenter(target));
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();

        // The horizontal caret is the small 5×10 CustomPaint on the panel edge.
        final caret = find.byWidgetPredicate(
          (w) => w is CustomPaint && w.size == const Size(5, 10),
        );
        expect(caret, findsOneWidget);
        expect(tester.getCenter(caret).dy, tester.getCenter(target).dy);
      },
    );

    testWidgets('tooltip nested inside another overlay portal does not throw', (
      tester,
    ) async {
      // The composer is itself an OverlayPortal (the mention popup). The
      // degraded badge's tooltip is a second portal nested in that child.
      final outer = OverlayPortalController();
      const message =
          'Plan mode on Claude Code relies on the sandbox only; the agent\'s own file tools are not intercepted.';
      await tester.pumpWidget(
        ccTestApp(
          Align(
            alignment: Alignment.bottomLeft,
            child: OverlayPortal(
              controller: outer,
              overlayChildBuilder: (_) => const SizedBox.shrink(),
              child: Row(
                children: [
                  CcMenu(
                    items: [
                      CcMenuItem(label: 'Agent', onSelected: () {}),
                      CcMenuItem(label: 'Plan', onSelected: () {}),
                    ],
                    target: const SizedBox(width: 88, height: 32),
                  ),
                  const CcTooltip(
                    message: message,
                    placement: CcTooltipPlacement.top,
                    showDelay: Duration(milliseconds: 100),
                    child: SizedBox(key: Key('badge'), width: 88, height: 32),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(const Key('badge'))));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(message), findsOneWidget);
    });

    testWidgets(
      'clicking a tab does not keep the tooltip after the pointer leaves',
      (tester) async {
        // The sidebar rail focuses the cell it selects. That focus used to
        // pin the hover tooltip, so moving into the panel below left the
        // name floating as if the pointer were still on the tab.
        final node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(
          ccTestApp(
            Align(
              alignment: Alignment.topLeft,
              child: Column(
                children: [
                  CcTooltip(
                    message: 'Explorer',
                    showDelay: const Duration(milliseconds: 100),
                    child: Focus(
                      focusNode: node,
                      child: const SizedBox(
                        key: Key('tab'),
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),
                  const SizedBox(key: Key('content'), width: 240, height: 200),
                ],
              ),
            ),
          ),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();
        final tab = find.byKey(const Key('tab'));
        await gesture.moveTo(tester.getCenter(tab));
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();
        expect(find.text('Explorer'), findsOneWidget);

        await gesture.down(tester.getCenter(tab));
        node.requestFocus();
        await gesture.up();
        await tester.pump();

        // Into the panel, passing through where the tooltip itself sits.
        final tabRect = tester.getRect(tab);
        await gesture.moveTo(tabRect.bottomCenter + const Offset(0, 28));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Explorer'), findsNothing);
        expect(node.hasFocus, isTrue);
      },
    );
  });
}
