import 'package:cc_domain/core/domain/entities/agent_run_log.dart'
    show AgentRunLog;
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';

/// The outcome status of a `/compact` request.
enum ConversationCompactionStatus {
  /// Older history was folded into an anchored summary.
  compacted,

  /// The conversation is still too short to fold — nothing changed.
  nothingToCompact,

  /// An agent turn is in flight in the channel; compacting now would race
  /// the live transcript writes. Try again once the turn finishes.
  agentBusy,

  /// The server has no compaction pass wired (e.g. a bare test host).
  unavailable,
}

/// The result of a manual conversation-compaction request (`/compact`).
class ConversationCompactionResult {
  /// Creates a [ConversationCompactionResult].
  const ConversationCompactionResult({
    required this.status,
    this.compactedMessageCount = 0,
  });

  /// What happened.
  final ConversationCompactionStatus status;

  /// Number of messages folded into the summary (0 unless [status] is
  /// [ConversationCompactionStatus.compacted]).
  final int compactedMessageCount;
}

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
///
/// **Workspace invariant:** every channel-scoped operation takes the
/// `workspaceId` that owns the channel. Channel, conversation and message ids
/// are uuids, but a uuid is not an access boundary — the workspace selects the
/// database the channel lives in, so an id from another workspace resolves to
/// nothing rather than being read or written. [pauseRun], [resumeRun] and
/// [steerRun] are the exceptions: they address a live in-process dispatch and
/// touch no stored state, so they need no workspace.
abstract interface class MessagingPort {
  /// Sends a user message to a channel in [workspaceId]. [metadata] (e.g.
  /// `entityRefs`) is persisted onto the message; [conversationId] selects the
  /// target stream (defaults to the channel's `main` conversation).
  /// [senderUserId] attributes the message to the acting human; programmatic
  /// callers (pipelines) pass null and the implementation attributes to the
  /// workspace owner.
  Future<void> sendUserMessage(
    String workspaceId,
    String channelId,
    String content, {
    String? senderUserId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  });

  /// Adds an agent to a channel within [workspaceId].
  ///
  /// [renameForGroup] controls the DM→group nicety: when a two-participant
  /// conversation gains a second agent, the channel is renamed after its
  /// members. Programmatic joins (a pipeline step dispatching a worker into the
  /// room a plan was authored in) pass false — renaming the operator's
  /// conversation out from under them is never what they asked for.
  Future<void> addAgentToChannel(
    String workspaceId,
    String channelId,
    String agentId, {
    bool renameForGroup = true,
  });

  /// Removes an agent from a channel within [workspaceId].
  Future<void> removeParticipant(
    String workspaceId,
    String channelId,
    String agentId,
  );

  /// Deletes a channel and its messages/participants within [workspaceId].
  Future<void> deleteChannel(String workspaceId, String channelId);

  /// Clears all messages from a channel within [workspaceId] without deleting
  /// the channel itself.
  Future<void> clearChannelMessages(String workspaceId, String channelId);

  /// Whether a channel row still exists in [workspaceId]. Used before reusing a
  /// channel id that may have been deleted (e.g. a ticket's stored `channelId`
  /// whose channel the user removed from the sidebar), so callers can create a
  /// fresh channel instead of writing a participant against a missing channel
  /// (FK violation).
  Future<bool> channelExists(String workspaceId, String channelId);

  /// Creates a channel in [workspaceId] with zero or more agents. The optional
  /// [mode] is set on the channel row at creation time so the dispatch pipeline
  /// picks it up on the first message dispatched into the channel.
  /// [createdByUserId] records the creating human as a participant.
  /// [repoIds] optionally scopes which of the workspace's repos the channel's
  /// conversation worktree provisions. Empty (the default) means all repos.
  Future<Channel> createChannel(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    List<String> repoIds = const [],
  });

  /// Sends a user message and automatically dispatches agents. [entityRefs]
  /// are `#`-tagged tickets/PRs/meetings persisted onto the message metadata.
  /// [senderUserId] attributes the message to the acting human.
  ///
  /// [metadata] is merged onto the stored message and carries server-side
  /// provenance for a message that arrived from somewhere other than a Control
  /// Center client — the chat bridge stamps `metadata['chat']` with the
  /// `provider` plus the conversation/thread/user the message came from, which is
  /// also how the bridge recognizes its own inbound messages and does not mirror
  /// them back out.
  Future<void> sendAndDispatch(
    String workspaceId,
    String channelId,
    String content, {
    String? senderUserId,
    String? conversationId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    Map<String, dynamic>? metadata,
  });

  /// Dispatches an agent to respond in a channel.
  ///
  /// The implementation resolves `agentName`, `workingDirectory`, and
  /// `adapterId` from the agent record so callers do not need to pass them.
  /// [expectedOutputSchema] / [outputContractMode], when set, are stamped onto
  /// the created [AgentRunLog] so the `submit_output` path can enforce the
  /// pipeline output contract.
  ///
  /// [requestedByUserId] is the human on whose behalf this run executes. It
  /// flows down to the run's environment so the agent's git commits carry an
  /// honest co-author trailer and, when that member stored their own GitHub
  /// token, the run uses it instead of the owner's. Programmatic callers
  /// (pipelines, retries, plan refinement) pass null — the run then attributes
  /// to the server owner.
  ///
  /// Returns the run-log id of the dispatched run (the `submit_output` /
  /// resume key), or null when the agent could not be resolved.
  Future<String?> dispatchAgent({
    required String workspaceId,
    required String channelId,
    required String agentId,
    required String prompt,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    String? requestedByUserId,
    WakeContext? wakeContext,
    String? conversationId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
  });

  /// Marks a pending plan as refining and re-dispatches with feedback.
  Future<void> refinePlan({
    required String workspaceId,
    required String channelId,
    required String feedback,
  });

  /// Re-dispatches the agent of a failed turn. [failedMessageId] is the
  /// errored agent message (carries `runId`); the implementation re-dispatches
  /// the same agent in the same channel and stamps the failed message so the
  /// retry affordance hides.
  ///
  /// [workspaceId] must be the channel's own workspace: the retry carries the
  /// same context as the turn it replaces, and a retried run whose run log
  /// carried a different (or no) workspace would be invisible to every
  /// workspace-scoped surface — the composer's stop affordance, the run tree,
  /// presence — and rejected by the ownership check on
  /// `stopRun`/`pauseRun`/`steer`, i.e. an unstoppable run.
  Future<void> retryAgentTurn({
    required String workspaceId,
    required String channelId,
    required String failedMessageId,
  });

  /// Stops the in-flight agent turn identified by [runLogId] (which equals the
  /// agent turn's message id) within [workspaceId]. Terminates only that run's
  /// process — other concurrent runs are unaffected — and finalizes the run as
  /// interrupted. A no-op for an already-finished run.
  ///
  /// [workspaceId] scopes the run log this finalizes; a run id from another
  /// workspace resolves to no row.
  Future<void> stopRun(String workspaceId, String runLogId);

  /// Pauses the in-flight agent turn identified by [runLogId] at its next clean
  /// turn boundary (built-in harness only). The run stays registered and simply
  /// waits; [resumeRun] releases it. Returns true when a pausable run accepted
  /// it — false for an already-finished run or an external-CLI transport with
  /// no safe boundary (the caller should fall back to [stopRun]).
  Future<bool> pauseRun(String runLogId);

  /// Releases a run previously paused by [pauseRun], continuing it from the
  /// turn boundary. Returns true when a live paused run received it.
  Future<bool> resumeRun(String runLogId);

  /// Delivers a mid-run steering [message] to the in-flight agent turn
  /// identified by [runLogId] (built-in harness only). The message is injected
  /// at the next safe turn boundary so the user can nudge a running agent
  /// without a new dispatch; [followUp] true runs it once the agent would
  /// otherwise stop. Returns true when a live run received it.
  Future<bool> steerRun(String runLogId, String message, {bool followUp});

  /// Forces an anchored-compaction pass over the conversation (the `/compact`
  /// command): older history is folded into a summary message so the
  /// conversation can continue within the model's context window. Unlike the
  /// automatic pass this skips the context-pressure gate, but it still refuses
  /// while an agent turn is streaming in the channel (the prune pass would
  /// race the live transcript writes) and when there is nothing old enough to
  /// fold. [conversationId] selects the stream (defaults to `main`).
  Future<ConversationCompactionResult> compactConversation({
    required String workspaceId,
    required String channelId,
    String? conversationId,
  });
}
