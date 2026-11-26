import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:control_center/shared/widgets/markdown/markdown_indentation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

/// Tab and Shift+Tab indent inside a code fence; everywhere else, and after
/// Escape, they keep their usual meaning.
void main() {
  late ComposerTextController controller;
  var planToggles = 0;

  setUp(() {
    controller = ComposerTextController();
    planToggles = 0;
    resetMarkdownIndentHint();
  });

  tearDown(() => controller.dispose());

  Future<void> pumpComposer(WidgetTester tester, String text, int caret) async {
    await tester.pumpWidget(
      testWrap(
        Align(
          alignment: Alignment.bottomCenter,
          child: Composer(
            controller: controller,
            autofocus: true,
            sources: const [],
            onPlanToggle: () => planToggles++,
            onSubmit: (_) async {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret),
    );
    await tester.pump();
  }

  bool fieldHasFocus(WidgetTester tester) => tester
      .state<EditableTextState>(find.byType(EditableText))
      .widget
      .focusNode
      .hasFocus;

  Future<void> shiftTab(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
  }

  testWidgets('Tab indents in a fence and Shift+Tab takes it back', (
    tester,
  ) async {
    await pumpComposer(tester, '```\nfoo\n```', 4);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(controller.text, '```\n  foo\n```');
    expect(fieldHasFocus(tester), isTrue);

    await shiftTab(tester);
    expect(controller.text, '```\nfoo\n```');
    expect(planToggles, 0);

    // Nothing left to outdent: the key is the plan toggle's again.
    await shiftTab(tester);
    expect(controller.text, '```\nfoo\n```');
    expect(planToggles, 1);
  });

  testWidgets('the first captured Tab says how to leave, once', (tester) async {
    await pumpComposer(tester, '```\nfoo\n```', 4);
    const hint =
        'Tab indents here. Press Esc, then Tab to move to the next control.';

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.text(hint), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.text(hint), findsOneWidget);
    // Let the toast run out so no timer outlives the test.
    await tester.pump(const Duration(seconds: 9));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Escape, then Tab or Shift+Tab leaves from the composer', (
    tester,
  ) async {
    final before = FocusNode(debugLabel: 'before');
    final after = FocusNode(debugLabel: 'after');
    addTearDown(before.dispose);
    addTearDown(after.dispose);
    await tester.pumpWidget(
      testWrap(
        Column(
          children: [
            Focus(focusNode: before, child: const SizedBox(height: 20)),
            Composer(
              controller: controller,
              autofocus: true,
              sources: const [],
              onPlanToggle: () => planToggles++,
              onSubmit: (_) async {},
            ),
            Focus(focusNode: after, child: const SizedBox(height: 20)),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    controller.value = const TextEditingValue(
      text: '```\nfoo\n```',
      selection: TextSelection.collapsed(offset: 4),
    );
    await tester.pump();
    expect(fieldHasFocus(tester), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(fieldHasFocus(tester), isFalse);
    await shiftTab(tester);
    expect(before.hasPrimaryFocus, isTrue);
    expect(planToggles, 0);
    expect(controller.text, '```\nfoo\n```');

    tester
        .state<EditableTextState>(find.byType(EditableText))
        .widget
        .focusNode
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(controller.text, '```\nfoo\n```');
    expect(fieldHasFocus(tester), isFalse);
    // The next stop is whatever follows the field (the composer's own
    // toolbar first), never the window's first control or nothing at all.
    final landed = FocusManager.instance.primaryFocus!;
    expect(landed, isNot(isA<FocusScopeNode>()));
    expect(landed, isNot(before));
    final field = tester.getRect(find.byType(EditableText));
    expect(landed.rect.top, greaterThanOrEqualTo(field.top));
  });

  testWidgets('Tab in prose leaves the draft alone', (tester) async {
    await pumpComposer(tester, 'hello', 5);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(controller.text, 'hello');
  });
}
