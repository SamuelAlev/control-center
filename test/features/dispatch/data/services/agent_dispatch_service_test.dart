import 'dart:async';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/run_cost.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/features/dispatch/data/services/agent_dispatch_service.dart';
import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:control_center/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:control_center/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:control_center/features/dispatch/domain/value_objects/mention_context.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake implementations
// ---------------------------------------------------------------------------

class _FakeDispatchUseCase implements DispatchAgentUseCase {
  _FakeDispatchUseCase(this.cannedResult);
  final PreparedDispatch cannedResult;

  @override
  Future<PreparedDispatch> execute({
    required String agentId,
    required String prompt,
    String? channelId,
    String? conversationId,
    String? adapterId,
    String? workingDirectory,
    WakeContext? wakeContext,
    MentionContext? mentionContext,
  }) async {
    return cannedResult;
  }
}

class _FakeAgentDispatchPort implements AgentDispatchPort {
  _FakeAgentDispatchPort(this.eventsController);
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
    String? modelId,
    String? agentId,
    String? workspaceId,
    String? conversationId,
    String? runLogId,
    String? ticketId,
    WakeContext? wakeContext,
    ConversationMode? mode,
    int? silenceTimeoutMinutes,
    Map<String, String>? environment,
    List<String>? imagePaths,
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

  @override
  Future<void> stop() async {
    stopCalled = true;
  }
}

class _FakeRunLogRepository implements AgentRunLogRepository {
  @override
  Future<AgentRunLog?> activeRunForAgent(String agentId) async => null;

  final Map<String, AgentRunLog> _logs = {};
  final List<AgentRunLog> upserted = [];

  @override
  Future<AgentRunLog?> getById(String id) async => _logs[id];

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
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) =>
      Stream.value([]);
}

class _FakeRepoProvisioner implements RepoWorkspaceProvisionerPort {

  _FakeRepoProvisioner(this.cannedDir);
  final String cannedDir;
  bool ensureCalled = false;

  @override
  Future<String> ensureConversationWorkspace({
    required String workspaceId,
    required String channelId,
    required String fallbackDir,
    String? agentConfigDir,
    String? ticketId,
    String? ticketKey,
    String? ticketTitle,
    String branchType = 'feature',
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
  }) async =>
      0;

  @override
  Future<int> sweepStale({required String workspaceId}) async => 0;
}

PreparedDispatch _cannedDispatch() => const PreparedDispatch(
      effectivePrompt: 'test prompt',
      effectiveConversationId: null,
      agent: null,
      mode: ConversationMode.chat,
      resolvedAdapterId: null,
      cliName: 'pi',
    );

AgentRunLog _pendingRunLog({String id = 'run-1', String agentId = 'agent-1'}) =>
    AgentRunLog(
      id: id,
      agentId: agentId,
      startedAt: DateTime(2025, 1, 1),
      status: RunStatus.pending,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AgentDispatchResult', () {
    test('constructs with required fields', timeout: const Timeout.factor(2), () {
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
    });

    test('constructs with agent field set', timeout: const Timeout.factor(2), () {
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
    });

    test('agent field is null by default', timeout: const Timeout.factor(2), () {
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
    });

    test('stream emits events from controller', timeout: const Timeout.factor(2),
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
    });

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

    test('different instances with same dispatchId have different streams',
        timeout: const Timeout.factor(2), () {
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
    });
  });

  group('AgentDispatchService', () {
    late _FakeAgentDispatchPort dispatchPort;
    late _FakeRunLogRepository runLogRepo;
    late _FakeDispatchUseCase dispatchUseCase;

    AgentDispatchService createService({
      _FakeRepoProvisioner? repoProvisioner,
    }) {
      return AgentDispatchService(
        agentDispatch: dispatchPort,
        dispatchUseCase: dispatchUseCase,
        runLogRepo: runLogRepo,
        repoProvisioner: repoProvisioner,
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

    test('dispatch returns AgentDispatchResult with correct dispatchId',
        timeout: const Timeout.factor(2), () async {
      final service = createService();

      final result = await service.dispatch(
        agentId: 'agent-1',
        prompt: 'do work',
        workingDirectory: '/tmp/work',
      );

      expect(result.dispatchId, 'dispatch-1');
      expect(result.stream, isNotNull);
      expect(result.runLog, isNotNull);
    });

    test('dispatch creates runLog with status pending',
        timeout: const Timeout.factor(2), () async {
      final service = createService();

      await service.dispatch(
        agentId: 'agent-1',
        prompt: 'do work',
        workingDirectory: '/tmp/work',
      );

      expect(runLogRepo.upserted, isNotEmpty);
      final persisted = runLogRepo.upserted.first;
      expect(persisted.status, RunStatus.pending);
      expect(persisted.agentId, 'agent-1');
    });

    test('dispatch stores runId-to-dispatchId mapping (verified via stopRun)',
        timeout: const Timeout.factor(2), () async {
      final service = createService();

      final result = await service.dispatch(
        agentId: 'agent-1',
        prompt: 'do work',
        workingDirectory: '/tmp/work',
      );
      final runLogId = result.runLog.id;

      await service.stopRun(runLogId);

      expect(dispatchPort.stoppedDispatchIds, contains(result.dispatchId));
    });

    test('completeRun marks run as completed',
        timeout: const Timeout.factor(2), () async {
      final service = createService();
      final log = _pendingRunLog();
      await runLogRepo.upsert(log);

      await service.completeRun(log, null);

      // One seed upsert + one completeRun upsert.
      expect(runLogRepo.upserted.length, 2);
      final completed = runLogRepo.upserted.last;
      expect(completed.status, RunStatus.completed);
      expect(completed.completedAt, isNotNull);
    });

    test('completeRun is idempotent', timeout: const Timeout.factor(2), () async {
      final service = createService();
      final log = _pendingRunLog();
      await runLogRepo.upsert(log);

      await service.completeRun(log, null);
      await service.completeRun(log, null);

      // Seed upsert + exactly one completeRun upsert (second was no-op).
      expect(runLogRepo.upserted.length, 2);
    });

    test('completeRun removes dispatch mapping (stopRun becomes no-op)',
        timeout: const Timeout.factor(2), () async {
      final service = createService();

      final result = await service.dispatch(
        agentId: 'agent-1',
        prompt: 'do work',
        workingDirectory: '/tmp/work',
      );

      // completeRun deletes the mapping from _runToDispatch.
      await service.completeRun(result.runLog, null);

      // stopRun should find no mapping and therefore NOT call stopDispatch.
      await service.stopRun(result.runLog.id);

      expect(dispatchPort.stoppedDispatchIds, isEmpty);
    });

    test('failRun marks run with error', timeout: const Timeout.factor(2), () async {
      final service = createService();
      final log = _pendingRunLog();
      await runLogRepo.upsert(log);

      await service.failRun(log, 'something went wrong');

      expect(runLogRepo.upserted.length, 2);
      final failed = runLogRepo.upserted.last;
      expect(failed.status, RunStatus.error);
      expect(failed.summary, 'something went wrong');
      expect(failed.completedAt, isNotNull);
    });

    test('failRun is idempotent for already completed run',
        timeout: const Timeout.factor(2), () async {
      final service = createService();
      final log = _pendingRunLog();
      await runLogRepo.upsert(log);

      await service.completeRun(log, null);
      await service.failRun(log, 'should be ignored');

      // Seed + completeRun only; failRun should not have upserted again.
      expect(runLogRepo.upserted.length, 2);
      // The last upsert should still be the completed one.
      expect(runLogRepo.upserted.last.status, RunStatus.completed);
    });

    test('stopRun stops dispatch and updates runLog',
        timeout: const Timeout.factor(2), () async {
      final service = createService();

      final result = await service.dispatch(
        agentId: 'agent-1',
        prompt: 'do work',
        workingDirectory: '/tmp/work',
      );

      await service.stopRun(result.runLog.id);

      // Dispatch called stopDispatch with the correct id.
      expect(
        dispatchPort.stoppedDispatchIds,
        contains(result.dispatchId),
      );

      // The run log should be updated to error state.
      final updated = runLogRepo._logs[result.runLog.id];
      expect(updated, isNotNull);
      expect(updated!.status, RunStatus.error);
      expect(updated.summary, 'Stopped by user');
    });

    test('stopRun is no-op for already completed run',
        timeout: const Timeout.factor(2), () async {
      final service = createService();

      final result = await service.dispatch(
        agentId: 'agent-1',
        prompt: 'do work',
        workingDirectory: '/tmp/work',
      );

      await service.completeRun(result.runLog, null);
      // Reset tracking to clearly see whether stopRun calls stopDispatch.
      dispatchPort.stoppedDispatchIds.clear();

      await service.stopRun(result.runLog.id);

      expect(dispatchPort.stoppedDispatchIds, isEmpty);
    });

    test('stopRun handles unknown runLogId gracefully',
        timeout: const Timeout.factor(2), () async {
      final service = createService();

      // Should not throw.
      await service.stopRun('non-existent-id');

      expect(dispatchPort.stoppedDispatchIds, isEmpty);
      // No upsert for unknown log (the seed from dispatch was never called).
      // The only items in upserted would be from dispatch, which we didn't call.
      expect(runLogRepo.upserted, isEmpty);
    });

    test('dispatch uses repo provisioner when available',
        timeout: const Timeout.factor(2), () async {
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
    });

    test('dispatch falls back to working directory when no workspaceId',
        timeout: const Timeout.factor(2), () async {
      final provisioner = _FakeRepoProvisioner('/provisioned/work');
      final service = createService(repoProvisioner: provisioner);

      await service.dispatch(
        agentId: 'agent-1',
        prompt: 'do work',
        workingDirectory: '/fallback/work',
        workspaceId: null,
      );

      expect(provisioner.ensureCalled, isFalse);
    });

    test('completeRun persists summary and cost', timeout: const Timeout.factor(2),
        () async {
      final service = createService();
      final log = _pendingRunLog();
      await runLogRepo.upsert(log);

      await service.completeRun(log, 'Done!',
          cost: const RunCost(inputTokens: 42, outputTokens: 7));

      final completed = runLogRepo.upserted.last;
      expect(completed.summary, 'Done!');
      expect(completed.cost.inputTokens, 42);
      expect(completed.cost.outputTokens, 7);
    });

    test('failRun removes dispatch mapping (stopRun becomes no-op)',
        timeout: const Timeout.factor(2), () async {
      final service = createService();

      final result = await service.dispatch(
        agentId: 'agent-1',
        prompt: 'do work',
        workingDirectory: '/tmp/work',
      );

      // failRun deletes the mapping from _runToDispatch.
      await service.failRun(result.runLog, 'error');

      // stopRun should find no mapping and therefore NOT call stopDispatch.
      await service.stopRun(result.runLog.id);

      expect(dispatchPort.stoppedDispatchIds, isEmpty);
    });

    test('dispatch uses conversationId when channelId is null',
        timeout: const Timeout.factor(2), () async {
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
    });

    test('dispatch works with null runLogRepo', timeout: const Timeout.factor(2),
        () async {
      final service = AgentDispatchService(
        agentDispatch: dispatchPort,
        dispatchUseCase: dispatchUseCase,
        runLogRepo: null,
      );

      final result = await service.dispatch(
        agentId: 'agent-1',
        prompt: 'do work',
        workingDirectory: '/tmp/work',
      );
      expect(result.dispatchId, 'dispatch-1');
      expect(result.runLog, isNotNull);
    });

    test('completeRun with null runLogRepo does not throw',
        timeout: const Timeout.factor(2), () async {
      final service = AgentDispatchService(
        agentDispatch: dispatchPort,
        dispatchUseCase: dispatchUseCase,
        runLogRepo: null,
      );

      // Should not throw.
      await service.completeRun(_pendingRunLog(), null);
    });

    test('failRun with null runLogRepo does not throw',
        timeout: const Timeout.factor(2), () async {
      final service = AgentDispatchService(
        agentDispatch: dispatchPort,
        dispatchUseCase: dispatchUseCase,
        runLogRepo: null,
      );

      // Should not throw.
      await service.failRun(_pendingRunLog(), 'error');
    });

    test('stopRun with null runLogRepo still stops dispatch',
        timeout: const Timeout.factor(2), () async {
      final service = AgentDispatchService(
        agentDispatch: dispatchPort,
        dispatchUseCase: dispatchUseCase,
        runLogRepo: null,
      );

      final result = await service.dispatch(
        agentId: 'agent-1',
        prompt: 'do work',
        workingDirectory: '/tmp/work',
      );

      await service.stopRun(result.runLog.id);

      expect(
        dispatchPort.stoppedDispatchIds,
        contains(result.dispatchId),
      );
    });

    test('stopRun on already-failed run is no-op for dispatch',
        timeout: const Timeout.factor(2), () async {
      final service = createService();

      final result = await service.dispatch(
        agentId: 'agent-1',
        prompt: 'do work',
        workingDirectory: '/tmp/work',
      );

      await service.failRun(result.runLog, 'error');
      // Reset tracking.
      dispatchPort.stoppedDispatchIds.clear();

      await service.stopRun(result.runLog.id);

      expect(dispatchPort.stoppedDispatchIds, isEmpty);
    });
  });
}
