import 'package:control_center/features/messaging/presentation/widgets/composer/wake_command_sources.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/composer_command_strip.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/composer_command_strip_parts.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/slash_command_source.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

/// `/schedule` and `/loop` are written step by step in the composer's own
/// suggestion list: the command, when it fires, then the prompt, with the
/// limits on a dash.
void main() {
  late ComposerTextController controller;
  late FocusNode focus;
  late List<ComposerSubmission> submitted;
  final l10n = AppLocalizationsEn();
  final noon = DateTime(2026, 11, 20, 12);
  // The list sets its section headings in capitals.
  final whenHeader = l10n.scheduleWhenLabel.toUpperCase();

  setUp(() {
    controller = ComposerTextController();
    focus = FocusNode();
    submitted = [];
  });

  tearDown(() {
    controller.dispose();
    focus.dispose();
  });

  Future<void> pumpComposer(WidgetTester tester) async {
    await tester.pumpWidget(
      testWrap(
        Align(
          alignment: Alignment.bottomCenter,
          child: Composer(
            controller: controller,
            focusNode: focus,
            autofocus: true,
            banner: ComposerCommandStrip(
              spaceId: 'sp-1',
              conversationId: 'conv-1',
              controller: controller,
              focusNode: focus,
            ),
            sources: [
              SlashCommandSource(const [
                SlashCommand(name: 'schedule', description: 'Run a task later'),
                SlashCommand(name: 'loop', description: 'Repeat a task'),
              ]),
              WakeArgumentSource.when(
                l10n: l10n,
                timeLabel: (at) =>
                    '${at.hour.toString().padLeft(2, '0')}:'
                    '${at.minute.toString().padLeft(2, '0')}',
                now: () => noon,
              ),
              WakeArgumentSource.option(l10n: l10n),
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
    await tester.pump();
  }

  testWidgets('picking /schedule goes straight on to when it fires', (
    tester,
  ) async {
    await pumpComposer(tester);
    await type(tester, '/sch');
    await press(tester, LogicalKeyboardKey.enter);

    expect(controller.text, '/schedule ');
    expect(find.text(whenHeader), findsOneWidget);
    expect(find.text('in 30m'), findsOneWidget);
    expect(find.text('Once, 12:30'), findsOneWidget);
    expect(find.text('Once, 09:00'), findsOneWidget);
    expect(find.text('Weekdays at 09:00'), findsOneWidget);
    // The list is the one talking: the strip does not repeat its heading.
    expect(find.byType(CommandStripFrame), findsNothing);

    // The second row, then Enter: the when is written and the list closes.
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.enter);
    expect(controller.text, '/schedule in 2h ');
    expect(find.text(whenHeader), findsNothing);
    expect(submitted, isEmpty);
    // The strip reads the when back and names what is left.
    expect(find.textContaining('Once, '), findsOneWidget);
    expect(find.text('What each run starts from'), findsOneWidget);

    // The prompt, then Enter sends the command as ordinary text.
    await type(tester, '/schedule in 2h check the deploy');
    await press(tester, LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 50));
    expect(submitted.map((s) => s.text), ['/schedule in 2h check the deploy']);
  });

  testWidgets('a held Enter picks the command and stops there', (tester) async {
    await pumpComposer(tester);
    await type(tester, '/sch');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(controller.text, '/schedule ');
    expect(find.text(whenHeader), findsOneWidget);
    expect(submitted, isEmpty);
  });

  testWidgets('typing narrows the when, and its row says what it means', (
    tester,
  ) async {
    await pumpComposer(tester);
    await type(tester, '/schedule in 4');

    expect(find.text('in 4m'), findsOneWidget);
    expect(find.text('Once, 16:00'), findsOneWidget);
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.tab);
    expect(controller.text, '/schedule in 4h ');
  });

  testWidgets('a /loop offers how often, and takes a prompt instead', (
    tester,
  ) async {
    await pumpComposer(tester);
    await type(tester, '/loop ');
    expect(find.text('every 30m'), findsOneWidget);
    expect(find.text('Every 30m'), findsOneWidget);

    await type(tester, '/loop keep the build green');
    expect(find.text('every 30m'), findsNothing);
    await press(tester, LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 50));
    expect(submitted.map((s) => s.text), ['/loop keep the build green']);
  });

  testWidgets('a dash after the when offers the limits', (tester) async {
    await pumpComposer(tester);
    await type(tester, '/schedule in 2h --');

    expect(find.text('--max'), findsOneWidget);
    expect(find.text('Run cap'), findsOneWidget);
    expect(find.text('Cost cap (dollars)'), findsOneWidget);
    await press(tester, LogicalKeyboardKey.enter);
    expect(controller.text, '/schedule in 2h --max ');
    expect(submitted, isEmpty);
  });

  testWidgets('the list floats above the strip instead of covering it', (
    tester,
  ) async {
    await pumpComposer(tester);
    await type(tester, '/schedule in 2h --');

    final strip = tester.getRect(find.byType(CommandStripFrame));
    final row = tester.getRect(find.text('Run cap'));
    expect(row.bottom, lessThanOrEqualTo(strip.top));
    expect(find.textContaining('Once, '), findsOneWidget);
  });

  testWidgets('Escape closes a step without leaving the field', (tester) async {
    await pumpComposer(tester);
    await type(tester, '/schedule ');
    expect(find.text(whenHeader), findsOneWidget);

    await press(tester, LogicalKeyboardKey.escape);

    expect(find.text(whenHeader), findsNothing);
    expect(controller.text, '/schedule ');
    final field = tester.state<EditableTextState>(find.byType(EditableText));
    expect(field.widget.focusNode.hasFocus, isTrue);
  });
}
