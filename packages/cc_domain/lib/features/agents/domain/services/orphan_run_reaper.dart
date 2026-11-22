import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/process_control_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/agents/domain/services/budget_policy_service.dart';
import 'package:cc_domain/features/dispatch/domain/services/run_settlement.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';

/// Scans for orphaned agent runs (marked running but no active process)
/// and reaps them by marking them failed and scheduling recovery.
class OrphanRunReaper {
  /// Creates an orphan reaper with the required repositories,
  /// [_ticketWorkflow], [_processControl] and optional [_budgetEnforcement].
  /// A reaped run settles on [_eventBus] (`AgentRunSettled`, reason
  /// `serverStopped`); null writes the row and announces nothing.
  ///
  /// `startedBefore` is when this server process started: a run that began
  /// at or after it is this process's own (a goal segment or a pipeline step
  /// boot recovery just dispatched, a person's new run), never an orphan,
  /// whatever its pid says.
  OrphanRunReaper({
    required this._runLogRepo,
    required this._ticketRepo,
    required this._ticketWorkflow,
    required this._processControl,
    required this._eventBus,
    required this._startedBefore,
    this._budgetEnforcement,
  });

  final DateTime _startedBefore;

  final DomainEventBus? _eventBus;

  final AgentRunLogRepository _runLogRepo;
  final TicketRepository _ticketRepo;
  final TicketWorkflowService _ticketWorkflow;
  final ProcessControlPort _processControl;
  final BudgetEnforcementService? _budgetEnforcement;

  static const _tag = 'OrphanRunReaper';
  static const _maxRetries = 3;

  /// Scans all active runs, identifies orphans and reaps them.
  Future<void> reap() async {
    final runs = await _runLogRepo.nonTerminal();
    final activeRuns = runs
        .where(
          (r) =>
              r.status == RunStatus.running &&
              r.startedAt.isBefore(_startedBefore),
        )
        .toList();

    if (activeRuns.isEmpty) {
      CcDomainLog.info('$_tag: No active runs to inspect');
      return;
    }

    CcDomainLog.info(
      '$_tag: Inspecting ${activeRuns.length} active run(s) for orphans',
    );

    for (final run in activeRuns) {
      try {
        await _reapRun(run);
      } on Object catch (e, st) {
        CcDomainLog.error('$_tag: Failed to reap run ${run.id}', e, st);
      }
    }
  }

  Future<void> _reapRun(AgentRunLog run) async {
    final pid = run.pid;
    if (pid == null) {
      CcDomainLog.warning(
        '$_tag: Run ${run.id} has null pid — marking as dead',
      );
      if (await _markRunFailed(run, 'process_lost_missing_pid')) {
        await _failBackingTicket(run);
      }
      return;
    }

    final processAlive = _processControl.isPidAlive(pid);

    if (!processAlive) {
      CcDomainLog.info(
        '$_tag: Run ${run.id} pid $pid is dead (process not found)',
      );
      if (await _markRunFailed(run, 'process_lost')) {
        await _failBackingTicket(run);
        await _maybeScheduleRecovery(run);
      }
      return;
    }

    // Dispatch liveness check removed after AgentDispatchPort interface
    // was simplified. If re-introduced, query the active dispatcher directly.
  }

  /// Fails [run] only if it is still active, and reports whether it did.
  ///
  /// [run] is a snapshot taken at the start of the scan; the run may have
  /// finished since. The terminal write is conditional on the row still being
  /// active and carries no usage, so a run that completed in the meantime keeps
  /// its own outcome and cost, and its ticket is left alone.
  Future<bool> _markRunFailed(AgentRunLog run, String failureReason) async {
    final workspaceId = run.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      CcDomainLog.warning(
        '$_tag: Run ${run.id} carries no workspace — cannot mark it failed',
      );
      return false;
    }
    final failed = run.copyWith(
      status: RunStatus.error,
      errorFamily: RunErrorFamily.processLost,
      summary: failureReason,
      completedAt: DateTime.now(),
      liveness: RunLiveness.dead,
    );
    // A run whose process is gone was ended by the server going away (or
    // dying): it settles as a server stop, through the same chokepoint as
    // every other terminal write, so it is announced exactly once, naming
    // the requester its row recorded at dispatch.
    final settled = await RunSettlement(
      runLogs: _runLogRepo,
      eventBus: _eventBus,
    ).settle(
      failed,
      endReason: RunEndReason.serverStopped,
      writeCost: false,
    );
    if (!settled) {
      CcDomainLog.info(
        '$_tag: Run ${run.id} finished before it could be reaped — left as is',
      );
      return false;
    }
    // The terminal write does not carry the error family; the run is now
    // terminal and owned by this pass, so classify it.
    await _runLogRepo.updateRuntime(
      workspaceId,
      run.id,
      errorFamily: RunErrorFamily.processLost,
    );
    CcDomainLog.info('$_tag: Run ${run.id} marked as failed ($failureReason)');
    return true;
  }

  Future<void> _failBackingTicket(AgentRunLog run) async {
    final ticketId = run.ticketId;
    if (ticketId == null || ticketId.isEmpty) {
      return;
    }

    final workspaceId = run.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      CcDomainLog.warning(
        '$_tag: Run ${run.id} carries no workspace — cannot scope ticket $ticketId',
      );
      return;
    }

    try {
      final ticket = await _ticketRepo.getById(workspaceId, ticketId);
      if (ticket == null || ticket.isTerminal) {
        return;
      }

      await _ticketWorkflow.failTicket(
        ticketId,
        'Orphaned run ${run.id}: process lost',
        workspaceId: ticket.workspaceId,
      );
      CcDomainLog.info('$_tag: Backing ticket $ticketId marked as failed');
    } on Object catch (e, st) {
      CcDomainLog.error(
        '$_tag: Failed to fail backing ticket $ticketId',
        e,
        st,
      );
    }
  }

  Future<void> _maybeScheduleRecovery(AgentRunLog run) async {
    if (run.retry.attempt >= _maxRetries) {
      CcDomainLog.info(
        '$_tag: Run ${run.id} exhausted retries ($_maxRetries) — skipping recovery',
      );
      return;
    }

    final budget = _budgetEnforcement;
    if (budget != null) {
      try {
        final block = await budget.checkInvocationBlock(
          agentId: run.agentId,
          workspaceId: run.workspaceId ?? '',
          ticketId: run.ticketId,
        );

        if (block != null) {
          CcDomainLog.warning(
            '$_tag: Run ${run.id} recovery blocked by budget: ${block.reason}',
          );
          return;
        }
      } on Object catch (e, st) {
        CcDomainLog.error(
          '$_tag: Budget check failed for run ${run.id}',
          e,
          st,
        );
        return;
      }
    }

    // Deliberately does not re-dispatch here. Recovery for a TICKET-backed run
    // is performed by `StrandedTicketReconciler`, which runs immediately after
    // this reaper at boot: this pass failed the run and its backing ticket, and
    // the reconciler resets an eligible ticket to `open` so the dispatcher
    // picks it up again (with the same retry + budget ceilings re-checked
    // there). This log line is the hand-off record.
    //
    // A run with NO ticket (a chat turn) is intentionally NOT resurrected: it
    // is a user's turn, and silently re-running it after a crash would re-spend
    // budget on work nobody asked to repeat. The failed run is visible in the
    // transcript and the operator can re-ask.
    CcDomainLog.info(
      '$_tag: Run ${run.id} eligible for recovery '
      '(attempt ${run.retry.attempt + 1} of $_maxRetries) — '
      '${run.ticketId == null ? 'no backing ticket, not resurrected' : 'handed to the stranded-ticket reconciler'}',
    );
  }
}
