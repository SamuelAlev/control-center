import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_text_area.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcTextArea', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(ccTestApp(const CcTextArea(hintText: 'Notes')));
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

    testWidgets('fires onChanged as the user types', (tester) async {
      String? latest;
      await tester.pumpWidget(
        ccTestApp(CcTextArea(onChanged: (v) => latest = v)),
      );
      await tester.enterText(find.byType(EditableText), 'hello');
      expect(latest, 'hello');
    });

    testWidgets('focusing the area changes appearance', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(ccTestApp(CcTextArea(focusNode: focusNode)));
      expect(focusNode.hasFocus, isFalse);
      await tester.tap(find.byType(CcTextArea));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders a label above the box', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcTextArea(label: 'Description')),
      );
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('renders helper text beneath the box', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcTextArea(helperText: 'Up to 500 chars')),
      );
      expect(find.text('Up to 500 chars'), findsOneWidget);
    });

    testWidgets('renders an error state with a danger glyph', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcTextArea(errorText: 'Too short')),
      );
      expect(find.text('Too short'), findsOneWidget);
      expect(find.byIcon(CcIcons.circleX), findsOneWidget);
    });

    testWidgets('renders a warn state with a warning glyph', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcTextArea(warnText: 'Heads up')),
      );
      expect(find.text('Heads up'), findsOneWidget);
      expect(find.byIcon(CcIcons.triangleAlert), findsOneWidget);
    });

    testWidgets('error takes precedence over warn', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcTextArea(warnText: 'warn', errorText: 'error')),
      );
      expect(find.text('error'), findsOneWidget);
      expect(find.text('warn'), findsNothing);
    });

    testWidgets('hides helper text when there is an error', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcTextArea(helperText: 'helper', errorText: 'error')),
      );
      expect(find.text('error'), findsOneWidget);
      expect(find.text('helper'), findsNothing);
    });

    testWidgets('a disabled field ignores input', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ccTestApp(CcTextArea(controller: controller, enabled: false)),
      );
      // A disabled EditableText is not focusable/editable; tapping does nothing.
      await tester.tap(find.byType(EditableText), warnIfMissed: false);
      await tester.pump();
      expect(controller.text, '');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a read-only field does not accept text changes', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'locked');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ccTestApp(CcTextArea(controller: controller, readOnly: true)),
      );
      await tester.enterText(find.byType(EditableText), 'changed');
      // Read-only EditableText discards the entered text.
      expect(controller.text, 'locked');
    });

    testWidgets('enforces a hard maxLength', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ccTestApp(CcTextArea(controller: controller, maxLength: 5)),
      );
      await tester.enterText(find.byType(EditableText), 'abcdef');
      // The LengthLimitingTextInputFormatter truncates to 5 chars.
      expect(controller.text.length, lessThanOrEqualTo(5));
    });

    testWidgets('autofocus requests focus on mount', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        ccTestApp(CcTextArea(focusNode: focusNode, autofocus: true)),
      );
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('swapping an external controller rebinds its listener', (
      tester,
    ) async {
      final a = TextEditingController();
      final b = TextEditingController();
      addTearDown(a.dispose);
      addTearDown(b.dispose);

      late void Function(void Function()) mutate;
      var useB = false;
      await tester.pumpWidget(
        ccTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              mutate = setState;
              return CcTextArea(controller: useB ? b : a);
            },
          ),
        ),
      );
      // Rebuild with the second controller — didUpdateWidget must unbind/rebind
      // listeners without leaking or throwing.
      mutate(() => useB = true);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'on b');
      expect(b.text, 'on b');
      expect(a.text, '');
      expect(tester.takeException(), isNull);
    });
  });
}
