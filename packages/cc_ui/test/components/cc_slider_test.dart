import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcSlider', () {
    testWidgets('shows the committed value in the start-edge label', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: 240,
              child: CcSlider(value: 0.3, onChanged: (_) {}),
            ),
          ),
        ),
      );

      expect(find.text('30%'), findsOneWidget);
      expect(find.byKey(CcSlider.previewKey), findsNothing);
    });

    testWidgets('hover aims a future value without committing', (tester) async {
      double? received;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: 240,
              child: CcSlider(value: 0.2, onChanged: (v) => received = v),
            ),
          ),
        ),
      );

      expect(find.text('20%'), findsOneWidget);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      final track = tester.getRect(find.byKey(CcSlider.trackKey));
      // Physical right of the track maps to max in LTR.
      await gesture.moveTo(Offset(track.right - 1, track.center.dy));
      await tester.pump();

      expect(received, isNull, reason: 'hover must not write the value');
      expect(find.byKey(CcSlider.previewKey), findsOneWidget);
      expect(find.text('20%'), findsNothing);
      expect(find.text('100%'), findsWidgets);
    });

    testWidgets('clicking the aimed position commits that value', (
      tester,
    ) async {
      double? received;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: 240,
              child: CcSlider(value: 0.2, onChanged: (v) => received = v),
            ),
          ),
        ),
      );

      final track = tester.getRect(find.byKey(CcSlider.trackKey));
      await tester.tapAt(Offset(track.right - 1, track.center.dy));
      await tester.pump();

      expect(received, isNotNull);
      expect(received!, closeTo(1.0, 0.001));
    });

    testWidgets('label prefix and custom formatter render together', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: 280,
              child: CcSlider(
                value: 0.75,
                label: 'Opacity',
                formatValue: (v) => '${(v * 100).round()}%',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Opacity: 75%'), findsOneWidget);
    });

    testWidgets('integer ranges show a compact number, not a percent', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: 240,
              child: CcSlider(
                value: 4,
                min: 1,
                max: 8,
                divisions: 7,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('4'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('hides the value label when showValue is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: 240,
              child: CcSlider(value: 0.4, showValue: false, onChanged: (_) {}),
            ),
          ),
        ),
      );

      expect(find.text('40%'), findsNothing);
      expect(find.byKey(CcSlider.valueKey), findsNothing);
    });

    testWidgets('disabled slider is inert and shows no preview', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const Center(
            child: SizedBox(
              width: 240,
              child: CcSlider(value: 0.3, onChanged: null),
            ),
          ),
        ),
      );

      expect(find.text('30%'), findsOneWidget);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(CcSlider.trackKey)));
      await tester.pump();

      expect(find.byKey(CcSlider.previewKey), findsNothing);
      await tester.tap(find.byKey(CcSlider.trackKey));
      expect(tester.takeException(), isNull);
    });

    testWidgets('keyboard still steps the value', (tester) async {
      double? received;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: 240,
              child: CcSlider(
                value: 0.5,
                autofocus: true,
                onChanged: (v) => received = v,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(received, isNotNull);
      expect(received!, closeTo(0.51, 0.001));
    });

    testWidgets('named steps sit under the track and name the reading', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: 280,
              child: CcSlider(
                value: 1,
                min: 0,
                max: 2,
                divisions: 2,
                stepLabels: const ['Low', 'Medium', 'High'],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(CcSlider.stepLabelsKey), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Medium'), findsWidgets);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('named steps commit by stop, not by percent', (tester) async {
      double? received;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: 280,
              child: CcSlider(
                value: 0,
                min: 0,
                max: 2,
                stepLabels: const ['Low', 'Medium', 'High'],
                showValue: false,
                onChanged: (v) => received = v,
              ),
            ),
          ),
        ),
      );

      final track = tester.getRect(find.byKey(CcSlider.trackKey));
      await tester.tapAt(Offset(track.right - 1, track.center.dy));
      await tester.pump();

      expect(received, closeTo(2.0, 0.001));
    });
  });
}
