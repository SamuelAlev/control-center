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

    testWidgets('expands to full width in a centered Column', (tester) async {
      // Regression: a Column's default (center) cross-axis alignment hands
      // children loose width constraints, and a childless ColoredBox sizes to
      // constraints.smallest — the divider rendered at width 0 (invisible in
      // the chat conversation pane).
      await tester.pumpWidget(ccTestApp(const Column(children: [CcDivider()])));

      expect(tester.getSize(find.byType(CcDivider)), const Size(800, 1));
    });

    testWidgets('vertical divider expands to full height in a loose Row', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const Row(
            children: [
              SizedBox(height: 40, child: CcDivider(axis: Axis.vertical)),
            ],
          ),
        ),
      );

      expect(tester.getSize(find.byType(CcDivider)), const Size(1, 40));
    });

    testWidgets('degrades to zero length in an unbounded cross axis', (
      tester,
    ) async {
      // Instead of crashing on BoxConstraints.expand() under an infinite
      // constraint, the LimitedBox clamp keeps the old zero-length behavior.
      await tester.pumpWidget(
        ccTestApp(
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: CcDivider(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(CcDivider)).width, 0);
    });
  });
}
