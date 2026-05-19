import 'dart:async';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/governance/domain/services/budget_governance_service.dart';

/// Evaluates an agent's budget the moment one of its runs completes.
///
/// On [AgentRunCompleted] it asks the [BudgetGovernanceService] to evaluate the
/// agent: a spend that crosses the soft threshold records a warning incident,
/// and a spend that exhausts the budget records a hard incident AND auto-pauses
/// the agent (its lifecycle flips to `paused`, so it stops being dispatchable).
/// The completed run's cost is already persisted by the time the event fires,
/// so the evaluation sees the up-to-date monthly spend.
class BudgetEvaluationListener {
  /// Creates a [BudgetEvaluationListener].
  BudgetEvaluationListener({required this.eventBus, required this.governance});

  /// Bus carrying [AgentRunCompleted].
  final DomainEventBus eventBus;

  /// Performs the spend evaluation + hard-stop / warning bookkeeping.
  final BudgetGovernanceService governance;

  StreamSubscription<DomainEvent>? _sub;

  /// Starts listening.
  void start() {
    _sub = eventBus.on<DomainEvent>().listen(_onEvent);
  }

  Future<void> _onEvent(DomainEvent event) async {
    if (event is! AgentRunCompleted) {
      return;
    }
    final workspaceId = event.workspaceId;
    if (workspaceId == null) {
      return;
    }
    try {
      await governance.evaluateAgent(
        workspaceId: workspaceId,
        agentId: event.agentId,
      );
    } on Object catch (e, st) {
      CcDomainLog.error(
        'BudgetEvaluationListener: budget evaluation failed',
        e,
        st,
      );
    }
  }

  /// Stops listening.
  void dispose() {
    _sub?.cancel();
  }
}
