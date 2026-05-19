import 'package:cc_ui/src/components/cc_menu.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcMenu', () {
    testWidgets('opens the item list on target tap', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMenu(
              target: const Text('Menu'),
              items: [
                CcMenuItem(label: 'Rename', onSelected: () {}),
                CcMenuItem(label: 'Delete', destructive: true, onSelected: () {}),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Rename'), findsNothing);

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('selecting an item closes the menu and fires onSelected',
        (tester) async {
      var selected = 0;

      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcMenu(
              target: const Text('Menu'),
              items: [
                CcMenuItem(label: 'Rename', onSelected: () => selected++),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(selected, 1);
      expect(find.text('Rename'), findsNothing);
    });
  });
}
