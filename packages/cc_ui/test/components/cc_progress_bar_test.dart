import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcProgressBar', () {
    testWidgets('renders a determinate value without throwing', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(width: 200, child: CcProgressBar(value: 0.5)),
        ),
      );
      expect(find.byType(CcProgressBar), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('clamps out-of-range values', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(width: 200, child: CcProgressBar(value: 2)),
        ),
      );
      final fill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fill.widthFactor, 1.0);
    });

    testWidgets('animates when indeterminate', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(width: 200, child: CcProgressBar()),
        ),
      );
      expect(find.byType(CcProgressBar), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('indeterminate is static when motion is reduced',
        (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(width: 200, child: CcProgressBar()),
          theme: CcThemeData.light(reducedMotion: true),
        ),
      );
      final fill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fill.widthFactor, 0.3);
      await tester.pumpAndSettle();
    });
  });
}
