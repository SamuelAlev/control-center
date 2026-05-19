/// Reason an agent was woken / dispatched.
enum WakeReason {
  /// User sent a message or mentioned the agent.
  userMessage,

  /// Ticket was assigned to the agent.
  assignment,

  /// Recovery system re-dispatched after a failure.
  recovery,

  /// A child ticket was completed.
  childCompleted,

  /// A scheduled follow-up heartbeat.
  followUp,

  /// Pipeline step triggered the dispatch.
  pipelineStep,
}

/// Context injected into the agent at dispatch so it knows WHY it was woken.
class WakeContext {
  const WakeContext({
    this.ticketId,
    required this.runId,
    required this.agentId,
    required this.workspaceId,
    this.channelId,
    required this.wakeReason,
    this.messageId,
    this.pipelineRunId,
  });

  /// Ticket the agent was dispatched to handle, if any.
  final String? ticketId;

  /// Unique identifier for this run.
  final String runId;

  /// Agent that was woken.
  final String agentId;

  /// Workspace scope.
  final String workspaceId;

  /// Channel where the trigger originated, if any.
  final String? channelId;

  /// Why the agent was woken.
  final WakeReason wakeReason;

  /// The triggering message ID, if applicable.
  final String? messageId;

  /// Pipeline run ID, if this is a pipeline-triggered dispatch.
  final String? pipelineRunId;

  /// Builds environment variables that the agent CLI can read.
  Map<String, String> toEnvironment() {
    return {
      'CC_TASK_ID': ticketId ?? '',
      'CC_RUN_ID': runId,
      'CC_AGENT_ID': agentId,
      'CC_WORKSPACE_ID': workspaceId,
      'CC_WAKE_REASON': wakeReason.name,
      'CC_CHANNEL_ID': ?channelId,
      'CC_MESSAGE_ID': ?messageId,
      'CC_PIPELINE_RUN_ID': ?pipelineRunId,
    };
  }

  @override
  String toString() =>
      'WakeContext(runId=$runId, agentId=$agentId, reason=${wakeReason.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WakeContext &&
          ticketId == other.ticketId &&
          runId == other.runId &&
          agentId == other.agentId &&
          workspaceId == other.workspaceId &&
          channelId == other.channelId &&
          wakeReason == other.wakeReason &&
          messageId == other.messageId &&
          pipelineRunId == other.pipelineRunId;

  @override
  int get hashCode => Object.hash(
    ticketId,
    runId,
    agentId,
    workspaceId,
    channelId,
    wakeReason,
    messageId,
    pipelineRunId,
  );
}
