import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_line_actions.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

/// ⌘←/⌘→ (Home/End off macOS) stop at the ends of the TYPED line, not at a
/// soft wrap: a wrapped sentence is one line, as it is for ↑ recall.
void main() {
  group('logical line bounds', () {
    test('start is just past the previous newline', () {
      expect(logicalLineStart('ab\ncd', 5), 3);
      expect(logicalLineStart('ab\ncd', 3), 3);
      expect(logicalLineStart('ab\ncd', 2), 0);
      expect(logicalLineStart('', 0), 0);
    });

    test('end is the next newline or the text end', () {
      expect(logicalLineEnd('ab\ncd', 0), 2);
      expect(logicalLineEnd('ab\ncd', 2), 2);
      expect(logicalLineEnd('ab\ncd', 3), 5);
    });
  });

  group('in the composer', () {
    late ComposerTextController controller;

    setUp(() => controller = ComposerTextController());

    tearDown(() => controller.dispose());

    // Long enough to wrap several times at this width.
    final sentence = List.filled(12, 'wrapping').join(' ');
    final draft = 'first\n$sentence\nlast';
    const sentenceStart = 'first\n'.length;
    final sentenceEnd = sentenceStart + sentence.length;

    Future<EditableTextState> pumpComposer(WidgetTester tester) async {
      await tester.pumpWidget(
        testWrap(
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 220,
              child: Composer(
                controller: controller,
                autofocus: true,
                sources: const [],
                onSubmit: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return tester.state<EditableTextState>(find.byType(EditableText));
    }

    Future<void> placeCaret(
      WidgetTester tester,
      EditableTextState editable,
      int offset,
    ) async {
      controller.value = TextEditingValue(
        text: draft,
        selection: TextSelection.collapsed(offset: offset),
      );
      await tester.pump();
      // The caret really is on a wrapped row, past a soft break.
      final row = editable.renderEditable.getLineAtOffset(
        TextPosition(offset: offset),
      );
      expect(row.start, greaterThan(sentenceStart));
      expect(row.end, lessThan(sentenceEnd));
    }

    final middle = sentenceStart + sentence.length ~/ 2;

    testWidgets('macOS ⌘← / ⌘→ move to the typed line ends', (tester) async {
      final editable = await pumpComposer(tester);
      await placeCaret(tester, editable, middle);

      editable.performSelector('moveToLeftEndOfLine:');
      await tester.pump();
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: sentenceStart),
      );

      await placeCaret(tester, editable, middle);
      editable.performSelector('moveToRightEndOfLine:');
      await tester.pump();
      expect(
        controller.selection,
        TextSelection.collapsed(offset: sentenceEnd),
      );
    });

    testWidgets('macOS ⇧⌘← selects back to the typed line start', (
      tester,
    ) async {
      final editable = await pumpComposer(tester);
      await placeCaret(tester, editable, middle);

      editable.performSelector('moveToLeftEndOfLineAndModifySelection:');
      await tester.pump();
      expect(controller.selection.start, sentenceStart);
      expect(controller.selection.end, middle);
    });

    testWidgets('Home / End move to the typed line ends', (tester) async {
      final editable = await pumpComposer(tester);
      await placeCaret(tester, editable, middle);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: sentenceStart),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(
        controller.selection,
        TextSelection.collapsed(offset: sentenceEnd),
      );
    });
  });
}
