import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/src/dispatch/limit_park_credential_gate.dart';
import 'package:cc_infra/src/dispatch/limit_park_rows.dart';
import 'package:cc_infra/src/dispatch/limit_park_service.dart';
import 'package:cc_infra/src/dispatch/person_removal_service.dart';
import 'package:cc_infra/src/dispatch/wake_queue_service.dart';
import 'package:test/test.dart';

import 'fake_wake_repository.dart';

const _ws = 'ws-1';
const _space = 'sp-1';
const _conv = 'conv-1';
const _agent = 'agent-1';
const _person = 'user-1';

class _Timer implements Timer {
  @override
  void cancel() {}

  @override
  bool get isActive => false;

  @override
  int get tick => 0;
}

class _RunLogs implements AgentRunLogRepository {
  final logs = <String, AgentRunLog>{};

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async {
    final log = logs[id];
    return log != null && log.workspaceId == workspaceId ? log : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The conversation's rows, for the real row stamp.
class _Messages implements MessagingRepository {
  _Messages(this.world);

  final _World world;

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async => [
    for (final (i, row) in world.rows.indexed)
      Message(
        id: 'msg-${i + 1}',
        spaceId: _space,
        conversationId: _conv,
        senderId: 'system',
        senderType: SenderType.system,
        content: row.content,
        messageType: MessageType.system,
        metadata: row.metadata,
        createdAt: world.now,
      ),
  ];

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? messageType,
    String? idempotencyKey,
  }) async {
    final i = int.parse(messageId.substring('msg-'.length)) - 1;
    world.rows[i] = (content: world.rows[i].content, metadata: metadata!);
    world.rowUpdates++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A steering card in the fake conversation.
class _Card {
  _Card(this.sender);

  final String sender;
  String state = 'queued';
  String? heldBy;
  String? run;
  DateTime? resetsAt;
}

/// A gate whose park ends when the test says so.
class _Gate implements RunCredentialGatePort {
  final parked = <RunCredentialBlockRequest>[];
  Completer<RunCredentialOutcome> outcome = Completer();

  @override
  Future<RunCredentialOutcome> awaitCredentials(
    RunCredentialBlockRequest request, {
    required Future<bool> Function() recheck,
  }) {
    parked.add(request);
    return outcome.future;
  }
}

/// One server process: a wake queue and the park service over shared rows
/// (a restart is a second process on the same rows).
class _Process {
  _Process(this.world) {
    queue = WakeQueueService(
      wakes: world.wakes,
      runLedger: FakeWakeRunLedger(),
      eventBus: world.bus,
      clock: () => world.now,
      timerFactory: (_, _) => _Timer(),
      nonce: () => 'nonce1',
      ports: WakeQueuePorts(
        workspaceActive: (ws) async => ws == _ws,
        conversationSpace: (ws, conv) async =>
            ws == _ws && conv == _conv ? _space : null,
        agent: (ws, id) async => ws == _ws
            ? Agent(
                id: id,
                name: 'Ada',
                title: 't',
                agentMdPath: '/tmp/$id.md',
                workspaceId: _ws,
                skills: AgentSkills(const []),
                createdAt: DateTime.utc(2026),
                lifecycleStatus: AgentLifecycleStatus.active,
              )
            : null,
        isMember: (ws, user) async => !world.removed.contains('$ws/$user'),
        takenOver: (ws, space) async => false,
        budgetBlocked: (ws, agentId) async => false,
        liveSessions: (_) => const [],
        hasLiveRun: (ws, conv, agentId) async => false,
        dispatch: (run) async {
          world.dispatched.add(run);
          return 'wake-run-${world.dispatched.length}';
        },
        postSystemRow:
            ({
              required String workspaceId,
              required String spaceId,
              required String conversationId,
              required String content,
              required Map<String, Object?> metadata,
            }) async {},
      ),
    );
    parks = LimitParkService(
      wakes: world.wakes,
      queue: queue,
      runLogs: world.runLogs,
      eventBus: world.bus,
      clock: () => world.now,
      postRow:
          ({
            required String workspaceId,
            required String spaceId,
            required String conversationId,
            required String content,
            required Map<String, Object?> metadata,
          }) async {
            world.rows.add((content: content, metadata: metadata));
            return 'msg-${world.rows.length}';
          },
      releaseCards:
          ({
            required String workspaceId,
            required String spaceId,
            required String conversationId,
            required String heldBy,
            required String senderId,
          }) async {
            var n = 0;
            for (final MapEntry(:key, :value) in world.cards.entries) {
              if (value.state == 'held' &&
                  value.heldBy == heldBy &&
                  value.sender == senderId) {
                value.state = 'sent';
                world.sent.add(key);
                n++;
              }
            }
            return n;
          },
      holdCards:
          ({
            required String workspaceId,
            required String spaceId,
            required String conversationId,
            required String runId,
            required String heldBy,
            required DateTime? resetsAt,
            required String? pausePerson,
          }) async {
            var n = 0;
            for (final card in world.cards.values) {
              // As `SteeringQueueService.holdRunCards`: under a pause only
              // its person's cards wait with it.
              final theirs =
                  heldBy != LimitPark.dedupKey(runId) ||
                  (pausePerson != null && card.sender == pausePerson);
              final holder = theirs ? heldBy : 'stop';
              final reset = theirs ? resetsAt : null;
              if (card.state == 'held' &&
                  (card.run == runId ||
                      card.heldBy == LimitPark.dedupKey(runId)) &&
                  (card.heldBy != holder || card.resetsAt != reset)) {
                card
                  ..heldBy = holder
                  ..resetsAt = reset;
                n++;
              }
            }
            return n;
          },
      heldCards: (ws) async {
        final cards = [
          for (final MapEntry(:key, :value) in world.cards.entries)
            if (ws == _ws && value.state == 'held')
              Message(
                id: key,
                spaceId: _space,
                conversationId: _conv,
                senderId: value.sender,
                senderType: SenderType.user,
                content: key,
                messageType: MessageType.steering,
                metadata: {
                  'steerState': 'held',
                  'steerHeldBy': value.heldBy,
                  'steerHeldRun': ?value.run,
                },
                createdAt: world.now,
              ),
        ];
        world.sweepSaw.add([
          for (final w in world.wakes.all(_ws)) '${w.id}:${w.state.wire}',
        ]);
        return cards;
      },
      openParkRows: (ws) async => [
        for (final row in await _Messages(world).getMessages(ws, _space))
          if (ws == _ws &&
              row.metadata?['kind'] == LimitPark.rowKind &&
              row.metadata?[LimitPark.rowOutcomeKey] == null)
            row,
      ],
      stampRow: LimitParkRowStamp(_Messages(world)).call,
    )..start();
  }

  final _World world;
  late final WakeQueueService queue;
  late final LimitParkService parks;

  Future<void> stop() async {
    await parks.dispose();
    await queue.stop();
  }
}

class _World {
  DateTime now = DateTime.utc(2026, 11, 19, 12);
  final bus = DomainEventBus();
  final wakes = FakeWakeRepository();
  final runLogs = _RunLogs();
  final dispatched = <WakeDispatchRequest>[];
  final rows = <({String content, Map<String, Object?> metadata})>[];

  /// The conversation's steering cards, by id.
  final cards = <String, _Card>{};

  /// `workspace/user` pairs no longer members.
  final removed = <String>{};

  /// The cards a park's resume sent, in order.
  final sent = <String>[];

  /// What the boot sweep saw of the wakes when it read the cards.
  final sweepSaw = <List<String>>[];

  /// A card [sender] queued.
  void queueCard(String id, {String sender = _person}) =>
      cards[id] = _Card(sender);

  /// The steering queue at [runId]'s end on a usage limit: the queued cards
  /// held as a Stop's, marked with the run, then the park service decides.
  Future<void> steerHold(_Process p, String runId) async {
    for (final card in cards.values) {
      if (card.state == 'queued') {
        card
          ..state = 'held'
          ..heldBy = 'stop'
          ..run = runId;
      }
    }
    await p.parks.reconcileCards(
      workspaceId: _ws,
      spaceId: _space,
      conversationId: _conv,
      runId: runId,
    );
  }

  /// Who holds card [id]: `stop`, `limit:<runId>`, or its state when not
  /// held.
  String? holderOf(String id) =>
      cards[id]?.state == 'held' ? cards[id]!.heldBy : cards[id]?.state;

  /// How often a row's metadata was rewritten.
  int rowUpdates = 0;

  Future<void> pump() async {
    for (var i = 0; i < 100; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> advance(_Process p, Duration by) async {
    now = now.add(by);
    await p.queue.tick();
    await pump();
  }

  void runRow(
    String runId, {
    String? requester = _person,
    WakeReason wakeReason = WakeReason.userMessage,
    List<String> wakeIds = const [],
    bool live = false,
  }) => runLogs.logs[runId] = AgentRunLog(
    id: runId,
    agentId: _agent,
    workspaceId: _ws,
    conversationId: _conv,
    spaceId: _space,
    startedAt: now,
    status: live ? RunStatus.running : RunStatus.error,
    completedAt: live ? null : now,
    adapter: 'claude-code',
    requestedByUserId: requester,
    wakeIds: wakeIds,
    wakeReason: wakeReason,
  );

  Future<void> settle(
    String runId, {
    RunEndReason reason = RunEndReason.usageLimit,
    DateTime? resetsAt,
    String? requester = _person,
    WakeReason? wakeReason = WakeReason.userMessage,
    List<String> wakeIds = const [],
  }) async {
    bus.publish(
      AgentRunSettled(
        agentId: _agent,
        workspaceId: _ws,
        spaceId: _space,
        conversationId: _conv,
        runId: runId,
        status: RunStatus.error,
        endReason: reason,
        costMicros: 0,
        limitResetsAt: resetsAt,
        wakeIds: wakeIds,
        requestedByUserId: requester,
        wakeReason: wakeReason,
        occurredAt: now,
      ),
    );
    await pump();
  }

  List<Wake> limitWakes() => [
    for (final w in wakes.all(_ws))
      if (w.reason == WakeReason.limitReset) w,
  ];

  LimitParkRun parkRun(String runId) => LimitParkRun(
    workspaceId: _ws,
    spaceId: _space,
    conversationId: _conv,
    agentId: _agent,
    runId: runId,
    requestedByUserId: _person,
    wakeReason: WakeReason.userMessage,
    wakeIds: const [],
    adapter: 'claude-code',
    modelId: null,
  );
}

void main() {
  late _World w;
  late _Process p;

  setUp(() async {
    w = _World();
    p = _Process(w);
    await p.queue.start();
  });
  tearDown(() async {
    await p.stop();
    w.bus.dispose();
  });

  group("a person's run", () {
    test('gets a held wake for the person and one system row with the reset '
        'as data', () async {
      final reset = w.now.add(const Duration(hours: 2, minutes: 30));
      w.runRow('run-1');
      await w.settle('run-1', resetsAt: reset);
      final wake = w.limitWakes().single;
      expect(wake.state, WakeState.held);
      expect(wake.stateReason, LimitPark.heldReason);
      expect(wake.requestedByUserId, _person);
      expect(wake.dedupKey, 'limit:run-1');
      expect(wake.notBefore, reset.add(const Duration(seconds: 30)));
      expect(wake.detail.sourceRunId, 'run-1');
      expect(wake.detail.fields[WakeFields.provider], 'anthropic');
      expect(wake.runOptions, isNull);
      final row = w.rows.single;
      expect(row.metadata.keys.toSet(), LimitPark.rowKeys.toSet());
      expect(row.metadata['kind'], 'limit_park');
      expect(row.metadata['wakeId'], wake.id);
      expect(row.metadata['runId'], 'run-1');
      expect(row.metadata['agentId'], _agent);
      expect(row.metadata['provider'], 'anthropic');
      expect(row.metadata['requestedByUserId'], _person);
      expect(row.metadata['resetsAt'], reset.toIso8601String());
      expect(
        row.metadata['resumesAt'],
        reset.add(const Duration(seconds: 30)).toIso8601String(),
      );
      expect(row.content, contains('anthropic usage limit'));
    });

    test('a release before the reset waits for the reset, then resumes the '
        'run for the person', () async {
      final reset = w.now.add(const Duration(hours: 1));
      w.runRow('run-1');
      await w.settle('run-1', resetsAt: reset);
      final wake = w.limitWakes().single;
      await expectLater(
        p.queue.release(_ws, wakeId: wake.id, userId: 'user-2'),
        throwsA(anything),
      );
      expect(await p.queue.release(_ws, wakeId: wake.id, userId: _person), 1);
      await w.pump();
      expect(w.dispatched, isEmpty);
      expect((await w.wakes.getById(_ws, wake.id))!.state, WakeState.pending);
      await w.advance(p, const Duration(hours: 1, seconds: 29));
      expect(w.dispatched, isEmpty);
      await w.advance(p, const Duration(seconds: 1));
      await w.advance(p, WakeQueueService.quietWindow);
      expect(w.dispatched, hasLength(1));
      final run = w.dispatched.single;
      expect(run.wakeContext.wakeReason, WakeReason.limitReset);
      expect(run.requestedByUserId, _person);
    });

    test("an unresumed person's pause expires at the reset plus seven days: "
        "its cards become a Stop's, unsent, and its row says expired",
        () async {
      final reset = w.now.add(const Duration(hours: 1));
      w
        ..queueCard('c-mine')
        ..queueCard('c-theirs', sender: 'user-2')
        ..runRow('run-1');
      await w.settle('run-1', resetsAt: reset);
      await w.steerHold(p, 'run-1');
      final wake = w.limitWakes().single;
      expect(wake.expiresAt, reset.add(const Duration(days: 7)));
      expect(w.holderOf('c-mine'), 'limit:run-1');
      expect(w.holderOf('c-theirs'), 'stop');

      // Past the reset it still waits for its person's Resume.
      await w.advance(p, const Duration(days: 7));
      await w.advance(p, WakeQueueService.maintenanceEvery);
      expect(w.limitWakes().single.state, WakeState.held);
      expect(w.holderOf('c-mine'), 'limit:run-1');

      await w.advance(p, const Duration(hours: 1));
      await w.advance(p, WakeQueueService.maintenanceEvery);
      expect(w.limitWakes().single.state, WakeState.expired);
      expect(w.dispatched, isEmpty);
      expect(w.sent, isEmpty);
      expect(w.holderOf('c-mine'), 'stop');
      expect(w.cards['c-mine']!.resetsAt, isNull);
      expect(
        w.rows.single.metadata[LimitPark.rowOutcomeKey],
        LimitPark.outcomeExpired,
      );
      // A Resume after the expiry moves nothing.
      expect(await p.queue.release(_ws, wakeId: wake.id, userId: _person), 0);
      await w.pump();
      expect(w.dispatched, isEmpty);
    });

    test('a Resume after the reset starts the run at once, for the person',
        () async {
      final reset = w.now.add(const Duration(hours: 1));
      w.runRow('run-1');
      await w.settle('run-1', resetsAt: reset);
      final wake = w.limitWakes().single;
      await w.advance(p, const Duration(days: 2));
      expect(w.dispatched, isEmpty, reason: 'held for its person');
      expect(await p.queue.release(_ws, wakeId: wake.id, userId: _person), 1);
      await w.advance(p, WakeQueueService.quietWindow);
      expect(w.dispatched, hasLength(1));
      expect(w.dispatched.single.requestedByUserId, _person);
    });

    test('a cancel drops the wake; nothing runs at the reset', () async {
      final reset = w.now.add(const Duration(hours: 1));
      w.runRow('run-1');
      await w.settle('run-1', resetsAt: reset);
      final wake = w.limitWakes().single;
      expect(
        await p.queue.cancel(_ws, wake.id, reason: 'cancelled_by_person'),
        isTrue,
      );
      await w.advance(p, const Duration(hours: 2));
      expect(w.dispatched, isEmpty);
      expect(w.limitWakes().single.state, WakeState.cancelled);
    });

    test('no park without a reset, past seven days, for a server stop, for '
        'a server run, or for a goal\'s or a rule\'s run', () async {
      w.runRow('run-1');
      await w.settle('run-1');
      await w.settle(
        'run-1',
        resetsAt: w.now.add(const Duration(days: 7, minutes: 1)),
      );
      await w.settle(
        'run-1',
        reason: RunEndReason.serverStopped,
        resetsAt: w.now.add(const Duration(hours: 1)),
      );
      await w.settle(
        'run-1',
        requester: null,
        resetsAt: w.now.add(const Duration(hours: 1)),
      );
      await w.settle(
        'run-1',
        wakeReason: WakeReason.peerMessage,
        resetsAt: w.now.add(const Duration(hours: 1)),
      );
      final goalWake = Wake(
        id: 'goal-wake',
        workspaceId: _ws,
        spaceId: _space,
        conversationId: _conv,
        agentId: _agent,
        reason: WakeReason.limitReset,
        payload: '',
        detail: WakeDetail(goalId: 'goal-1'),
        dedupKey: 'limit:earlier',
        notBefore: w.now,
        state: WakeState.delivered,
        createdAt: w.now,
      );
      await w.wakes.insertIfAbsent(goalWake);
      await w.settle(
        'run-1',
        wakeReason: WakeReason.limitReset,
        wakeIds: const ['goal-wake'],
        resetsAt: w.now.add(const Duration(hours: 1)),
      );
      expect(w.limitWakes().where((x) => x.dedupKey == 'limit:run-1'), isEmpty);
      expect(w.rows, isEmpty);
    });

    test('a run a peer ask\'s park resumed is the ask\'s to park again, '
        'never a person\'s', () async {
      w.runRow('run-1');
      await w.wakes.insertIfAbsent(
        Wake(
          id: 'ask-park',
          workspaceId: _ws,
          spaceId: _space,
          conversationId: _conv,
          agentId: _agent,
          reason: WakeReason.limitReset,
          payload: 'Is the cast safe?',
          detail: WakeDetail(askId: 'ask-1', sourceRunId: 'run-0'),
          dedupKey: 'limit:run-0',
          notBefore: w.now,
          state: WakeState.delivered,
          createdAt: w.now,
        ),
      );
      await w.settle(
        'run-1',
        wakeReason: WakeReason.limitReset,
        wakeIds: const ['ask-park'],
        resetsAt: w.now.add(const Duration(hours: 1)),
      );
      expect(w.limitWakes().where((x) => x.dedupKey == 'limit:run-1'), isEmpty);
      expect(w.rows, isEmpty);
    });

    test(
      'a server stop of a parked run leaves no second (recovery) wake',
      () async {
        final ticket = await p.parks.credentialParked(
          w.parkRun('run-1'),
          resetsAt: w.now.add(const Duration(hours: 1)),
        );
        expect(ticket, isNotNull);
        await w.settle('run-1', reason: RunEndReason.serverStopped);
        expect(
          w.wakes.all(_ws).where((x) => x.reason == WakeReason.recovery),
          isEmpty,
        );
      },
    );
  });

  group('the credential park', () {
    test('writes the pending wake; the in-memory park defers it and, when '
        'it resolves first, cancels it: one run', () async {
      final reset = w.now.add(const Duration(minutes: 10));
      final ticket = await p.parks.credentialParked(
        w.parkRun('run-1'),
        resetsAt: reset,
      );
      final wake = w.limitWakes().single;
      expect(wake.state, WakeState.pending);
      expect(wake.requestedByUserId, _person);
      expect(wake.notBefore, reset.add(const Duration(seconds: 30)));
      // Due while the run is still parked in memory: deferred, not started.
      await w.advance(p, const Duration(minutes: 11));
      expect(w.dispatched, isEmpty);
      expect(
        (await w.wakes.getById(_ws, wake.id))!.stateReason,
        WakeStateReasons.limitRunLive,
      );
      expect(
        await p.parks.credentialParkEnded(
          ticket!,
          outcome: RunCredentialOutcome.resolved,
        ),
        isTrue,
      );
      expect((await w.wakes.getById(_ws, wake.id))!.state, WakeState.cancelled);
      await w.advance(p, const Duration(hours: 1));
      expect(w.dispatched, isEmpty);
    });

    test('survives a restart: the wake starts the run at the reset, once, '
        'and the old park, if it resolves, does not start a second', () async {
      final reset = w.now.add(const Duration(minutes: 10));
      final ticket = await p.parks.credentialParked(
        w.parkRun('run-1'),
        resetsAt: reset,
      );
      expect(ticket, isNotNull);
      // A restart: a new process on the same rows; the old park is gone
      // from memory, its wake is not.
      final restarted = _Process(w);
      await restarted.queue.start();
      await w.advance(restarted, const Duration(minutes: 10, seconds: 30));
      await w.advance(restarted, WakeQueueService.quietWindow);
      expect(w.dispatched, hasLength(1));
      expect(w.dispatched.single.wakeContext.wakeReason, WakeReason.limitReset);
      expect(w.dispatched.single.requestedByUserId, _person);
      // Whichever resumes first cancels the other: the queue was first.
      expect(
        await p.parks.credentialParkEnded(
          ticket!,
          outcome: RunCredentialOutcome.resolved,
        ),
        isFalse,
      );
      await w.advance(restarted, const Duration(hours: 1));
      expect(w.dispatched, hasLength(1));
      await restarted.stop();
    });

    test('a park that gives up holds the wake at once; the run\'s end posts '
        'one row', () async {
      final reset = w.now.add(const Duration(minutes: 10));
      final ticket = await p.parks.credentialParked(
        w.parkRun('run-1'),
        resetsAt: reset,
      );
      expect(
        await p.parks.credentialParkEnded(
          ticket!,
          outcome: RunCredentialOutcome.timedOut,
        ),
        isFalse,
      );
      expect(w.limitWakes().single.state, WakeState.held);
      expect(w.limitWakes().single.stateReason, LimitPark.heldReason);
      w.runRow('run-1');
      await w.settle('run-1', resetsAt: reset);
      final wake = w.limitWakes().single;
      expect(wake.state, WakeState.held);
      expect(wake.stateReason, LimitPark.heldReason);
      expect(w.rows.single.metadata['wakeId'], wake.id);
    });

    test('a park that gives up, then a dispatch that fails before its run '
        'row: nothing starts at the reset', () async {
      final reset = w.now.add(const Duration(minutes: 10));
      final ticket = await p.parks.credentialParked(
        w.parkRun('run-1'),
        resetsAt: reset,
      );
      await p.parks.credentialParkEnded(
        ticket!,
        outcome: RunCredentialOutcome.timedOut,
      );
      // No run row and no settlement: the dispatch threw first.
      await w.advance(p, const Duration(hours: 1));
      expect(w.dispatched, isEmpty);
      expect(w.limitWakes().single.state, WakeState.held);
    });

    test('a person who cancels the credential block drops the wake: '
        'nothing restarts the run at the reset', () async {
      final reset = w.now.add(const Duration(minutes: 10));
      final ticket = await p.parks.credentialParked(
        w.parkRun('run-1'),
        resetsAt: reset,
      );
      expect(
        await p.parks.credentialParkEnded(
          ticket!,
          outcome: RunCredentialOutcome.cancelled,
        ),
        isFalse,
      );
      final wake = w.limitWakes().single;
      expect(wake.state, WakeState.cancelled);
      await w.advance(p, const Duration(hours: 1));
      expect(w.dispatched, isEmpty);
    });

    test('nothing durable for a wake-started run or a server run', () async {
      final started = LimitParkRun(
        workspaceId: _ws,
        spaceId: _space,
        conversationId: _conv,
        agentId: _agent,
        runId: 'run-2',
        requestedByUserId: _person,
        wakeReason: WakeReason.schedule,
        wakeIds: const ['wk-1'],
        adapter: null,
        modelId: null,
      );
      expect(
        await p.parks.credentialParked(
          started,
          resetsAt: w.now.add(const Duration(hours: 1)),
        ),
        isNull,
      );
      final bot = LimitParkRun(
        workspaceId: _ws,
        spaceId: _space,
        conversationId: _conv,
        agentId: _agent,
        runId: 'run-3',
        requestedByUserId: null,
        wakeReason: WakeReason.userMessage,
        wakeIds: const [],
        adapter: null,
        modelId: null,
      );
      expect(
        await p.parks.credentialParked(
          bot,
          resetsAt: w.now.add(const Duration(hours: 1)),
        ),
        isNull,
      );
      expect(w.limitWakes(), isEmpty);
    });

    test('the gate over a recorded run: resolved in place goes on; the '
        'queue first turns the outcome into a cancel', () async {
      w.runRow('run-1', live: true);
      final inner = _Gate();
      final gate = LimitParkCredentialGate(
        inner,
        parks: () => p.parks,
        runLogs: w.runLogs,
      );
      final request = RunCredentialBlockRequest(
        lane: RunCredentialLane.harness,
        reason: RunCredentialReason.planSpent,
        detail: 'spent',
        runLogId: 'run-1',
        availableAt: w.now.add(const Duration(minutes: 5)),
        workspaceId: _ws,
        spaceId: _space,
        conversationId: _conv,
        agentId: _agent,
      );
      final first = gate.awaitCredentials(request, recheck: () async => true);
      await w.pump();
      expect(w.limitWakes().single.state, WakeState.pending);
      inner.outcome.complete(RunCredentialOutcome.resolved);
      expect(await first, RunCredentialOutcome.resolved);
      expect(w.limitWakes().single.state, WakeState.cancelled);

      // A second park of another run whose wake a restarted queue took.
      w.runRow('run-2', live: true);
      inner.outcome = Completer();
      final second = gate.awaitCredentials(
        RunCredentialBlockRequest(
          lane: RunCredentialLane.harness,
          reason: RunCredentialReason.planSpent,
          detail: 'spent',
          runLogId: 'run-2',
          availableAt: w.now.add(const Duration(minutes: 5)),
          workspaceId: _ws,
          spaceId: _space,
          conversationId: _conv,
          agentId: _agent,
        ),
        recheck: () async => true,
      );
      await w.pump();
      final restarted = _Process(w);
      await restarted.queue.start();
      await w.advance(restarted, const Duration(minutes: 5, seconds: 30));
      await w.advance(restarted, WakeQueueService.quietWindow);
      expect(w.dispatched, hasLength(1));
      inner.outcome.complete(RunCredentialOutcome.resolved);
      expect(await second, RunCredentialOutcome.cancelled);
      await restarted.stop();
    });
  });

  group('a person leaves the workspace', () {
    late List<String> stopped;
    late PersonRemovalService removal;

    setUp(() {
      stopped = [];
      removal = PersonRemovalService(
        eventBus: null,
        isMember: (ws, user) async => !w.removed.contains('$ws/$user'),
        cancelWakes: (ws, user) => p.queue.cancelWhere(
          ws,
          requestedByUserId: user,
          reason: WakeStateReasons.personRemoved,
        ),
        liveRuns: (ws) async => [
          for (final log in w.runLogs.logs.values)
            if (log.workspaceId == ws && log.completedAt == null) log,
        ],
        stopRun: (ws, runId) async {
          stopped.add(runId);
          final log = w.runLogs.logs[runId]!;
          w.runLogs.logs[runId] = log.copyWith(completedAt: w.now);
          return true;
        },
        cardsOf: (ws, user) async => [
          for (final MapEntry(:key, :value) in w.cards.entries)
            if (ws == _ws && value.sender == user)
              Message(
                id: key,
                spaceId: _space,
                conversationId: _conv,
                senderId: value.sender,
                senderType: SenderType.user,
                content: key,
                messageType: MessageType.steering,
                createdAt: w.now,
              ),
        ],
        deleteCard: (ws, card) async => w.cards.remove(card.id) != null,
      );
    });

    Wake held(String id, {String person = _person, String ws = _ws}) => Wake(
      id: id,
      workspaceId: ws,
      spaceId: _space,
      conversationId: _conv,
      agentId: _agent,
      reason: WakeReason.schedule,
      payload: '',
      dedupKey: 'key:$id',
      notBefore: w.now,
      requestedByUserId: person,
      state: WakeState.held,
      stateReason: WakeStateReasons.stopped,
      createdAt: w.now,
    );

    WorkspaceMemberRemoved left(String ws) =>
        WorkspaceMemberRemoved(workspaceId: ws, userId: _person, occurredAt: w.now);

    test("cancels the person's pause and Stop-held wakes, deletes their "
        "cards and stops their runs; everyone else's work and their work in "
        'another workspace go on; a second event changes nothing', () async {
      final reset = w.now.add(const Duration(hours: 1));
      w
        ..queueCard('c-mine')
        ..queueCard('c-theirs', sender: 'user-2')
        ..runRow('run-1');
      await w.settle('run-1', resetsAt: reset);
      await w.steerHold(p, 'run-1');
      final pause = w.limitWakes().single;
      w.queueCard('c-queued');
      await w.wakes.insertIfAbsent(held('stop-mine'));
      await w.wakes.insertIfAbsent(held('stop-theirs', person: 'user-2'));
      await w.wakes.insertIfAbsent(held('elsewhere', ws: 'ws-2'));
      w
        ..runRow('run-live', live: true)
        ..runRow('run-other', requester: 'user-2', live: true)
        ..runRow('run-bot', requester: null, live: true);
      w.removed.add('$_ws/$_person');

      final first = await removal.handle(left(_ws));
      await w.pump();

      expect(first.wakes, 2);
      expect(first.cards, 2);
      expect(first.runs, 1);
      final pauseNow = (await w.wakes.getById(_ws, pause.id))!;
      expect(pauseNow.state, WakeState.cancelled);
      expect(pauseNow.stateReason, WakeStateReasons.personRemoved);
      expect(
        w.rows.single.metadata[LimitPark.rowOutcomeKey],
        LimitPark.outcomeCancelled,
      );
      expect(
        (await w.wakes.getById(_ws, 'stop-mine'))!.state,
        WakeState.cancelled,
      );
      expect(
        (await w.wakes.getById(_ws, 'stop-theirs'))!.state,
        WakeState.held,
      );
      expect(
        (await w.wakes.getById('ws-2', 'elsewhere'))!.state,
        WakeState.held,
      );
      expect(w.cards.keys, ['c-theirs']);
      expect(stopped, ['run-live']);

      final second = await removal.handle(left(_ws));
      expect(second, (goals: 0, wakes: 0, cards: 0, runs: 0));
      expect(w.rowUpdates, 1, reason: 'the row is stamped once');
    });

    test('a person who is a member again by the time it is handled is left '
        'alone', () async {
      await w.wakes.insertIfAbsent(held('stop-mine'));
      w.queueCard('c-mine');
      expect(
        await removal.handle(left(_ws)),
        (goals: 0, wakes: 0, cards: 0, runs: 0),
      );
      expect(
        (await w.wakes.getById(_ws, 'stop-mine'))!.state,
        WakeState.held,
      );
      expect(w.cards.keys, ['c-mine']);
    });

    test('a removed person\'s run that a server stop ended leaves no held '
        'recovery wake behind', () async {
      w
        ..runRow('run-1')
        ..removed.add('$_ws/$_person');
      await w.settle('run-1', reason: RunEndReason.serverStopped);
      expect(
        [for (final x in w.wakes.all(_ws)) x.reason],
        isNot(contains(WakeReason.recovery)),
      );
      w.removed.clear();
      w.runRow('run-2');
      await w.settle('run-2', reason: RunEndReason.serverStopped);
      expect(
        [for (final x in w.wakes.all(_ws)) x.reason],
        contains(WakeReason.recovery),
      );
    });
  });

  group("a park's ending", () {
    /// A park wake shaped as [kind] makes it: a person's and a credential
    /// park's wake is held for the person; a rule's and a goal's is pending.
    Wake shaped(String kind, {DateTime? expiresAt, bool bot = false}) {
      final held = kind == 'person' || kind == 'credential';
      return Wake(
        id: 'park-$kind',
        workspaceId: _ws,
        spaceId: _space,
        conversationId: _conv,
        agentId: _agent,
        reason: WakeReason.limitReset,
        payload: '',
        detail: WakeDetail(
          sourceRunId: 'src-$kind',
          goalId: kind == 'goal' ? 'goal-1' : null,
          ruleId: kind == 'rule' ? 'rule-1' : null,
        ),
        dedupKey: LimitPark.dedupKey('src-$kind'),
        notBefore: w.now.add(const Duration(hours: 1)),
        expiresAt: expiresAt,
        requestedByUserId: bot ? null : _person,
        state: held ? WakeState.held : WakeState.pending,
        stateReason: held ? LimitPark.heldReason : null,
        createdAt: w.now,
      );
    }

    for (final kind in ['person', 'credential', 'rule', 'goal']) {
      final held = kind == 'person' || kind == 'credential';
      final hold = LimitPark.dedupKey('src-$kind');

      /// The run's end at the limit held one card of the park's person and
      /// one of someone else, before the park's wake was written.
      Future<void> heldAtTheLimit() async {
        w
          ..queueCard('c-mine')
          ..queueCard('c-theirs', sender: 'user-2');
        await w.steerHold(p, 'src-$kind');
        expect(w.holderOf('c-mine'), 'stop', reason: 'no pause yet');
        expect(await p.queue.enqueue(shaped(kind)), isTrue);
        expect(w.holderOf('c-mine'), hold, reason: 'the pause adopts them');
        // Only the pause's person's cards wait with it: another writer's
        // are a Stop's at once, theirs to send while the pause waits.
        expect(w.holderOf('c-theirs'), 'stop');
        expect(w.cards['c-theirs']!.resetsAt, isNull);
      }

      test(
        "$kind: delivered at the reset sends its person's cards once; "
        "another writer's become a Stop's",
        () async {
          await heldAtTheLimit();
          await w.advance(p, const Duration(hours: 1, seconds: 1));
          if (held) {
            expect(w.dispatched, isEmpty, reason: 'held for its person');
            await p.queue.release(_ws, wakeId: 'park-$kind', userId: _person);
            await w.advance(p, const Duration(seconds: 1));
          }
          expect(w.dispatched, hasLength(1));
          expect(w.sent, ['c-mine']);
          expect(w.holderOf('c-theirs'), 'stop');
        },
      );

      test('$kind: released early, the cards go when it runs', () async {
        await heldAtTheLimit();
        if (held) {
          await p.queue.release(_ws, wakeId: 'park-$kind', userId: _person);
          await w.advance(p, const Duration(minutes: 30));
          expect(w.dispatched, isEmpty, reason: 'it waits for the reset');
          expect(w.sent, isEmpty);
          await w.advance(p, const Duration(minutes: 31));
        } else {
          await p.queue.deliverNow(_ws, 'park-$kind', userId: _person);
          await w.pump();
        }
        expect(w.dispatched, hasLength(1));
        expect(w.sent, ['c-mine']);
      });

      test("$kind: cancelled, the cards become a Stop's, unsent", () async {
        await heldAtTheLimit();
        expect(
          await p.queue.cancel(_ws, 'park-$kind', reason: 'person'),
          isTrue,
        );
        await w.advance(p, const Duration(hours: 2));
        expect(w.dispatched, isEmpty);
        expect(w.sent, isEmpty);
        expect(w.holderOf('c-mine'), 'stop');
        expect(w.cards['c-mine']!.resetsAt, isNull);
      });

      test("$kind: expired, the cards become a Stop's, unsent", () async {
        w
          ..queueCard('c-mine')
          ..queueCard('c-theirs', sender: 'user-2');
        await w.steerHold(p, 'src-$kind');
        final expiry = w.now.add(const Duration(minutes: 30));
        expect(await p.queue.enqueue(shaped(kind, expiresAt: expiry)), isTrue);
        expect(w.holderOf('c-mine'), hold);
        await w.advance(p, const Duration(minutes: 31));
        await w.advance(p, WakeQueueService.maintenanceEvery);
        expect(w.limitWakes().single.state, WakeState.expired);
        await w.advance(p, const Duration(hours: 1));
        expect(w.dispatched, isEmpty);
        expect(w.sent, isEmpty);
        expect(w.holderOf('c-mine'), 'stop');
      });

      test("$kind: skipped, the cards become a Stop's, unsent", () async {
        await heldAtTheLimit();
        final wake = w.limitWakes().single;
        await w.wakes.markSkipped(
          _ws,
          ids: [wake.id],
          reason: 'agent_deleted',
          now: w.now,
        );
        await p.parks.onWakeSettled(
          WakeSettlement(
            wake: wake,
            state: WakeState.skipped,
            reason: 'agent_deleted',
          ),
        );
        expect(w.sent, isEmpty);
        expect(w.holderOf('c-mine'), 'stop');
      });
    }

    test("a rule's pause that acts for no one gives every card back as a "
        "Stop's at once", () async {
      w
        ..queueCard('c-1')
        ..queueCard('c-2', sender: 'user-2');
      await w.steerHold(p, 'src-rule');
      expect(await p.queue.enqueue(shaped('rule', bot: true)), isTrue);
      expect(w.holderOf('c-1'), 'stop');
      expect(w.holderOf('c-2'), 'stop');
    });

    test('a park that ends while another park of the same run still waits '
        'leaves the cards to that park', () async {
      final first = shaped('person');
      w.queueCard('c-1');
      await w.steerHold(p, 'src-person');
      expect(await p.queue.enqueue(first), isTrue);
      expect(
        await p.queue.enqueue(
          first.copyWith(id: 'park-again', dedupKey: 'limit:src-person:r2'),
        ),
        isTrue,
      );
      await p.queue.cancel(_ws, first.id, reason: 'person');
      await w.pump();
      expect(w.holderOf('c-1'), LimitPark.dedupKey('src-person'));
    });

    group('a run that gets no pause', () {
      final reset = DateTime.utc(2026, 11, 19, 13);

      for (final reason in [WakeReason.peerReply, WakeReason.assignment]) {
        test("a ${reason.name} run: its cards are a Stop's at once, unsent",
            () async {
          w
            ..runRow('run-x', wakeReason: reason)
            ..queueCard('c-1');
          await w.settle('run-x', resetsAt: reset, wakeReason: reason);
          await w.steerHold(p, 'run-x');
          expect(w.limitWakes(), isEmpty);
          expect(w.holderOf('c-1'), 'stop');
          expect(w.sent, isEmpty);
          expect(w.dispatched, isEmpty);
        });
      }

      test("a goal's run its goal does not park (past its park limit): "
          "a Stop's", () async {
        final segment = Wake(
          id: 'goal-seg',
          workspaceId: _ws,
          spaceId: _space,
          conversationId: _conv,
          agentId: _agent,
          reason: WakeReason.goalContinuation,
          payload: '',
          detail: WakeDetail(goalId: 'goal-1'),
          dedupKey: 'goal:goal-1:9',
          notBefore: w.now,
          requestedByUserId: _person,
          state: WakeState.delivered,
          createdAt: w.now,
        );
        await w.wakes.insertIfAbsent(segment);
        w
          ..runRow('run-g', wakeIds: ['goal-seg'])
          ..queueCard('c-1');
        await w.settle('run-g', resetsAt: reset, wakeIds: ['goal-seg']);
        await w.steerHold(p, 'run-g');
        expect(w.limitWakes(), isEmpty);
        expect(w.holderOf('c-1'), 'stop');
      });

      test("the server is stopping: a Stop's", () async {
        p.queue.beginStopping();
        w
          ..runRow('run-s')
          ..queueCard('c-1');
        await w.settle('run-s', resetsAt: reset);
        await w.steerHold(p, 'run-s');
        expect(w.limitWakes(), isEmpty);
        expect(w.holderOf('c-1'), 'stop');
      });

      test("a person's run gets its pause, whichever lands first", () async {
        w
          ..runRow('run-p')
          ..queueCard('c-1');
        // The steering queue first: no pause yet, a Stop's; the pause's
        // wake then adopts the card.
        await w.steerHold(p, 'run-p');
        expect(w.holderOf('c-1'), 'stop');
        await w.settle('run-p', resetsAt: reset);
        expect(w.holderOf('c-1'), LimitPark.dedupKey('run-p'));
        expect(w.cards['c-1']!.resetsAt, reset);
        // The pause first: the steering queue's hold finds it.
        w
          ..runRow('run-q')
          ..queueCard('c-2');
        await w.settle('run-q', resetsAt: reset);
        await w.steerHold(p, 'run-q');
        expect(w.holderOf('c-2'), LimitPark.dedupKey('run-q'));
      });
    });

    group('the boot sweep', () {
      test('a pause that settled while the server was down: its cards become '
          "a Stop's; a pause still waiting, and a Stop's cards, are left",
          () async {
        // run-a's park was cancelled and the server stopped before its
        // settlement was heard; src-person's park still waits; run-b held
        // its card and the server stopped before its pause adopted it.
        final settled = shaped('person').copyWith(
          id: 'park-a',
          detail: WakeDetail(sourceRunId: 'run-a'),
          dedupKey: LimitPark.dedupKey('run-a'),
        );
        await w.wakes.insertIfAbsent(settled);
        await w.wakes.cancel(
          _ws,
          ids: [settled.id],
          reason: 'person',
          now: w.now,
        );
        final waiting = shaped('person');
        await w.wakes.insertIfAbsent(waiting);
        final adopting = shaped('person').copyWith(
          id: 'park-b',
          detail: WakeDetail(
            sourceRunId: 'run-b',
            fields: {'resetsAt': '2026-11-19T13:00:00.000Z'},
          ),
          dedupKey: LimitPark.dedupKey('run-b'),
        );
        await w.wakes.insertIfAbsent(adopting);
        w.cards
          ..['m-1'] = (_Card(_person)
            ..state = 'held'
            ..heldBy = LimitPark.dedupKey('run-a'))
          ..['m-2'] = (_Card(_person)
            ..state = 'held'
            ..heldBy = waiting.dedupKey
            ..run = 'src-person')
          ..['m-3'] = (_Card(_person)
            ..state = 'held'
            ..heldBy = 'stop'
            ..run = 'run-b')
          ..['m-4'] = (_Card(_person)
            ..state = 'held'
            ..heldBy = 'stop');
        expect(await p.parks.sweepAtBoot([_ws, 'ws-other']), 2);
        expect(w.holderOf('m-1'), 'stop');
        expect(w.holderOf('m-2'), waiting.dedupKey);
        expect(w.holderOf('m-3'), LimitPark.dedupKey('run-b'));
        expect(w.cards['m-3']!.resetsAt, DateTime.utc(2026, 11, 19, 13));
        expect(w.holderOf('m-4'), 'stop');
        expect(w.sent, isEmpty);
      });

      test('runs before the queue starts: a pause due at boot is delivered '
          'with its cards, never re-held as a Stop\'s', () async {
        await p.stop();
        p = _Process(w);
        final due = shaped('rule').copyWith(notBefore: w.now);
        await w.wakes.insertIfAbsent(due);
        w.cards['c-1'] = _Card(_person)
          ..state = 'held'
          ..heldBy = LimitPark.dedupKey('src-rule')
          ..run = 'src-rule';
        await p.parks.startQueueAfterSweep(() async => [_ws]);
        await w.advance(p, const Duration(seconds: 1));
        expect(w.sweepSaw.single, ['park-rule:pending']);
        expect(w.dispatched, hasLength(1));
        expect(w.sent, ['c-1']);
      });

      test('the queue starts even when listing the workspaces fails',
          () async {
        await p.stop();
        p = _Process(w);
        await w.wakes.insertIfAbsent(shaped('rule').copyWith(notBefore: w.now));
        await p.parks.startQueueAfterSweep(
          () async => throw StateError('registry down'),
        );
        await w.advance(p, const Duration(seconds: 1));
        expect(w.sweepSaw, isEmpty);
        expect(w.dispatched, hasLength(1));
      });

      test("a person's park row whose settlement was lost gets its outcome; "
          'a waiting one is left', () async {
        w.runRow('run-1');
        await w.settle('run-1', resetsAt: w.now.add(const Duration(hours: 1)));
        w.runRow('run-2');
        await w.settle('run-2', resetsAt: w.now.add(const Duration(hours: 1)));
        final lost = w.limitWakes().firstWhere(
          (x) => x.detail.sourceRunId == 'run-1',
        );
        await w.wakes.cancel(_ws, ids: [lost.id], reason: 'p', now: w.now);
        expect(await p.parks.sweepAtBoot([_ws]), 1);
        final byRun = {
          for (final r in w.rows) r.metadata['runId']: r.metadata,
        };
        expect(byRun['run-1']![LimitPark.rowOutcomeKey], 'cancelled');
        expect(byRun['run-2']![LimitPark.rowOutcomeKey], isNull);
      });

      test('a row whose wake is gone is stamped skipped', () async {
        w.runRow('run-1');
        await w.settle('run-1', resetsAt: w.now.add(const Duration(hours: 1)));
        final wake = w.limitWakes().single;
        await w.wakes.cancel(_ws, ids: [wake.id], reason: 'p', now: w.now);
        await w.wakes.deleteSettledBefore(
          _ws,
          cutoff: w.now.add(const Duration(days: 1)),
        );
        expect(await p.parks.sweepAtBoot([_ws]), 1);
        expect(
          w.rows.single.metadata[LimitPark.rowOutcomeKey],
          LimitPark.outcomeSkipped,
        );
      });
    });

    group("the person's row records how it ended, once", () {
      late Wake wake;

      setUp(() async {
        w.runRow('run-1');
        await w.settle('run-1', resetsAt: w.now.add(const Duration(hours: 1)));
        wake = w.limitWakes().single;
      });

      Map<String, Object?> row() => w.rows.single.metadata;

      test('resumed', () async {
        await p.queue.release(_ws, wakeId: wake.id, userId: _person);
        await w.advance(p, const Duration(hours: 1, minutes: 1));
        expect(w.dispatched, hasLength(1));
        expect(row()[LimitPark.rowOutcomeKey], LimitPark.outcomeResumed);
        expect(row()[LimitPark.rowSettledAtKey], w.now.toIso8601String());
      });

      test('cancelled, and a second settle changes nothing', () async {
        await p.queue.cancel(_ws, wake.id, reason: 'person');
        await w.pump();
        expect(row()[LimitPark.rowOutcomeKey], LimitPark.outcomeCancelled);
        final settledAt = row()[LimitPark.rowSettledAtKey];
        w.now = w.now.add(const Duration(minutes: 5));
        await p.parks.onWakeSettled(
          WakeSettlement(wake: wake, state: WakeState.expired),
        );
        expect(row()[LimitPark.rowOutcomeKey], LimitPark.outcomeCancelled);
        expect(row()[LimitPark.rowSettledAtKey], settledAt);
        expect(w.rowUpdates, 1);
      });

      test('expired', () async {
        await p.parks.onWakeSettled(
          WakeSettlement(wake: wake, state: WakeState.expired),
        );
        expect(row()[LimitPark.rowOutcomeKey], LimitPark.outcomeExpired);
        expect(row().containsKey(LimitPark.rowSkipKindKey), isFalse);
      });

      test('skipped, with the skip kind', () async {
        await p.parks.onWakeSettled(
          WakeSettlement(
            wake: wake,
            state: WakeState.skipped,
            reason: 'agent_deleted',
          ),
        );
        expect(row()[LimitPark.rowOutcomeKey], LimitPark.outcomeSkipped);
        expect(row()[LimitPark.rowSkipKindKey], 'agent_deleted');
      });

      test("a rule's or a goal's park has no person's row to stamp", () async {
        final rule = Wake(
          id: 'rule-park',
          workspaceId: _ws,
          spaceId: _space,
          conversationId: _conv,
          agentId: _agent,
          reason: WakeReason.limitReset,
          payload: '',
          detail: WakeDetail(ruleId: 'rule-1', sourceRunId: 'run-9'),
          dedupKey: LimitPark.dedupKey('run-9'),
          notBefore: w.now,
          createdAt: w.now,
        );
        await p.parks.onWakeSettled(
          WakeSettlement(wake: rule, state: WakeState.cancelled),
        );
        expect(w.rowUpdates, 0);
      });
    });
  });
}
