import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/ports/worktree_fingerprint_port.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_checks_outcome.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/src/dispatch/goal_activity.dart';
import 'package:cc_infra/src/dispatch/goal_owed_work.dart';
import 'package:cc_infra/src/dispatch/goal_progress.dart';
import 'package:cc_infra/src/dispatch/goal_store.dart';
import 'package:cc_infra/src/dispatch/goal_supervisor.dart';
import 'package:cc_infra/src/dispatch/goal_verifier.dart';
import 'package:cc_infra/src/dispatch/wake_queue_service.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/agent_awaiting_input_publisher.dart';
import 'package:test/test.dart';

import 'helpers/seed_spaces.dart';
import 'helpers/test_database.dart';

const _ws = 'ws-1';
const _space = 'sp-1';
const _conv = 'conv-1';
const _agent = 'agent-1';
const _person = 'user-1';

class _Agents implements AgentRepository {
  final agent = Agent(
    id: _agent,
    name: 'Ada',
    title: 'Engineer',
    agentMdPath: '/tmp/agent-1.md',
    workspaceId: _ws,
    skills: AgentSkills(const []),
    createdAt: DateTime.utc(2026),
  );

  @override
  Future<Agent?> getById(String workspaceId, String id) async =>
      workspaceId == _ws && id == _agent ? agent : null;

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(workspaceId == _ws ? [agent] : const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Fingerprints implements WorktreeFingerprintPort {
  @override
  Future<String?> fingerprint({
    required String workspaceId,
    required String conversationId,
  }) async => 'fp-0';
}

class _NoTimer implements Timer {
  @override
  void cancel() {}

  @override
  bool get isActive => false;

  @override
  int get tick => 0;
}

/// A goal's wait-and-resume and a verification round against the real goal
/// repository, wake repository and run log over an in-memory workspace
/// database: every compare-and-set the supervisor makes reads back what
/// drift stored (times as whole seconds, read back local) and must still
/// match.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoAgentGoalRunRepository goals;
  late DaoWakeRepository wakes;
  late DaoAgentRunLogRepository runLogs;
  late DomainEventBus bus;
  late WakeQueueService queue;
  late GoalSupervisor supervisor;
  // Sub-second on purpose: what drift drops must not matter.
  var now = DateTime.utc(2026, 11, 19, 12, 0, 0, 400);
  var delegations = const <String>[];
  final runIds = <String>[];
  final dispatched = <WakeDispatchRequest>[];
  final settled = <GoalSettled>[];

  Future<void> pump() async {
    for (var i = 0; i < 200; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> advance(Duration by) async {
    now = now.add(by);
    await queue.tick();
    await pump();
  }

  Future<AgentGoalRun> goal() async =>
      (await goals.listByWorkspace(_ws)).single;

  Future<String?> plain(WakeDispatchRequest run) async {
    dispatched.add(run);
    final id = 'run-${runIds.length + 1}';
    runIds.add(id);
    await runLogs.upsert(
      AgentRunLog(
        id: id,
        agentId: run.agentId,
        workspaceId: run.workspaceId,
        conversationId: run.conversationId,
        spaceId: run.spaceId,
        startedAt: now,
        status: RunStatus.running,
      ),
    );
    return id;
  }

  Future<void> settle(String runId, {Map<String, dynamic>? output}) async {
    final log = (await runLogs.getById(_ws, runId))!;
    await runLogs.upsert(
      log.copyWith(
        status: RunStatus.completed,
        completedAt: now,
        endReason: RunEndReason.completed,
        outputJson: output,
      ),
    );
    bus.publish(
      AgentRunSettled(
        agentId: log.agentId,
        workspaceId: _ws,
        spaceId: _space,
        conversationId: _conv,
        runId: runId,
        status: RunStatus.completed,
        endReason: RunEndReason.completed,
        costMicros: 1000,
        limitResetsAt: null,
        wakeIds: const [],
        requestedByUserId: _person,
        wakeReason: null,
        occurredAt: now,
      ),
    );
    await pump();
  }

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, _ws);
    final db = dbs.of(_ws);
    await seedConversation(db, _conv, spaceId: _space);
    await db.customStatement(
      'INSERT INTO agents (id, name, title, agent_md_path, workspace_id, '
      'skills) VALUES (?, ?, ?, ?, ?, ?)',
      [_agent, 'Ada', 'Engineer', '/tmp/agent-1.md', _ws, '[]'],
    );
    goals = DaoAgentGoalRunRepository(dbs);
    wakes = DaoWakeRepository(dbs, clock: () => now);
    runLogs = DaoAgentRunLogRepository(dbs);
    bus = DomainEventBus();
    runIds.clear();
    dispatched.clear();
    settled.clear();
    delegations = const [];
    final agents = _Agents();
    queue = WakeQueueService(
      wakes: wakes,
      runLedger: runLogs,
      eventBus: bus,
      clock: () => now,
      timerFactory: (_, _) => _NoTimer(),
      nonce: () => 'nonce1',
      ports: WakeQueuePorts(
        workspaceActive: (ws) async => ws == _ws,
        conversationSpace: (ws, conv) async =>
            ws == _ws && conv == _conv ? _space : null,
        agent: agents.getById,
        isMember: (ws, user) async => true,
        takenOver: (ws, space) async => false,
        budgetBlocked: (ws, agent) async => false,
        liveSessions: (_) => const [],
        hasLiveRun: (ws, conv, agentId) async => false,
        dispatch: (run) => supervisor.dispatchWakeRun(run, plain),
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
    final store = GoalStore(
      goals: goals,
      wakes: wakes,
      wakeQueue: () => queue,
      say:
          ({
            required workspaceId,
            required spaceId,
            required content,
            conversationId,
          }) async {},
      eventBus: bus,
      now: () => now,
      startRefs: (ws, conv) async => null,
    );
    final progress = GoalProgressObserver(
      fingerprints: _Fingerprints(),
      todos: null,
      activity: RunToolActivity(),
      mcpClassesOf: (_) => null,
    );
    supervisor = GoalSupervisor(
      store: store,
      verifier: GoalVerifier(
        store: store,
        runChecks:
            ({
              required workspaceId,
              required spaceId,
              required conversationId,
              required agentId,
              required contract,
            }) async => GoalChecksOutcome(
              status: GoalChecksStatus.ran,
              results: const [],
              fingerprint: null,
            ),
        fingerprintOf: progress.fingerprintOf,
        spaceCheckerOf: (ws, space) async => null,
        agents: agents,
        runLogs: runLogs,
      ),
      progress: progress,
      owedWork: GoalOwedWork(
        wakes: wakes,
        rules: null,
        asks: null,
        openDelegations:
            (ws, {required conversationId, required agentId}) async =>
                delegations,
      ),
      agents: agents,
      runLogs: runLogs,
      todos: null,
      hasLiveRun: (ws, conv, agentId) async => false,
      eventBus: bus,
    );
    queue
      ..registerGuard(supervisor)
      ..registerSettledHandler(supervisor.onWakeSettled);
    bus.on<GoalSettled>().listen(settled.add);
    await queue.start();
  });

  tearDown(() async {
    supervisor.dispose();
    await queue.stop();
    bus.dispose();
    await dbs.closeAll();
    await global.close();
  });

  test(
    'a goal waits on owed work, is paused and resumed, and passes a '
    'verification round, every write landing on what was read back',
    () async {
      final started = await supervisor.startGoal(
        workspaceId: _ws,
        spaceId: _space,
        conversationId: _conv,
        agentId: _agent,
        userText: 'ship it',
        requestedByUserId: _person,
      );
      await pump();
      expect(started, isNotNull);
      expect(runIds, ['run-1']);
      final stored = await goal();
      expect(stored.activeRunId, 'run-1');
      expect(stored.createdAt.isUtc, isTrue);
      expect(stored.progressMarks!.marks, hasLength(1));

      // The segment ends owing work: the goal waits, its fallback in the
      // wake table.
      delegations = const ['T-1'];
      await settle('run-1');
      final waiting = await goal();
      expect(waiting.hold, GoalHold.waiting);
      expect(waiting.runCount, 1);
      expect(waiting.holdUntil!.isUtc, isTrue);
      expect(waiting.progressMarks!.waits, 1);
      expect(waiting.progressMarks!.waitSince!.isUtc, isTrue);

      // A person pauses it and resumes it: the wait's wake is cancelled, the
      // resume writes the next segment's wake.
      await supervisor.pauseGoal(_ws, waiting.id);
      expect((await goal()).status, AgentGoalStatus.paused);
      await supervisor.resumeGoal(_ws, waiting.id);
      final resumed = await goal();
      expect(resumed.status, AgentGoalStatus.active);
      expect(resumed.hold, isNull);
      expect(resumed.progressMarks!.waits, 0);
      await advance(WakeQueueService.quietWindow);
      expect(runIds, ['run-1', 'run-2']);
      expect((await goal()).activeRunId, 'run-2');

      // The segment claims completion; the review run passes it.
      delegations = const [];
      await supervisor.claimCompletion(
        _ws,
        _agent,
        conversationId: _conv,
        callingRunId: 'run-2',
        summary: 'done',
        evidence: const [],
      );
      await settle('run-2');
      await supervisor.verificationsDone();
      expect((await goal()).hold, GoalHold.verifying);
      await advance(WakeQueueService.quietWindow);
      expect(dispatched.last.wakeContext.wakeReason, WakeReason.goalReview);
      expect((await goal()).verification!.reviewRunId, 'run-3');
      await settle(
        'run-3',
        output: {
          'verdict': 'pass',
          'items': [
            {
              'criterion': 'the objective',
              'state': 'met',
              'evidence': 'read the files',
            },
          ],
          'concerns': const <Object?>[],
        },
      );
      final done = await goal();
      expect(done.status, AgentGoalStatus.completed);
      expect(done.verification!.verdict!.verdict, GoalVerdictOutcome.pass);
      expect(done.verification!.at.isUtc, isTrue);
      expect(settled.last.status, AgentGoalStatus.completed);
    },
  );

  test(
    'an approval of the segment, through the real publisher, holds the goal '
    'on the person until it is answered, and starts nothing meanwhile',
    () async {
      final approvals = PendingConfirmationRegistry();
      final publisher = AgentAwaitingInputPublisher(
        eventBus: bus,
        agents: _Agents(),
        clock: () => now,
      )..watch(confirmations: approvals);
      addTearDown(() async {
        await publisher.dispose();
        approvals.dispose();
      });
      await supervisor.startGoal(
        workspaceId: _ws,
        spaceId: _space,
        conversationId: _conv,
        agentId: _agent,
        userText: 'ship it',
        requestedByUserId: _person,
      );
      await pump();
      expect((await goal()).activeRunId, 'run-1');
      // As the sandbox exec gate asks for the segment's run.
      final entry = approvals.register(
        const ConfirmationRequest(
          spaceId: _space,
          conversationId: _conv,
          title: 'Run make deploy',
          detail: 'make deploy',
          workspaceId: _ws,
          agentId: _agent,
          runId: 'run-1',
        ),
      );
      await pump();
      final held = await goal();
      expect(held.hold, GoalHold.person);
      expect(held.holdDetail, '${GoalSupervisor.inputHoldPrefix}${entry.id}');
      expect(held.activeRunId, 'run-1');
      await advance(const Duration(hours: 1));
      await supervisor.sweep();
      await pump();
      expect(runIds, ['run-1']);
      expect((await goal()).hold, GoalHold.person);
      approvals.respond(entry.id, approved: true);
      await pump();
      final answered = await goal();
      expect(answered.hold, isNull);
      expect(answered.status, AgentGoalStatus.active);
      expect(answered.activeRunId, 'run-1');
    },
  );
}
