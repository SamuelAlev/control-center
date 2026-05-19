import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

/// Terminal-style ↑/↓ prompt recall (see [Composer.history]): ArrowUp walks
/// backwards through the host-supplied history, ArrowDown forwards, and
/// stepping past the newest restores the draft parked on first ArrowUp.
///
/// Key events go through `sendKeyDownEvent`, which dispatches the same
/// HardwareKeyboard → focus-chain path a real keypress takes, so these tests
/// exercise the `Focus.onKeyEvent` interception itself — including that a
/// consumed ArrowUp never reaches the framework's default arrow→caret
/// shortcuts.
void main() {
  late ComposerTextController controller;
  late List<ComposerSubmission> submitted;
  List<String> history = const ['first prompt', 'second prompt'];
  String? historyKey;

  setUp(() {
    controller = ComposerTextController();
    submitted = [];
    history = const ['first prompt', 'second prompt'];
    historyKey = 'conv';
  });

  tearDown(() => controller.dispose());

  Future<void> pumpComposer(WidgetTester tester) async {
    await tester.pumpWidget(
      testWrap(
        Align(
          alignment: Alignment.bottomCenter,
          child: Composer(
            controller: controller,
            autofocus: true,
            sources: const [],
            history: history,
            historyKey: historyKey,
            onSubmit: (s) async => submitted.add(s),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(key);
    await tester.sendKeyUpEvent(key);
    await tester.pump();
  }

  /// Replaces the draft with [text], caret at [caret] (end of the text when
  /// null).
  Future<void> draft(
    WidgetTester tester,
    String text, {
    int? caret,
  }) async {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret ?? text.length),
    );
    await tester.pump();
  }

  testWidgets('ArrowUp recalls the newest prompt and walks back, clamping at the oldest', (tester) async {
    await pumpComposer(tester);

    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(controller.text, 'second prompt');

    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(controller.text, 'first prompt');

    // At the oldest entry, one more up stays put — like a shell.
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(controller.text, 'first prompt');

    // A recalled prompt is editable from its tip.
    expect(
      controller.selection.baseOffset,
      controller.text.length,
      reason: 'the caret should sit at the end of the recalled prompt',
    );
  });

  testWidgets('ArrowDown walks forward and past the newest restores the parked draft', (tester) async {
    await pumpComposer(tester);
    await draft(tester, 'a brand new draft');

    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(controller.text, 'second prompt');
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(controller.text, 'first prompt');

    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(controller.text, 'second prompt');

    // Past the newest entry: back to what was being composed.
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(controller.text, 'a brand new draft');

    // Leaving browsing means Down is a caret key again, not a recall.
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(controller.text, 'a brand new draft');
  });

  testWidgets('ArrowUp enters history from the first line of a draft, not from later lines', (tester) async {
    await pumpComposer(tester);
    await draft(tester, 'line one\nline two');

    // Caret on the second line: ArrowUp still belongs to the caret.
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(controller.text, 'line one\nline two');

    // Caret on the first line: ArrowUp recalls.
    await draft(tester, 'line one\nline two', caret: 'line one'.length);
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(controller.text, 'second prompt');
    // The multiline draft was parked, so Down past the end brings it back.
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(controller.text, 'line one\nline two');
  });

  testWidgets('Escape abandons a recall and restores the draft', (tester) async {
    await pumpComposer(tester);
    await draft(tester, 'keep me');

    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(controller.text, 'second prompt');

    await press(tester, LogicalKeyboardKey.escape);
    expect(controller.text, 'keep me');

    // Browsing is over: the next Up starts from the newest again.
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(controller.text, 'second prompt');
  });

  testWidgets('Enter sends the recalled prompt and resets the browsing position', (tester) async {
    await pumpComposer(tester);

    await press(tester, LogicalKeyboardKey.arrowUp);
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(controller.text, 'first prompt');

    await press(tester, LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 50));

    expect(submitted, hasLength(1));
    expect(submitted.single.text, 'first prompt');
    expect(controller.text, isEmpty);

    // A submitted prompt is history, not a browsing position: the next recall
    // starts from the newest entry again.
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(controller.text, 'second prompt');
  });

  testWidgets('modifier chords keep their text-editing meaning', (tester) async {
    await pumpComposer(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    expect(controller.text, isEmpty, reason: 'Shift+Up must extend the selection, not recall');
  });

  testWidgets('without a history, ArrowUp does nothing', (tester) async {
    history = const [];
    await pumpComposer(tester);
    await draft(tester, 'just typing');

    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(controller.text, 'just typing');
  });

  testWidgets('a historyKey change resets the browsing position', (tester) async {
    await pumpComposer(tester);
    await press(tester, LogicalKeyboardKey.arrowUp);
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(controller.text, 'first prompt');

    // The same composer element now serves another conversation.
    history = const ['other a', 'other b'];
    historyKey = 'conv-2';
    await pumpComposer(tester);

    // The position picked in the old conversation must not index into the new
    // one: the first Up recalls the NEW conversation's newest prompt.
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(controller.text, 'other b');
  });
}
