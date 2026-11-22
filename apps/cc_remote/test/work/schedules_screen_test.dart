@TestOn('browser')
library;

import 'package:cc_domain/cc_domain.dart' show UserDto;
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/screens/schedules_screen.dart';
import 'package:cc_remote/work_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'work_test_host.dart';

final _at = DateTime.utc(2026, 11, 20, 10);

WakeRuleView _rule(
  String id, {
  WakeRuleStatus status = WakeRuleStatus.active,
  String trigger = 'every:30m',
  String triggerKind = 'every',
  bool canChange = true,
  String? owner = 'u1',
  WakeRuleEndReason? endReason,
  String note = 'Check the api-server deploy',
  WakeRuleOrigin noteAuthor = WakeRuleOrigin.person,
}) => WakeRuleView(
  id: id,
  workspaceId: ws,
  spaceId: 's1',
  conversationId: 'c1',
  agentId: 'a1',
  origin: WakeRuleOrigin.person,
  trigger: trigger,
  triggerKind: triggerKind,
  note: note,
  noteAuthor: noteAuthor,
  deliver: WakeDeliver.run,
  whenBusy: WakeWhenBusy.skip,
  runCount: 3,
  skipCount: 1,
  costMicros: 1500000,
  costCapMicros: 5000000,
  status: status,
  endReason: endReason,
  expiresAt: _at.add(const Duration(days: 7)),
  createdAt: _at,
  nextFireAt: status == WakeRuleStatus.active
      ? _at.add(const Duration(minutes: 30))
      : null,
  ownerUserId: owner,
  canChange: canChange,
  nextFires: const [],
);

void main() {
  late AppLocalizations l;
  WorkRpcHost? host;
  // Made inside each test's zone, so its streams run on the test's clock.
  WorkRpcHost rpc() => host ??= WorkRpcHost();

  setUpAll(() async => l = await english());
  setUp(() => host = null);
  tearDown(() => host?.close());

  Future<void> pump(
    WidgetTester tester,
    List<WakeRuleView> rules, {
    String? ruleId,
    TextDirection? direction,
  }) => pumpWork(
    tester,
    SchedulesScreen(ruleId: ruleId),
    scroll: false,
    direction: direction,
    overrides: [
      ...workOverrides(
        rpc(),
        users: {'u1': UserDto(id: 'u1', handle: 'sam', displayName: 'Sam')},
      ),
      phoneSchedulesProvider(ws).overrideWith((ref) => Stream.value(rules)),
    ],
  );

  testWidgets('empty: says how to start one', (tester) async {
    await pump(tester, const []);
    expect(find.text(l.schedulesEmpty), findsOneWidget);
    expect(find.text(l.schedulesEmptyDescription), findsOneWidget);
  });

  testWidgets('each row: trigger in words, agent, status, runs and money', (
    tester,
  ) async {
    await pump(tester, [
      _rule('r1'),
      _rule('r2', status: WakeRuleStatus.paused),
      _rule(
        'r3',
        status: WakeRuleStatus.ended,
        endReason: WakeRuleEndReason.costCap,
        trigger: 'on:pr_checks:acme/shop-ui#12',
        triggerKind: 'on_event',
      ),
      _rule('r4', trigger: 'next', triggerKind: 'self_paced'),
    ]);
    expect(find.text(l.scheduleEvery('30m')), findsNWidgets(2));
    expect(find.text(l.scheduleSelfPacedLoop), findsOneWidget);
    expect(find.text(l.scheduleWatch(l.scheduleWatchPrChecks)), findsOneWidget);
    expect(find.text(l.scheduleStatusActive), findsNWidgets(2));
    expect(find.text(l.scheduleStatusPaused), findsOneWidget);
    expect(find.text(l.scheduleStatusEnded), findsOneWidget);
    expect(find.text(l.wakeRuleEndCostCap), findsOneWidget);
    expect(find.text(l.scheduleWakes('Builder')), findsNWidgets(4));
    expect(find.text(l.scheduleRuns(3)), findsNWidgets(4));
    expect(find.text(l.goalMoney(r'$1.50', r'$5.00')), findsNWidgets(4));
    expect(find.text(l.scheduleSkipped(1)), findsNWidgets(4));
    // No trailing chevrons on rows.
    expect(find.byIcon(AppIcons.chevronRight), findsNothing);
  });

  testWidgets('pause, resume and delete send their ops', (tester) async {
    await pump(tester, [_rule('r1')]);
    await tapLabel(tester, l.schedulePause);
    expect(rpc().ops, ['wakeRules.pause']);
    expect(rpc().sent.last.args, {'workspace_id': ws, 'rule_id': 'r1'});

    await pump(tester, [_rule('r2', status: WakeRuleStatus.paused)]);
    await tapLabel(tester, l.scheduleResume);
    expect(rpc().ops.last, 'wakeRules.resume');

    await tapLabel(tester, l.scheduleDelete);
    expect(find.text(l.scheduleDeleteBody), findsOneWidget);
    await tapLabel(tester, l.scheduleDelete);
    expect(rpc().ops.last, 'wakeRules.delete');

    await pump(tester, [_rule('r3', status: WakeRuleStatus.ended)]);
    expect(find.text(l.schedulePause), findsNothing);
    await tapLabel(tester, l.scheduleRemove);
    await tapLabel(tester, l.scheduleRemove);
    expect(rpc().ops.last, 'wakeRules.delete');
  });

  testWidgets('resume shows only when the server says this viewer may', (
    tester,
  ) async {
    await pump(tester, [
      _rule('r1', status: WakeRuleStatus.paused, canChange: false),
    ]);
    expect(find.text(l.scheduleResume), findsNothing);
    expect(find.text(l.scheduleResumeNotYours), findsOneWidget);
    expect(find.text(l.scheduleDelete), findsOneWidget);

    await pump(tester, [
      _rule('r1', status: WakeRuleStatus.paused, canChange: false, owner: null),
    ]);
    expect(find.text(l.scheduleResumeAdminOnly), findsOneWidget);
  });

  testWidgets('a refusal shows its sentence', (tester) async {
    rpc().refuse = 'wake_not_yours';
    await pump(tester, [_rule('r1')]);
    await tapLabel(tester, l.schedulePause);
    expect(find.text(l.wakeRuleRefusalNotYours), findsOneWidget);
  });

  testWidgets('a row opens the schedule route; the detail shows the note '
      'and whom it acts for', (tester) async {
    await pump(tester, [_rule('r1')]);
    await tester.tap(find.text(l.scheduleWakes('Builder')));
    await tester.pumpAndSettle();
    expect(find.text('Opened /schedules/r1?workspace_id=$ws'), findsOneWidget);

    await pump(tester, [
      _rule('r1', noteAuthor: WakeRuleOrigin.agent),
    ], ruleId: 'r1');
    expect(find.text(l.scheduleNoteAgent), findsOneWidget);
    expect(find.text('Check the api-server deploy'), findsOneWidget);
    expect(find.text(l.scheduleActsFor('Sam')), findsOneWidget);
    expect(find.text(l.scheduleOpenConversation), findsOneWidget);

    await pump(tester, [_rule('r1')], ruleId: 'gone');
    expect(find.text(l.scheduleMissing), findsOneWidget);
  });

  testWidgets('right to left: badges sit at the start-opposite edge', (
    tester,
  ) async {
    await pump(tester, [_rule('r1')], direction: TextDirection.rtl);
    expect(tester.takeException(), isNull);
    final title = tester.getRect(find.text(l.scheduleEvery('30m')));
    final badge = tester.getRect(find.text(l.scheduleStatusActive));
    expect(badge.right, lessThan(title.left + 1));
  });
}
