import 'package:control_center/features/analytics/presentation/widgets/charts/success_rate_donut.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

void main() {
  group('SuccessRateDonut', () {
    testWidgets('renders with all successes', (tester) async {
      await tester.pumpWidget(testWrap(
        const SuccessRateDonut(successCount: 10, errorCount: 0),
      ));

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('renders with all errors', (tester) async {
      await tester.pumpWidget(testWrap(
        const SuccessRateDonut(successCount: 0, errorCount: 5),
      ));

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('renders with mixed results', (tester) async {
      await tester.pumpWidget(testWrap(
        const SuccessRateDonut(successCount: 7, errorCount: 3),
      ));

      expect(find.text('70%'), findsOneWidget);
    });

    testWidgets('renders with zero total', (tester) async {
      await tester.pumpWidget(testWrap(
        const SuccessRateDonut(successCount: 0, errorCount: 0),
      ));

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('renders with large counts', (tester) async {
      await tester.pumpWidget(testWrap(
        const SuccessRateDonut(successCount: 750, errorCount: 250),
      ));

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('renders with single success', (tester) async {
      await tester.pumpWidget(testWrap(
        const SuccessRateDonut(successCount: 1, errorCount: 0),
      ));

      expect(find.text('100%'), findsOneWidget);
    });
  });
}
