import 'package:cc_ui/src/components/cc_text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcTextField', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(ccTestApp(const CcTextField(hintText: 'Search')));
      expect(find.byType(CcTextField), findsOneWidget);
      expect(find.byType(EditableText), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('typing updates the controller', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(ccTestApp(CcTextField(controller: controller)));
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

    // Regression: tapping a populated field must place a collapsed caret where
    // the user clicked, not select all the text. The select-all happened when
    // the RenderEditable ignored pointer events (rendererIgnoresPointer), so
    // the tap never reached it and focus was gained without a tap position.
    testWidgets('tapping places the caret instead of selecting all', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      await tester.pumpWidget(ccTestApp(CcTextField(controller: controller)));

      // Tap into the field (towards the start of the text).
      await tester.tap(find.byType(EditableText));
      await tester.pump();

      // The selection must be a collapsed caret, not a range covering the text.
      expect(
        controller.selection.isCollapsed,
        isTrue,
        reason: 'tap should place a caret, not select all text',
      );
    });

    // Regression: pointer selection must work — double-clicking selects the
    // word under the cursor and click-dragging selects a range. Both were
    // dead when the EditableText had no selection gesture detector.
    testWidgets('double-clicking selects the word under the pointer', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      await tester.pumpWidget(ccTestApp(CcTextField(controller: controller)));

      // Double-click inside the first word.
      final target =
          tester.getTopLeft(find.byType(EditableText)) + const Offset(10, 8);
      await tester.tapAt(target, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tapAt(target, kind: PointerDeviceKind.mouse);
      await tester.pump();

      expect(
        controller.selection.textInside(controller.text),
        'hello',
        reason: 'double-click should select the word under the pointer',
      );
    });

    testWidgets('click-dragging selects a text range', (tester) async {
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      await tester.pumpWidget(ccTestApp(CcTextField(controller: controller)));

      final left = tester.getTopLeft(find.byType(EditableText));
      final gesture = await tester.startGesture(
        left + const Offset(2, 8),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(left + const Offset(300, 8));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(
        controller.selection.isCollapsed,
        isFalse,
        reason: 'click-drag should select a range, not just move the caret',
      );
    });

    // Regression: a blurred field kept painting its selection highlight, so a
    // roster row and the field it was typed in both looked selected at once.
    testWidgets('only the focused field paints its selection', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ccTestApp(CcTextField(controller: controller, focusNode: focusNode)),
      );

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).selectionColor,
        isNull,
        reason: 'an unfocused field must not paint a selection',
      );

      focusNode.requestFocus();
      // Two pumps: the focus change lands in one frame, the rebuild it
      // schedules in the next.
      await tester.pump();
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).selectionColor,
        isNotNull,
      );

      focusNode.unfocus();
      await tester.pump();
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).selectionColor,
        isNull,
        reason: 'the highlight must clear when the field loses focus',
      );
    });

    testWidgets('warn state renders the warn message and glyph', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(const CcTextField(warnText: 'Check this')),
      );
      expect(find.text('Check this'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('error takes precedence over warn', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcTextField(errorText: 'Boom', warnText: 'Soft')),
      );
      expect(find.text('Boom'), findsOneWidget);
      expect(find.text('Soft'), findsNothing);
    });

    testWidgets('a label and helper render around the box', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcTextField(label: 'Email', helperText: 'We never share'),
        ),
      );
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('We never share'), findsOneWidget);
    });

    testWidgets('helper is hidden when there is an error', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcTextField(helperText: 'Helper', errorText: 'Bad')),
      );
      expect(find.text('Bad'), findsOneWidget);
      expect(find.text('Helper'), findsNothing);
    });

    testWidgets('maxLength caps the entered text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ccTestApp(CcTextField(controller: controller, maxLength: 3)),
      );
      await tester.enterText(find.byType(EditableText), 'abcdef');
      await tester.pump();
      // Only the first 3 characters survive the length-limiting formatter.
      expect(controller.text, 'abc');
    });

    testWidgets('prefix and suffix render inside the box', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcTextField(prefix: Text('pre'), suffix: Text('post'))),
      );
      expect(find.text('pre'), findsOneWidget);
      expect(find.text('post'), findsOneWidget);
    });

    testWidgets('a disabled field renders without throwing', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcTextField(enabled: false, hintText: 'Locked')),
      );
      expect(find.text('Locked'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a read-only field renders without throwing', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcTextField(readOnly: true, hintText: 'View')),
      );
      expect(find.text('View'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the sm size and obscureText render without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcTextField(
            size: CcTextFieldSize.sm,
            obscureText: true,
            hintText: 'Password',
          ),
        ),
      );
      expect(find.byType(EditableText), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('swapping an external controller/focus re-binds listeners', (
      tester,
    ) async {
      final a = TextEditingController();
      final b = TextEditingController();
      final fa = FocusNode();
      final fb = FocusNode();
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      addTearDown(fa.dispose);
      addTearDown(fb.dispose);

      var whichController = true;
      var whichFocus = true;
      late void Function(void Function()) setStateOf;
      await tester.pumpWidget(
        ccTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              setStateOf = setState;
              return CcTextField(
                controller: whichController ? a : b,
                focusNode: whichFocus ? fa : fb,
              );
            },
          ),
        ),
      );
      // Swap both the controller and focus node: didUpdateWidget rebinds the
      // listeners without leaving dangling ones.
      setStateOf(() {
        whichController = false;
        whichFocus = false;
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
