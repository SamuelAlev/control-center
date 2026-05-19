import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcBadge', () {
    testWidgets('renders its label', (tester) async {
      await tester.pumpWidget(ccTestApp(const CcBadge(label: 'Active')));

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('renders a leading icon when provided', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcBadge(
            label: 'Done',
            variant: CcBadgeVariant.success,
            icon: IconData(0x1, fontFamily: 'test'),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('omits the icon when none is given', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcBadge(label: 'Neutral', variant: CcBadgeVariant.neutral),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('every variant renders its label without throwing', (
      tester,
    ) async {
      for (final v in CcBadgeVariant.values) {
        await tester.pumpWidget(ccTestApp(CcBadge(label: 'v', variant: v)));
        expect(find.text('v'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(ccTestApp(const SizedBox()));
      }
    });

    testWidgets('renders under a dark theme', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          theme: CcThemeData(
            tokens: DesignSystemTokens.dark(),
            brightness: CcBrightness.dark,
          ),
          const CcBadge(label: 'Dark', variant: CcBadgeVariant.brand),
        ),
      );
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('long labels truncate instead of wrapping or overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const Center(
            child: SizedBox(
              width: 80,
              child: CcBadge(label: 'An extremely long badge label'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('An extremely long badge label'), findsWidgets);
    });
  });
}
