import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';

/// Evaluates completed runs and schedules retries or recovery dispatches.
class HeartbeatRecoveryService {
  /// Creates a recovery service backed by [runLogRepo] and [ticketWorkflow].
  HeartbeatRecoveryService({
    required AgentRunLogRepository runLogRepo,
    required TicketWorkflowService ticketWorkflow,
  })  : _runLogRepo = runLogRepo,
        _ticketWorkflow = ticketWorkflow;

  final AgentRunLogRepository _runLogRepo;
  final TicketWorkflowService _ticketWorkflow;

  /// Exponential backoff delays for transient upstream failures (API rate
  /// limits, auth issues, etc.).
  static const List<Duration> boundedTransientRetryDelays = [
    Duration(minutes: 2),
    Duration(minutes: 10),
    Duration(minutes: 30),
    Duration(hours: 2),
  ];

  /// Maximum continuation attempts for stalled/empty runs.
  static const int maxContinuationAttempts = 3;

  /// Evaluates a completed [run] and schedules retry/continuation if needed.
  Future<void> evaluateAndSchedule(AgentRunLog run) async {
    if (run.errorFamily == RunErrorFamily.transientUpstream &&
        run.retry.attempt < boundedTransientRetryDelays.length) {
      final delay = boundedTransientRetryDelays[run.retry.attempt];
      CcDomainLog.info('HeartbeatRecovery: Scheduling retry ${run.retry.attempt + 1} '
          'for run ${run.id} in ${delay.inMinutes}min');

      await _scheduleRetry(run, delay);
      return;
    }

    if (run.liveness == RunLiveness.stalled) {
      if (!shouldContinue(run)) {
        CcDomainLog.warning('HeartbeatRecovery: Run ${run.id} exceeded max continuation '
            'attempts (${run.retry.attempt}/$maxContinuationAttempts)');
        await _failBackingTicket(run, 'max continuations exceeded');
        return;
      }

      CcDomainLog.info('HeartbeatRecovery: Scheduling continuation wake for '
          'stalled run ${run.id} (attempt ${run.retry.attempt + 1})');
      await _scheduleContinuation(run);
      return;
    }

    if (run.liveness == RunLiveness.dead) {
      CcDomainLog.warning('HeartbeatRecovery: Run ${run.id} classified as dead — '
          'failing ticket');
      await _failBackingTicket(run, 'agent process died');
    }
  }

  /// Whether [run] should be continued (within max continuation attempts).
  bool shouldContinue(AgentRunLog run) =>
      run.retry.attempt < maxContinuationAttempts;

  Future<void> _scheduleRetry(AgentRunLog run, Duration delay) async {
    try {
      await _runLogRepo.upsert(
        run.copyWith(
          status: RunStatus.pending,
          retry: run.retry.nextAttempt(),
          completedAt: DateTime.now(),
          removeCompletedAt: true,
        ),
      );
    } catch (e, st) {
      CcDomainLog.error('HeartbeatRecovery: Failed to schedule retry for ${run.id}', e, st);
    }
  }

  Future<void> _scheduleContinuation(AgentRunLog run) async {
    try {
      await _runLogRepo.upsert(
        run.copyWith(
          status: RunStatus.pending,
          retry: run.retry.nextAttempt(),
          completedAt: DateTime.now(),
          removeCompletedAt: true,
        ),
      );
    } catch (e, st) {
      CcDomainLog.error('HeartbeatRecovery: Failed to schedule continuation for ${run.id}', e, st);
    }
  }

  Future<void> _failBackingTicket(AgentRunLog run, String reason) async {
    final ticketId = run.ticketId;
    final workspaceId = run.workspaceId;
    // A ticket-backing run always carries the ticket's workspace; without it we
    // can't satisfy the workspace-scoped failTicket guard, so skip.
    if (ticketId == null || workspaceId == null) {
      return;
    }

    try {
      await _ticketWorkflow.failTicket(
        ticketId,
        reason,
        workspaceId: workspaceId,
      );
      await _runLogRepo.upsert(
        run.copyWith(
          status: RunStatus.error,
          summary: reason,
          errorFamily: RunErrorFamily.processLost,
          completedAt: DateTime.now(),
        ),
      );
    } catch (e, st) {
      CcDomainLog.error('HeartbeatRecovery: Failed to fail ticket $ticketId', e, st);
    }
  }
}
