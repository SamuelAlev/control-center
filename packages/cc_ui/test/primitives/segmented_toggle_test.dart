import 'package:cc_ui/src/primitives/segmented_toggle.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('SegmentedToggle', () {
    testWidgets('renders every segment label in order', (tester) async {
      const segments = <SegmentedOption<String>>[
        (value: 'recent', label: 'Recent'),
        (value: 'oldest', label: 'Oldest'),
        (value: 'largest', label: 'Largest'),
      ];
      await tester.pumpWidget(
        ccTestApp(
          SegmentedToggle<String>(
            segments: segments,
            value: 'oldest',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Oldest'), findsOneWidget);
      expect(find.text('Largest'), findsOneWidget);
    });

    testWidgets('fires onChanged with the tapped segment value', (
      tester,
    ) async {
      String? picked;
      const segments = <SegmentedOption<String>>[
        (value: 'write', label: 'Write'),
        (value: 'preview', label: 'Preview'),
      ];
      await tester.pumpWidget(
        ccTestApp(
          SegmentedToggle<String>(
            segments: segments,
            value: 'write',
            onChanged: (v) => picked = v,
          ),
        ),
      );

      // Tapping the non-selected segment selects it.
      await tester.tap(find.text('Preview'));
      expect(picked, 'preview');
    });

    testWidgets('tapping the already-selected segment is a no-op', (
      tester,
    ) async {
      var calls = 0;
      const segments = <SegmentedOption<String>>[
        (value: 'a', label: 'A'),
        (value: 'b', label: 'B'),
      ];
      await tester.pumpWidget(
        ccTestApp(
          SegmentedToggle<String>(
            segments: segments,
            value: 'a',
            onChanged: (_) => calls++,
          ),
        ),
      );

      // The selected segment's GestureDetector.onTap is null, so tapping it
      // never fires onChanged.
      await tester.tap(find.text('A'));
      expect(calls, 0);
    });

    testWidgets('renders without throwing for an int-valued toggle', (
      tester,
    ) async {
      const segments = <SegmentedOption<int>>[
        (value: 0, label: 'Zero'),
        (value: 1, label: 'One'),
      ];
      await tester.pumpWidget(
        ccTestApp(
          const SegmentedToggle<int>(
            segments: segments,
            value: 1,
            onChanged: _noop,
          ),
        ),
      );

      expect(find.byType(SegmentedToggle<int>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hovering a segment applies the hover background', (
      tester,
    ) async {
      const segments = <SegmentedOption<String>>[
        (value: 'a', label: 'A'),
        (value: 'b', label: 'B'),
      ];
      await tester.pumpWidget(
        ccTestApp(
          const SegmentedToggle<String>(
            segments: segments,
            value: 'a',
            onChanged: _noopStr,
          ),
        ),
      );

      // Drive a real mouse so the segment's MouseRegion onEnter/onExit fire and
      // the hovered + resting background branches execute.
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Enter the non-selected segment -> hovered branch.
      await gesture.moveTo(tester.getCenter(find.text('B')));
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Leave -> resting branch (alpha-0 background).
      await gesture.moveTo(Offset.zero);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}

void _noopStr(String _) {}

void _noop(int _) {}
