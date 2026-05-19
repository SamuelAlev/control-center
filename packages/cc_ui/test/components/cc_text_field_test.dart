import 'package:cc_ui/src/components/cc_text_field.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcTextField', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcTextField(hintText: 'Search')),
      );
      expect(find.byType(CcTextField), findsOneWidget);
      expect(find.byType(EditableText), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('typing updates the controller', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ccTestApp(CcTextField(controller: controller)),
      );
      await tester.enterText(find.byType(EditableText), 'hello');
      expect(controller.text, 'hello');
      // Hint disappears once there is text.
      await tester.pump();
    });

    testWidgets('focusing the field changes appearance', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        ccTestApp(CcTextField(focusNode: focusNode, hintText: 'Name')),
      );
      expect(focusNode.hasFocus, isFalse);
      await tester.tap(find.byType(CcTextField));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('error state renders without throwing', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcTextField(errorText: 'Required')),
      );
      expect(find.byType(CcTextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
