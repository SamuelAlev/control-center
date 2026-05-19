import 'package:cc_ui/src/components/cc_text_area.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcTextArea', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcTextArea(hintText: 'Notes')),
      );
      expect(find.byType(CcTextArea), findsOneWidget);
      expect(find.byType(EditableText), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('typing multiple lines updates the controller', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ccTestApp(CcTextArea(controller: controller, minLines: 2)),
      );
      await tester.enterText(find.byType(EditableText), 'line one\nline two');
      expect(controller.text, 'line one\nline two');
    });

    testWidgets('focusing the area changes appearance', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        ccTestApp(CcTextArea(focusNode: focusNode)),
      );
      expect(focusNode.hasFocus, isFalse);
      await tester.tap(find.byType(CcTextArea));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
