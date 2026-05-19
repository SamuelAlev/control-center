import 'package:control_center/features/analytics/presentation/widgets/charts/pr_throughput_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

void main() {
  group('PrThroughputChart', () {
    testWidgets('renders with data', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrThroughputChart(
          spots: [
            ThroughputSpot(week: 0, label: 'W1', created: 5, merged: 3),
            ThroughputSpot(week: 1, label: 'W2', created: 8, merged: 7),
            ThroughputSpot(week: 2, label: 'W3', created: 4, merged: 4),
          ],
        ),
      ));

      expect(find.text('W1'), findsWidgets);
      expect(find.text('W2'), findsWidgets);
      expect(find.text('W3'), findsWidgets);
    });

    testWidgets('renders with single data point', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrThroughputChart(
          spots: [ThroughputSpot(week: 0, label: 'W1', created: 3, merged: 2)],
        ),
      ));

      expect(find.text('W1'), findsWidgets);
    });

    testWidgets('renders with zero values', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrThroughputChart(
          spots: [
            ThroughputSpot(week: 0, label: 'W1', created: 0, merged: 0),
            ThroughputSpot(week: 1, label: 'W2', created: 0, merged: 0),
          ],
        ),
      ));

      expect(find.text('W1'), findsWidgets);
      expect(find.text('W2'), findsWidgets);
    });

    testWidgets('renders with only created and no merged', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrThroughputChart(
          spots: [ThroughputSpot(week: 0, label: 'W1', created: 10, merged: 0)],
        ),
      ));

      expect(find.text('W1'), findsWidgets);
    });
  });

  group('ThroughputSpot', () {
    test('creates with all fields', () {
      const spot = ThroughputSpot(week: 0, label: 'W1', created: 5, merged: 3);
      expect(spot.week, 0);
      expect(spot.label, 'W1');
      expect(spot.created, 5);
      expect(spot.merged, 3);
    });
  });
}
