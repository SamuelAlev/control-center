import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcSpinner', () {
    testWidgets('renders without throwing and animates', (tester) async {
      await tester.pumpWidget(ccTestApp(const CcSpinner()));
      expect(find.byType(CcSpinner), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // The repeating animation keeps scheduling frames; pump a couple.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('respects custom size and color', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          // Center lets the spinner take its intrinsic size; placed bare as an
          // Overlay entry it would be forced to fill the screen.
          const Center(child: CcSpinner(size: 32, color: Color(0xFF112233))),
        ),
      );
      final box = tester.getSize(find.byType(CcSpinner));
      expect(box.width, 32);
      expect(box.height, 32);
    });

    testWidgets('shows a static ring when motion is reduced', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcSpinner(),
          theme: CcThemeData.light(reducedMotion: true),
        ),
      );
      expect(find.byType(CcSpinner), findsOneWidget);
      // No running animation: settle returns without timing out.
      await tester.pumpAndSettle();
    });
  });
}
