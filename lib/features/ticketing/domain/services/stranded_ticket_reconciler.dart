import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/agents/domain/services/budget_policy_service.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';

/// Reconciles tickets that may have been left stranded by interrupted execution.
class StrandedTicketReconciler {
  /// Creates a reconciler with the repositories and services needed to repair stranded tickets.
  StrandedTicketReconciler({
    required TicketRepository ticketRepo,
    required AgentRepository agentRepo,
    required AgentRunLogRepository runLogRepo,
    required TicketWorkflowService ticketWorkflow,
    BudgetEnforcementService? budgetEnforcement,
  })  : _ticketRepo = ticketRepo,
        _agentRepo = agentRepo,
        _runLogRepo = runLogRepo,
        _ticketWorkflow = ticketWorkflow,
        _budgetEnforcement = budgetEnforcement;

  final TicketRepository _ticketRepo;
  final AgentRepository _agentRepo;
  final AgentRunLogRepository _runLogRepo;
  final TicketWorkflowService _ticketWorkflow;
  final BudgetEnforcementService? _budgetEnforcement;

  static const _tag = 'StrandedTicketReconciler';
  static const _maxRetries = 3;

  /// Scans active tickets and repairs ones left in an inconsistent execution state.
  Future<void> reconcile() async {
    final agents = await _agentRepo.watchAll().first;
    final allRuns = await _runLogRepo.watchAll().first;

    final seenTickets = <String>{};

    AppLog.i(
      _tag,
      'Reconciling tickets across ${agents.length} agent(s)',
    );

    for (final agent in agents) {
      try {
        final tickets = await _ticketRepo.forAgent(agent.workspaceId, agent.id);
        for (final ticket in tickets) {
          if (ticket.isTerminal || seenTickets.contains(ticket.id)) {
            continue;
          }
          seenTickets.add(ticket.id);
          await _reconcileTicket(ticket, agent, allRuns);
        }
      } on Object catch (e, st) {
        AppLog.e(_tag, 'Failed to reconcile agent ${agent.id}', e, st);
      }
    }

    AppLog.i(_tag, 'Reconciliation finished (${seenTickets.length} ticket(s) inspected)');
  }

  Future<void> _reconcileTicket(
    Ticket ticket,
    Agent? agent,
    List<AgentRunLog> allRuns,
  ) async {
    if (agent == null) {
      AppLog.w(
        _tag,
        'Ticket ${ticket.id} assigned to non-existent agent '
        '${ticket.assignedAgentId}',
      );
      await _escalateToBlocked(ticket, 'Assigned agent no longer exists');
      return;
    }

    final ticketRuns = allRuns
        .where((r) => r.ticketId == ticket.id)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    if (ticketRuns.isEmpty) {
      AppLog.i(
        _tag,
        'Ticket ${ticket.id} has no runs — eligible for re-dispatch',
      );
      await _markForRedispatch(ticket, agent);
      return;
    }

    final latestRun = ticketRuns.first;

    if (latestRun.status == RunStatus.error) {
      await _handleFailedRun(ticket, agent, latestRun);
      return;
    }

    if (ticket.status == TicketStatus.inProgress) {
      final retryCount = latestRun.retry.attempt;
      if (retryCount >= _maxRetries) {
        AppLog.w(
          _tag,
          'Ticket ${ticket.id} in-progress with exhausted retries '
          '($retryCount) — escalating to blocked',
        );
        await _escalateToBlocked(
          ticket,
          'Exhausted retries ($_maxRetries) while in-progress',
        );
        return;
      }
    }
  }

  Future<void> _handleFailedRun(
    Ticket ticket,
    Agent agent,
    AgentRunLog latestRun,
  ) async {
    if (latestRun.retry.attempt >= _maxRetries) {
      AppLog.w(
        _tag,
        'Ticket ${ticket.id} previous runs failed with exhausted retries '
        '(${latestRun.retry.attempt}) — escalating',
      );
      await _escalateToBlocked(
        ticket,
        'All $_maxRetries retry attempts exhausted',
      );
      return;
    }

    final budget = _budgetEnforcement;
    if (budget != null) {
      try {
        final block = await budget.checkInvocationBlock(
          agentId: agent.id,
          workspaceId: ticket.workspaceId,
          ticketId: ticket.id,
        );

        if (block != null) {
          AppLog.w(
            _tag,
            'Ticket ${ticket.id} re-dispatch blocked by budget: ${block.reason}',
          );
          await _escalateToBlocked(
            ticket,
            'Budget blocked: ${block.reason}',
          );
          return;
        }
      } on Object catch (e, st) {
        AppLog.e(
          _tag,
          'Budget check failed for ticket ${ticket.id}',
          e,
          st,
        );
        return;
      }
    }

    AppLog.i(
      _tag,
      'Ticket ${ticket.id} eligible for re-dispatch '
      '(retry ${latestRun.retry.attempt + 1} of $_maxRetries)',
    );
    await _markForRedispatch(ticket, agent);
  }

  Future<void> _markForRedispatch(Ticket ticket, Agent agent) async {
    final now = DateTime.now();
    final updated = ticket.copyWith(
      status: TicketStatus.open,
      updatedAt: now,
    );
    await _ticketRepo.update(updated);
    AppLog.i(
      _tag,
      'Ticket ${ticket.id} reset to open for re-dispatch (agent ${agent.id})',
    );
  }

  Future<void> _escalateToBlocked(Ticket ticket, String reason) async {
    if (!ticket.status.canTransitionTo(TicketStatus.blocked)) {
      AppLog.w(
        _tag,
        'Cannot transition ticket ${ticket.id} from ${ticket.status} to blocked',
      );
      return;
    }

    try {
      await _ticketWorkflow.transitionStatus(
        ticket.id,
        TicketStatus.blocked,
        workspaceId: ticket.workspaceId,
      );
      AppLog.i(
        _tag,
        'Ticket ${ticket.id} escalated to blocked ($reason)',
      );
    } on Object catch (e, st) {
      AppLog.e(
        _tag,
        'Failed to escalate ticket ${ticket.id} to blocked',
        e,
        st,
      );
    }
  }
}
