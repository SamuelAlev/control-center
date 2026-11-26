import 'dart:ui' show Tristate;

import 'package:cc_ui/src/components/cc_popover.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcPopover', () {
    testWidgets('opens its content on target tap', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcPopover(
              target: const Text('Open'),
              overlayBuilder: (context, size) => const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Popover content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Popover content'), findsNothing);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Popover content'), findsOneWidget);
    });

    testWidgets('supplies a complete text style over a bad ambient default', (
      tester,
    ) async {
      // OverlayPortal content often sits outside a route's Material, where
      // the only ambient DefaultTextStyle is WidgetsApp's 48px double-yellow
      // underline. The panel must override it so Text copyWith cannot leak
      // the decoration.
      TextStyle? resolved;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: DefaultTextStyle(
              style: const TextStyle(
                fontSize: 48,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFFFFFF00),
                decorationStyle: TextDecorationStyle.double,
              ),
              child: CcPopover(
                target: const Text('Open'),
                overlayBuilder: (context, size) => Builder(
                  builder: (context) {
                    resolved = DefaultTextStyle.of(context).style;
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Popover content'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Popover content'), findsOneWidget);
      expect(resolved, isNotNull);
      expect(resolved!.decoration, TextDecoration.none);
      expect(resolved!.fontSize, 14);
    });

    testWidgets('an external controller drives open state', (tester) async {
      final controller = CcOverlayController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcPopover(
              controller: controller,
              toggleOnTargetTap: false,
              target: const Text('Trigger'),
              overlayBuilder: (context, size) => const Text('Driven content'),
            ),
          ),
        ),
      );

      expect(find.text('Driven content'), findsNothing);

      controller.show();
      await tester.pumpAndSettle();

      expect(find.text('Driven content'), findsOneWidget);
    });

    testWidgets('default trigger washes on hover and press', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const Center(
            child: CcPopover(
              target: Text('Open'),
              overlayBuilder: _emptyOverlay,
            ),
          ),
        ),
      );

      BoxDecoration decoration() {
        final box = tester.widget<AnimatedContainer>(
          find.descendant(
            of: find.byType(CcPopover),
            matching: find.byType(AnimatedContainer),
          ),
        );
        return box.decoration! as BoxDecoration;
      }

      final rest = DesignSystemTokens.light().hover.withValues(alpha: 0);
      expect(decoration().color, rest);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Open')));
      await tester.pumpAndSettle();

      expect(decoration().color, DesignSystemTokens.light().hover);

      await gesture.down(tester.getCenter(find.text('Open')));
      await tester.pumpAndSettle();
      expect(decoration().color, DesignSystemTokens.light().hoverStrong);
      await gesture.up();
    });

    group('focus', () {
      late FocusNode inner;
      late FocusNode after;
      setUp(() {
        inner = FocusNode(debugLabel: 'inner');
        after = FocusNode(debugLabel: 'after');
      });
      tearDown(() {
        inner.dispose();
        after.dispose();
      });

      Widget host() => ccTestApp(
        Column(
          children: [
            CcPopover(
              target: const Text('Open'),
              overlayBuilder: (context, size) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CcTappable(
                    focusNode: inner,
                    onPressed: () {},
                    builder: (context, states) => const Text('Inner'),
                  ),
                  CcTappable(
                    onPressed: () {},
                    builder: (context, states) => const Text('Second'),
                  ),
                ],
              ),
            ),
            CcTappable(
              focusNode: after,
              onPressed: () {},
              builder: (context, states) => const Text('After'),
            ),
          ],
        ),
      );

      FocusNode trigger(WidgetTester tester) =>
          Focus.of(tester.element(find.text('Open')));

      Future<void> open(WidgetTester tester) async {
        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump();
      }

      testWidgets('opening moves focus in; Tab stays inside', (tester) async {
        await tester.pumpWidget(host());
        await open(tester);
        expect(trigger(tester).hasFocus, isFalse);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(inner.hasPrimaryFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(inner.hasPrimaryFocus, isTrue, reason: 'Tab wraps inside');
        expect(after.hasFocus, isFalse);
      });

      testWidgets('Escape closes and returns focus to the trigger', (
        tester,
      ) async {
        await tester.pumpWidget(host());
        await open(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        await tester.pump();
        expect(find.text('Inner'), findsNothing);
        expect(trigger(tester).hasPrimaryFocus, isTrue);

        // The next Tab continues from the trigger.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(after.hasPrimaryFocus, isTrue);
      });

      testWidgets('an outside tap returns focus to the trigger', (
        tester,
      ) async {
        await tester.pumpWidget(host());
        await open(tester);
        await tester.tapAt(const Offset(700, 500));
        await tester.pump();
        await tester.pump();
        expect(find.text('Inner'), findsNothing);
        expect(trigger(tester).hasPrimaryFocus, isTrue);
      });

      testWidgets('the trigger reports expanded', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(host());
        expect(
          tester.getSemantics(find.text('Open')),
          matchesSemantics(
            label: 'Open',
            isButton: true,
            hasExpandedState: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
        await open(tester);
        expect(
          tester.getSemantics(find.text('Open')).flagsCollection.isExpanded,
          Tristate.isTrue,
        );
        semantics.dispose();
      });
    });
  });
}

Widget _emptyOverlay(BuildContext context, Size? size) {
  return const SizedBox.shrink();
}
