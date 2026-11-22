import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show AuthException, WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_run_options.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_harness/context.dart'
    show ToolCallForms, plainToolForm;
import 'package:cc_harness/loop.dart' show SteeringQueue;
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/dispatch/sandboxed_agent_dispatch_adapter.dart';
import 'package:cc_infra/src/dispatch/steering_session_view.dart';
import 'package:cc_infra/src/dispatch/wake_queue_service.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:test/test.dart';

import 'fake_wake_repository.dart';

class _NoTimer implements Timer {
  _NoTimer(this.delay);

  final Duration delay;
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled;

  @override
  int get tick => 0;
}

/// A live run of an agent: the harness (or the Claude stdin pump) drains
/// its queue at its own turn boundaries; tests drain it by hand.
class _Session implements SteeringSessionView {
  _Session({
    this.workspaceId = 'ws-1',
    this.acceptsSteering = true,
    this.runLogId = 'live-run',
    this.requestedByUserId,
    this.readOnly = false,
    this.freshHistory = false,
  });

  @override
  final String? workspaceId;
  @override
  String? get conversationId => 'conv-1';
  @override
  String? get agentId => 'agent-1';
  @override
  final String? runLogId;
  @override
  final String? requestedByUserId;
  @override
  final bool readOnly;
  @override
  final bool freshHistory;
  @override
  bool acceptsSteering;
  @override
  String? get spaceId => 'sp-1';
  @override
  final SteeringQueue steeringQueue = SteeringQueue();

  @override
  ToolCallForms toolForms = plainToolForm;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A Claude Code run whose turn ended while its background task runs: live,
/// accepting, and held only for that wait until it yields.
class _HeldSession extends _Session implements BackgroundHoldView {
  _HeldSession({super.requestedByUserId});

  int yields = 0;

  @override
  bool heldForBackgroundOnly = true;

  @override
  void yieldBackgroundHold() {
    yields++;
    acceptsSteering = false;
  }
}

/// What the real dispatch service and adapter reach before a run row: each
/// call is recorded in [_reached], and none is expected before a refusal.
final List<Symbol> _reached = [];

class _UseCase implements DispatchAgentUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    _reached.add(invocation.memberName);
    return super.noSuchMethod(invocation);
  }
}

class _RunLogs implements AgentRunLogRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    _reached.add(invocation.memberName);
    return super.noSuchMethod(invocation);
  }
}

class _Sandbox implements SandboxPort {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    _reached.add(invocation.memberName);
    return super.noSuchMethod(invocation);
  }
}

class _Manager implements SandboxManager {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    _reached.add(invocation.memberName);
    return super.noSuchMethod(invocation);
  }
}

class _Agents implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    _reached.add(invocation.memberName);
    return super.noSuchMethod(invocation);
  }
}

class _Guard implements WakeAdmissionGuard {
  _Guard(this.answer);

  WakeAdmission Function(Wake wake) answer;

  @override
  Future<WakeAdmission> admit(Wake wake, {required DateTime now}) async =>
      answer(wake);
}

class _AsyncGuard implements WakeAdmissionGuard {
  _AsyncGuard(this.answer);

  final Future<WakeAdmission> Function(Wake wake) answer;

  @override
  Future<WakeAdmission> admit(Wake wake, {required DateTime now}) =>
      answer(wake);
}

void main() {
  late FakeWakeRepository repo;
  late FakeWakeRunLedger ledger;
  late DomainEventBus bus;
  late DateTime now;
  late List<WakeDispatchRequest> dispatched;
  late List<
    ({String conversationId, String content, Map<String, Object?> metadata})
  >
  rows;
  late List<_Session> sessions;
  late Map<String, Agent?> agents;
  late Set<String> foreignRecords;
  late Set<String> members;
  late Set<String> activeWorkspaces;
  late bool takenOver;
  late bool budgetBlocked;
  late bool liveRun;
  late Future<String?> Function(WakeDispatchRequest run) onDispatch;
  late List<WakeSettlement> settlements;
  late WakeQueueService queue;
  var runSeq = 0;
  var idSeq = 0;

  Agent agent(String id, {AgentLifecycleStatus? status}) => Agent(
    id: id,
    name: id == 'agent-1' ? 'Builder' : 'Reviewer',
    title: 't',
    agentMdPath: '/tmp/$id.md',
    workspaceId: 'ws-1',
    skills: AgentSkills(const []),
    createdAt: DateTime.utc(2026),
    lifecycleStatus: status ?? AgentLifecycleStatus.active,
  );

  WakeQueueService build() {
    final q = WakeQueueService(
      wakes: repo,
      runLedger: ledger,
      eventBus: bus,
      clock: () => now,
      timerFactory: (delay, _) => _NoTimer(delay),
      nonce: () => 'nonce1',
      newId: () => 'gen-${idSeq++}',
      ports: WakeQueuePorts(
        workspaceActive: (ws) async => activeWorkspaces.contains(ws),
        // Every conversation of these tests is in `sp-1` of both workspaces,
        // except those named in [foreignRecords] (`<ws>/<id>`).
        conversationSpace: (ws, conv) async =>
            foreignRecords.contains('$ws/$conv') ? null : 'sp-1',
        agent: (ws, id) async =>
            foreignRecords.contains('$ws/$id') ? null : agents[id],
        isMember: (ws, user) async => members.contains(user),
        takenOver: (ws, space) async => takenOver,
        budgetBlocked: (ws, agentId) async => budgetBlocked,
        liveSessions: (conv) => [
          for (final s in sessions)
            if (s.conversationId == conv) s,
        ],
        hasLiveRun: (ws, conv, agentId) async => liveRun,
        dispatch: (run) {
          dispatched.add(run);
          return onDispatch(run);
        },
        postSystemRow:
            ({
              required String workspaceId,
              required String spaceId,
              required String conversationId,
              required String content,
              required Map<String, Object?> metadata,
            }) async => rows.add((
              conversationId: conversationId,
              content: content,
              metadata: metadata,
            )),
      ),
    )..registerSettledHandler(settlements.add);
    return q;
  }

  setUp(() async {
    repo = FakeWakeRepository();
    ledger = FakeWakeRunLedger();
    bus = DomainEventBus();
    now = DateTime.utc(2026, 5, 1, 12);
    dispatched = [];
    rows = [];
    sessions = [];
    agents = {'agent-1': agent('agent-1'), 'agent-2': agent('agent-2')};
    foreignRecords = {};
    members = {'user-1'};
    activeWorkspaces = {'ws-1', 'ws-2'};
    takenOver = false;
    budgetBlocked = false;
    liveRun = false;
    settlements = [];
    runSeq = 0;
    onDispatch = (_) async => 'run-${++runSeq}';
    queue = build();
    await queue.start();
  });

  tearDown(() async {
    await queue.stop();
    bus.dispose();
  });

  Wake wake(
    String id, {
    String workspaceId = 'ws-1',
    String conversationId = 'conv-1',
    String agentId = 'agent-1',
    WakeReason reason = WakeReason.peerMessage,
    String? payload,
    DateTime? notBefore,
    String? requestedByUserId,
    WakeLane lane = WakeLane.aside,
    String? dedupKey,
    DateTime? expiresAt,
    List<String> chain = const [],
    WakeRunOptions? runOptions,
    String spaceId = 'sp-1',
  }) => Wake(
    id: id,
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    agentId: agentId,
    reason: reason,
    lane: lane,
    runOptions: runOptions,
    payload: payload ?? 'payload $id',
    detail: WakeDetail(sourceAgentId: 'agent-2'),
    dedupKey: dedupKey ?? 'key:$id',
    notBefore: notBefore ?? now,
    expiresAt: expiresAt,
    requestedByUserId: requestedByUserId,
    chain: chain,
    createdAt: now,
  );

  Future<void> advance(Duration by) async {
    now = now.add(by);
    await queue.tick();
    await pumpEventQueue();
  }

  WakeState stateOf(String id, {String ws = 'ws-1'}) =>
      repo.all(ws).firstWhere((w) => w.id == id).state;

  Wake rowOf(String id, {String ws = 'ws-1'}) =>
      repo.all(ws).firstWhere((w) => w.id == id);

  void settle(
    String runId, {
    RunEndReason endReason = RunEndReason.completed,
    List<String> wakeIds = const [],
    String? requestedByUserId,
    WakeReason? wakeReason,
    String agentId = 'agent-1',
    String workspaceId = 'ws-1',
  }) => bus.publish(
    AgentRunSettled(
      agentId: agentId,
      workspaceId: workspaceId,
      spaceId: 'sp-1',
      conversationId: 'conv-1',
      runId: runId,
      status: endReason == RunEndReason.completed
          ? RunStatus.completed
          : RunStatus.error,
      endReason: endReason,
      costMicros: 0,
      limitResetsAt: null,
      wakeIds: wakeIds,
      requestedByUserId: requestedByUserId,
      wakeReason: wakeReason,
      occurredAt: now,
    ),
  );

  group('insert', () {
    test('a duplicate dedup key inserts nothing', () async {
      expect(await queue.enqueue(wake('a', dedupKey: 'same')), isTrue);
      expect(await queue.enqueue(wake('b', dedupKey: 'same')), isFalse);
      expect(
        await queue.enqueueAndDeliver(wake('c', dedupKey: 'same')),
        isA<WakeDuplicate>(),
      );
      expect(repo.all('ws-1'), hasLength(1));
    });

    test('an unregistered workspace is refused before its database', () async {
      activeWorkspaces.remove('ws-2');
      await expectLater(
        queue.enqueue(wake('a', workspaceId: 'ws-2')),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      expect(repo.all('ws-2'), isEmpty);
    });

    test('a conversation of another workspace is refused', () async {
      foreignRecords.add('ws-1/conv-9');
      for (final insert in <Future<Object?> Function()>[
        () => queue.enqueue(wake('a', conversationId: 'conv-9')),
        () => queue.enqueueAndDeliver(wake('b', conversationId: 'conv-9')),
      ]) {
        await expectLater(insert(), throwsA(isA<WorkspaceMismatchException>()));
      }
      expect(repo.all('ws-1'), isEmpty);
    });

    test('an agent of another workspace is refused', () async {
      foreignRecords.add('ws-2/agent-1');
      await expectLater(
        queue.enqueue(wake('a', workspaceId: 'ws-2')),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      expect(repo.all('ws-2'), isEmpty);
    });

    test('a space the conversation is not in is refused', () async {
      await expectLater(
        queue.enqueue(wake('a', spaceId: 'sp-other')),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      expect(repo.all('ws-1'), isEmpty);
    });
  });

  group('delivery', () {
    test('starts one run with the wakes, marks them delivered and leaves '
        'one system row', () async {
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      expect(dispatched, hasLength(1));
      final run = dispatched.single;
      expect(run.wakeContext.wakeIds, ['a']);
      expect(run.wakeContext.nonce, 'nonce1');
      expect(run.wakeContext.wakeReason, WakeReason.peerMessage);
      expect(run.inReplyToAgentId, 'agent-2');
      expect(run.requestedByUserId, isNull);
      expect(run.prompt, isNot(contains('payload a')));
      final delivered = rowOf('a');
      expect(delivered.state, WakeState.delivered);
      expect(delivered.deliveredRunId, 'run-1');
      expect(rows, hasLength(1));
      expect(rows.single.content, startsWith('Woke Builder: [peer-message]'));
      expect(rows.single.metadata, {
        'kind': wakeDeliveredRowKind,
        'wakeIds': ['a'],
        'wakeReason': 'peer_message',
        'wakeOrigin': 'peer-message',
        'wakeHeadline': wakeHeadline(rowOf('a')),
        'wakeRunId': 'run-1',
        'wakeAgentId': 'agent-1',
        'wakeSourceAgentId': 'agent-2',
      });
      // The headline the text shows, as data: no parsing after "] ".
      expect(
        rows.single.content,
        endsWith('] ${rows.single.metadata['wakeHeadline']}'),
      );
      expect(settlements.single.state, WakeState.delivered);
      expect(settlements.single.runId, 'run-1');
    });

    test('the quiet window groups wakes that arrive together', () async {
      await queue.enqueue(wake('a'));
      await advance(const Duration(seconds: 1));
      expect(dispatched, isEmpty);
      await queue.enqueue(wake('b'));
      await advance(const Duration(seconds: 1));
      expect(dispatched.single.wakeContext.wakeIds, ['a', 'b']);
    });

    test(
      'a wake that becomes due on the timer skips the quiet window',
      () async {
        await queue.enqueue(
          wake('a', notBefore: now.add(const Duration(minutes: 5))),
        );
        await advance(const Duration(minutes: 5));
        expect(dispatched.single.wakeContext.wakeIds, ['a']);
      },
    );

    test('more than ten wakes due: ten go now, the rest wait', () async {
      for (var i = 0; i < 12; i++) {
        await queue.enqueue(
          wake('w$i', notBefore: now.subtract(Duration(seconds: 60 - i))),
        );
      }
      await advance(WakeQueueService.quietWindow);
      expect(dispatched.first.wakeContext.wakeIds, hasLength(10));
      final waiting = repo
          .all('ws-1')
          .where((w) => w.state == WakeState.pending)
          .map((w) => w.id);
      expect(waiting, unorderedEquals(['w10', 'w11']));
    });

    test('a delivery carries at most 16,000 payload characters', () {
      final big = [
        for (var i = 0; i < 6; i++) wake('b$i', payload: 'x' * 3500),
      ];
      final batch = WakeQueueService.takeBatch(big);
      expect(batch, hasLength(4));
    });

    test('wakes for different people never share a run', () {
      final batch = WakeQueueService.takeBatch([
        wake('a', requestedByUserId: 'user-1'),
        wake('b'),
        wake('c', requestedByUserId: 'user-1'),
      ]);
      expect([for (final w in batch) w.id], ['a', 'c']);
    });

    test('two deliveries racing start one run', () async {
      await queue.enqueue(
        wake('a', notBefore: now.subtract(const Duration(seconds: 10))),
      );
      final gate = Completer<String?>();
      onDispatch = (_) => gate.future;
      now = now.add(WakeQueueService.quietWindow);
      final first = queue.deliverNow('ws-1', 'a', userId: 'user-1');
      final second = queue.tick();
      final third = queue.deliverNow('ws-1', 'a', userId: 'user-1');
      await pumpEventQueue();
      gate.complete('run-x');
      final receipts = await Future.wait([first, third]);
      await second;
      expect(dispatched, hasLength(1));
      expect(receipts.first, isA<WakeStarted>());
      expect(rowOf('a').deliveredRunId, 'run-x');
      expect(rows.where((r) => r.metadata['kind'] == 'wake'), hasLength(1));
    });

    test(
      'a refused dispatch retries, then skips after three attempts',
      () async {
        onDispatch = (_) async => null;
        await queue.enqueue(wake('a'));
        await advance(WakeQueueService.quietWindow);
        expect(rowOf('a').stateReason, WakeStateReasons.dispatchRefused);
        await advance(const Duration(minutes: 1));
        await advance(const Duration(minutes: 1));
        expect(dispatched, hasLength(3));
        expect(stateOf('a'), WakeState.skipped);
        expect(rowOf('a').stateReason, WakeStateReasons.attempts);
        expect(rows.single.metadata['kind'], wakeSkippedRowKind);
        expect(rows.single.metadata['wakeHeadline'], wakeHeadline(rowOf('a')));
        expect(
          rows.single.content,
          endsWith('] ${rows.single.metadata['wakeHeadline']}'),
        );
      },
    );

    for (final (name, posture, manager) in [
      ('sandbox off', HostExecutionPosture.offByOwner, _Manager()),
      ('no sandbox', HostExecutionPosture.sandboxed, null),
    ]) {
      test('a read-only wake on a host with $name is skipped before any '
          'run row', () async {
        _reached.clear();
        final service = AgentDispatchService(
          agentDispatch: SandboxedAgentDispatchAdapter(
            hostExecution: HostExecutionGate(posture: posture),
            sandbox: _Sandbox(),
            agentRepository: _Agents(),
            sandboxManager: manager,
          ),
          dispatchUseCase: _UseCase(),
          runLogRepo: _RunLogs(),
        );
        onDispatch = (run) async => (await service.dispatch(
          agentId: run.agentId,
          prompt: run.prompt,
          workingDirectory: '/tmp/work',
          workspaceId: run.workspaceId,
          spaceId: run.spaceId,
          conversationId: run.conversationId,
          freshHistory: run.freshHistory,
          readOnly: run.readOnly,
          requestedByUserId: run.requestedByUserId,
          wakeContext: run.wakeContext,
        )).runLog.id;
        await queue.enqueue(
          wake('a', runOptions: WakeRunOptions(readOnly: true)),
        );
        await advance(WakeQueueService.quietWindow);
        expect(dispatched.single.readOnly, isTrue);
        expect(_reached, isEmpty, reason: 'no run row, no preparation');
        expect(stateOf('a'), WakeState.skipped);
        expect(rowOf('a').stateReason, WakeStateReasons.sandboxUnavailable);
        expect(settlements, hasLength(1));
        expect(settlements.single.reason, WakeStateReasons.sandboxUnavailable);
        expect(
          rows.single.metadata['wakeSkipKind'],
          WakeStateReasons.sandboxUnavailable,
        );
      });
    }

    test('an expired wake is not delivered', () async {
      await queue.enqueue(
        wake(
          'a',
          notBefore: now.add(const Duration(minutes: 2)),
          expiresAt: now.add(const Duration(minutes: 1)),
        ),
      );
      await advance(const Duration(minutes: 2));
      expect(dispatched, isEmpty);
      expect(stateOf('a'), WakeState.expired);
      expect(settlements.single.state, WakeState.expired);
    });
  });

  group('admission', () {
    test('a deleted agent skips with one system row', () async {
      await queue.enqueue(wake('a'));
      agents.remove('agent-1');
      await advance(WakeQueueService.quietWindow);
      expect(dispatched, isEmpty);
      expect(rowOf('a').stateReason, WakeStateReasons.agentDeleted);
      expect(
        rows.single.metadata['wakeSkipKind'],
        WakeStateReasons.agentDeleted,
      );
    });

    test('an archived agent skips with one system row', () async {
      await queue.enqueue(wake('a'));
      await queue.enqueue(wake('b'));
      agents['agent-1'] = agent(
        'agent-1',
        status: AgentLifecycleStatus.archived,
      );
      await advance(WakeQueueService.quietWindow);
      expect(dispatched, isEmpty);
      expect(stateOf('a'), WakeState.skipped);
      expect(rowOf('a').stateReason, WakeStateReasons.agentNotDispatchable);
      expect(rows, hasLength(2));
      await advance(const Duration(minutes: 5));
      expect(rows, hasLength(2));
    });

    test('a paused agent: the wake waits, re-checked each minute, and is '
        'delivered once it is resumed', () async {
      agents['agent-1'] = agent('agent-1', status: AgentLifecycleStatus.paused);
      final raised = now;
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      expect(stateOf('a'), WakeState.pending);
      expect(rowOf('a').stateReason, WakeStateReasons.agentPaused);
      expect(
        rowOf('a').expiresAt,
        raised.add(WakeQueueService.maxWaitOnRefusal),
      );
      await advance(const Duration(minutes: 1));
      expect(dispatched, isEmpty);
      expect(rows, isEmpty);
      agents['agent-1'] = agent('agent-1');
      await advance(const Duration(minutes: 1));
      expect(dispatched.single.wakeContext.wakeIds, ['a']);
      expect(settlements.single.state, WakeState.delivered);
    });

    test('a blocked budget: the wake waits, then is delivered when the block '
        'lifts', () async {
      budgetBlocked = true;
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      expect(dispatched, isEmpty);
      expect(stateOf('a'), WakeState.pending);
      expect(rowOf('a').stateReason, WakeStateReasons.budgetBlocked);
      expect(rows, isEmpty);
      budgetBlocked = false;
      await advance(const Duration(minutes: 1));
      expect(dispatched, hasLength(1));
    });

    test('a wake that waits out a budget block for 7 days expires with its '
        'kind: one row, heard once', () async {
      budgetBlocked = true;
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      await advance(const Duration(days: 7));
      expect(dispatched, isEmpty);
      expect(stateOf('a'), WakeState.expired);
      expect(rowOf('a').stateReason, WakeStateReasons.budgetBlocked);
      expect(settlements.single.state, WakeState.expired);
      expect(settlements.single.reason, WakeStateReasons.budgetBlocked);
      expect(rows.single.metadata['kind'], wakeSkippedRowKind);
      expect(
        rows.single.metadata['wakeSkipKind'],
        WakeStateReasons.budgetBlocked,
      );
      await advance(const Duration(days: 1));
      expect(rows, hasLength(1));
      expect(settlements, hasLength(1));
    });

    test("a waiting wake's own expiry bounds the wait", () async {
      agents['agent-1'] = agent('agent-1', status: AgentLifecycleStatus.paused);
      final until = now.add(const Duration(hours: 1));
      await queue.enqueue(wake('a', expiresAt: until));
      await advance(WakeQueueService.quietWindow);
      expect(rowOf('a').expiresAt, until);
      await advance(const Duration(hours: 1));
      expect(stateOf('a'), WakeState.expired);
      expect(settlements.single.reason, WakeStateReasons.agentPaused);
      expect(
        rows.single.metadata['wakeSkipKind'],
        WakeStateReasons.agentPaused,
      );
    });

    test('a person removed from the workspace: their wake skips, a bot '
        'wake still runs', () async {
      await queue.enqueue(wake('a', requestedByUserId: 'user-gone'));
      await queue.enqueue(wake('b'));
      await advance(WakeQueueService.quietWindow);
      expect(rowOf('a').stateReason, WakeStateReasons.personRemoved);
      expect(dispatched.single.wakeContext.wakeIds, ['b']);
    });

    test('a take-over defers, then delivers once handed back', () async {
      takenOver = true;
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      expect(dispatched, isEmpty);
      expect(stateOf('a'), WakeState.pending);
      expect(rowOf('a').stateReason, WakeStateReasons.takeOver);
      takenOver = false;
      await advance(const Duration(minutes: 1));
      expect(dispatched, hasLength(1));
    });

    test('a guard defers or skips', () async {
      final guard = _Guard(
        (w) => w.id == 'a'
            ? const WakeAdmission.defer(reason: 'goal_paused')
            : const WakeAdmission.skip('goal_ended'),
      );
      queue.registerGuard(guard);
      await queue.enqueue(wake('a'));
      await queue.enqueue(wake('b'));
      await advance(WakeQueueService.quietWindow);
      expect(dispatched, isEmpty);
      expect(rowOf('a').stateReason, 'goal_paused');
      expect(stateOf('b'), WakeState.skipped);
      guard.answer = (_) => const WakeAdmission.admit();
      await advance(const Duration(minutes: 1));
      expect(dispatched.single.wakeContext.wakeIds, ['a']);
    });

    test('guards that admit within a cap run the wake at the lowest one, '
        'never above its own', () async {
      queue
        ..registerGuard(_Guard((_) => const WakeAdmission.admitWithin(700000)))
        ..registerGuard(_Guard((_) => const WakeAdmission.admitWithin(400000)))
        ..registerGuard(_Guard((_) => const WakeAdmission.admit()));
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      expect(dispatched.single.costCapMicros, 400000);
      // The stored wake keeps its own options.
      expect(rowOf('a').runOptions, isNull);
    });

    test('the per-conversation cap defers the 31st run in an hour', () async {
      for (var i = 0; i < 30; i++) {
        final id = 'old$i';
        await repo.insertIfAbsent(wake(id));
        await repo.markDelivered('ws-1', ids: [id], runId: 'r$i', now: now);
      }
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      expect(dispatched, isEmpty);
      expect(rowOf('a').stateReason, WakeStateReasons.rateCapConversation);
    });

    test('the per-workspace cap defers across conversations', () async {
      for (var i = 0; i < 300; i++) {
        final id = 'old$i';
        await repo.insertIfAbsent(
          wake(id, conversationId: 'conv-${i % 20 + 2}'),
        );
        await repo.markDelivered('ws-1', ids: [id], runId: 'r$i', now: now);
      }
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      expect(dispatched, isEmpty);
      expect(rowOf('a').stateReason, WakeStateReasons.rateCapWorkspace);
    });
  });

  group('live runs', () {
    for (final lane in WakeLane.values) {
      test('a wake for a live run goes into its ${lane.name} lane and is '
          'delivered when the run drains it', () async {
        final session = _Session();
        sessions.add(session);
        queue.handleHarnessStarted(session);
        await queue.enqueue(wake('a', lane: lane));
        await advance(WakeQueueService.quietWindow);
        expect(dispatched, isEmpty);
        expect(stateOf('a'), WakeState.claimed);
        final drained = lane == WakeLane.aside
            ? session.steeringQueue.drainAside()
            : session.steeringQueue.drainFollowUp();
        expect(drained.single.ref, 'wake:a');
        expect(drained.single.content, startsWith('## Why you were woken\n'));
        expect(
          drained.single.content,
          contains('<wake-data id="nonce1">payload a</wake-data id="nonce1">'),
        );
        await pumpEventQueue();
        expect(rowOf('a').state, WakeState.delivered);
        expect(rowOf('a').deliveredRunId, 'live-run');
        expect(ledger.runs['ws-1']!['live-run'], ['a']);
        expect(settlements.single.runId, 'live-run');
      });
    }

    test('a wake left undrained when the run ends is delivered once, by a '
        'new run', () async {
      final session = _Session();
      sessions.add(session);
      queue.handleHarnessStarted(session);
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      expect(stateOf('a'), WakeState.claimed);
      sessions.clear();
      settle('live-run');
      await pumpEventQueue();
      expect(session.steeringQueue.drainAside(), isEmpty);
      expect(dispatched.single.wakeContext.wakeIds, ['a']);
      expect(rowOf('a').deliveredRunId, 'run-1');
      settle('run-1', wakeIds: ['a']);
      await advance(const Duration(minutes: 5));
      expect(dispatched, hasLength(1));
    });

    test(
      'a live run that takes no input (ACP) waits for its settlement',
      () async {
        sessions.add(_Session(acceptsSteering: false));
        await queue.enqueue(wake('a'));
        await advance(WakeQueueService.quietWindow);
        expect(dispatched, isEmpty);
        expect(rowOf('a').stateReason, WakeStateReasons.liveRunNoInput);
        sessions.clear();
        settle('live-run');
        await pumpEventQueue();
        expect(dispatched.single.wakeContext.wakeIds, ['a']);
      },
    );

    test('a run in the log with no session yet also waits', () async {
      liveRun = true;
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      expect(dispatched, isEmpty);
      liveRun = false;
      settle('other-run');
      await pumpEventQueue();
      expect(dispatched, hasLength(1));
    });

    test("a wake is never pushed into another workspace's session", () async {
      final foreign = _Session(workspaceId: 'ws-2');
      sessions.add(foreign);
      queue.handleHarnessStarted(foreign);
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      expect(foreign.steeringQueue.drainAside(), isEmpty);
      expect(dispatched.single.workspaceId, 'ws-1');
    });

    test('cancelling a wake in a lane takes it back out', () async {
      final session = _Session();
      sessions.add(session);
      queue.handleHarnessStarted(session);
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      expect(
        await queue.cancel('ws-1', 'a', reason: 'cancelled_by_person'),
        isTrue,
      );
      expect(session.steeringQueue.drainAside(), isEmpty);
      expect(stateOf('a'), WakeState.cancelled);
    });

    for (final (name, options) in [
      ('read-only', WakeRunOptions(readOnly: true)),
      ('fresh', WakeRunOptions(freshHistory: true)),
      ('capped', WakeRunOptions(costCapMicros: 5000000)),
      ('schema-bound', WakeRunOptions(outputSchema: {'type': 'object'})),
    ]) {
      test('a $name wake never joins a live run: it starts its own run with '
          'its options when that one settles', () async {
        final session = _Session();
        sessions.add(session);
        queue.handleHarnessStarted(session);
        await queue.enqueue(wake('a', runOptions: options));
        await advance(WakeQueueService.quietWindow);
        expect(session.steeringQueue.drainAside(), isEmpty);
        expect(dispatched, isEmpty);
        expect(stateOf('a'), WakeState.pending);
        expect(rowOf('a').stateReason, WakeStateReasons.liveRunOtherOptions);
        sessions.clear();
        settle('live-run');
        await pumpEventQueue();
        final run = dispatched.single;
        expect(run.wakeContext.wakeIds, ['a']);
        expect(run.readOnly, options.readOnly);
        expect(run.freshHistory, options.freshHistory);
        expect(run.costCapMicros, options.costCapMicros);
        expect(run.expectedOutputSchema, options.outputSchema);
      });
    }

    for (final (name, runFor, wakeFor) in [
      ("a bot wake against a person's run", 'user-1', null),
      ("a person's wake against a bot run", null, 'user-1'),
      ("a person's wake against another person's run", 'user-2', 'user-1'),
    ]) {
      test('$name waits, then runs with its own authority', () async {
        members.add('user-2');
        final session = _Session(requestedByUserId: runFor);
        sessions.add(session);
        queue.handleHarnessStarted(session);
        await queue.enqueue(wake('a', requestedByUserId: wakeFor));
        await advance(WakeQueueService.quietWindow);
        expect(session.steeringQueue.drainAside(), isEmpty);
        expect(rowOf('a').stateReason, WakeStateReasons.liveRunOtherPerson);
        sessions.clear();
        settle('live-run', requestedByUserId: runFor);
        await pumpEventQueue();
        expect(dispatched.single.wakeContext.wakeIds, ['a']);
        expect(dispatched.single.requestedByUserId, wakeFor);
      });
    }

    test("a person's plain wake joins that person's run", () async {
      final session = _Session(requestedByUserId: 'user-1');
      sessions.add(session);
      queue.handleHarnessStarted(session);
      await queue.enqueue(wake('a', requestedByUserId: 'user-1'));
      await advance(WakeQueueService.quietWindow);
      expect(session.steeringQueue.drainAside().single.ref, 'wake:a');
      expect(dispatched, isEmpty);
    });

    for (final (name, session) in [
      ('read-only', _Session(readOnly: true)),
      ('fresh', _Session(freshHistory: true)),
    ]) {
      test('a plain wake does not join a $name live run', () async {
        sessions.add(session);
        queue.handleHarnessStarted(session);
        await queue.enqueue(wake('a'));
        await advance(WakeQueueService.quietWindow);
        expect(session.steeringQueue.drainAside(), isEmpty);
        expect(rowOf('a').stateReason, WakeStateReasons.liveRunOtherOptions);
      });
    }

    test('a run starting takes only the waiting wakes it may take', () async {
      liveRun = true;
      await queue.enqueue(wake('a'));
      await queue.enqueue(wake('b', requestedByUserId: 'user-1'));
      await queue.enqueue(
        wake('c', runOptions: WakeRunOptions(readOnly: true)),
      );
      await advance(WakeQueueService.quietWindow);
      expect(rowOf('a').stateReason, WakeStateReasons.liveRunNoInput);
      final session = _Session();
      sessions.add(session);
      queue.handleHarnessStarted(session);
      await pumpEventQueue();
      expect(
        [for (final m in session.steeringQueue.drainAside()) m.ref],
        ['wake:a'],
      );
      expect(rowOf('b').stateReason, WakeStateReasons.liveRunOtherPerson);
      expect(rowOf('c').stateReason, WakeStateReasons.liveRunOtherOptions);
      expect(dispatched, isEmpty);
    });

    test("a pushed wake's chain joins the live run's chain when the run "
        'drains it', () async {
      final carried = <(String, String, List<String>)>[];
      queue.chainCarried = (ws, runId, chain) =>
          carried.add((ws, runId, chain));
      final session = _Session();
      sessions.add(session);
      queue.handleHarnessStarted(session);
      await queue.enqueue(wake('a', chain: ['agent-3', 'agent-2']));
      await advance(WakeQueueService.quietWindow);
      expect(carried, isEmpty);
      session.steeringQueue.drainAside();
      expect(carried.single.$1, 'ws-1');
      expect(carried.single.$2, 'live-run');
      expect(carried.single.$3, ['agent-3', 'agent-2']);
    });
  });

  group('races', () {
    test('a push racing the run\'s end takes the claim back, and a new run '
        'delivers the wake', () async {
      final session = _Session();
      sessions.add(session);
      queue.handleHarnessStarted(session);
      await queue.enqueue(wake('a'));
      repo.duringClaim = () async {
        sessions.clear();
        settle('live-run');
        await pumpEventQueue();
      };
      await advance(WakeQueueService.quietWindow);
      await pumpEventQueue();
      expect(session.steeringQueue.drainAside(), isEmpty);
      expect(dispatched.single.wakeContext.wakeIds, ['a']);
      expect(rowOf('a').deliveredRunId, 'run-1');
    });

    test('a cancel while a delivery claims the wake is refused, and the run '
        'gets it', () async {
      await queue.enqueue(wake('a'));
      bool? cancelled;
      repo.duringClaim = () async {
        cancelled = await queue.cancel('ws-1', 'a', reason: 'by_person');
      };
      await advance(WakeQueueService.quietWindow);
      expect(cancelled, isFalse);
      expect(dispatched, hasLength(1));
      expect(stateOf('a'), WakeState.delivered);
    });

    test('a cancel during the dispatch is refused', () async {
      await queue.enqueue(wake('a'));
      final gate = Completer<String?>();
      onDispatch = (_) => gate.future;
      await advance(WakeQueueService.quietWindow);
      expect(await queue.cancel('ws-1', 'a', reason: 'by_person'), isFalse);
      gate.complete('run-x');
      await pumpEventQueue();
      expect(rowOf('a').deliveredRunId, 'run-x');
    });

    test('a settled handler may deliver the same key again', () async {
      var again = false;
      queue.registerSettledHandler((settled) async {
        if (settled.wake.id == 'a' && !again) {
          again = true;
          await queue.enqueueAndDeliver(wake('b'));
        }
      });
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      await pumpEventQueue();
      expect(
        [for (final r in dispatched) r.wakeContext.wakeIds],
        [
          ['a'],
          ['b'],
        ],
      );
    });

    test('a producer awaiting a delivery hears its settlement first', () async {
      final heard = <String>[];
      queue.registerSettledHandler((settled) => heard.add(settled.wake.id));
      final receipt = await queue.enqueueAndDeliver(wake('a'));
      expect(receipt, isA<WakeStarted>());
      expect(heard, ['a']);
    });
  });

  group('sweep', () {
    test('a dispatch that never completes holds up no other delivery and no '
        'maintenance', () async {
      onDispatch = (run) => run.workspaceId == 'ws-1'
          ? Completer<String?>().future
          : Future.value('run-${++runSeq}');
      await queue.enqueue(wake('a'));
      await queue.enqueue(wake('b', workspaceId: 'ws-2'));
      await queue.enqueue(
        wake(
          'x',
          workspaceId: 'ws-2',
          notBefore: now.add(const Duration(minutes: 5)),
          expiresAt: now.add(const Duration(minutes: 6)),
        ),
      );
      await advance(WakeQueueService.quietWindow);
      expect(stateOf('b', ws: 'ws-2'), WakeState.delivered);
      await advance(const Duration(minutes: 6));
      expect(stateOf('x', ws: 'ws-2'), WakeState.expired);
      // Still being delivered: its claim is kept fresh, not reclaimed.
      expect(stateOf('a'), WakeState.claimed);
      expect(dispatched, hasLength(2));
    });

    test('at most ${WakeQueueService.maxConcurrentDispatches} dispatches run '
        'at once; the next starts when one ends', () async {
      final gates = <Completer<String?>>[];
      onDispatch = (_) {
        final gate = Completer<String?>();
        gates.add(gate);
        return gate.future;
      };
      const keys = WakeQueueService.maxConcurrentDispatches + 1;
      // Over five workspaces: none reaches its share of the slots.
      activeWorkspaces.addAll(['ws-3', 'ws-4', 'ws-5']);
      for (var i = 0; i < keys; i++) {
        await queue.enqueue(
          wake('w$i', workspaceId: 'ws-${i % 5 + 1}', conversationId: 'conv-$i'),
        );
      }
      await advance(WakeQueueService.quietWindow);
      expect(dispatched, hasLength(WakeQueueService.maxConcurrentDispatches));
      gates.first.complete('run-a');
      await pumpEventQueue();
      expect(dispatched, hasLength(keys));
    });
  });

  group('boot', () {
    test(
      'nothing is delivered before start: a settlement only moves state',
      () async {
        await queue.stop();
        queue = build();
        await repo.insertIfAbsent(wake('a'));
        await repo.claim('ws-1', ids: ['a'], now: now);
        await repo.markDelivered('ws-1', ids: ['a'], runId: 'run-0', now: now);
        expect(await queue.enqueueAndDeliver(wake('b')), isA<WakeWaiting>());
        settle('run-0', endReason: RunEndReason.serverStopped, wakeIds: ['a']);
        await pumpEventQueue();
        await queue.tick();
        expect(dispatched, isEmpty);
        expect(stateOf('a'), WakeState.pending);
        await queue.start();
        await pumpEventQueue();
        expect(
          dispatched.single.wakeContext.wakeIds,
          unorderedEquals(['a', 'b']),
        );
      },
    );
  });

  group('whose wake', () {
    setUp(() => members.add('user-2'));

    test("another person may not release or deliver a person's held wake, "
        'but may cancel it', () async {
      // Ada (user-1) stopped the run: her wake is held.
      await queue.enqueue(wake('a', requestedByUserId: 'user-1'));
      await queue.enqueue(wake('c', requestedByUserId: 'user-1'));
      await queue.hold(
          'ws-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          reason: 'stopped');
      final notYours = throwsA(
        isA<AuthException>().having((e) => e.code, 'code', wakeNotYoursKind),
      );
      // Ben (user-2) presses "deliver now", or releases it.
      await expectLater(
        queue.deliverNow('ws-1', 'a', userId: 'user-2'),
        notYours,
      );
      await expectLater(
        queue.release('ws-1', wakeId: 'a', userId: 'user-2'),
        notYours,
      );
      expect(stateOf('a'), WakeState.held);
      expect(dispatched, isEmpty);
      expect(
        await queue.cancel('ws-1', 'c', reason: 'cancelled_by_person'),
        isTrue,
      );
      // Ada may.
      expect(await queue.release('ws-1', wakeId: 'a', userId: 'user-1'), 1);
      await pumpEventQueue();
      expect(dispatched.single.requestedByUserId, 'user-1');
    });

    test("another person's conversation release leaves a person's recovery "
        'wake held and is refused', () async {
      settle(
        'ada-run',
        endReason: RunEndReason.serverStopped,
        requestedByUserId: 'user-1',
        wakeReason: WakeReason.userMessage,
      );
      await pumpEventQueue();
      final notYours = throwsA(
        isA<AuthException>().having((e) => e.code, 'code', wakeNotYoursKind),
      );
      await expectLater(
        queue.release('ws-1', conversationId: 'conv-1', userId: 'user-2'),
        notYours,
      );
      expect(repo.all('ws-1').single.state, WakeState.held);
      expect(dispatched, isEmpty);
    });

    test(
      'a conversation release takes the bot wakes and the caller\'s own',
      () async {
        await queue.enqueue(wake('ada', requestedByUserId: 'user-1'));
        await queue.enqueue(wake('bot'));
        await queue.enqueue(wake('ben', requestedByUserId: 'user-2'));
        await queue.hold(
          'ws-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          reason: 'stopped');
        expect(
          await queue.release(
            'ws-1',
            conversationId: 'conv-1',
            userId: 'user-2',
          ),
          2,
        );
        expect(stateOf('ada'), WakeState.held);
        expect(stateOf('bot'), isNot(WakeState.held));
        expect(stateOf('ben'), isNot(WakeState.held));
      },
    );

    test('mayAct: a bot wake is anyone\'s, a person\'s wake only theirs', () {
      expect(WakeQueueService.mayAct(wake('a'), 'user-2'), isTrue);
      final ada = wake('b', requestedByUserId: 'user-1');
      expect(WakeQueueService.mayAct(ada, 'user-1'), isTrue);
      expect(WakeQueueService.mayAct(ada, 'user-2'), isFalse);
    });
  });

  group('dispatch slots', () {
    test('one workspace takes at most a quarter of the slots; the rest '
        'wait their turn in order', () async {
      final running = <String, Completer<String?>>{};
      onDispatch = (run) {
        final done = Completer<String?>();
        running[run.conversationId] = done;
        return done.future;
      };
      for (var i = 1; i <= 6; i++) {
        await queue.enqueue(wake('a$i', conversationId: 'c$i'));
      }
      await queue.enqueue(
        wake('b1', workspaceId: 'ws-2', conversationId: 'd1'),
      );
      await advance(WakeQueueService.quietWindow);
      expect(
        [
          for (final r in dispatched)
            if (r.workspaceId == 'ws-1') r.conversationId,
        ],
        hasLength(WakeQueueService.maxDispatchesPerWorkspace),
      );
      // A second workspace is not stuck behind the first.
      expect(dispatched.where((r) => r.workspaceId == 'ws-2'), hasLength(1));
      final first = dispatched.first.conversationId;
      running[first]!.complete('run-$first');
      await pumpEventQueue();
      expect(
        dispatched.where((r) => r.workspaceId == 'ws-1'),
        hasLength(WakeQueueService.maxDispatchesPerWorkspace + 1),
      );
      for (final done in running.values) {
        if (!done.isCompleted) {
          done.complete('run-x');
        }
      }
      await pumpEventQueue();
    });
  });

  group('stops and restarts', () {
    test("a person's stop holds the conversation's wakes; release sends "
        'them', () async {
      await queue.enqueue(
        wake('a', notBefore: now.add(const Duration(minutes: 1))),
      );
      settle('run-0', endReason: RunEndReason.stoppedByUser);
      await pumpEventQueue();
      expect(stateOf('a'), WakeState.held);
      await advance(const Duration(minutes: 2));
      expect(dispatched, isEmpty);
      expect(
        await queue.release('ws-1', conversationId: 'conv-1', userId: 'user-1'),
        1,
      );
      await pumpEventQueue();
      expect(dispatched.single.wakeContext.wakeIds, ['a']);
    });

    test("a person's stop holds only the stopped agent's wakes, never a "
        "goal's", () async {
      final later = now.add(const Duration(minutes: 1));
      await queue.enqueue(wake('mine', notBefore: later));
      await queue.enqueue(wake('peer', agentId: 'agent-2', notBefore: later));
      await queue.enqueue(
        wake(
          'goal',
          notBefore: later,
        ).copyWith(detail: WakeDetail(goalId: 'goal-1')),
      );
      settle('run-0', endReason: RunEndReason.stoppedByUser);
      await pumpEventQueue();
      expect(stateOf('mine'), WakeState.held);
      // Another agent's wake waits for that agent, not for this Stop.
      expect(stateOf('peer'), WakeState.pending);
      // The goal's own wake: the goal decides (it pauses on the Stop).
      expect(stateOf('goal'), WakeState.pending);
    });

    /// The server's shutdown: the queue stops delivering, then the runs are
    /// stopped (each settles `serverStopped`), then the queue stops; the
    /// next boot builds and starts a new one.
    Future<void> restartAfter(List<String> runIds, List<String> wakeIds) async {
      queue.beginStopping();
      for (final runId in runIds) {
        settle(runId, endReason: RunEndReason.serverStopped, wakeIds: wakeIds);
      }
      await pumpEventQueue();
      await queue.stop();
      queue = build();
      await queue.start();
      await pumpEventQueue();
    }

    test("shutdown: a server stop reopens a wake-started run's wakes and "
        'nothing is delivered until the next boot', () async {
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      expect(rowOf('a').deliveredRunId, 'run-1');
      queue.beginStopping();
      settle('run-1', endReason: RunEndReason.serverStopped, wakeIds: ['a']);
      await pumpEventQueue();
      expect(stateOf('a'), WakeState.pending);
      expect(rowOf('a').stateReason, WakeStateReasons.serverStopped);
      // While stopping, no path starts a run: the timer, a producer's
      // immediate delivery, a person's deliver-now, a run starting.
      await advance(const Duration(minutes: 5));
      expect(await queue.enqueueAndDeliver(wake('b')), isA<WakeWaiting>());
      expect(
        await queue.deliverNow('ws-1', 'a', userId: 'user-1'),
        isA<WakeWaiting>(),
      );
      sessions.add(_Session());
      queue.handleHarnessStarted(sessions.single);
      await pumpEventQueue();
      expect(dispatched, hasLength(1));
      expect(sessions.single.steeringQueue.drainAside(), isEmpty);
      sessions.clear();
      await queue.stop();
      queue = build();
      await queue.start();
      await pumpEventQueue();
      expect(dispatched, hasLength(2));
      expect(dispatched.last.wakeContext.wakeIds, unorderedEquals(['a', 'b']));
      expect(rowOf('a').attempt, 2);
    });

    test('a wake stopped by the server three times skips', () async {
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      for (var i = 1; i <= 3; i++) {
        await restartAfter(['run-$i'], ['a']);
      }
      expect(dispatched, hasLength(3));
      expect(stateOf('a'), WakeState.skipped);
      expect(rowOf('a').stateReason, WakeStateReasons.attempts);
    });

    test('a run the server stopped before its delivery was written: its '
        'wakes go back to pending', () async {
      await queue.enqueue(wake('a'));
      final gate = Completer<String?>();
      onDispatch = (_) => gate.future;
      await advance(WakeQueueService.quietWindow);
      queue.beginStopping();
      settle('run-x', endReason: RunEndReason.serverStopped, wakeIds: ['a']);
      await pumpEventQueue();
      expect(stateOf('a'), WakeState.claimed);
      gate.complete('run-x');
      await pumpEventQueue();
      expect(stateOf('a'), WakeState.pending);
      expect(rowOf('a').stateReason, WakeStateReasons.serverStopped);
      expect(rows, isEmpty);
    });

    test("a server stop releases the stopped run's claims this process does "
        'not hold', () async {
      await repo.insertIfAbsent(wake('a'));
      await repo.claim('ws-1', ids: ['a'], now: now);
      queue.beginStopping();
      settle('run-0', endReason: RunEndReason.serverStopped, wakeIds: ['a']);
      await pumpEventQueue();
      expect(stateOf('a'), WakeState.pending);
    });

    test("a person's run the server stopped: the wakes it drained are "
        'reopened and its recovery wake is held', () async {
      final session = _Session(
        runLogId: 'person-run',
        requestedByUserId: 'user-1',
      );
      sessions.add(session);
      queue.handleHarnessStarted(session);
      await queue.enqueue(wake('a', requestedByUserId: 'user-1'));
      await advance(WakeQueueService.quietWindow);
      expect(session.steeringQueue.drainAside().single.ref, 'wake:a');
      await pumpEventQueue();
      expect(rowOf('a').deliveredRunId, 'person-run');
      sessions.clear();
      queue.beginStopping();
      settle(
        'person-run',
        endReason: RunEndReason.serverStopped,
        requestedByUserId: 'user-1',
        wakeReason: WakeReason.userMessage,
        wakeIds: ['a'],
      );
      await pumpEventQueue();
      expect(stateOf('a'), WakeState.pending);
      expect(rowOf('a').stateReason, WakeStateReasons.serverStopped);
      final recovery = repo
          .all('ws-1')
          .singleWhere((w) => w.reason == WakeReason.recovery);
      expect(recovery.state, WakeState.held);
      expect(recovery.requestedByUserId, 'user-1');
      expect(dispatched, isEmpty);
    });

    test('a run a wake started for a person leaves no recovery wake', () async {
      settle(
        'woken-run',
        endReason: RunEndReason.serverStopped,
        requestedByUserId: 'user-1',
        wakeReason: WakeReason.peerMessage,
      );
      await pumpEventQueue();
      expect(repo.all('ws-1'), isEmpty);
    });

    test(
      "a person's run the server stopped leaves a held recovery wake",
      () async {
        settle(
          'person-run',
          endReason: RunEndReason.serverStopped,
          requestedByUserId: 'user-1',
          wakeReason: WakeReason.userMessage,
        );
        await pumpEventQueue();
        final recovery = repo.all('ws-1').single;
        expect(recovery.reason, WakeReason.recovery);
        expect(recovery.state, WakeState.held);
        expect(recovery.dedupKey, 'recovery:person-run');
        expect(recovery.requestedByUserId, 'user-1');
        expect(dispatched, isEmpty);
        final receipt = await queue.deliverNow(
          'ws-1',
          recovery.id,
          userId: 'user-1',
        );
        expect(receipt, isA<WakeStarted>());
        expect(dispatched.single.requestedByUserId, 'user-1');
      },
    );

    test("the held recovery wake carries the stopped run's lineage", () async {
      final asked = <List<String>>[];
      queue.lineageRootOfRuns = (ws, runIds) async {
        asked.add(runIds);
        return 'rule-root';
      };
      settle(
        'person-run',
        endReason: RunEndReason.serverStopped,
        requestedByUserId: 'user-1',
        wakeReason: WakeReason.userMessage,
      );
      await pumpEventQueue();
      final recovery = repo.all('ws-1').single;
      expect(asked, [
        ['person-run'],
      ]);
      expect(recovery.detail.fields[WakeFields.lineageRoot], 'rule-root');
      expect(recovery.state, WakeState.held);
    });

    test('a restart between claim and run start: the claim goes back to '
        'pending and a new run delivers it', () async {
      await repo.insertIfAbsent(
        wake('a', notBefore: now.subtract(const Duration(minutes: 5))),
      );
      await repo.claim(
        'ws-1',
        ids: ['a'],
        now: now.subtract(const Duration(minutes: 5)),
      );
      await queue.stop();
      queue = build();
      await queue.start();
      await pumpEventQueue();
      expect(dispatched.single.wakeContext.wakeIds, ['a']);
      expect(rowOf('a').deliveredRunId, 'run-1');
    });

    for (final ended in [null, RunEndReason.completed]) {
      test(
        'a restart after a run that took the claim '
        '(${ended?.wire ?? 'live'}): delivered to it, no second run',
        () async {
          await repo.insertIfAbsent(
            wake('a', notBefore: now.subtract(const Duration(minutes: 5))),
          );
          await repo.claim(
            'ws-1',
            ids: ['a'],
            now: now.subtract(const Duration(minutes: 5)),
          );
          await ledger.addWakeIds('ws-1', 'run-before', ['a']);
          if (ended != null) {
            ledger.ended['run-before'] = ended;
          }
          await queue.stop();
          queue = build();
          await queue.start();
          await pumpEventQueue();
          expect(dispatched, isEmpty);
          expect(rowOf('a').deliveredRunId, 'run-before');
        },
      );
    }

    test('a restart after a run the server stopped took the claim: the wake '
        'goes back to pending and a new run delivers it', () async {
      await repo.insertIfAbsent(
        wake('a', notBefore: now.subtract(const Duration(minutes: 5))),
      );
      await repo.claim(
        'ws-1',
        ids: ['a'],
        now: now.subtract(const Duration(minutes: 5)),
      );
      await ledger.addWakeIds('ws-1', 'run-before', ['a']);
      ledger.ended['run-before'] = RunEndReason.serverStopped;
      await queue.stop();
      queue = build();
      await queue.start();
      await pumpEventQueue();
      expect(dispatched.single.wakeContext.wakeIds, ['a']);
      expect(rowOf('a').deliveredRunId, 'run-1');
    });
  });

  group('workspace isolation', () {
    test('every operation on a foreign wake id throws', () async {
      await queue.enqueue(wake('a', workspaceId: 'ws-2'));
      for (final op in <Future<Object?> Function()>[
        () => queue.cancel('ws-1', 'a', reason: 'x'),
        () => queue.release('ws-1', wakeId: 'a', userId: 'user-1'),
        () => queue.deliverNow('ws-1', 'a', userId: 'user-1'),
      ]) {
        await expectLater(op(), throwsA(isA<WorkspaceMismatchException>()));
      }
      expect(stateOf('a', ws: 'ws-2'), WakeState.pending);
    });

    test('cancelWhere and hold touch only their workspace', () async {
      await queue.enqueue(
        wake('a', workspaceId: 'ws-2', requestedByUserId: 'user-1'),
      );
      await queue.enqueue(wake('b', requestedByUserId: 'user-1'));
      expect(
        await queue.cancelWhere(
          'ws-1',
          requestedByUserId: 'user-1',
          reason: 'r',
        ),
        1,
      );
      expect(
        await queue.hold(
          'ws-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          reason: 'r'),
        0,
      );
      expect(stateOf('a', ws: 'ws-2'), WakeState.pending);
    });
  });

  group('a run held only for its background tasks', () {
    late _HeldSession held;

    setUp(() {
      held = _HeldSession(requestedByUserId: 'user-1');
      sessions.add(held);
      liveRun = true;
      queue.handleHarnessStarted(held);
    });

    Future<void> runSettles() async {
      sessions.clear();
      liveRun = false;
      settle('live-run', requestedByUserId: 'user-1');
      await pumpEventQueue();
    }

    test("a peer's message for another person yields the hold and is "
        'delivered once the run settles', () async {
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      expect(held.yields, 1);
      expect(held.steeringQueue.drainAside(), isEmpty);
      expect(rowOf('a').stateReason, WakeStateReasons.liveRunNoInput);
      expect(dispatched, isEmpty);
      await runSettles();
      expect(dispatched.single.wakeContext.wakeIds, ['a']);
    });

    test("a goal's next step yields the hold and starts its own run after "
        'it', () async {
      await queue.enqueue(
        wake(
          'g',
          requestedByUserId: 'user-1',
        ).copyWith(detail: WakeDetail(goalId: 'goal-1')),
      );
      await advance(WakeQueueService.quietWindow);
      expect(held.yields, 1);
      expect(held.steeringQueue.drainAside(), isEmpty);
      await runSettles();
      expect(dispatched.single.wakeContext.wakeIds, ['g']);
    });

    test("a `when_busy: skip` rule's wake: the held run is not busy for it, "
        'so it yields and the wake is delivered after it', () async {
      // The rule guard's busy check, as the server wires it.
      queue.registerGuard(
        _AsyncGuard(
          (w) async =>
              await queue.agentBusy(w.workspaceId, w.conversationId, w.agentId)
              ? const WakeAdmission.skip('rule:busy')
              : const WakeAdmission.admit(),
        ),
      );
      await queue.enqueue(
        wake(
          'r',
          requestedByUserId: 'user-1',
        ).copyWith(detail: WakeDetail(ruleId: 'rule-1')),
      );
      await advance(WakeQueueService.quietWindow);
      expect(held.yields, 1);
      expect(stateOf('r'), WakeState.pending);
      await runSettles();
      expect(dispatched.single.wakeContext.wakeIds, ['r']);
    });

    test('a run that is not held is busy for a rule', () async {
      held.heldForBackgroundOnly = false;
      expect(await queue.agentBusy('ws-1', 'conv-1', 'agent-1'), isTrue);
      held.heldForBackgroundOnly = true;
      expect(await queue.agentBusy('ws-1', 'conv-1', 'agent-1'), isFalse);
    });

    for (final (name, answer) in [
      ('defers', const WakeAdmission.defer(reason: 'orchestration_budget')),
      ('skips', const WakeAdmission.skip('rule:superseded')),
    ]) {
      test("a wake a guard $name does not end the person's background task",
          () async {
        queue.registerGuard(_Guard((_) => answer));
        await queue.enqueue(
          wake(
            'g',
            requestedByUserId: 'user-1',
          ).copyWith(detail: WakeDetail(goalId: 'goal-1')),
        );
        await advance(WakeQueueService.quietWindow);
        expect(held.yields, 0);
        expect(held.acceptsSteering, isTrue);
        expect(dispatched, isEmpty);
      });
    }

    test('a yielded run still listed when its settlement arrives holds '
        'nothing back', () async {
      await queue.enqueue(wake('a'));
      await advance(WakeQueueService.quietWindow);
      expect(held.yields, 1);
      // The run settled; its session ends a moment after the publish.
      liveRun = false;
      settle('live-run', requestedByUserId: 'user-1');
      await pumpEventQueue();
      expect(dispatched.single.wakeContext.wakeIds, ['a']);
    });

    test("the person's own plain wake joins the held run (a turn starts): "
        'no yield', () async {
      await queue.enqueue(wake('a', requestedByUserId: 'user-1'));
      await advance(WakeQueueService.quietWindow);
      expect(held.yields, 0);
      expect(held.steeringQueue.drainAside().single.ref, 'wake:a');
    });
  });
}
