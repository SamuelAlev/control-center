import 'package:cc_ui/src/components/cc_kbd.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('renders the key label', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcKbd(keyLabel: '⌘K'),
      ),
    );

    expect(find.text('⌘K'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders with a custom font size and family', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcKbd(keyLabel: 'Esc', fontSize: 13, fontFamily: 'Courier'),
      ),
    );

    expect(find.text('Esc'), findsOneWidget);
    expect(find.byType(CcKbd), findsOneWidget);
  });
}
