import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/retry_meta.dart';
import 'package:cc_domain/features/agents/domain/services/heartbeat_recovery_service.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_agent_run_log_repository.dart';

class _FakeTicketWorkflowService implements TicketWorkflowService {
  final List<({String ticketId, String reason, String workspaceId})>
      failedTickets = [];

  @override
  Future<void> failTicket(
    String ticketId,
    String errorMessage, {
    required String workspaceId,
    bool force = false,
  }) async {
    failedTickets.add((
      ticketId: ticketId,
      reason: errorMessage,
      workspaceId: workspaceId,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

AgentRunLog _makeRun({
  String id = 'run-1',
  RunStatus status = RunStatus.error,
  RunErrorFamily? errorFamily,
  RunLiveness? liveness,
  String? ticketId,
  String? workspaceId,
  int retryAttempt = 0,
  String? parentRunId,
}) =>
    AgentRunLog(
      id: id,
      agentId: 'agent-1',
      workspaceId: workspaceId,
      ticketId: ticketId,
      startedAt: DateTime(2025, 6, 1),
      status: status,
      errorFamily: errorFamily,
      liveness: liveness,
      retry: RetryMeta(attempt: retryAttempt, parentRunId: parentRunId),
    );

void main() {
  group('HeartbeatRecoveryService', () {
    late FakeAgentRunLogRepository runLogRepo;
    late _FakeTicketWorkflowService ticketWorkflow;
    late HeartbeatRecoveryService service;

    setUp(() {
      runLogRepo = FakeAgentRunLogRepository();
      ticketWorkflow = _FakeTicketWorkflowService();
      service = HeartbeatRecoveryService(
        runLogRepo: runLogRepo,
        ticketWorkflow: ticketWorkflow,
      );
    });

    group('evaluateAndSchedule', () {
      test('schedules retry for transient upstream with attempts remaining',
          timeout: const Timeout.factor(2), () async {
        final run = _makeRun(
          errorFamily: RunErrorFamily.transientUpstream,
          retryAttempt: 0,
        );
        runLogRepo.seed(run);

        await service.evaluateAndSchedule(run);

        final updated = await runLogRepo.getById(run.id);
        expect(updated, isNotNull);
        expect(updated!.status, RunStatus.pending);
        expect(updated.retry.attempt, 1);
      });

      test('does not retry transient upstream when attempts exhausted',
          timeout: const Timeout.factor(2), () async {
        final run = _makeRun(
          errorFamily: RunErrorFamily.transientUpstream,
          retryAttempt:
              HeartbeatRecoveryService.boundedTransientRetryDelays.length,
          ticketId: 'ticket-1',
          workspaceId: 'ws-1',
        );
        runLogRepo.seed(run);

        await service.evaluateAndSchedule(run);

        expect(ticketWorkflow.failedTickets, isEmpty);
      });

      test('schedules continuation for stalled run with attempts remaining',
          timeout: const Timeout.factor(2), () async {
        final run = _makeRun(
          liveness: RunLiveness.stalled,
          retryAttempt: 1,
        );
        runLogRepo.seed(run);

        await service.evaluateAndSchedule(run);

        final updated = await runLogRepo.getById(run.id);
        expect(updated, isNotNull);
        expect(updated!.status, RunStatus.pending);
        expect(updated.retry.attempt, 2);
      });

      test('fails ticket for stalled run exceeding max continuations',
          timeout: const Timeout.factor(2), () async {
        final run = _makeRun(
          liveness: RunLiveness.stalled,
          retryAttempt: HeartbeatRecoveryService.maxContinuationAttempts,
          ticketId: 'ticket-1',
          workspaceId: 'ws-1',
        );
        runLogRepo.seed(run);

        await service.evaluateAndSchedule(run);

        expect(ticketWorkflow.failedTickets, hasLength(1));
        expect(ticketWorkflow.failedTickets.first.ticketId, 'ticket-1');
        expect(ticketWorkflow.failedTickets.first.reason,
            contains('max continuations'));
      });

      test('fails ticket for dead run', timeout: const Timeout.factor(2), () async {
        final run = _makeRun(
          liveness: RunLiveness.dead,
          ticketId: 'ticket-1',
          workspaceId: 'ws-1',
        );
        runLogRepo.seed(run);

        await service.evaluateAndSchedule(run);

        expect(ticketWorkflow.failedTickets, hasLength(1));
        expect(ticketWorkflow.failedTickets.first.ticketId, 'ticket-1');
      });

      test('skips failBackingTicket when ticketId is null',
          timeout: const Timeout.factor(2), () async {
        final run = _makeRun(
          liveness: RunLiveness.dead,
          ticketId: null,
          workspaceId: 'ws-1',
        );

        await service.evaluateAndSchedule(run);

        expect(ticketWorkflow.failedTickets, isEmpty);
      });

      test('skips failBackingTicket when workspaceId is null',
          timeout: const Timeout.factor(2), () async {
        final run = _makeRun(
          liveness: RunLiveness.dead,
          ticketId: 'ticket-1',
          workspaceId: null,
        );

        await service.evaluateAndSchedule(run);

        expect(ticketWorkflow.failedTickets, isEmpty);
      });
    });

    group('shouldContinue', () {
      test('returns true when attempt < max', timeout: const Timeout.factor(2), () {
        final run = _makeRun(retryAttempt: 0);
        expect(service.shouldContinue(run), isTrue);
      });

      test('returns false when attempt >= max', timeout: const Timeout.factor(2), () {
        final run = _makeRun(
          retryAttempt: HeartbeatRecoveryService.maxContinuationAttempts,
        );
        expect(service.shouldContinue(run), isFalse);
      });
    });

    test('transient upstream takes priority over stalled',
        timeout: const Timeout.factor(2), () async {
      final run = _makeRun(
        errorFamily: RunErrorFamily.transientUpstream,
        liveness: RunLiveness.stalled,
        retryAttempt: 0,
      );
      runLogRepo.seed(run);

      await service.evaluateAndSchedule(run);

      final updated = await runLogRepo.getById(run.id);
      expect(updated!.retry.attempt, 1);
      expect(ticketWorkflow.failedTickets, isEmpty);
    });
  });
}
