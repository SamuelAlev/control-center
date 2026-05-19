import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// Fired when an agent finishes a run (success or failure).
class AgentRunCompleted implements DomainEvent {
  /// Creates an [AgentRunCompleted] event.
  const AgentRunCompleted({
    required this.agentId,
    required this.workspaceId,
    required this.conversationId,
    required this.occurredAt,
    this.runId,
  });

  /// Run-log id of the finished run, when known. Lets listeners read the run
  /// log directly (exact cost rollup, audit) instead of re-deriving it from
  /// the agent's most-recent log.
  final String? runId;

  /// Agent that finished the run.
  final String agentId;

  /// Workspace the run was executed in.
  ///
  /// `Agent.workspaceId` is non-null and no production site passes null here.
  ///
  /// `required` but still nullable, and the second half is deliberate rather
  /// than forgotten: the DISPATCH CHAIN cannot yet prove non-null.
  /// `AgentDispatchPort.start` takes `String? workspaceId` and
  /// `DispatchSession` stores it as `String?`, so tightening the event without
  /// tightening that chain would only move the `!` to the publisher. What `required` buys today is that a publisher has to SAY
  /// `null` rather than omit the argument, which is what let sites drift.
  final String? workspaceId;

  /// Conversation tied to the run, if any.
  final String? conversationId;

  @override
  final DateTime occurredAt;
}
