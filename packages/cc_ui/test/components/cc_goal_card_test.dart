import 'package:cc_ui/cc_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('formatters', () {
    test('formatCompactCount scales magnitudes', () {
      expect(formatCompactCount(999), '999');
      expect(formatCompactCount(1500), '1.5K');
      expect(formatCompactCount(25000), '25K');
      expect(formatCompactCount(1500000), '1.5M');
      expect(formatCompactCount(2000000000), '2B');
    });

    test('formatCoarseDuration scales time', () {
      expect(formatCoarseDuration(const Duration(seconds: 45)), '45s');
      expect(formatCoarseDuration(const Duration(minutes: 12)), '12m');
      expect(formatCoarseDuration(const Duration(hours: 3)), '3h');
      expect(formatCoarseDuration(const Duration(days: 2)), '2d');
    });
  });

  testWidgets('renders objective, status and budget line', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcGoalCard(
          objective: 'Ship PRD 08',
          status: CcGoalStatus.active,
          statusLabel: 'Active',
          tokensUsed: 12000,
          tokenBudget: 100000,
          elapsed: Duration(hours: 3),
        ),
      ),
    );

    expect(find.text('Ship PRD 08'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.textContaining('12K / 100K tokens'), findsOneWidget);
    expect(find.byType(CcProgressBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides the budget bar when no tokens tracked', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcGoalCard(
          objective: 'Explore',
          status: CcGoalStatus.paused,
          statusLabel: 'Paused',
        ),
      ),
    );

    expect(find.byType(CcProgressBar), findsNothing);
  });
}
