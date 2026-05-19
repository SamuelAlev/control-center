import 'package:control_center/features/analytics/presentation/widgets/charts/review_turnaround_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

void main() {
  group('ReviewTurnaroundChart', () {
    testWidgets('renders with data', (tester) async {
      await tester.pumpWidget(testWrap(
        const ReviewTurnaroundChart(
          data: [
            TurnaroundData(label: 'Mon', hours: 2.5),
            TurnaroundData(label: 'Tue', hours: 4.0),
            TurnaroundData(label: 'Wed', hours: 1.0),
          ],
        ),
      ));

      expect(find.text('Mon'), findsWidgets);
      expect(find.text('Tue'), findsWidgets);
      expect(find.text('Wed'), findsWidgets);
    });

    testWidgets('renders with single data point', (tester) async {
      await tester.pumpWidget(testWrap(
        const ReviewTurnaroundChart(
          data: [TurnaroundData(label: 'Mon', hours: 3.0)],
        ),
      ));

      expect(find.text('Mon'), findsWidgets);
    });

    testWidgets('renders with zero hours', (tester) async {
      await tester.pumpWidget(testWrap(
        const ReviewTurnaroundChart(
          data: [
            TurnaroundData(label: 'Mon', hours: 0),
            TurnaroundData(label: 'Tue', hours: 0),
          ],
        ),
      ));

      expect(find.text('Mon'), findsWidgets);
      expect(find.text('Tue'), findsWidgets);
    });

    testWidgets('renders with fractional hours', (tester) async {
      await tester.pumpWidget(testWrap(
        const ReviewTurnaroundChart(
          data: [
            TurnaroundData(label: 'Mon', hours: 0.5),
            TurnaroundData(label: 'Tue', hours: 1.25),
          ],
        ),
      ));

      expect(find.text('Mon'), findsWidgets);
      expect(find.text('Tue'), findsWidgets);
    });
  });

  group('TurnaroundData', () {
    test('creates with label and hours', () {
      const data = TurnaroundData(label: 'Mon', hours: 2.5);
      expect(data.label, 'Mon');
      expect(data.hours, 2.5);
    });
  });
}
