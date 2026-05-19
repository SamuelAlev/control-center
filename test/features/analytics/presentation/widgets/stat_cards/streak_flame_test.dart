import 'package:control_center/features/analytics/presentation/widgets/stat_cards/streak_flame.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

void main() {
  group('StreakFlame', () {
    testWidgets('renders active streak', (tester) async {
      await tester.pumpWidget(testWrap(
        const StreakFlame(count: 7, label: 'Day streak', isActive: true),
      ));

      expect(find.text('7'), findsOneWidget);
      expect(find.text('Day streak'), findsOneWidget);
    });

    testWidgets('renders inactive streak', (tester) async {
      await tester.pumpWidget(testWrap(
        const StreakFlame(count: 0, label: 'Week streak', isActive: false),
      ));

      expect(find.text('0'), findsOneWidget);
      expect(find.text('Week streak'), findsOneWidget);
    });

    testWidgets('renders large count', (tester) async {
      await tester.pumpWidget(testWrap(
        const StreakFlame(count: 365, label: 'Day streak', isActive: true),
      ));

      expect(find.text('365'), findsOneWidget);
    });

    testWidgets('renders with custom label', (tester) async {
      await tester.pumpWidget(testWrap(
        const StreakFlame(count: 3, label: 'PR streak', isActive: true),
      ));

      expect(find.text('3'), findsOneWidget);
      expect(find.text('PR streak'), findsOneWidget);
    });

    testWidgets('renders zero streak inactive', (tester) async {
      await tester.pumpWidget(testWrap(
        const StreakFlame(count: 0, label: 'Day streak', isActive: false),
      ));

      expect(find.text('0'), findsOneWidget);
    });
  });
}
