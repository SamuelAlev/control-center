import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/composer_command_strip.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/composer_command_strip_parts.dart';
import 'package:control_center/features/messaging/providers/composer_command_refusal.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/active_workspace.dart';
import '../../../../../helpers/test_wrap.dart';

const _key = (spaceId: 'sp-1', conversationId: 'conv-1');

void main() {
  late TextEditingController controller;
  late FocusNode focus;
  late ProviderContainer container;

  /// What the server answers a cron preview with; empty until it "answers".
  var fires = <DateTime>[];

  setUp(() {
    controller = TextEditingController();
    focus = FocusNode();
    fires = [];
  });

  tearDown(() {
    controller.dispose();
    focus.dispose();
  });

  Future<void> pumpStrip(
    WidgetTester tester, {
    TextDirection? textDirection,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          cronPreviewProvider.overrideWith(
            (ref, key) async => (nextFires: fires, zoneKnown: true),
          ),
        ],
        child: testWrap(
          textDirection: textDirection,
          Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ComposerCommandStrip(
                    spaceId: _key.spaceId,
                    conversationId: _key.conversationId,
                    controller: controller,
                    focusNode: focus,
                  ),
                  Focus(focusNode: focus, child: const SizedBox(height: 10)),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> write(WidgetTester tester, String text) async {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    await tester.pump();
    await tester.pump();
  }

  bool refused() => container.read(composerCommandRefusalProvider(_key));

  IconData stripIcon(WidgetTester tester) =>
      tester.widget<CommandStripFrame>(find.byType(CommandStripFrame)).icon;

  testWidgets('shows nothing for an ordinary draft', (tester) async {
    await pumpStrip(tester);
    await write(tester, 'please look at the failing test');
    expect(find.byType(CommandStripFrame), findsNothing);
    await write(tester, '/plan the migration');
    expect(find.byType(CommandStripFrame), findsNothing);
  });

  testWidgets('steps aside while the suggestion list offers the step', (
    tester,
  ) async {
    await pumpStrip(tester);
    // The name is still being written: the list offers the commands.
    await write(tester, '/schedule');
    expect(find.byType(CommandStripFrame), findsNothing);
    await write(tester, '/loop');
    expect(find.byType(CommandStripFrame), findsNothing);
    // The caret is on the when: the list offers its forms.
    await write(tester, '/schedule ');
    expect(find.byType(CommandStripFrame), findsNothing);
    await write(tester, '/schedule in 4');
    expect(find.byType(CommandStripFrame), findsNothing);

    // The caret left the when: the list is gone, the strip speaks.
    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();
    expect(find.text('When it fires'), findsOneWidget);
  });

  testWidgets('a when that fits no form names the step and offers the forms', (
    tester,
  ) async {
    await pumpStrip(tester);
    await write(tester, '/schedule tomorrow');

    expect(find.text('When it fires'), findsOneWidget);
    expect(find.byType(CommandStripToken), findsNWidgets(3));
    expect(stripIcon(tester), AppIcons.calendarClock);

    await tester.tap(find.text('at 09:00'));
    await tester.pump();
    expect(controller.text, '/schedule at 09:00 ');
    expect(controller.selection.baseOffset, controller.text.length);
    expect(focus.hasFocus, isTrue);
    expect(find.byType(CommandStripToken), findsNothing);
  });

  testWidgets('a token goes in front of words already past the when', (
    tester,
  ) async {
    await pumpStrip(tester);
    await write(tester, '/schedule tomorrow check the deploy');
    await tester.tap(find.text('in 2h'));
    await tester.pump();
    expect(controller.text, '/schedule in 2h tomorrow check the deploy');
    expect(controller.selection.baseOffset, '/schedule in 2h '.length);
  });

  testWidgets('reads the when back and names the prompt as what is left', (
    tester,
  ) async {
    await pumpStrip(tester);
    await write(tester, '/schedule in 2h ');
    expect(find.textContaining('Once, '), findsOneWidget);
    expect(find.text('What each run starts from'), findsOneWidget);
    expect(find.byType(CommandStripToken), findsNothing);

    await write(tester, '/schedule in 2h check the deploy');
    expect(find.textContaining('Once, '), findsOneWidget);
    expect(find.text('What each run starts from'), findsNothing);
    // One run: no end date to state.
    expect(find.textContaining('Ends '), findsNothing);
  });

  testWidgets('a loop reads as its pace and says when it ends', (tester) async {
    await pumpStrip(tester);
    await write(tester, '/loop every 30m keep the build green');
    expect(find.text('Every 30m'), findsOneWidget);
    expect(find.textContaining('Ends '), findsOneWidget);
    expect(stripIcon(tester), AppIcons.repeat);

    await write(tester, '/loop keep the build green');
    expect(
      find.text('When the agent chooses, 1 to 60 minutes apart'),
      findsOneWidget,
    );
  });

  testWidgets('a part still being written is a hint, one left behind is '
      'named, and a refused Enter says it as a warning', (tester) async {
    await pumpStrip(tester);
    await write(tester, '/loop every ');
    expect(find.textContaining("isn't a duration"), findsNothing);
    await write(tester, '/loop --max ');
    expect(find.text('Run cap'), findsOneWidget);
    expect(find.text('1 to 500 runs.'), findsNothing);

    await write(tester, '/schedule in soon check');
    expect(find.textContaining("isn't a duration"), findsOneWidget);
    expect(stripIcon(tester), AppIcons.calendarClock);

    final sent = container
        .read(composerCommandRefusalProvider(_key).notifier)
        .check(controller.text);
    await tester.pump();
    expect(sent, isFalse);
    expect(stripIcon(tester), AppIcons.triangleAlert);
    final ds = DesignSystemTokens.light();
    final sentence = tester.widget<Text>(
      find.textContaining("isn't a duration"),
    );
    expect(sentence.style!.color, ds.textPrimary);

    // Fixing the draft ends the refusal; the next mistake is a hint again.
    await write(tester, '/schedule in 2h check');
    expect(refused(), isFalse);
    expect(stripIcon(tester), AppIcons.calendarClock);
  });

  testWidgets('says what the server would refuse: pace, time, ranges', (
    tester,
  ) async {
    await pumpStrip(tester);
    await write(tester, '/loop every 30s check');
    expect(find.textContaining('at least 60 s apart'), findsOneWidget);
    await write(tester, '/schedule at noonish check');
    expect(find.textContaining("isn't a time ahead"), findsOneWidget);
    await write(tester, '/schedule cron "0 9 * *" check');
    expect(find.textContaining("isn't a five-field cron"), findsOneWidget);
    await write(tester, '/loop --max 9999 check');
    expect(find.text('1 to 500 runs.'), findsOneWidget);
    await write(tester, '/loop --days 999 check');
    expect(find.text('1 to 365 days.'), findsOneWidget);
    await write(tester, '/loop --budget nothing check');
    expect(find.textContaining('At least 1 dollar'), findsOneWidget);
  });

  testWidgets('an unknown option offers the real ones in its place', (
    tester,
  ) async {
    await pumpStrip(tester);
    await write(tester, '/loop every 5m --max 3 --fast check');
    expect(find.text("--fast isn't an option."), findsOneWidget);
    expect(find.text('--max'), findsNothing, reason: 'already written');

    await tester.tap(find.text('--days'));
    await tester.pump();
    expect(controller.text, '/loop every 5m --max 3 --days check');
    expect(
      controller.selection.baseOffset,
      '/loop every 5m --max 3 --days '.length,
    );
  });

  testWidgets('the limits control writes an option before the prompt', (
    tester,
  ) async {
    await pumpStrip(tester);
    await write(tester, '/schedule in 2h --days 3 check the deploy');
    await tester.tap(find.byType(CommandLimitsMenu));
    await tester.pumpAndSettle();
    expect(find.text('Ends after (days)'), findsNothing);

    await tester.tap(find.text('Run cap'));
    await tester.pumpAndSettle();
    expect(controller.text, '/schedule in 2h --days 3 --max check the deploy');
    expect(
      controller.selection.baseOffset,
      '/schedule in 2h --days 3 --max '.length,
    );

    // Nothing to offer while a part is missing or wrong.
    await write(tester, '/schedule ');
    expect(find.byType(CommandLimitsMenu), findsNothing);
  });

  testWidgets('a cron and a wall clock are placed in time by the server', (
    tester,
  ) async {
    await pumpStrip(tester);
    await write(tester, '/schedule at 09:00 standup notes');
    expect(find.text('Once, 09:00'), findsOneWidget);
    await write(tester, '/schedule cron "0 9 * * 1-5" triage');
    expect(find.text('On a cron schedule'), findsOneWidget);

    final tomorrow = DateTime.now().toUtc().add(const Duration(days: 1));
    fires = [tomorrow, tomorrow.add(const Duration(days: 1))];
    container.invalidate(cronPreviewProvider);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Next: '), findsOneWidget);

    await write(tester, '/schedule at 09:00 standup notes');
    await tester.pump();
    // Tomorrow's, as the server placed it: with its day.
    expect(find.textContaining('Once, '), findsOneWidget);
    expect(find.text('Once, 09:00'), findsNothing);
  });

  testWidgets('a /goal speaks only once it was refused', (tester) async {
    await pumpStrip(tester);
    await write(tester, '/goal --checker');
    expect(find.byType(CommandStripFrame), findsNothing);

    container
        .read(composerCommandRefusalProvider(_key).notifier)
        .check(controller.text);
    await tester.pump();
    expect(find.byType(CommandStripFrame), findsOneWidget);
    expect(stripIcon(tester), AppIcons.triangleAlert);

    await write(tester, '/goal ship the release');
    expect(find.byType(CommandStripFrame), findsNothing);
    expect(refused(), isFalse);
  });

  testWidgets('lays out right to left', (tester) async {
    await pumpStrip(tester, textDirection: TextDirection.rtl);
    await write(tester, '/schedule tomorrow');
    expect(tester.takeException(), isNull);
    final icon = tester.getCenter(find.byIcon(AppIcons.calendarClock));
    final label = tester.getCenter(find.text('When it fires'));
    expect(icon.dx, greaterThan(label.dx));
    // Command text itself stays left to right.
    final token = tester.widget<Directionality>(
      find
          .ancestor(
            of: find.text('in 2h'),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(token.textDirection, TextDirection.ltr);
  });
}
