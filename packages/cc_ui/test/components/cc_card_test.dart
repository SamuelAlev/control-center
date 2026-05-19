import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcCard', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcCard(child: Text('content'))),
      );

      expect(find.text('content'), findsOneWidget);
      expect(find.byType(CcTappable), findsNothing);
    });

    testWidgets('non-interactive card does not respond to taps',
        (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcCard(child: Text('static'))),
      );

      expect(find.byType(CcTappable), findsNothing);
    });

    testWidgets('interactive card fires onPressed on tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        ccTestApp(
          CcCard(
            interactive: true,
            onPressed: () => taps++,
            child: const Text('tap me'),
          ),
        ),
      );

      expect(find.byType(CcTappable), findsOneWidget);
      await tester.tap(find.text('tap me'));
      await tester.pump();
      expect(taps, 1);
    });
  });
}
