import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/ports/process_control_port.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/agents/domain/services/budget_policy_service.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';

class OrphanRunReaper {
  OrphanRunReaper({
    required AgentRunLogRepository runLogRepo,
    required TicketRepository ticketRepo,
    required TicketWorkflowService ticketWorkflow,
    required ProcessControlPort processControl,
    BudgetEnforcementService? budgetEnforcement,
  })  : _runLogRepo = runLogRepo,
        _ticketRepo = ticketRepo,
        _ticketWorkflow = ticketWorkflow,
        _processControl = processControl,
        _budgetEnforcement = budgetEnforcement;

  final AgentRunLogRepository _runLogRepo;
  final TicketRepository _ticketRepo;
  final TicketWorkflowService _ticketWorkflow;
  final ProcessControlPort _processControl;
  final BudgetEnforcementService? _budgetEnforcement;

  static const _tag = 'OrphanRunReaper';
  static const _maxRetries = 3;

  Future<void> reap() async {
    final runs = await _runLogRepo.watchAll().first;
    final activeRuns = runs.where((r) => r.status == RunStatus.running).toList();

    if (activeRuns.isEmpty) {
      AppLog.d(_tag, 'No active runs to inspect');
      return;
    }

    AppLog.i(_tag, 'Inspecting ${activeRuns.length} active run(s) for orphans');

    for (final run in activeRuns) {
      try {
        await _reapRun(run);
      } on Object catch (e, st) {
        AppLog.e(_tag, 'Failed to reap run ${run.id}', e, st);
      }
    }
  }

  Future<void> _reapRun(AgentRunLog run) async {
    final pid = run.pid;
    if (pid == null) {
      AppLog.w(_tag, 'Run ${run.id} has null pid — marking as dead');
      await _markRunFailed(run, 'process_lost_missing_pid');
      await _failBackingTicket(run);
      return;
    }

    final processAlive = _processControl.isPidAlive(pid);

    if (!processAlive) {
      AppLog.i(_tag, 'Run ${run.id} pid $pid is dead (process not found)');
      await _markRunFailed(run, 'process_lost');
      await _failBackingTicket(run);
      await _maybeScheduleRecovery(run);
      return;
    }

    // Dispatch liveness check removed after AgentDispatchPort interface
    // was simplified. If re-introduced, query the active dispatcher directly.
  }

  Future<void> _markRunFailed(AgentRunLog run, String failureReason) async {
    final now = DateTime.now();
    final updated = run.copyWith(
      status: RunStatus.error,
      errorFamily: RunErrorFamily.processLost,
      summary: failureReason,
      completedAt: now,
      liveness: RunLiveness.dead,
    );
    await _runLogRepo.upsert(updated);
    AppLog.i(_tag, 'Run ${run.id} marked as failed ($failureReason)');
  }


  Future<void> _failBackingTicket(AgentRunLog run) async {
    final ticketId = run.ticketId;
    if (ticketId == null || ticketId.isEmpty) return;

    try {
      final ticket = await _ticketRepo.getById(ticketId);
      if (ticket == null || ticket.isTerminal) return;

      await _ticketWorkflow.failTicket(
        ticketId,
        'Orphaned run ${run.id}: process lost',
        workspaceId: ticket.workspaceId,
      );
      AppLog.i(_tag, 'Backing ticket $ticketId marked as failed');
    } on Object catch (e, st) {
      AppLog.e(_tag, 'Failed to fail backing ticket $ticketId', e, st);
    }
  }

  Future<void> _maybeScheduleRecovery(AgentRunLog run) async {
    if (run.retry.attempt >= _maxRetries) {
      AppLog.i(
        _tag,
        'Run ${run.id} exhausted retries ($_maxRetries) — skipping recovery',
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
          AppLog.w(
            _tag,
            'Run ${run.id} recovery blocked by budget: ${block.reason}',
          );
          return;
        }
      } on Object catch (e, st) {
        AppLog.e(_tag, 'Budget check failed for run ${run.id}', e, st);
        return;
      }
    }

    AppLog.i(
      _tag,
      'Run ${run.id} eligible for recovery '
      '(attempt ${run.retry.attempt + 1} of $_maxRetries)',
    );
  }
}
