import 'package:cc_ui/src/components/cc_popover.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
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
  });
}
