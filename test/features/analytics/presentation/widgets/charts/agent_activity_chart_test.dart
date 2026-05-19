import 'package:control_center/features/analytics/presentation/widgets/charts/agent_activity_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

void main() {
  group('AgentActivityChart', () {
    testWidgets('renders with data', (tester) async {
      await tester.pumpWidget(testWrap(
        const AgentActivityChart(
          data: [
            ActivityBarData(label: 'Mon', runs: 5),
            ActivityBarData(label: 'Tue', runs: 12),
            ActivityBarData(label: 'Wed', runs: 8),
          ],
        ),
      ));

      expect(find.text('Mon'), findsWidgets);
      expect(find.text('Tue'), findsWidgets);
      expect(find.text('Wed'), findsWidgets);
    });

    testWidgets('renders with single data point', (tester) async {
      await tester.pumpWidget(testWrap(
        const AgentActivityChart(
          data: [ActivityBarData(label: 'Mon', runs: 3)],
        ),
      ));

      expect(find.text('Mon'), findsWidgets);
    });

    testWidgets('renders with zero runs', (tester) async {
      await tester.pumpWidget(testWrap(
        const AgentActivityChart(
          data: [
            ActivityBarData(label: 'Mon', runs: 0),
            ActivityBarData(label: 'Tue', runs: 0),
          ],
        ),
      ));

      expect(find.text('Mon'), findsWidgets);
      expect(find.text('Tue'), findsWidgets);
    });

    testWidgets('renders with many data points', (tester) async {
      final data = List.generate(
        7,
        (i) => ActivityBarData(label: 'D$i', runs: i * 3 + 1),
      );
      await tester.pumpWidget(testWrap(
        AgentActivityChart(data: data),
      ));

      for (var i = 0; i < 7; i++) {
        expect(find.text('D$i'), findsWidgets);
      }
    });
  });

  group('ActivityBarData', () {
    test('creates with label and runs', () {
      const data = ActivityBarData(label: 'Mon', runs: 5);
      expect(data.label, 'Mon');
      expect(data.runs, 5);
    });

    test('creates with zero runs', () {
      const data = ActivityBarData(label: 'Fri', runs: 0);
      expect(data.label, 'Fri');
      expect(data.runs, 0);
    });
  });
}
