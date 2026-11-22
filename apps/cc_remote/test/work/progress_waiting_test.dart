@TestOn('browser')
library;

import 'package:cc_domain/cc_domain.dart' show MessageDto;
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_remote/conversation_progress_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_waiting.dart';
import 'package:cc_remote/work_providers.dart';
import 'package:flutter/widgets.dart' show TextDirection;
import 'package:flutter_test/flutter_test.dart';

import 'work_test_host.dart';

const ProgressScope _scope = (
  workspaceId: ws,
  spaceId: 's1',
  conversationId: 'c1',
);

WakeView _wake(
  String id, {
  WakeState state = WakeState.pending,
  WakeReason reason = WakeReason.schedule,
  String? stateReason,
  bool canRelease = true,
  String? sourceAgentId,
  int attempt = 0,
}) => WakeView(
  id: id,
  workspaceId: ws,
  spaceId: 's1',
  conversationId: 'c1',
  agentId: 'a1',
  reason: reason,
  origin: 'system',
  headline: '[schedule] headline in English',
  state: state,
  lane: WakeLane.followUp,
  notBefore: DateTime.now().toUtc().add(const Duration(hours: 2)),
  createdAt: DateTime.utc(2026, 11, 20),
  canRelease: canRelease,
  stateReason: stateReason,
  sourceAgentId: sourceAgentId,
  attempt: attempt,
);

MessageDto _row(String id, Map<String, dynamic> meta) => MessageDto(
  id: id,
  content: '',
  senderId: 'system',
  senderType: 'system',
  messageType: 'system',
  metadata: meta,
  spaceId: 's1',
  conversationId: 'c1',
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
    List<WakeView> wakes, {
    List<MessageDto> messages = const [],
    TextDirection direction = TextDirection.ltr,
  }) => pumpWork(
    tester,
    const ProgressWaiting(scope: _scope),
    overrides: [
      ...workOverrides(rpc()),
      phoneConversationWakesProvider((
        workspaceId: ws,
        conversationId: 'c1',
      )).overrideWith((ref) => Stream.value(wakes)),
      progressConversationProvider(_scope).overrideWith(
        (ref) async => Conversation(
          id: 'c1',
          workspaceId: ws,
          spaceId: 's1',
          title: '',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      ),
      progressRecentMessagesProvider(_scope).overrideWith(
        (ref) => Stream.value((messages: messages, hasMore: false)),
      ),
    ],
    direction: direction,
  );

  testWidgets('nothing waiting says so', (tester) async {
    await pump(tester, const []);
    expect(find.text(l.progressNothingWaiting), findsOneWidget);
  });

  testWidgets('a pending wake: origin, agent, due, Deliver now and Cancel', (
    tester,
  ) async {
    await pump(tester, [
      _wake('w1', reason: WakeReason.peerReply, sourceAgentId: 'a2'),
    ]);
    expect(find.text(l.wakeOriginReplyFrom('Reviewer')), findsOneWidget);
    expect(find.text(l.wakeFor('Builder')), findsOneWidget);
    expect(find.textContaining('Due'), findsOneWidget);
    expect(find.textContaining('headline in English'), findsNothing);
    await tapLabel(tester, l.wakeDeliverNow);
    expect(rpc().ops, ['wakes.deliverNow']);
    expect(rpc().sent.single.args, {'workspace_id': ws, 'wake_id': 'w1'});
    await tapLabel(tester, l.wakeCancel);
    expect(rpc().ops.last, 'wakes.cancel');
  });

  testWidgets('a held wake: the reason in words; Resume only with '
      'canRelease', (tester) async {
    await pump(tester, [
      _wake('w1', state: WakeState.held, stateReason: 'budget_blocked'),
    ]);
    expect(find.text(l.wakeHeld), findsOneWidget);
    expect(find.text(l.wakeKindBudgetBlocked), findsOneWidget);
    await tapLabel(tester, l.wakeResume);
    expect(rpc().ops, ['wakes.release']);
    expect(rpc().sent.single.args, {'workspace_id': ws, 'wake_id': 'w1'});

    await pump(tester, [
      _wake(
        'w2',
        state: WakeState.held,
        stateReason: 'stopped',
        canRelease: false,
      ),
    ]);
    expect(find.text(l.wakeResume), findsNothing);
    expect(find.text(l.wakeDeliverNow), findsNothing);
    expect(find.text(l.wakeResumeOnlyTheirs), findsOneWidget);
    expect(find.text(l.wakeCancel), findsOneWidget);
  });

  testWidgets('an unknown reason shows the lead-in and the raw kind', (
    tester,
  ) async {
    await pump(tester, [
      _wake('w1', state: WakeState.held, stateReason: 'brand_new_reason'),
    ]);
    expect(find.text(l.workKindUnknown), findsOneWidget);
    expect(find.text('brand_new_reason'), findsOneWidget);
  });

  testWidgets('a recovery wake after a server stop: Resume and Dismiss', (
    tester,
  ) async {
    await pump(tester, [
      _wake(
        'w1',
        state: WakeState.held,
        reason: WakeReason.recovery,
        stateReason: 'server_stopped',
      ),
    ]);
    expect(find.text(l.wakeRecovery), findsOneWidget);
    await tapLabel(tester, l.wakeDismiss);
    expect(rpc().ops, ['wakes.cancel']);
  });

  testWidgets('a provider-limit park: Resumes at, Resume now and Cancel', (
    tester,
  ) async {
    final resumes = DateTime.utc(2026, 11, 20, 14, 30);
    final row = _row('m1', {
      'kind': 'limit_park',
      'wakeId': 'w1',
      'provider': 'Anthropic',
      'resumesAt': resumes.toIso8601String(),
    });
    await pump(
      tester,
      [
        _wake(
          'w1',
          state: WakeState.held,
          reason: WakeReason.limitReset,
          stateReason: 'limit',
        ),
      ],
      messages: [row],
    );
    expect(
      find.textContaining("Paused at Anthropic's usage limit, which resets"),
      findsOneWidget,
    );
    // The wake shows once, as the park card.
    expect(find.text(l.wakeKindLimit), findsNothing);
    await tapLabel(tester, l.limitParkResumeNow);
    expect(rpc().ops, ['wakes.release']);
    await tapLabel(tester, l.limitParkCancel);
    expect(rpc().ops.last, 'wakes.cancel');
  });

  testWidgets('a settled park reads its outcome from the row, without '
      'actions; a later wake row decides nothing', (tester) async {
    Map<String, dynamic> park([Map<String, dynamic> stamp = const {}]) => {
      'kind': 'limit_park',
      'wakeId': 'w1',
      'provider': 'Anthropic',
      ...stamp,
    };
    final settledAt = DateTime.utc(2026, 11, 20, 15, 5);
    final stamped = {
      'outcome': 'resumed',
      'settledAt': settledAt.toIso8601String(),
    };
    await pump(tester, const [], messages: [_row('m1', park(stamped))]);
    expect(find.text(l.limitParkResumed('Anthropic')), findsOneWidget);
    expect(find.text(l.limitParkResumeNow), findsNothing);

    for (final (outcome, text) in [
      ('cancelled', l.limitParkCancelled('Anthropic')),
      ('expired', l.limitParkExpired('Anthropic')),
    ]) {
      await pump(
        tester,
        const [],
        messages: [
          _row('m1', park({...stamped, 'outcome': outcome})),
        ],
      );
      expect(find.text(text), findsOneWidget, reason: outcome);
      expect(find.text(l.limitParkCancel), findsNothing);
    }

    // A skip names its kind; an unknown one keeps the raw kind.
    await pump(
      tester,
      const [],
      messages: [
        _row(
          'm1',
          park({...stamped, 'outcome': 'skipped', 'skipKind': 'agent_paused'}),
        ),
      ],
    );
    expect(find.text(l.limitParkSkipped('Anthropic')), findsOneWidget);
    expect(find.text(l.wakeKindAgentPaused), findsOneWidget);
    await pump(
      tester,
      const [],
      messages: [
        _row(
          'm1',
          park({...stamped, 'outcome': 'skipped', 'skipKind': 'new_kind'}),
        ),
      ],
    );
    expect(find.text(l.workKindUnknown), findsOneWidget);
    expect(find.text('new_kind'), findsOneWidget);

    // An outcome on the row wins even while the wake list still has it.
    await pump(
      tester,
      [
        _wake(
          'w1',
          state: WakeState.held,
          reason: WakeReason.limitReset,
          stateReason: 'limit',
        ),
      ],
      messages: [
        _row('m1', park({...stamped, 'outcome': 'cancelled'})),
      ],
    );
    expect(find.text(l.limitParkCancelled('Anthropic')), findsOneWidget);
    expect(find.text(l.limitParkResumeNow), findsNothing);

    // An expired pause offers no Resume, even while the wake is listed.
    await pump(
      tester,
      [
        _wake(
          'w1',
          state: WakeState.held,
          reason: WakeReason.limitReset,
          stateReason: 'limit',
        ),
      ],
      messages: [
        _row('m1', park({...stamped, 'outcome': 'expired'})),
      ],
    );
    expect(find.text(l.limitParkExpired('Anthropic')), findsOneWidget);
    expect(find.text(l.limitParkResumeNow), findsNothing);

    // No stamp yet: no longer waiting, whatever later rows say.
    await pump(
      tester,
      const [],
      messages: [
        _row('m1', park()),
        _row('m2', {
          'kind': 'wake',
          'wakeIds': ['w1'],
        }),
      ],
    );
    expect(find.text(l.limitParkGone('Anthropic')), findsOneWidget);
    expect(find.text(l.limitParkResumed('Anthropic')), findsNothing);
  });

  testWidgets('a settled park in RTL', (tester) async {
    await pump(
      tester,
      const [],
      messages: [
        _row('m1', {
          'kind': 'limit_park',
          'wakeId': 'w1',
          'outcome': 'skipped',
          'skipKind': 'agent_paused',
          'settledAt': DateTime.utc(2026, 11, 20, 15).toIso8601String(),
        }),
      ],
      direction: TextDirection.rtl,
    );
    expect(
      find.text(l.limitParkSkipped(l.limitParkProviderUnknown)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
