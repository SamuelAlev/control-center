import 'package:control_center/features/analytics/presentation/widgets/charts/workspace_health_gauge.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

void main() {
  group('WorkspaceHealthGauge', () {
    testWidgets('renders healthy score', (tester) async {
      await tester.pumpWidget(testWrap(
        const WorkspaceHealthGauge(score: 95, label: 'main'),
      ));

      expect(find.text('95'), findsOneWidget);
      expect(find.text('main'), findsOneWidget);
    });

    testWidgets('renders warning score', (tester) async {
      await tester.pumpWidget(testWrap(
        const WorkspaceHealthGauge(score: 55, label: 'dev'),
      ));

      expect(find.text('55'), findsOneWidget);
      expect(find.text('dev'), findsOneWidget);
    });

    testWidgets('renders critical score', (tester) async {
      await tester.pumpWidget(testWrap(
        const WorkspaceHealthGauge(score: 12, label: 'staging'),
      ));

      expect(find.text('12'), findsOneWidget);
      expect(find.text('staging'), findsOneWidget);
    });

    testWidgets('renders zero score', (tester) async {
      await tester.pumpWidget(testWrap(
        const WorkspaceHealthGauge(score: 0, label: 'empty'),
      ));

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('renders perfect score', (tester) async {
      await tester.pumpWidget(testWrap(
        const WorkspaceHealthGauge(score: 100, label: 'perfect'),
      ));

      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('renders boundary at 70', (tester) async {
      await tester.pumpWidget(testWrap(
        const WorkspaceHealthGauge(score: 70, label: 'boundary'),
      ));

      expect(find.text('70'), findsOneWidget);
    });

    testWidgets('renders boundary at 40', (tester) async {
      await tester.pumpWidget(testWrap(
        const WorkspaceHealthGauge(score: 40, label: 'borderline'),
      ));

      expect(find.text('40'), findsOneWidget);
    });
  });
}
