import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/system_message.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_items.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_system_row.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/active_workspace.dart';
import '../../../../../helpers/test_wrap.dart';
import 'work_test_harness.dart';

Message _row(
  Map<String, dynamic> metadata, {
  String id = 'r-1',
  String content = 'server text',
  bool compacted = false,
}) => Message(
  id: id,
  spaceId: 'sp-1',
  conversationId: 'conv-1',
  senderId: 'system',
  senderType: SenderType.system,
  content: content,
  messageType: MessageType.system,
  metadata: metadata,
  compacted: compacted,
  createdAt: DateTime(2026, 11, 19, 10),
);

Map<String, dynamic> _limitPark() => {
  'kind': 'limit_park',
  'wakeId': 'wk-limit',
  'runId': 'run-1',
  'agentId': 'agent-2',
  'provider': 'Anthropic',
  'resetsAt': '2026-11-20T14:30:00Z',
  'resumesAt': '2026-11-20T14:30:30Z',
  'requestedByUserId': 'u-1',
};

void main() {
  late FakeWakesRepository wakes;

  setUp(() => wakes = FakeWakesRepository());

  Future<void> pump(
    WidgetTester tester,
    Message message, {
    List<WakeView> wakeList = const [],
    List<Message> feed = const [],
    TextDirection? textDirection,
  }) async {
    // A fresh scope per pump: overrides never carry over.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            ...workOverrides(wakes: wakes, wakeList: wakeList),
            spaceFeedWindowedProvider.overrideWith(
              (ref, key) => Stream.value((messages: feed, hasMore: false)),
            ),
          ],
          child: SingleChildScrollView(child: WorkSystemRow(message: message)),
        ),
        textDirection: textDirection,
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  test('only work kinds and still-in-flight rows are work rows', () {
    expect(isWorkSystemRow(_row({'kind': 'wake'})), isTrue);
    expect(isWorkSystemRow(_row({'stillInFlightFor': 'agent-2'})), isTrue);
    expect(isWorkSystemRow(_row({'kind': 'something_else'})), isFalse);
    // A missed slot is a skipped wake; no row kind `wake_missed` exists.
    expect(isWorkSystemRow(_row({'kind': 'wake_missed'})), isFalse);
    expect(isWorkSystemRow(_row({'kind': 'orchestration_cap_raised'})), isTrue);
    expect(isWorkSystemRow(_row(const {})), isFalse);
  });

  testWidgets('a delivered wake names the agent, the origin and the headline', (
    tester,
  ) async {
    await pump(
      tester,
      _row({
        'kind': 'wake',
        'wakeIds': ['a', 'b'],
        'wakeReason': WakeReason.peerReply.wire,
        'wakeAgentId': 'agent-2',
        'wakeSourceAgentId': 'agent-3',
        'wakeHeadline': 'Ben answered your question',
      }, content: 'Woke Ada: [reply] something else entirely (and 1 more)'),
    );
    expect(find.text('Woke Ada for 2 waiting items'), findsOneWidget);
    expect(find.text('Reply from Ben'), findsOneWidget);
    // The headline comes from the metadata, never parsed from the text.
    expect(find.text('Ben answered your question'), findsOneWidget);
    expect(find.textContaining('something else'), findsNothing);
  });

  testWidgets('a wake row without a headline shows none', (tester) async {
    await pump(
      tester,
      _row({
        'kind': 'wake',
        'wakeIds': ['a'],
        'wakeReason': 'schedule',
        'wakeAgentId': 'agent-2',
      }, content: 'Woke Ada: [schedule] parsed from text'),
    );
    expect(find.text('Woke Ada'), findsOneWidget);
    expect(find.textContaining('parsed from text'), findsNothing);
  });

  testWidgets('a skipped wake shows its headline under the reason', (
    tester,
  ) async {
    await pump(
      tester,
      _row({
        'kind': 'wake_skipped',
        'wakeReason': 'schedule',
        'wakeSkipKind': 'agent_paused',
        'wakeAgentId': 'agent-2',
        'wakeHeadline': '**check** the \u001b[2Jdeploy',
      }),
    );
    expect(find.text('The agent is paused.'), findsOneWidget);
    expect(find.text('**check** the \uFFFD[2Jdeploy'), findsOneWidget);
  });

  testWidgets('a skipped wake says why; an unknown kind shows it raw', (
    tester,
  ) async {
    await pump(
      tester,
      _row({
        'kind': 'wake_skipped',
        'wakeId': 'w',
        'wakeReason': 'schedule',
        'wakeSkipKind': 'agent_deleted',
        'wakeAgentId': 'agent-2',
      }),
    );
    expect(find.text('A wake for Ada was not delivered.'), findsOneWidget);
    expect(find.text('The agent no longer exists.'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);

    await pump(
      tester,
      _row({
        'kind': 'wake_skipped',
        'wakeReason': 'schedule',
        'wakeSkipKind': 'novel_kind',
        'wakeAgentId': 'nobody',
      }),
    );
    expect(find.text('A wake for an agent was not delivered.'), findsOneWidget);
    expect(find.text('novel_kind'), findsOneWidget);
  });

  testWidgets('a missed wake has its own sentence', (tester) async {
    await pump(
      tester,
      _row({
        'kind': 'wake_skipped',
        'wakeReason': 'schedule',
        'wakeSkipKind': 'wake_missed',
        'wakeAgentId': 'agent-2',
      }),
    );
    expect(
      find.text('A wake for Ada was missed while the server was down.'),
      findsOneWidget,
    );
  });

  testWidgets('schedule created and ended rows link the schedule', (
    tester,
  ) async {
    await pump(
      tester,
      _row({
        'kind': 'wake_rule_created',
        'ruleId': 'rule-1',
        'agentId': 'agent-2',
      }),
    );
    expect(find.text('Schedule set for Ada.'), findsOneWidget);
    expect(tip('Open schedule'), findsOneWidget);

    await pump(
      tester,
      _row({
        'kind': 'wake_rule_ended',
        'ruleId': 'rule-1',
        'endReason': 'cost_cap',
        'agentId': 'agent-2',
      }),
    );
    expect(find.text('The schedule for Ada ended.'), findsOneWidget);
    expect(find.text('It reached its cost cap.'), findsOneWidget);
  });

  testWidgets('a paused schedule names who paused it, and links it', (
    tester,
  ) async {
    await pump(
      tester,
      _row({
        'kind': 'wake_rule_paused',
        'ruleId': 'rule-1',
        'agentId': 'agent-2',
        'pausedByUserId': 'u-2',
      }),
    );
    expect(find.text('Grace paused the schedule for Ada.'), findsOneWidget);
    expect(tip('Open schedule'), findsOneWidget);

    await pump(
      tester,
      _row({
        'kind': 'wake_rule_paused',
        'agentId': 'agent-2',
        'pausedByUserId': 'u-unknown',
      }),
    );
    expect(find.text('A person paused the schedule for Ada.'), findsOneWidget);
    expect(tip('Open schedule'), findsNothing);
  });

  testWidgets('right to left: the paused row leads from the right edge', (
    tester,
  ) async {
    await pump(
      tester,
      _row({
        'kind': 'wake_rule_paused',
        'ruleId': 'rule-1',
        'agentId': 'agent-2',
        'pausedByUserId': 'u-2',
      }),
      textDirection: TextDirection.rtl,
    );
    final text = tester.getCenter(
      find.text('Grace paused the schedule for Ada.'),
    );
    final open = tester.getCenter(tip('Open schedule'));
    expect(open.dx, lessThan(text.dx));
  });

  testWidgets("an agent's note is its own words, quoted and inert", (
    tester,
  ) async {
    await pump(
      tester,
      _row(
        {
          'kind': 'wake_rule_note',
          'ruleId': 'rule-1',
          'wakeId': 'w',
          'agentId': 'agent-2',
          'noteAuthor': 'agent',
        },
        content:
            'Ada left a note for every 30m, in its own words:\n\n'
            '> check [the deploy](https://evil.test)\n> \u001b[2Jthen report',
      ),
    );
    expect(
      find.text('Ada left this note for itself, in its own words:'),
      findsOneWidget,
    );
    expect(
      find.text('check [the deploy](https://evil.test)\n\uFFFD[2Jthen report'),
      findsOneWidget,
    );

    await pump(
      tester,
      _row({
        'kind': 'wake_rule_note',
        'ruleId': 'rule-1',
        'noteAuthor': 'person',
      }, content: 'A reminder a person set for 09:00:\n\n> stand-up notes'),
    );
    expect(find.text('A reminder a person set:'), findsOneWidget);
    expect(find.text('stand-up notes'), findsOneWidget);
  });

  testWidgets('limit card, held and mine: Resume releases, Cancel cancels', (
    tester,
  ) async {
    await pump(
      tester,
      _row(_limitPark()),
      wakeList: [
        wakeView(
          id: 'wk-limit',
          reason: WakeReason.limitReset,
          state: WakeState.held,
          stateReason: 'limit',
        ),
      ],
    );
    expect(
      find.textContaining(
        "Paused at Anthropic's usage limit. The limit resets at",
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Resume'));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(wakes.calls, [
      'release:$kTestWorkspaceId:wk-limit',
      'cancel:$kTestWorkspaceId:wk-limit',
    ]);
  });

  testWidgets("limit card, held and someone else's: no Resume, Cancel stays", (
    tester,
  ) async {
    await pump(
      tester,
      _row(_limitPark()),
      wakeList: [
        wakeView(
          id: 'wk-limit',
          reason: WakeReason.limitReset,
          state: WakeState.held,
          canRelease: false,
        ),
      ],
    );
    expect(find.text('Resume'), findsNothing);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('limit card, released: resumes at its time', (tester) async {
    await pump(
      tester,
      _row(_limitPark()),
      wakeList: [wakeView(id: 'wk-limit', reason: WakeReason.limitReset)],
    );
    expect(
      find.textContaining("Paused at Anthropic's usage limit. Resumes at"),
      findsOneWidget,
    );
    expect(find.text('Resume'), findsNothing);
  });

  testWidgets('limit card, settled: reads its outcome from the row, with '
      'no actions even while the wake is still listed', (tester) async {
    Map<String, dynamic> settled(String outcome, [String? skipKind]) => {
      ..._limitPark(),
      'outcome': outcome,
      'settledAt': '2026-11-20T14:31:00Z',
      'skipKind': ?skipKind,
    };
    final stillListed = [
      wakeView(
        id: 'wk-limit',
        reason: WakeReason.limitReset,
        state: WakeState.held,
      ),
    ];
    await pump(tester, _row(settled('resumed')), wakeList: stillListed);
    expect(find.textContaining('Resumed at '), findsOneWidget);
    expect(
      find.textContaining("after Anthropic's usage limit."),
      findsOneWidget,
    );
    expect(find.text('Resume'), findsNothing);
    expect(find.text('Cancel'), findsNothing);

    await pump(tester, _row(settled('cancelled')));
    expect(
      find.textContaining("It did not resume after Anthropic's usage limit."),
      findsOneWidget,
    );
    expect(find.textContaining('Cancelled at '), findsOneWidget);

    await pump(tester, _row(settled('expired')));
    expect(
      find.textContaining("without resuming after Anthropic's usage limit."),
      findsOneWidget,
    );

    await pump(tester, _row(settled('skipped', 'budget_blocked')));
    expect(
      find.textContaining("Not resumed after Anthropic's usage limit"),
      findsOneWidget,
    );
    expect(find.text('A budget blocks a run.'), findsOneWidget);

    await pump(tester, _row(settled('skipped', 'novel_skip')));
    expect(find.text('novel_skip'), findsOneWidget);

    await pump(tester, _row(settled('vanished')));
    expect(
      find.text("No longer waiting at Anthropic's usage limit."),
      findsOneWidget,
    );
    expect(find.text('vanished'), findsOneWidget);
  });

  testWidgets("limit card, not settled and its wake not listed: a person's "
      'run never resumes by itself, so it reads as paused until the reset; '
      'no actions, no inference from later rows', (tester) async {
    await pump(
      tester,
      _row(_limitPark()),
      feed: [
        _row({
          'kind': 'wake',
          'wakeIds': ['wk-limit'],
          'wakeReason': 'limit_reset',
        }, id: 'r-2'),
      ],
    );
    expect(
      find.textContaining(
        "Paused at Anthropic's usage limit. The limit resets at",
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Resumes at'), findsNothing);
    expect(find.textContaining('Resumed'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('limit card, held with an expiry: says when it expires', (
    tester,
  ) async {
    await pump(
      tester,
      _row(_limitPark()),
      wakeList: [
        wakeView(
          id: 'wk-limit',
          reason: WakeReason.limitReset,
          state: WakeState.held,
          stateReason: 'limit',
          expiresAt: DateTime.utc(2026, 11, 27, 14, 30),
        ),
      ],
    );
    expect(find.textContaining('Expires '), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
  });

  testWidgets('limit card, expired: no Resume, even while the wake is still '
      'listed', (tester) async {
    await pump(
      tester,
      _row({
        ..._limitPark(),
        'outcome': 'expired',
        'settledAt': '2026-11-27T14:30:00Z',
      }),
      wakeList: [
        wakeView(
          id: 'wk-limit',
          reason: WakeReason.limitReset,
          state: WakeState.held,
          expiresAt: DateTime.utc(2026, 11, 27, 14, 30),
        ),
      ],
    );
    expect(find.textContaining('Expired at '), findsOneWidget);
    expect(find.text('Resume'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    expect(find.textContaining('Expires '), findsNothing);
  });

  testWidgets('right to left: the expiry line starts at the right edge', (
    tester,
  ) async {
    await pump(
      tester,
      _row(_limitPark()),
      wakeList: [
        wakeView(
          id: 'wk-limit',
          reason: WakeReason.limitReset,
          state: WakeState.held,
          expiresAt: DateTime.utc(2026, 11, 27, 14, 30),
        ),
      ],
      textDirection: TextDirection.rtl,
    );
    final expires = tester.getTopRight(find.textContaining('Expires '));
    final resume = tester.getCenter(find.text('Resume'));
    expect(resume.dx, lessThan(expires.dx));
  });

  testWidgets('still in flight: collapsed to one line, expands to the plain '
      'text', (tester) async {
    await pump(
      tester,
      _row({
        'stillInFlightFor': 'agent-2',
      }, content: '## Still in flight\n- **run** `make test`'),
    );
    expect(find.text('State handed to Ada after compaction'), findsOneWidget);
    await tester.tap(find.text('State handed to Ada after compaction'));
    await tester.pumpAndSettle();
    expect(
      find.text('## Still in flight\n- **run** `make test`'),
      findsOneWidget,
    );
  });

  testWidgets('a refused command row names its command and reads its '
      'refusal kind; the text is only the fallback', (tester) async {
    final cases = {
      ('schedule', 'wake_too_soon'): 'That time is too soon. Pick a later one.',
      ('goal', 'goal_checker_unknown'): 'No agent has that name.',
      ('refine', 'improvement_review_queued'):
          'A review of this conversation is already waiting to run.',
      ('refine', 'improvement_review_cooldown'):
          'This conversation was reviewed recently. Try again later.',
      ('refine', 'agent_not_found'):
          'That agent is not an agent of this workspace.',
      ('loop', 'wake_queue_full'):
          'Too many wakes already wait here. Try again once some have run.',
    };
    for (final MapEntry(key: (command, kind), :value) in cases.entries) {
      await pump(
        tester,
        _row({
          'kind': 'command_refused',
          'refusalKind': kind,
          'command': command,
        }, content: 'server words'),
      );
      expect(
        find.text('The /$command command was refused.'),
        findsOneWidget,
        reason: kind,
      );
      expect(find.text(value), findsOneWidget, reason: kind);
      expect(find.text('server words'), findsNothing);
    }

    await pump(
      tester,
      _row({
        'kind': 'command_refused',
        'refusalKind': 'brand_new_refusal',
        'command': 'goal',
      }),
    );
    expect(find.text('The server refused this:'), findsOneWidget);
    expect(find.text('brand_new_refusal'), findsOneWidget);

    await pump(
      tester,
      _row({
        'kind': 'command_refused',
        'command': 'something',
      }, content: 'No objective given.'),
    );
    expect(find.text('The command was refused.'), findsOneWidget);
    expect(find.text('No objective given.'), findsOneWidget);
  });

  testWidgets('a raised pipeline cap names who, from what, to what', (
    tester,
  ) async {
    await pump(
      tester,
      _row({
        'kind': 'orchestration_cap_raised',
        'orchestration_id': 'o1',
        'old_micros': 2000000,
        'new_micros': 5000000,
        'user_id': 'u-unknown',
      }),
    );
    expect(
      find.text(r"A person raised the run's cap from $2.00 to $5.00."),
      findsOneWidget,
    );
  });

  testWidgets('an improvement that could not be applied links the proposal', (
    tester,
  ) async {
    await pump(
      tester,
      _row({
        'kind': 'improvement_apply_incomplete',
        'proposal_id': 'p1',
        'skill_slug': 'release-notes',
      }),
    );
    expect(
      find.textContaining('the skill release-notes could not be finished'),
      findsOneWidget,
    );
    expect(tip('Open improvement'), findsOneWidget);
  });

  testWidgets('right to left: the glyph sits at the right edge', (
    tester,
  ) async {
    await pump(
      tester,
      _row({
        'kind': 'wake_rule_created',
        'ruleId': 'rule-1',
        'agentId': 'agent-2',
      }),
      textDirection: TextDirection.rtl,
    );
    final sentence = tester.getCenter(find.text('Schedule set for Ada.'));
    final open = tester.getCenter(tip('Open schedule'));
    expect(open.dx, lessThan(sentence.dx));
  });

  test('the feed skips held steering and compacted still-in-flight rows', () {
    final held = Message(
      id: 'h',
      spaceId: 'sp-1',
      conversationId: 'conv-1',
      senderId: 'u-1',
      senderType: SenderType.user,
      content: 'held',
      messageType: MessageType.steering,
      metadata: const {'steerState': 'held'},
      createdAt: DateTime(2026, 11, 19, 9),
    );
    final items = buildFeedItems([
      held,
      _row({'stillInFlightFor': 'agent-2'}, id: 'old', compacted: true),
      _row({'stillInFlightFor': 'agent-2'}, id: 'new'),
    ], suppressOldestSeparator: true);
    final ids = [
      for (final i in items)
        if (i is MessageItem) i.message.id,
    ];
    expect(ids, ['new']);
    expect(find.byType(SystemMessage), findsNothing);
  });
}
