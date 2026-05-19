import 'package:control_center/core/domain/events/domain_event_bus.dart';

/// Fired when an agent finishes a run (success or failure).
class AgentRunCompleted implements DomainEvent {
  /// Creates an [AgentRunCompleted] event.
  const AgentRunCompleted({
    required this.agentId,
    required this.workspaceId,
    required this.conversationId,
    required this.occurredAt,
  });

  /// Agent that finished the run.
  final String agentId;

  /// Workspace the run was executed in, if any.
  final String? workspaceId;

  /// Conversation tied to the run, if any.
  final String? conversationId;

  @override
  final DateTime occurredAt;
}
