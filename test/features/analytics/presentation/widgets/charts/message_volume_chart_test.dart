import 'package:control_center/features/analytics/presentation/widgets/charts/message_volume_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

void main() {
  group('MessageVolumeChart', () {
    testWidgets('renders with data', (tester) async {
      await tester.pumpWidget(testWrap(
        const MessageVolumeChart(
          data: [
            VolumePoint(day: 0, label: 'Mon', count: 5),
            VolumePoint(day: 1, label: 'Tue', count: 12),
            VolumePoint(day: 2, label: 'Wed', count: 8),
          ],
        ),
      ));

      expect(find.text('Mon'), findsWidgets);
      expect(find.text('Tue'), findsWidgets);
      expect(find.text('Wed'), findsWidgets);
    });

    testWidgets('renders with single data point', (tester) async {
      await tester.pumpWidget(testWrap(
        const MessageVolumeChart(
          data: [VolumePoint(day: 0, label: 'Mon', count: 3)],
        ),
      ));

      expect(find.text('Mon'), findsWidgets);
    });

    testWidgets('renders with zero counts', (tester) async {
      await tester.pumpWidget(testWrap(
        const MessageVolumeChart(
          data: [
            VolumePoint(day: 0, label: 'Mon', count: 0),
            VolumePoint(day: 1, label: 'Tue', count: 0),
          ],
        ),
      ));

      expect(find.text('Mon'), findsWidgets);
      expect(find.text('Tue'), findsWidgets);
    });

    testWidgets('renders with many data points', (tester) async {
      final data = List.generate(
        10,
        (i) => VolumePoint(day: i, label: 'D$i', count: i * 2),
      );
      await tester.pumpWidget(testWrap(
        MessageVolumeChart(data: data),
      ));

      expect(find.text('D0'), findsWidgets);
    });
  });

  group('VolumePoint', () {
    test('creates with day, label, and count', () {
      const point = VolumePoint(day: 0, label: 'Mon', count: 5);
      expect(point.day, 0);
      expect(point.label, 'Mon');
      expect(point.count, 5);
    });
  });
}
