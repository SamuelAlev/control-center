import 'package:cc_ui/src/components/cc_autocomplete.dart';
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
  group('CcAutocomplete', () {
    testWidgets('typing filters the options into the floating list',
        (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: _options,
              hintText: 'Search fruit',
              onSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search fruit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'an');
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsNothing);
    });

    testWidgets('selecting a match fills the field and reports the value',
        (tester) async {
      String? chosen;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcAutocomplete<String>(
              options: _options,
              hintText: 'Search fruit',
              onSelected: (v) => chosen = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search fruit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'ch');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cherry'));
      await tester.pumpAndSettle();

      expect(chosen, 'c');
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.controller.text, 'Cherry');
    });
  });
}
