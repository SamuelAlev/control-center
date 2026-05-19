import 'package:cc_ui/src/components/cc_radio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcRadio', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          CcRadio<int>(value: 1, groupValue: 2, onChanged: (_) {}),
        ),
      );
      expect(find.byType(CcRadio<int>), findsOneWidget);
    });

    testWidgets('selects its value on tap', (tester) async {
      int? selected;
      await tester.pumpWidget(
        ccTestApp(
          CcRadio<int>(value: 1, groupValue: 2, onChanged: (v) => selected = v),
        ),
      );
      await tester.tap(find.byType(CcRadio<int>));
      expect(selected, 1);
    });

    testWidgets('renders the selected state', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          CcRadio<int>(value: 1, groupValue: 1, onChanged: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is inert when disabled', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcRadio<int>(value: 1, groupValue: 2, onChanged: null),
        ),
      );
      await tester.tap(find.byType(CcRadio<int>));
      expect(tester.takeException(), isNull);
    });
  });
}
