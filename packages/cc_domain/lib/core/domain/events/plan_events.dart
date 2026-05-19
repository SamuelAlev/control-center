import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// Base for plan-document lifecycle events. All carry the plan id, its
/// conversation and the workspace so listeners can re-scope safely.
abstract class PlanDocumentEvent implements DomainEvent {
  /// Creates a [PlanDocumentEvent].
  const PlanDocumentEvent({
    required this.planId,
    required this.workspaceId,
    required this.conversationId,
    required this.occurredAt,
  });

  /// The plan document this event concerns.
  final String planId;

  /// Workspace scope.
  final String workspaceId;

  /// The conversation the plan was authored in.
  final String conversationId;

  @override
  final DateTime occurredAt;
}

/// Fired when an agent submits (or resubmits) a plan via `submit_plan`.
///
/// The load-bearing half of making a plan visible is the typed channel message
/// the tool posts alongside this; the event is the decoupled lane for
/// notifications, the newsfeed and anything that wants to react without
/// polling. Before both existed, a submitted plan was reachable only by
/// navigating to Plan Studio and noticing a new card.
class PlanDocumentSubmitted extends PlanDocumentEvent {
  /// Creates a [PlanDocumentSubmitted] event.
  const PlanDocumentSubmitted({
    required super.planId,
    required super.workspaceId,
    required super.conversationId,
    required super.occurredAt,
    required this.revision,
    required this.agentId,
    required this.nodeCount,
  });

  /// 1-based revision of the submitted plan (a resubmit supersedes and bumps).
  final int revision;

  /// The agent that authored it.
  final String agentId;

  /// How many nodes the plan graph carries.
  final int nodeCount;
}

/// Fired when an operator approves a plan document, after the compiled
/// orchestration has been materialized.
class PlanDocumentApproved extends PlanDocumentEvent {
  /// Creates a [PlanDocumentApproved] event.
  const PlanDocumentApproved({
    required super.planId,
    required super.workspaceId,
    required super.conversationId,
    required super.occurredAt,
    required this.orchestrationId,
    required this.approvedNodeKeys,
  });

  /// The orchestration compiled from the plan.
  final String orchestrationId;

  /// The node keys approved to run (empty = the whole graph).
  final List<String> approvedNodeKeys;
}
