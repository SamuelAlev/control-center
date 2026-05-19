import 'package:cc_ui/src/components/cc_multi_select.dart';
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
  group('CcMultiSelect', () {
    testWidgets('summarises the selection count in the trigger',
        (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: const {'a', 'b'},
              hintText: 'Pick fruit',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('toggling a row mutates the set and stays open',
        (tester) async {
      Set<String> current = {};
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMultiSelect<String>(
              options: _options,
              values: current,
              hintText: 'Pick fruit',
              onChanged: (v) => current = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick fruit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      expect(current, {'b'});
      // The panel is still open: the other rows remain visible.
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });
  });
}
