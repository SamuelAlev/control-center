import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
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

    for (final direction in TextDirection.values) {
      for (final sample in [
        (width: 320.0, labels: const ['Low', 'Medium', 'High']),
        (
          width: 1000.0,
          labels: const ['Low', 'Medium', 'High', 'Extra High', 'Max'],
        ),
      ]) {
        testWidgets(
          'centres labels on painted stops at ${sample.width}px in $direction',
          (tester) async {
            await tester.binding.setSurfaceSize(Size(sample.width + 32, 200));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            var value = 1.0;
            await tester.pumpWidget(
              ccTestApp(
                Center(
                  child: SizedBox(
                    width: sample.width,
                    child: StatefulBuilder(
                      builder: (context, setState) => CcSlider(
                        value: value,
                        max: sample.labels.length - 1.0,
                        stepLabels: sample.labels,
                        showValue: false,
                        onChanged: (next) => setState(() => value = next),
                      ),
                    ),
                  ),
                ),
                textDirection: direction,
              ),
            );

            final track = find.byKey(CcSlider.trackKey);
            final paintedTrack = tester.renderObject<RenderCustomPaint>(
              find.descendant(of: track, matching: find.byType(CustomPaint)),
            );
            final canvas = TestRecordingCanvas();
            paintedTrack.painter!.paint(canvas, paintedTrack.size);
            // Read the actual painted dots and thumb, not a second copy of
            // the slider's positioning formula.
            final stopXs = <double>{
              for (final call in canvas.invocations)
                if (call.invocation.memberName == #drawCircle)
                  (call.invocation.positionalArguments.first as Offset).dx,
            }.toList()..sort();
            expect(stopXs, hasLength(sample.labels.length));
            final trackY = tester.getCenter(track).dy;

            for (var i = 0; i < sample.labels.length; i++) {
              final label = sample.labels[i];
              final paragraph = tester.renderObject<RenderParagraph>(
                find.text(label),
              );
              final textBox = paragraph
                  .getBoxesForSelection(
                    TextSelection(baseOffset: 0, extentOffset: label.length),
                  )
                  .single;
              final labelCentre = paragraph.localToGlobal(
                textBox.toRect().center,
              );
              final stopX =
                  stopXs[direction == TextDirection.rtl
                      ? stopXs.length - 1 - i
                      : i];
              expect(
                labelCentre.dx,
                closeTo(paintedTrack.localToGlobal(Offset(stopX, 0)).dx, 0.01),
                reason: '$label must be centred under its dot',
              );

              await tester.tapAt(Offset(labelCentre.dx, trackY));
              await tester.pump();
              expect(value, i.toDouble());
            }
          },
        );
      }
    }

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
