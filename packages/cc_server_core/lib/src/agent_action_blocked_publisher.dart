import 'dart:async';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';

/// Publishes [AgentActionBlocked] for every guard verdict that REFUSED an
/// agent action without asking anyone.
///
/// The guard audits every verdict, allows included, so this cannot be wired to
/// the audit stream wholesale: it takes the audit and answers the only question
/// that matters — was a human shown this and asked? Two shapes are silent:
///
/// - an `allow` (nothing was blocked), and
/// - a `deny` with `prompted` set, which is the answer to a prompt the operator
///   saw arrive and end. That action already announced itself through
///   `AgentAwaitingInput`; re-announcing it here would double one action in the
///   bell and, worse, tell the operator a wait they just answered is still
///   pending.
///
/// What is left is the quiet refusal — a hard rule (or a fail-closed gate with
/// no approver) that the agent hit and replanned around. One event, one bell
/// row, nobody asked.
class AgentActionBlockedPublisher {
  /// Creates a publisher onto the event bus. The agent repository names the
  /// blocked agent, which the audit itself does not carry.
  AgentActionBlockedPublisher({
    required this._eventBus,
    required this._agents,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DomainEventBus _eventBus;
  final AgentRepository _agents;
  final DateTime Function() _clock;

  /// Reports one guard audit. Publishes only when the audit records a refusal
  /// nobody was asked to approve; every other verdict returns immediately, so
  /// the guard can call this on the hot path of every gated action.
  void report(GuardAudit audit) {
    if (audit.decision != ActionDecision.deny || audit.prompted) {
      return;
    }
    unawaited(_announce(audit));
  }

  Future<void> _announce(GuardAudit audit) async {
    final name = await _nameOf(audit.workspaceId, audit.agentId);
    final spaceId = audit.spaceId;
    try {
      _eventBus.publish(
        AgentActionBlocked(
          workspaceId: audit.workspaceId,
          reason: audit.reason,
          spaceId: (spaceId == null || spaceId.isEmpty) ? null : spaceId,
          agentId: audit.agentId,
          agentName: name,
          actionSummary: audit.actionSummary,
          source: audit.source,
          occurredAt: _clock().toUtc(),
        ),
      );
    } on StateError {
      // The bus closed while the name was resolving (server shutdown).
    }
  }

  Future<String?> _nameOf(String workspaceId, String? agentId) async {
    if (agentId == null || agentId.isEmpty) {
      return null;
    }
    try {
      return (await _agents.getById(workspaceId, agentId))?.name;
    } catch (_) {
      // A name is a nicety; the notification goes out without it.
      return null;
    }
  }
}
