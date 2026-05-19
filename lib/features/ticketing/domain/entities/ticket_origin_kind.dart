/// How a ticket was created — enables different lifecycle rules per origin.
enum TicketOriginKind {
  /// Created manually by a human user.
  manual,
  /// Created by a pipeline step.
  pipelineStep,
  /// Delegated by another agent.
  agentDelegation,
  /// Synced from a remote provider.
  externalSync,
  /// Created by the recovery system.
  recovery,
}
