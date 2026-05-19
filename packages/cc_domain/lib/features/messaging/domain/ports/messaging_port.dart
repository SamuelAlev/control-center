import 'package:cc_domain/core/domain/entities/agent_run_log.dart' show AgentRunLog;
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
/// A parsed structured agent mention.
class StructuredMention {
  /// Creates a [StructuredMention].
  const StructuredMention({required this.agentId, required this.raw});

  /// The agent ID extracted from the mention.
  final String agentId;
  /// The raw mention text.
  final String raw;
}

/// Port for messaging channel operations.
abstract interface class MessagingPort {
  /// Sends a user message to a channel. [metadata] (e.g. `entityRefs`) is
  /// persisted onto the message; [parentMessageId] threads it under a reply.
  Future<void> sendUserMessage(
    String channelId,
    String content, {
    String? parentMessageId,
    Map<String, dynamic>? metadata,
  });

  /// Adds an agent to a channel.
  Future<void> addAgentToChannel(String channelId, String agentId);

  /// Removes an agent from a channel.
  Future<void> removeParticipant(String channelId, String agentId);

  /// Opens (or reuses) a direct-message channel with the given agent.
  Future<Channel> openDm(String agentId, {String? workspaceId});

  /// Deletes a channel and its messages/participants.
  Future<void> deleteChannel(String channelId);

  /// Clears all messages from a channel without deleting the channel itself.
  Future<void> clearChannelMessages(String channelId);

  /// Whether a channel row still exists. Used before reusing a channel id that
  /// may have been deleted (e.g. a ticket's stored `channelId` whose channel
  /// the user removed from the sidebar), so callers can create a fresh channel
  /// instead of writing a participant against a missing channel (FK violation).
  Future<bool> channelExists(String channelId);

  /// Creates a group channel. The optional [mode] is set on the channel row
  /// at creation time so the dispatch pipeline picks it up on the first
  /// message dispatched into the channel.
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
    String? pipelineRunId,
  });

  /// Sends a user message and automatically dispatches agents. [entityRefs]
  /// are `#`-tagged tickets/PRs/meetings persisted onto the message metadata.
  Future<void> sendAndDispatch(
    String channelId,
    String content, {
    String? workspaceId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    String? parentMessageId,
  });

  /// Dispatches an agent to respond in a channel.
  ///
  /// The implementation resolves `agentName`, `workingDirectory`, and
  /// `adapterId` from the agent record so callers do not need to pass them.
  /// [expectedOutputSchema] / [outputContractMode], when set, are stamped onto
  /// the created [AgentRunLog] so the `submit_output` path can enforce the
  /// pipeline output contract.
  ///
  /// Returns the run-log id of the dispatched run (the `submit_output` /
  /// resume key), or null when the agent could not be resolved.
  Future<String?> dispatchAgent({
    required String channelId,
    required String agentId,
    required String prompt,
    String? workspaceId,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    WakeContext? wakeContext,
    String? parentMessageId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
  });

  /// Marks a pending plan as refining and re-dispatches with feedback.
  Future<void> refinePlan({
    required String channelId,
    required String feedback,
    String? workspaceId,
  });

  /// Re-dispatches the agent of a failed turn. [failedMessageId] is the
  /// errored agent message (carries `runId`); the implementation re-dispatches
  /// the same agent in the same channel and stamps the failed message so the
  /// retry affordance hides.
  Future<void> retryAgentTurn({
    required String channelId,
    required String failedMessageId,
  });

  /// Stops the in-flight agent turn identified by [runLogId] (which equals the
  /// agent turn's message id). Terminates only that run's process — other
  /// concurrent runs are unaffected — and finalizes the run as interrupted. A
  /// no-op for an already-finished run.
  Future<void> stopRun(String runLogId);
}
