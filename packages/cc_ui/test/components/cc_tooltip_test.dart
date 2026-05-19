import 'package:cc_ui/src/components/cc_tooltip.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcTooltip', () {
    testWidgets('renders its child without showing the message at rest',
        (tester) async {
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

    testWidgets('shows the message after the hover dwell elapses',
        (tester) async {
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
  });
}
