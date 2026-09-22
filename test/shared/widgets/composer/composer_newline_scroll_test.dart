import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

/// Shift+Enter inserts a newline on the controller, which skips the field's
/// own caret-reveal. Once the draft is taller than [Composer.maxLines] that
/// newline has to scroll the caret back into the viewport.
void main() {
  late ComposerTextController controller;

  setUp(() => controller = ComposerTextController());

  tearDown(() => controller.dispose());

  testWidgets(
    'Shift+Enter scrolls the caret into view once the field is full',
    (tester) async {
      await tester.pumpWidget(
        testWrap(
          Align(
            alignment: Alignment.bottomCenter,
            child: Composer(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              sources: const [],
              onSubmit: (_) async {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Taller than the viewport, caret on the last line. Setting the
      // controller directly does not scroll, so the caret starts off-screen.
      final draft = List.filled(10, 'line').join('\n');
      controller.value = TextEditingValue(
        text: draft,
        selection: TextSelection.collapsed(offset: draft.length),
      );
      await tester.pump();

      final before = _caretRect(tester);
      final viewport = _viewportHeight(tester);
      expect(before.top, greaterThan(viewport));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      // The reveal runs in a post-frame callback; one more frame applies the
      // new scroll offset to the caret's paint position.
      await tester.pump();

      expect(controller.text, '$draft\n');
      expect(controller.selection.extentOffset, controller.text.length);

      final after = _caretRect(tester);
      expect(after.top, greaterThanOrEqualTo(0));
      expect(after.bottom, lessThanOrEqualTo(viewport + 1));
    },
  );
}

Rect _caretRect(WidgetTester tester) {
  final editable = tester.state<EditableTextState>(find.byType(EditableText));
  return editable.renderEditable.getLocalRectForCaret(
    TextPosition(offset: editable.textEditingValue.selection.extentOffset),
  );
}

double _viewportHeight(WidgetTester tester) {
  final editable = tester.state<EditableTextState>(find.byType(EditableText));
  return editable.renderEditable.size.height;
}
