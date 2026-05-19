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

      node.requestFocus();
      await tester.pumpAndSettle();

      expect(find.text('Tooltip body'), findsOneWidget);
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

      node.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Tooltip body'), findsOneWidget);

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

    testWidgets('right-placed caret centers on the trigger, not the panel edge',
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
              placement: CcTooltipPlacement.right,
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

      // The horizontal caret is the small 5×10 CustomPaint on the panel edge.
      final caret = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.size == const Size(5, 10),
      );
      expect(caret, findsOneWidget);
      expect(tester.getCenter(caret).dy, tester.getCenter(target).dy);
    });
  });
}
