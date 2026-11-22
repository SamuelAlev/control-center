@TestOn('browser')
library;

import 'package:cc_domain/cc_domain.dart' show MessageDto, UserDto;
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/messaging/space_message_tile.dart';
import 'package:cc_remote/widgets/messaging/work_system_row.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'work_test_host.dart';

MessageDto _row(Map<String, dynamic> meta, {String content = ''}) => MessageDto(
  id: 'm1',
  content: content,
  senderId: 'system',
  senderType: 'system',
  messageType: 'system',
  metadata: meta,
  spaceId: 's1',
  conversationId: 'c1',
);

final _users = {'u1': UserDto(id: 'u1', handle: 'sam', displayName: 'Sam')};

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
    MessageDto message, {
    TextDirection? direction,
  }) => pumpWork(
    tester,
    SpaceMessageTile(
      message: message,
      workspaceId: ws,
      myUserId: 'u1',
      users: _users,
    ),
    overrides: workOverrides(rpc()),
    direction: direction,
  );

  test('only typed system rows are work rows', () {
    expect(isWorkSystemRow(_row({'kind': 'wake'})), isTrue);
    expect(isWorkSystemRow(_row({'kind': 'something_else'})), isFalse);
    expect(isWorkSystemRow(_row({})), isFalse);
    // A row of kind `wake_missed` does not exist; a missed slot is a skip.
    expect(workSystemRowKinds.contains('wake_missed'), isFalse);
  });

  testWidgets('a delivered wake takes its headline from wakeHeadline, never '
      'from the text', (tester) async {
    await pump(
      tester,
      _row({
        'kind': 'wake',
        'wakeIds': ['w1', 'w2'],
        'wakeReason': 'peer_reply',
        'wakeSourceAgentId': 'a2',
        'wakeHeadline': 'Reply **ready**',
        'wakeAgentId': 'a1',
      }, content: 'Woke Builder: [reply from Reviewer] English text'),
    );
    expect(find.text(l.workRowWoke(2, 'Builder')), findsOneWidget);
    expect(find.text(l.wakeOriginReplyFrom('Reviewer')), findsOneWidget);
    expect(find.text('Reply **ready**'), findsOneWidget);
    expect(find.textContaining('English text'), findsNothing);
  });

  testWidgets('a skipped wake names its kind; a missed slot is a skip of '
      'kind wake_missed', (tester) async {
    await pump(
      tester,
      _row({
        'kind': 'wake_skipped',
        'wakeSkipKind': 'agent_paused',
        'wakeReason': 'schedule',
        'wakeHeadline': 'Nightly check',
        'wakeAgentId': 'a1',
      }),
    );
    expect(find.text(l.workRowWakeSkipped('Builder')), findsOneWidget);
    expect(find.text(l.wakeKindAgentPaused), findsOneWidget);
    expect(find.text('Nightly check'), findsOneWidget);

    await pump(
      tester,
      _row({
        'kind': 'wake_skipped',
        'wakeSkipKind': 'wake_missed',
        'wakeReason': 'schedule',
        'wakeHeadline': 'Nightly check',
        'wakeAgentId': 'a1',
      }),
    );
    expect(find.text(l.workRowWakeMissed('Builder')), findsOneWidget);
    expect(find.text(l.wakeKindWakeMissed), findsNothing);

    await pump(
      tester,
      _row({
        'kind': 'wake_skipped',
        'wakeSkipKind': 'brand_new_kind',
        'wakeAgentId': 'gone',
      }),
    );
    expect(find.text(l.workRowWakeSkipped(l.agent)), findsOneWidget);
    expect(find.text(l.workKindUnknown), findsOneWidget);
    expect(find.text('brand_new_kind'), findsOneWidget);
  });

  testWidgets('a refused command reads its refusal kind; the text shows only '
      'without one', (tester) async {
    await pump(
      tester,
      _row({
        'kind': 'command_refused',
        'refusalKind': 'goal_already_active',
        'command': 'goal',
      }, content: 'English refusal'),
    );
    expect(find.text(l.workRowCommandRefusedNamed('/goal')), findsOneWidget);
    expect(find.text(l.goalRefusalAlreadyActive), findsOneWidget);
    expect(find.text('English refusal'), findsNothing);

    await pump(
      tester,
      _row({
        'kind': 'command_refused',
        'refusalKind': 'improvement_review_queued',
        'command': 'refine',
      }),
    );
    expect(find.text(l.improvementRefusalQueued), findsOneWidget);

    await pump(
      tester,
      _row({
        'kind': 'command_refused',
        'refusalKind': 'x_new',
        'command': 'loop',
      }),
    );
    expect(find.text(l.workRefusalUnknown), findsOneWidget);
    expect(find.text('x_new'), findsOneWidget);

    await pump(
      tester,
      _row({'kind': 'command_refused'}, content: 'No **objective** given'),
    );
    expect(find.text(l.workRowCommandRefused), findsOneWidget);
    expect(find.text('No **objective** given'), findsOneWidget);
  });

  testWidgets('a raised pipeline cap and an incomplete skill change', (
    tester,
  ) async {
    await pump(
      tester,
      _row({
        'kind': 'orchestration_cap_raised',
        'orchestration_id': 'o1',
        'old_micros': 5000000,
        'new_micros': 10000000,
        'user_id': 'u1',
      }),
    );
    expect(
      find.text(l.workRowCapRaised('Sam', r'$5.00', r'$10.00')),
      findsOneWidget,
    );

    await pump(
      tester,
      _row({
        'kind': 'improvement_apply_incomplete',
        'proposal_id': 'p1',
        'skill_slug': 'release-notes',
      }),
    );
    expect(find.text(l.workRowApplyIncomplete), findsOneWidget);
    expect(find.text('release-notes'), findsOneWidget);
  });

  testWidgets('schedule rows open the schedule', (tester) async {
    await pump(
      tester,
      _row({
        'kind': 'wake_rule_ended',
        'ruleId': 'r1',
        'endReason': 'run_cap',
        'agentId': 'a1',
      }),
    );
    expect(find.text(l.workRowScheduleEnded('Builder')), findsOneWidget);
    expect(find.text(l.wakeRuleEndRunCap), findsOneWidget);
    await tapLabel(tester, l.workRowOpenSchedule);
    expect(find.text('Opened /schedules/r1?workspace_id=$ws'), findsOneWidget);
  });

  testWidgets('a schedule created, a note from the agent and from a person, '
      'and a cap raised without amounts', (tester) async {
    await pump(
      tester,
      _row({'kind': 'wake_rule_created', 'ruleId': 'r1', 'agentId': 'a1'}),
    );
    expect(find.text(l.workRowScheduleCreated('Builder')), findsOneWidget);
    expect(find.text(l.workRowOpenSchedule), findsOneWidget);

    await pump(
      tester,
      _row({
        'kind': 'wake_rule_note',
        'ruleId': 'r1',
        'agentId': 'a1',
        'noteAuthor': 'agent',
      }, content: 'Check the **deploy**'),
    );
    expect(find.text(l.workRowNoteFromAgent('Builder')), findsOneWidget);
    expect(find.text('Check the **deploy**'), findsOneWidget);

    await pump(
      tester,
      _row({
        'kind': 'wake_rule_note',
        'ruleId': 'r1',
        'agentId': 'a1',
        'noteAuthor': 'person',
      }, content: 'Look at the logs'),
    );
    expect(find.text(l.workRowNoteFromPerson), findsOneWidget);

    await pump(
      tester,
      _row({'kind': 'orchestration_cap_raised', 'user_id': 'nobody'}),
    );
    expect(find.text(l.workRowCapRaisedNoAmounts(l.teammate)), findsOneWidget);
  });

  testWidgets('a paused schedule names who paused it', (tester) async {
    await pump(
      tester,
      _row({
        'kind': 'wake_rule_paused',
        'ruleId': 'r1',
        'agentId': 'a1',
        'pausedByUserId': 'u1',
      }, content: 'English row text'),
    );
    expect(
      find.text(l.workRowSchedulePaused('Sam', 'Builder')),
      findsOneWidget,
    );
    expect(find.text('English row text'), findsNothing);
    await tapLabel(tester, l.workRowOpenSchedule);
    expect(find.text('Opened /schedules/r1?workspace_id=$ws'), findsOneWidget);
  });

  testWidgets('a park row in the conversation carries its outcome', (
    tester,
  ) async {
    await pump(
      tester,
      _row({
        'kind': 'limit_park',
        'wakeId': 'w1',
        'provider': 'Anthropic',
        'resumesAt': DateTime.utc(2026, 11, 20, 14).toIso8601String(),
        'outcome': 'expired',
      }),
    );
    // Settled: only what came of it, not the old "Resumes at".
    expect(find.text(l.limitParkExpired('Anthropic')), findsOneWidget);
    expect(find.textContaining("Paused at Anthropic's"), findsNothing);

    await pump(
      tester,
      _row({
        'kind': 'limit_park',
        'wakeId': 'w1',
        'provider': 'Anthropic',
        'resumesAt': DateTime.utc(2026, 11, 20, 14).toIso8601String(),
      }),
    );
    expect(find.textContaining("Paused at Anthropic's"), findsOneWidget);
  });

  testWidgets('a plain system row keeps its text', (tester) async {
    await pump(tester, _row({}, content: 'Server notice'));
    expect(find.text(l.systemSender), findsOneWidget);
  });

  testWidgets('work rows lay out in RTL', (tester) async {
    await pump(
      tester,
      _row({
        'kind': 'command_refused',
        'refusalKind': 'x_new',
        'command': 'schedule',
      }),
      direction: TextDirection.rtl,
    );
    expect(
      find.text(l.workRowCommandRefusedNamed('/schedule')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
