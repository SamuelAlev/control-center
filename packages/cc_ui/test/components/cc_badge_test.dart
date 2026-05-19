import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcBadge', () {
    testWidgets('renders its label', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcBadge(label: 'Active')),
      );

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
  });
}
