import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_registry.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/mention_context.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/dispatch/agent_registry_impl.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake implementations
// ---------------------------------------------------------------------------

/// Workspace owning every dispatch in this suite. A dispatch's workspace picks
/// the database its run log is written to, so it is required and non-empty.
const String _workspaceId = 'ws-1';

class _FakeDispatchUseCase implements DispatchAgentUseCase {
  _FakeDispatchUseCase(this.cannedResult);
  final PreparedDispatch cannedResult;

  @override
  Future<PreparedDispatch> execute({
    required String workspaceId,
    required String agentId,
    required String prompt,
    String? channelId,
    String? conversationId,
    String? adapterId,
    WakeContext? wakeContext,
    MentionContext? mentionContext,
  }) async {
    return cannedResult;
  }
}

class _FakeAgentDispatchPort implements AgentDispatchPort {
  _FakeAgentDispatchPort(this.eventsController);

  /// Recorded `pauseDispatch` dispatch ids, in call order.
  final List<String> pausedDispatchIds = [];

  /// Recorded `resumeDispatch` dispatch ids, in call order.
  final List<String> resumedDispatchIds = [];

  /// The value `pauseDispatch` returns (default false — not pausable).
  bool pauseReturn = false;

  /// The value `resumeDispatch` returns (default false — not resumable).
  bool resumeReturn = false;

  @override
  Future<bool> pauseDispatch(String dispatchId) async {
    pausedDispatchIds.add(dispatchId);
    return pauseReturn;
  }

  @override
  Future<bool> resumeDispatch(String dispatchId) async {
    resumedDispatchIds.add(dispatchId);
    return resumeReturn;
  }

  final StreamController<AgentProcessEvent> eventsController;

  final List<String> stoppedDispatchIds = [];
  final List<String> stoppedAllForAgentIds = [];
  bool stopCalled = false;
  int startCallCount = 0;

  @override
  DispatchHandle start({
    required String cliName,
    required String prompt,
    required String workingDirectory,
    String? userText,
    String? modelId,
    String? agentId,
    String? agentName,
    String? workspaceId,
    String? conversationId,
    String? runLogId,
    String? ticketId,
    String? requestedByUserId,
    WakeContext? wakeContext,
    Mode? mode,
    int? silenceTimeoutMinutes,
    Map<String, String>? environment,
    List<String>? imagePaths,
    String? effortLevel,
    String? agentConfigDir,
    List<String>? adapterArgsOverride,
    Map<String, String>? adapterEnvOverride,
    int? costCapCents,
  }) {
    startCallCount++;
    final dispatchId = 'dispatch-$startCallCount';
    return DispatchHandle(
      dispatchId: dispatchId,
      events: eventsController.stream,
    );
  }

  @override
  Future<void> stopDispatch(String dispatchId) async {
    stoppedDispatchIds.add(dispatchId);
  }

  @override
  Future<void> stopAllForAgent(String agentId) async {
    stoppedAllForAgentIds.add(agentId);
  }

  /// Recorded `steerDispatch` calls (dispatchId, message, followUp).
  final List<({String dispatchId, String message, bool followUp})>
  steeredDispatches = [];

  /// The value `steerDispatch` returns (default false — no live run).
  bool steerReturn = false;

  @override
  Future<bool> steerDispatch(
    String dispatchId,
    String message, {
    bool followUp = false,
  }) async {
    steeredDispatches.add((
      dispatchId: dispatchId,
      message: message,
      followUp: followUp,
    ));
    return steerReturn;
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
  }
}

class _FakeRunLogRepository implements AgentRunLogRepository {
  @override
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async => const [];

  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async {
    // A run is "active" when it has no completedAt — mirror the real repo's
    // semantics so cost-propagation can find a seeded parent run.
    final log = _logs.values
        .where((l) => l.agentId == agentId && l.completedAt == null)
        .toList();
    return log.isEmpty ? null : log.last;
  }

  final Map<String, AgentRunLog> _logs = {};
  final List<AgentRunLog> upserted = [];

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async =>
      _logs[id];

  @override
  Future<void> upsert(AgentRunLog log) async {
    _logs[log.id] = log;
    upserted.add(log);
  }

  @override
  Future<List<AgentRunLog>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async => const [];
  @override
  Stream<List<AgentRunLog>> watchByAgent(String workspaceId, String agentId) =>
      Stream.value([]);

  @override
  Stream<List<AgentRunLog>> watchAll() => Stream.value([]);

  @override
  Stream<List<AgentRunLog>> watchRecent(int limit) => watchAll().map(
    (logs) => logs.length <= limit ? logs : logs.sublist(0, limit),
  );

  @override
  Stream<List<AgentRunLog>> watchByConversation(
    String workspaceId,
    String conversationId,
  ) => const Stream.empty();

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) => Stream.value([]);
}

class _FakeRepoProvisioner implements RepoWorkspaceProvisionerPort {
  _FakeRepoProvisioner(this.cannedDir);
  final String cannedDir;
  bool ensureCalled = false;

  @override
  Future<String> ensureConversationWorkspace({
    required String workspaceId,
    required String channelId,
    required String agentSlug,
    required String fallbackDir,
    String? agentConfigDir,
    String? ticketId,
    String? ticketKey,
    String? ticketTitle,
    String branchType = 'feature',
    String? prHeadRef,
    String? prHeadRepoFullName,
    String? prBranch,
    Set<String>? repoAllowlist,
    void Function(String repoName, {required bool prHead})? onRepoProvision,
  }) async {
    ensureCalled = true;
    return cannedDir;
  }

  @override
  Future<void> releaseConversation({
    required String workspaceId,
    required String channelId,
  }) async {
    // no-op for tests
  }

  @override
  Future<void> releaseConversationAnyWorkspace({
    required String channelId,
  }) async {
    // no-op for tests
  }

  @override
  Future<void> releaseTicket({required String ticketId}) async {
    // no-op for tests
  }

  @override
  Future<int> releaseTicketInWorkspace({
    required String workspaceId,
    required String ticketId,
  }) async => 0;

  @override
  Future<int> sweepStale({required String workspaceId}) async => 0;
}

PreparedDispatch _cannedDispatch() => const PreparedDispatch(
  effectivePrompt: 'test prompt',
  effectiveConversationId: null,
  agent: null,
  mode: Mode.chat,
  resolvedAdapterId: null,
  cliName: 'pi',
);

AgentRunLog _pendingRunLog({String id = 'run-1', String agentId = 'agent-1'}) =>
    AgentRunLog(
      id: id,
      agentId: agentId,
      workspaceId: _workspaceId,
      startedAt: DateTime(2025, 1, 1),
      status: RunStatus.pending,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AgentDispatchResult', () {
    test(
      'constructs with required fields',
      timeout: const Timeout.factor(2),
      () {
        final controller = StreamController<AgentProcessEvent>();
        final runLog = AgentRunLog(
          id: 'log-1',
          agentId: 'agent-1',
          startedAt: DateTime(2025, 1, 1),
          status: RunStatus.pending,
        );

        final result = AgentDispatchResult(
          stream: controller.stream,
          dispatchId: 'dispatch-1',
          runLog: runLog,
        );

        expect(result.dispatchId, 'dispatch-1');
        expect(result.agent, isNull);
        expect(result.runLog, runLog);
        expect(result.stream, isNotNull);
        controller.close();
      },
    );

    test(
      'constructs with agent field set',
      timeout: const Timeout.factor(2),
      () {
        final controller = StreamController<AgentProcessEvent>();
        final runLog = AgentRunLog(
          id: 'log-2',
          agentId: 'agent-2',
          startedAt: DateTime(2025, 1, 1),
          status: RunStatus.pending,
        );
        final agent = Agent(
          id: 'agent-2',
          name: 'Test Agent',
          title: 'Tester',
          agentMdPath: '/tmp/agent.md',
          workspaceId: 'ws-1',
          skills: AgentSkills([]),
          createdAt: DateTime(2025, 1, 1),
        );

        final result = AgentDispatchResult(
          stream: controller.stream,
          dispatchId: 'dispatch-2',
          runLog: runLog,
          agent: agent,
        );

        expect(result.agent, isNotNull);
        expect(result.agent!.id, 'agent-2');
        expect(result.agent!.name, 'Test Agent');
        controller.close();
      },
    );

    test(
      'agent field is null by default',
      timeout: const Timeout.factor(2),
      () {
        final controller = StreamController<AgentProcessEvent>();

        final result = AgentDispatchResult(
          stream: controller.stream,
          dispatchId: 'dispatch-3',
          runLog: AgentRunLog(
            id: 'log-3',
            agentId: 'agent-3',
            startedAt: DateTime(2025, 1, 1),
            status: RunStatus.pending,
          ),
        );

        expect(result.agent, isNull);
        controller.close();
      },
    );

    test(
      'stream emits events from controller',
      timeout: const Timeout.factor(2),
      () async {
        final controller = StreamController<AgentProcessEvent>();
        final result = AgentDispatchResult(
          stream: controller.stream,
          dispatchId: 'dispatch-4',
          runLog: AgentRunLog(
            id: 'log-4',
            agentId: 'agent-4',
            startedAt: DateTime(2025, 1, 1),
            status: RunStatus.pending,
          ),
        );

        final event = TextEvent(content: 'hello');
        final future = result.stream.first;
        controller.add(event);
        final emitted = await future;

        expect(emitted, event);
        unawaited(controller.close());
      },
    );

    test('runLog carries correct status', timeout: const Timeout.factor(2), () {
      final controller = StreamController<AgentProcessEvent>();

      final result = AgentDispatchResult(
        stream: controller.stream,
        dispatchId: 'dispatch-5',
        runLog: AgentRunLog(
          id: 'log-5',
          agentId: 'agent-5',
          startedAt: DateTime(2025, 1, 1),
          status: RunStatus.completed,
        ),
      );

      expect(result.runLog.status, RunStatus.completed);
      controller.close();
    });

    test('dispatchId is preserved', timeout: const Timeout.factor(2), () {
      final controller = StreamController<AgentProcessEvent>();

      final result = AgentDispatchResult(
        stream: controller.stream,
        dispatchId: 'dispatch-6',
        runLog: AgentRunLog(
          id: 'log-6',
          agentId: 'agent-6',
          startedAt: DateTime(2025, 1, 1),
          status: RunStatus.pending,
        ),
      );

      expect(result.dispatchId, 'dispatch-6');
      controller.close();
    });

    test(
      'different instances with same dispatchId have different streams',
      timeout: const Timeout.factor(2),
      () {
        final c1 = StreamController<AgentProcessEvent>();
        final c2 = StreamController<AgentProcessEvent>();

        final r1 = AgentDispatchResult(
          stream: c1.stream,
          dispatchId: 'shared-id',
          runLog: AgentRunLog(
            id: 'a',
            agentId: 'agent-a',
            startedAt: DateTime(2025, 1, 1),
            status: RunStatus.pending,
          ),
        );
        final r2 = AgentDispatchResult(
          stream: c2.stream,
          dispatchId: 'shared-id',
          runLog: AgentRunLog(
            id: 'b',
            agentId: 'agent-b',
            startedAt: DateTime(2025, 1, 1),
            status: RunStatus.pending,
          ),
        );

        expect(r1.dispatchId, r2.dispatchId);
        expect(r1.stream, isNot(same(r2.stream)));
        c1.close();
        c2.close();
      },
    );
  });

  group('AgentDispatchService', () {
    late _FakeAgentDispatchPort dispatchPort;
    late _FakeRunLogRepository runLogRepo;
    late _FakeDispatchUseCase dispatchUseCase;

    AgentDispatchService createService({
      _FakeRepoProvisioner? repoProvisioner,
      AgentRegistry? registry,
    }) {
      return AgentDispatchService(
        agentDispatch: dispatchPort,
        dispatchUseCase: dispatchUseCase,
        runLogRepo: runLogRepo,
        repoProvisioner: repoProvisioner,
        registry: registry,
      );
    }

    setUp(() {
      dispatchPort = _FakeAgentDispatchPort(
        StreamController<AgentProcessEvent>.broadcast(),
      );
      runLogRepo = _FakeRunLogRepository();
      dispatchUseCase = _FakeDispatchUseCase(_cannedDispatch());
    });

    tearDown(() {
      dispatchPort.eventsController.close();
    });

    test(
      'dispatch returns AgentDispatchResult with correct dispatchId',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();

        final result = await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );

        expect(result.dispatchId, 'dispatch-1');
        expect(result.stream, isNotNull);
        expect(result.runLog, isNotNull);
      },
    );

    test(
      'dispatch creates runLog with status pending',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();

        await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );

        expect(runLogRepo.upserted, isNotEmpty);
        final persisted = runLogRepo.upserted.first;
        expect(persisted.status, RunStatus.pending);
        expect(persisted.agentId, 'agent-1');
      },
    );

    test(
      'dispatch persists modelId from the agent config when present',
      timeout: const Timeout.factor(2),
      () async {
        final agent = Agent(
          id: 'agent-1',
          name: 'Test Agent',
          title: 'Tester',
          agentMdPath: '/tmp/agent.md',
          workspaceId: 'ws-1',
          skills: AgentSkills([]),
          modelId: 'claude-opus-4-5',
          createdAt: DateTime(2025, 1, 1),
        );
        dispatchUseCase = _FakeDispatchUseCase(
          PreparedDispatch(
            effectivePrompt: 'test prompt',
            effectiveConversationId: null,
            agent: agent,
            mode: Mode.chat,
            resolvedAdapterId: 'claude',
            cliName: 'pi',
          ),
        );
        final service = createService();

        await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );

        expect(runLogRepo.upserted, isNotEmpty);
        final persisted = runLogRepo.upserted.first;
        expect(persisted.adapter, 'claude');
        expect(persisted.modelId, 'claude-opus-4-5');
      },
    );

    test(
      'dispatch stores runId-to-dispatchId mapping (verified via stopRun)',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();

        final result = await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );
        final runLogId = result.runLog.id;

        await service.stopRun(_workspaceId, runLogId);

        expect(dispatchPort.stoppedDispatchIds, contains(result.dispatchId));
      },
    );

    test(
      'pauseRun maps runLogId to dispatchId and forwards the result',
      timeout: const Timeout.factor(2),
      () async {
        dispatchPort.pauseReturn = true;
        final service = createService();

        final result = await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );

        final accepted = await service.pauseRun(result.runLog.id);

        expect(accepted, isTrue);
        expect(dispatchPort.pausedDispatchIds, contains(result.dispatchId));
      },
    );

    test(
      'pauseRun returns false for an unknown runLogId (no live dispatch)',
      timeout: const Timeout.factor(2),
      () async {
        dispatchPort.pauseReturn = true;
        final service = createService();

        final accepted = await service.pauseRun('never-dispatched');

        expect(accepted, isFalse);
        expect(dispatchPort.pausedDispatchIds, isEmpty);
      },
    );

    test(
      'resumeRun maps runLogId to dispatchId and forwards the result',
      timeout: const Timeout.factor(2),
      () async {
        dispatchPort.resumeReturn = true;
        final service = createService();

        final result = await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );

        final accepted = await service.resumeRun(result.runLog.id);

        expect(accepted, isTrue);
        expect(dispatchPort.resumedDispatchIds, contains(result.dispatchId));
      },
    );

    test(
      'resumeRun returns false for an unknown runLogId',
      timeout: const Timeout.factor(2),
      () async {
        dispatchPort.resumeReturn = true;
        final service = createService();

        final accepted = await service.resumeRun('never-dispatched');

        expect(accepted, isFalse);
        expect(dispatchPort.resumedDispatchIds, isEmpty);
      },
    );

    test(
      'pauseRun forwards a false result when the transport cannot pause',
      timeout: const Timeout.factor(2),
      () async {
        // pauseReturn defaults to false — an external-CLI transport with no
        // turn boundary.
        final service = createService();

        final result = await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );

        final accepted = await service.pauseRun(result.runLog.id);

        expect(accepted, isFalse);
        expect(dispatchPort.pausedDispatchIds, contains(result.dispatchId));
      },
    );

    test(
      'completeRun marks run as completed',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();
        final log = _pendingRunLog();
        await runLogRepo.upsert(log);

        await service.completeRun(log, null);

        // One seed upsert + one completeRun upsert.
        expect(runLogRepo.upserted.length, 2);
        final completed = runLogRepo.upserted.last;
        expect(completed.status, RunStatus.completed);
        expect(completed.completedAt, isNotNull);
      },
    );

    test(
      'completeRun is idempotent',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();
        final log = _pendingRunLog();
        await runLogRepo.upsert(log);

        await service.completeRun(log, null);
        await service.completeRun(log, null);

        // Seed upsert + exactly one completeRun upsert (second was no-op).
        expect(runLogRepo.upserted.length, 2);
      },
    );

    test(
      'completeRun removes dispatch mapping (stopRun becomes no-op)',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();

        final result = await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );

        // completeRun deletes the mapping from _runToDispatch.
        await service.completeRun(result.runLog, null);

        // stopRun should find no mapping and therefore NOT call stopDispatch.
        await service.stopRun(_workspaceId, result.runLog.id);

        expect(dispatchPort.stoppedDispatchIds, isEmpty);
      },
    );

    test(
      'failRun marks run with error',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();
        final log = _pendingRunLog();
        await runLogRepo.upsert(log);

        await service.failRun(log, 'something went wrong');

        expect(runLogRepo.upserted.length, 2);
        final failed = runLogRepo.upserted.last;
        expect(failed.status, RunStatus.error);
        expect(failed.summary, 'something went wrong');
        expect(failed.completedAt, isNotNull);
      },
    );

    test(
      'failRun is idempotent for already completed run',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();
        final log = _pendingRunLog();
        await runLogRepo.upsert(log);

        await service.completeRun(log, null);
        await service.failRun(log, 'should be ignored');

        // Seed + completeRun only; failRun should not have upserted again.
        expect(runLogRepo.upserted.length, 2);
        // The last upsert should still be the completed one.
        expect(runLogRepo.upserted.last.status, RunStatus.completed);
      },
    );

    test(
      'stopRun stops dispatch and updates runLog',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();

        final result = await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );

        await service.stopRun(_workspaceId, result.runLog.id);

        // Dispatch called stopDispatch with the correct id.
        expect(dispatchPort.stoppedDispatchIds, contains(result.dispatchId));

        // The run log should be updated to error state.
        final updated = runLogRepo._logs[result.runLog.id];
        expect(updated, isNotNull);
        expect(updated!.status, RunStatus.error);
        expect(updated.summary, 'Stopped by user');
      },
    );

    test(
      'stopRun is no-op for already completed run',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();

        final result = await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );

        await service.completeRun(result.runLog, null);
        // Reset tracking to clearly see whether stopRun calls stopDispatch.
        dispatchPort.stoppedDispatchIds.clear();

        await service.stopRun(_workspaceId, result.runLog.id);

        expect(dispatchPort.stoppedDispatchIds, isEmpty);
      },
    );

    test(
      'stopRun handles unknown runLogId gracefully',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();

        // Should not throw.
        await service.stopRun(_workspaceId, 'non-existent-id');

        expect(dispatchPort.stoppedDispatchIds, isEmpty);
        // No upsert for unknown log (the seed from dispatch was never called).
        // The only items in upserted would be from dispatch, which we didn't call.
        expect(runLogRepo.upserted, isEmpty);
      },
    );

    test(
      'dispatch uses repo provisioner when available',
      timeout: const Timeout.factor(2),
      () async {
        final provisioner = _FakeRepoProvisioner('/provisioned/work');
        final service = createService(repoProvisioner: provisioner);

        await service.dispatch(
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/fallback/work',
          workspaceId: 'ws-1',
          channelId: 'ch-1',
        );

        expect(provisioner.ensureCalled, isTrue);
      },
    );

    test(
      'dispatch falls back to working directory on an empty workspaceId',
      timeout: const Timeout.factor(2),
      () async {
        final provisioner = _FakeRepoProvisioner('/provisioned/work');
        final service = createService(repoProvisioner: provisioner);

        // An empty workspace id selects no database, so there is no conversation
        // worktree to provision into.
        await service.dispatch(
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/fallback/work',
          workspaceId: '',
        );

        expect(provisioner.ensureCalled, isFalse);
      },
    );

    test(
      'completeRun persists summary and cost',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();
        final log = _pendingRunLog();
        await runLogRepo.upsert(log);

        await service.completeRun(
          log,
          'Done!',
          cost: const RunCost(inputTokens: 42, outputTokens: 7),
        );

        final completed = runLogRepo.upserted.last;
        expect(completed.summary, 'Done!');
        expect(completed.cost.inputTokens, 42);
        expect(completed.cost.outputTokens, 7);
      },
    );

    test(
      'completeRun stamps a wall-clock duration when usage carried none',
      timeout: const Timeout.factor(2),
      () async {
        // The built-in harness emits UsageEvent without durationMs, so a
        // top-level run persisted durationMs: null and its activity header
        // read "—". Only a subagent times itself.
        final service = createService();
        final log = _pendingRunLog();
        await runLogRepo.upsert(log);

        await service.completeRun(
          log,
          null,
          cost: const RunCost(inputTokens: 42),
        );

        final completed = runLogRepo.upserted.last;
        expect(completed.cost.inputTokens, 42, reason: 'usage is preserved');
        expect(
          completed.cost.durationMs,
          completed.completedAt!.difference(log.startedAt).inMilliseconds,
        );
      },
    );

    test(
      'completeRun keeps a measured duration over the wall clock',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();
        final log = _pendingRunLog();
        await runLogRepo.upsert(log);

        await service.completeRun(
          log,
          null,
          cost: const RunCost(inputTokens: 42, durationMs: 1234),
        );

        expect(runLogRepo.upserted.last.cost.durationMs, 1234);
      },
    );

    test(
      'failRun times the run too',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();
        final log = _pendingRunLog();
        await runLogRepo.upsert(log);

        await service.failRun(log, 'boom');

        final failed = runLogRepo.upserted.last;
        expect(failed.status, RunStatus.error);
        expect(failed.cost.durationMs, isNotNull);
        expect(failed.cost.durationMs, greaterThan(0));
      },
    );

    test(
      'failRun removes dispatch mapping (stopRun becomes no-op)',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();

        final result = await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );

        // failRun deletes the mapping from _runToDispatch.
        await service.failRun(result.runLog, 'error');

        // stopRun should find no mapping and therefore NOT call stopDispatch.
        await service.stopRun(_workspaceId, result.runLog.id);

        expect(dispatchPort.stoppedDispatchIds, isEmpty);
      },
    );

    test(
      'dispatch uses conversationId when channelId is null',
      timeout: const Timeout.factor(2),
      () async {
        final provisioner = _FakeRepoProvisioner('/provisioned/work');
        final service = createService(repoProvisioner: provisioner);

        await service.dispatch(
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/fallback/work',
          workspaceId: 'ws-1',
          conversationId: 'conv-1',
          channelId: null,
        );

        expect(provisioner.ensureCalled, isTrue);
      },
    );

    test(
      'dispatch works with null runLogRepo',
      timeout: const Timeout.factor(2),
      () async {
        final service = AgentDispatchService(
          agentDispatch: dispatchPort,
          dispatchUseCase: dispatchUseCase,
          runLogRepo: null,
        );

        final result = await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );
        expect(result.dispatchId, 'dispatch-1');
        expect(result.runLog, isNotNull);
      },
    );

    test(
      'completeRun with null runLogRepo does not throw',
      timeout: const Timeout.factor(2),
      () async {
        final service = AgentDispatchService(
          agentDispatch: dispatchPort,
          dispatchUseCase: dispatchUseCase,
          runLogRepo: null,
        );

        // Should not throw.
        await service.completeRun(_pendingRunLog(), null);
      },
    );

    test(
      'failRun with null runLogRepo does not throw',
      timeout: const Timeout.factor(2),
      () async {
        final service = AgentDispatchService(
          agentDispatch: dispatchPort,
          dispatchUseCase: dispatchUseCase,
          runLogRepo: null,
        );

        // Should not throw.
        await service.failRun(_pendingRunLog(), 'error');
      },
    );

    test(
      'stopRun with null runLogRepo still stops dispatch',
      timeout: const Timeout.factor(2),
      () async {
        final service = AgentDispatchService(
          agentDispatch: dispatchPort,
          dispatchUseCase: dispatchUseCase,
          runLogRepo: null,
        );

        final result = await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );

        await service.stopRun(_workspaceId, result.runLog.id);

        expect(dispatchPort.stoppedDispatchIds, contains(result.dispatchId));
      },
    );

    test(
      'stopRun on already-failed run is no-op for dispatch',
      timeout: const Timeout.factor(2),
      () async {
        final service = createService();

        final result = await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );

        await service.failRun(result.runLog, 'error');
        // Reset tracking.
        dispatchPort.stoppedDispatchIds.clear();

        await service.stopRun(_workspaceId, result.runLog.id);

        expect(dispatchPort.stoppedDispatchIds, isEmpty);
      },
    );

    test(
      'steerRun maps runLogId to dispatchId and forwards the result',
      timeout: const Timeout.factor(2),
      () async {
        dispatchPort.steerReturn = true;
        final service = createService();

        final result = await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );

        final delivered = await service.steerRun(result.runLog.id, 'nudge');

        expect(delivered, isTrue);
        expect(
          dispatchPort.steeredDispatches.single.dispatchId,
          result.dispatchId,
        );
        expect(dispatchPort.steeredDispatches.single.message, 'nudge');
        expect(dispatchPort.steeredDispatches.single.followUp, isFalse);
      },
    );

    test(
      'steerRun forwards followUp',
      timeout: const Timeout.factor(2),
      () async {
        dispatchPort.steerReturn = true;
        final service = createService();

        final result = await service.dispatch(
          workspaceId: _workspaceId,
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
        );

        await service.steerRun(result.runLog.id, 'later', followUp: true);

        expect(dispatchPort.steeredDispatches.single.followUp, isTrue);
      },
    );

    test(
      'steerRun returns false for an unknown runLogId',
      timeout: const Timeout.factor(2),
      () async {
        dispatchPort.steerReturn = true;
        final service = createService();

        final delivered = await service.steerRun('never-dispatched', 'nudge');

        expect(delivered, isFalse);
        expect(dispatchPort.steeredDispatches, isEmpty);
      },
    );

    test(
      'completeRun sets the agent idle in the registry',
      timeout: const Timeout.factor(2),
      () async {
        final registry = AgentRegistryImpl();
        final service = createService(registry: registry);

        final result = await service.dispatch(
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
          workspaceId: 'ws-1',
        );

        // Dispatch registers the agent as running.
        expect(registry.get('agent-1')?.status, AgentStatus.running);

        await service.completeRun(result.runLog, null);

        expect(registry.get('agent-1')?.status, AgentStatus.idle);
      },
    );

    test(
      'failRun sets the agent idle in the registry',
      timeout: const Timeout.factor(2),
      () async {
        final registry = AgentRegistryImpl();
        final service = createService(registry: registry);

        final result = await service.dispatch(
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
          workspaceId: 'ws-1',
        );

        await service.failRun(result.runLog, 'boom');

        expect(registry.get('agent-1')?.status, AgentStatus.idle);
      },
    );

    test(
      'a ToolCallEvent event sets the agent activity in the registry',
      timeout: const Timeout.factor(2),
      () async {
        final registry = AgentRegistryImpl();
        final service = createService(registry: registry);

        final result = await service.dispatch(
          agentId: 'agent-1',
          prompt: 'do work',
          workingDirectory: '/tmp/work',
          workspaceId: 'ws-1',
        );

        // The registry tap runs via .map on the event stream — it only fires
        // while a consumer is listening, so subscribe to the result stream.
        final sub = result.stream.listen((_) {});
        // Emit a tool-call event into the run's stream.
        dispatchPort.eventsController.add(
          ToolCallEvent(
            toolName: 'edit_file',
            toolCallId: 'tc-1',
            inputs: {'path': '/tmp/f'},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(registry.get('agent-1')?.activity, 'edit_file');

        // A DoneEvent flips the agent to idle.
        dispatchPort.eventsController.add(DoneEvent());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(registry.get('agent-1')?.status, AgentStatus.idle);
        await sub.cancel();
      },
    );

    test(
      'completeRun rolls child cost up into the parent run',
      timeout: const Timeout.factor(2),
      () async {
        final registry = AgentRegistryImpl();
        // Register a parent agent whose active run will receive the rollup.
        registry.register(
          const RegisterAgentInput(
            id: 'parent',
            displayName: 'Parent',
            workspaceId: 'ws-1',
          ),
        );
        registry.register(
          const RegisterAgentInput(
            id: 'child',
            displayName: 'Child',
            workspaceId: 'ws-1',
            parentId: 'parent',
          ),
        );
        final parentLog = _pendingRunLog(id: 'parent-run', agentId: 'parent');
        await runLogRepo.upsert(parentLog);

        final service = createService(registry: registry);

        // Completing the child with a cost propagates into the parent's run.
        // The child must be seeded in the repo — completeRun reads it fresh.
        final childLog = _pendingRunLog(id: 'child-run', agentId: 'child');
        await runLogRepo.upsert(childLog);
        await service.completeRun(
          childLog,
          null,
          cost: const RunCost(estimatedCostCents: 42),
        );

        // The parent's run row gained the child cost.
        final parent = runLogRepo._logs['parent-run'];
        expect(parent, isNotNull);
        expect(parent!.childCostCents, 42);
      },
    );

    test(
      'completeRun with zero cost does not propagate',
      timeout: const Timeout.factor(2),
      () async {
        final registry = AgentRegistryImpl();
        registry.register(
          const RegisterAgentInput(
            id: 'parent',
            displayName: 'Parent',
            workspaceId: 'ws-1',
          ),
        );
        registry.register(
          const RegisterAgentInput(
            id: 'child',
            displayName: 'Child',
            workspaceId: 'ws-1',
            parentId: 'parent',
          ),
        );
        final parentLog = _pendingRunLog(id: 'parent-run', agentId: 'parent');
        await runLogRepo.upsert(parentLog);

        final service = createService(registry: registry);
        final childLog = _pendingRunLog(id: 'child-run', agentId: 'child');
        await runLogRepo.upsert(childLog);
        await service.completeRun(childLog, null);

        // No cost to roll up — the parent's childCostCents stays at 0.
        expect(runLogRepo._logs['parent-run']!.childCostCents, 0);
      },
    );
  });
}
