import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

void main() {
  group('AppTimestamp', () {
    testWidgets('renders the relative label as its display', (tester) async {
      final ago = DateTime.now().subtract(const Duration(minutes: 3));
      await tester.pumpWidget(testWrap(AppTimestamp.relative(ago)));

      expect(find.text('3 minutes ago'), findsOneWidget);
    });

    testWidgets('wraps a custom child', (tester) async {
      final dt = DateTime(2026, 7, 17, 19, 40, 5);
      await tester.pumpWidget(
        testWrap(AppTimestamp(dateTime: dt, child: const Text('custom'))),
      );

      expect(find.text('custom'), findsOneWidget);
    });

    testWidgets('exposes the absolute time to screen readers', (tester) async {
      final dt = DateTime(2026, 7, 17, 19, 40, 5);
      await tester.pumpWidget(
        testWrap(AppTimestamp(dateTime: dt, child: const Text('1m ago'))),
      );

      final semantics = tester.getSemantics(find.text('1m ago'));
      expect(semantics.label, contains('17 Jul 2026 19:40:05'));
      expect(semantics.label, contains('GMT'));
    });

    testWidgets('reveals the hover card on pointer enter', (tester) async {
      final dt = DateTime(2026, 7, 17, 19, 40, 5);
      await tester.pumpWidget(
        testWrap(AppTimestamp(dateTime: dt, child: const Text('1m ago'))),
      );

      // No card before hover.
      expect(find.text('Timestamp'), findsNothing);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('1m ago')));
      // Hover-intent dwell: the card must not appear immediately.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Timestamp'), findsNothing);
      // After the dwell elapses it opens.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Relative'), findsOneWidget);
      expect(find.text('Timestamp'), findsOneWidget);
      // The raw ISO value (UTC) is shown.
      expect(find.textContaining(dt.toUtc().toIso8601String()), findsOneWidget);
    });

    testWidgets('copies the ISO timestamp when the display is tapped', (
      tester,
    ) async {
      final dt = DateTime(2026, 7, 17, 19, 40, 5);
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );

      await tester.pumpWidget(
        testWrap(AppTimestamp(dateTime: dt, child: const Text('1m ago'))),
      );

      // Copy is now a tap on the timestamp itself (the tooltip is descriptive
      // and non-interactive), no hover required.
      await tester.tap(find.text('1m ago'));
      await tester.pump();

      expect(copied, [dt.toUtc().toIso8601String()]);
    });
  });
}
