import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcDivider', () {
    testWidgets('renders a horizontal hairline by default', (tester) async {
      await tester.pumpWidget(ccTestApp(const CcDivider()));

      expect(find.byType(CcDivider), findsOneWidget);
      final box = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(CcDivider),
          matching: find.byType(SizedBox),
        ),
      );
      expect(box.height, 1);
      expect(box.width, isNull);
    });

    testWidgets('renders a vertical line sized by thickness', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(
            height: 40,
            child: CcDivider(axis: Axis.vertical, thickness: 2),
          ),
        ),
      );

      final box = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(CcDivider),
          matching: find.byType(SizedBox),
        ),
      );
      expect(box.width, 2);
      expect(box.height, isNull);
    });

    testWidgets('applies indent padding', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcDivider(indent: 8, endIndent: 4)),
      );

      expect(
        find.descendant(
          of: find.byType(CcDivider),
          matching: find.byType(Padding),
        ),
        findsOneWidget,
      );
    });
  });
}
