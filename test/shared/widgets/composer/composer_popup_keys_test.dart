import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/slash_command_source.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

/// Enter and Tab while the suggestion popup is open pick the highlighted row
/// and do nothing else.
///
/// The popup hears the key first (a `HardwareKeyboard` handler) and closes
/// itself on the pick; the field's own `Focus.onKeyEvent` then hears the same
/// key with the popup already closed. That second hearing used to send the
/// half-typed draft (Enter) or move focus off the field (Tab).
void main() {
  late ComposerTextController controller;
  late List<ComposerSubmission> submitted;

  setUp(() {
    controller = ComposerTextController();
    submitted = [];
  });

  tearDown(() => controller.dispose());

  bool fieldHasFocus(WidgetTester tester) => tester
      .state<EditableTextState>(find.byType(EditableText))
      .widget
      .focusNode
      .hasFocus;

  Future<void> pumpComposer(WidgetTester tester) async {
    await tester.pumpWidget(
      testWrap(
        Align(
          alignment: Alignment.bottomCenter,
          child: Composer(
            controller: controller,
            autofocus: true,
            sources: [
              SlashCommandSource(const [
                SlashCommand(name: 'goal', description: 'Work toward a goal'),
                SlashCommand(name: 'plan', description: 'Plan first'),
              ]),
            ],
            onSubmit: (s) async => submitted.add(s),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> type(WidgetTester tester, String text) async {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(key);
    await tester.sendKeyUpEvent(key);
    await tester.pump();
  }

  testWidgets('Enter picks the highlighted command and sends nothing', (
    tester,
  ) async {
    await pumpComposer(tester);
    await type(tester, '/goa');
    expect(find.text('/goal'), findsOneWidget);

    await press(tester, LogicalKeyboardKey.enter);

    expect(controller.text, '/goal ');
    expect(submitted, isEmpty);
    expect(fieldHasFocus(tester), isTrue);

    // The next Enter, with the popup closed, is an ordinary send.
    await type(tester, '/goal ship it');
    await press(tester, LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 50));
    expect(submitted.map((s) => s.text), ['/goal ship it']);
  });

  testWidgets('Tab picks the highlighted command and keeps the field focused', (
    tester,
  ) async {
    await pumpComposer(tester);
    await type(tester, '/pl');
    expect(find.text('/plan'), findsOneWidget);

    await press(tester, LogicalKeyboardKey.tab);

    expect(controller.text, '/plan ');
    expect(submitted, isEmpty);
    expect(fieldHasFocus(tester), isTrue);
  });

  testWidgets('the platform send action for the picking Enter sends nothing', (
    tester,
  ) async {
    await pumpComposer(tester);
    await type(tester, '/goa');

    // The web also reports Enter as the field's send action, from its own
    // keydown listener, after the key event and inside the same key press.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.text, '/goal ');
    expect(submitted, isEmpty);
  });

  testWidgets('a send action that arrives before the picking key is refused', (
    tester,
  ) async {
    await pumpComposer(tester);
    await type(tester, '/goa');

    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.text, '/goa');
    expect(submitted, isEmpty);
  });

  testWidgets('Escape closes the popup and keeps the field focused', (
    tester,
  ) async {
    await pumpComposer(tester);
    await type(tester, '/goa');
    expect(find.text('/goal'), findsOneWidget);

    await press(tester, LogicalKeyboardKey.escape);

    expect(find.text('/goal'), findsNothing);
    expect(controller.text, '/goa');
    expect(submitted, isEmpty);
    expect(fieldHasFocus(tester), isTrue);
  });

  testWidgets('Enter with no row to pick sends the draft as typed', (
    tester,
  ) async {
    await pumpComposer(tester);
    await type(tester, '/zzz');

    await press(tester, LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 50));

    expect(submitted.map((s) => s.text), ['/zzz']);
  });

  testWidgets('a held Enter picks once and does not send on its repeats', (
    tester,
  ) async {
    await pumpComposer(tester);
    await type(tester, '/goa');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(controller.text, '/goal ');
    expect(submitted, isEmpty);
  });
}
