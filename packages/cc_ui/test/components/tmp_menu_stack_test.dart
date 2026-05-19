import 'package:cc_ui/src/components/cc_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('repeated right-click does not stack menus', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        Builder(
          builder: (context) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onSecondaryTapDown: (d) => showCcMenuAt(
              context: context,
              position: d.globalPosition,
              items: [CcMenuItem(label: 'Rename', onSelected: () {})],
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(200, 200), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsOneWidget, reason: 'after 1 right-click');

    await tester.tapAt(const Offset(200, 200), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    debugPrint('after 2 clicks: ${find.text('Rename').evaluate().length}');

    await tester.tapAt(const Offset(400, 300), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    debugPrint('after 3 clicks: ${find.text('Rename').evaluate().length}');
  });
}
