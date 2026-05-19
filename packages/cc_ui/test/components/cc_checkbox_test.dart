import 'package:cc_ui/src/components/cc_checkbox.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcCheckbox', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        ccTestApp(CcCheckbox(value: false, onChanged: (_) {})),
      );
      expect(find.byType(CcCheckbox), findsOneWidget);
    });

    testWidgets('toggles value on tap', (tester) async {
      bool? next;
      await tester.pumpWidget(
        ccTestApp(CcCheckbox(value: false, onChanged: (v) => next = v)),
      );
      await tester.tap(find.byType(CcCheckbox));
      expect(next, isTrue);
    });

    testWidgets('renders the checked state with a glyph', (tester) async {
      await tester.pumpWidget(
        ccTestApp(CcCheckbox(value: true, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is inert when disabled', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcCheckbox(value: false, onChanged: null)),
      );
      await tester.tap(find.byType(CcCheckbox));
      expect(tester.takeException(), isNull);
    });
  });
}
