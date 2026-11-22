import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// An improvement review proposed changes a person should look at: one
/// event per review that wrote at least one proposal.
class ImprovementProposed implements DomainEvent {
  /// Creates an [ImprovementProposed] event.
  const ImprovementProposed({
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.agentId,
    required this.goalId,
    required this.proposalIds,
    required this.requestedByUserId,
    required this.occurredAt,
  });

  /// Workspace of the proposals.
  final String workspaceId;

  /// Space the reviewed work happened in.
  final String spaceId;

  /// Conversation the reviewed work happened in.
  final String conversationId;

  /// The agent whose work was reviewed.
  final String agentId;

  /// The verified goal the review followed, if any.
  final String? goalId;

  /// The proposals written, in the review's order.
  final List<String> proposalIds;

  /// Who the review is for (the goal's or the `/refine`'s person); null for
  /// a bot-started goal.
  final String? requestedByUserId;

  @override
  final DateTime occurredAt;
}

/// A pipeline run's remaining steps are held because the orchestration that
/// owns it reached its cost cap. Published once per hold.
class PipelineRunHeld implements DomainEvent {
  /// Creates a [PipelineRunHeld] event.
  const PipelineRunHeld({
    required this.workspaceId,
    required this.pipelineRunId,
    required this.orchestrationId,
    required this.spaceId,
    required this.reason,
    required this.capMicros,
    required this.spentMicros,
    required this.requestedByUserId,
    required this.occurredAt,
  });

  /// Workspace of the run.
  final String workspaceId;

  /// The held run.
  final String pipelineRunId;

  /// The orchestration whose cap holds it.
  final String orchestrationId;

  /// The orchestration's space, if it has one.
  final String? spaceId;

  /// Why (`orchestration_budget`).
  final String reason;

  /// The cap, in micro-dollars.
  final int capMicros;

  /// What the run has spent, in micro-dollars.
  final int spentMicros;

  /// The run's requester; null for a run nobody asked for.
  final String? requestedByUserId;

  @override
  final DateTime occurredAt;
}
