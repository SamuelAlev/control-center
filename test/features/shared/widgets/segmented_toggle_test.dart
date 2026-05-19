import 'package:control_center/shared/widgets/segmented_toggle.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

void main() {
  group('SegmentedToggle', () {
    testWidgets('renders segments', (tester) async {
      await tester.pumpWidget(testWrap(
        SegmentedToggle<String>(
          segments: const [
            (value: 'recent', label: 'Recent'),
            (value: 'oldest', label: 'Oldest'),
            (value: 'largest', label: 'Largest'),
          ],
          value: 'recent',
          onChanged: (_) {},
        ),
      ));

      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Oldest'), findsOneWidget);
      expect(find.text('Largest'), findsOneWidget);
    });

    testWidgets('calls onChanged when segment tapped', (tester) async {
      String selected = 'recent';
      await tester.pumpWidget(testWrap(
        SegmentedToggle<String>(
          segments: const [
            (value: 'recent', label: 'Recent'),
            (value: 'oldest', label: 'Oldest'),
          ],
          value: selected,
          onChanged: (v) => selected = v,
        ),
      ));

      await tester.tap(find.text('Oldest'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(selected, 'oldest');
    });

    testWidgets('renders binary toggle', (tester) async {
      await tester.pumpWidget(testWrap(
        SegmentedToggle<String>(
          segments: const [
            (value: 'write', label: 'Write'),
            (value: 'preview', label: 'Preview'),
          ],
          value: 'write',
          onChanged: (_) {},
        ),
      ));

      expect(find.text('Write'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
    });

    testWidgets('works with int type parameter', (tester) async {
      await tester.pumpWidget(testWrap(
        SegmentedToggle<int>(
          segments: const [
            (value: 0, label: 'Off'),
            (value: 1, label: 'On'),
          ],
          value: 0,
          onChanged: (_) {},
        ),
      ));

      expect(find.text('Off'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);
    });

    testWidgets('renders single segment', (tester) async {
      await tester.pumpWidget(testWrap(
        SegmentedToggle<String>(
          segments: const [
            (value: 'only', label: 'Only'),
          ],
          value: 'only',
          onChanged: (_) {},
        ),
      ));

      expect(find.text('Only'), findsOneWidget);
    });
  });
}
