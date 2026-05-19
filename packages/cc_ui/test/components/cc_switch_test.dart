import 'package:cc_ui/src/components/cc_switch.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcSwitch', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        ccTestApp(CcSwitch(value: false, onChanged: (_) {})),
      );
      expect(find.byType(CcSwitch), findsOneWidget);
    });

    testWidgets('toggles value on tap', (tester) async {
      bool? next;
      await tester.pumpWidget(
        ccTestApp(CcSwitch(value: false, onChanged: (v) => next = v)),
      );
      await tester.tap(find.byType(CcSwitch));
      expect(next, isTrue);
    });

    testWidgets('is inert when disabled', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcSwitch(value: true, onChanged: null)),
      );
      await tester.tap(find.byType(CcSwitch));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the on state', (tester) async {
      await tester.pumpWidget(
        ccTestApp(CcSwitch(value: true, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
