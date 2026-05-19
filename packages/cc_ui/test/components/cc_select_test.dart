import 'package:cc_ui/src/components/cc_select.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

const _options = <CcSelectOption<String>>[
  CcSelectOption(value: 'a', label: 'Apple'),
  CcSelectOption(value: 'b', label: 'Banana'),
  CcSelectOption(value: 'c', label: 'Cherry'),
];

void main() {
  group('CcSelect', () {
    testWidgets('shows the hint when nothing is selected', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Pick fruit'), findsOneWidget);
    });

    testWidgets('opening the dropdown shows the options', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Banana'), findsNothing);

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('selecting a row updates the value and closes', (tester) async {
      String? chosen;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              onChanged: (v) => chosen = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      expect(chosen, 'b');
      // Panel closed: the only remaining "Apple"/"Cherry" rows are gone.
      expect(find.text('Cherry'), findsNothing);
    });

    testWidgets('trigger border reverts to resting after closing',
        (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcSelect<String>(
              options: _options,
              value: null,
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final resting = _triggerBorder(tester);

      // Open the dropdown — border switches to the focused (brand) color.
      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      final open = _triggerBorder(tester);
      expect(
        open,
        isNot(equals(resting)),
        reason: 'border should be the brand color while open',
      );

      // Close by tapping the dismissal barrier (outside the panel).
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(
        _triggerBorder(tester),
        equals(resting),
        reason: 'border must revert to the resting color after closing',
      );
    });
  });
}

/// The border color of the select trigger (the bordered box holding the hint).
Color? _triggerBorder(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.ancestor(
      of: find.text('Pick fruit'),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration,
      ),
    ),
  );
  final border = (container.decoration as BoxDecoration).border;
  return border is Border ? border.top.color : null;
}
