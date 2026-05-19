import 'package:cc_domain/core/domain/entities/agent_run_log.dart'
    show AgentRunLog;
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';

/// The outcome status of a `/compact` request.
enum ConversationCompactionStatus {
  /// Older history was folded into an anchored summary.
  compacted,

  /// The conversation is still too short to fold — nothing changed.
  nothingToCompact,

  /// An agent turn is in flight in the space; compacting now would race
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

/// Port for messaging space operations.
///
/// **Workspace invariant:** every space-scoped operation takes the
/// `workspaceId` that owns the space. Space, conversation and message ids
/// are uuids, but a uuid is not an access boundary — the workspace selects the
/// database the space lives in, so an id from another workspace resolves to
/// nothing rather than being read or written. [pauseRun], [resumeRun] and
/// [steerRun] are the exceptions: they address a live in-process dispatch and
/// touch no stored state, so they need no workspace.
abstract interface class MessagingPort {
  /// Sends a user message to a space in [workspaceId]. [metadata] (e.g.
  /// `entityRefs`) is persisted onto the message; [conversationId] selects the
  /// target stream (defaults to the space's STANDING conversation — its oldest
  /// active one, minted untitled when the space has none).
  /// [senderUserId] attributes the message to the acting human; programmatic
  /// callers (pipelines) pass null and the implementation attributes to the
  /// workspace owner.
  Future<void> sendUserMessage(
    String workspaceId,
    String spaceId,
    String content, {
    String? senderUserId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  });

  /// Adds an agent to a space within [workspaceId].
  ///
  /// [renameForGroup] controls the DM→group nicety: when a two-participant
  /// conversation gains a second agent, the space is renamed after its
  /// members. Programmatic joins (a pipeline step dispatching a worker into the
  /// room a plan was authored in) pass false — renaming the operator's
  /// conversation out from under them is never what they asked for.
  Future<void> addAgentToSpace(
    String workspaceId,
    String spaceId,
    String agentId, {
    bool renameForGroup = true,
  });

  /// Removes an agent from a space within [workspaceId].
  Future<void> removeParticipant(
    String workspaceId,
    String spaceId,
    String agentId,
  );

  /// Deletes a space and its messages/participants within [workspaceId].
  Future<void> deleteSpace(String workspaceId, String spaceId);

  /// Archives a space within [workspaceId]: a reversible soft hide that keeps
  /// every message, participant and worktree. The space leaves the sidebar
  /// and the activity feed until [unarchiveSpace] restores it.
  Future<void> archiveSpace(String workspaceId, String spaceId);

  /// Restores an archived space within [workspaceId].
  Future<void> unarchiveSpace(String workspaceId, String spaceId);

  /// Renames a space within [workspaceId].
  Future<void> updateSpaceName(String workspaceId, String spaceId, String name);

  /// The space's effective repo selection: null → all workspace repos, an
  /// EMPTY list → explicitly no repos, a subset → those repos.
  Future<List<String>?> getSpaceRepos(String workspaceId, String spaceId);

  /// Replaces a space's repo selection (same contract as [getSpaceRepos]).
  /// Repos that LEAVE the selection have their worktree folder torn down —
  /// adding repos is lazy (provisioned on the next dispatch).
  Future<void> setSpaceRepos(
    String workspaceId,
    String spaceId,
    List<String>? repoIds,
  );

  /// Clears all messages from a space within [workspaceId] without deleting
  /// the space itself.
  Future<void> clearSpaceMessages(String workspaceId, String spaceId);

  /// Whether a space row still exists in [workspaceId]. Used before reusing a
  /// space id that may have been deleted (e.g. a ticket's stored `spaceId`
  /// whose space the user removed from the sidebar), so callers can create a
  /// fresh space instead of writing a participant against a missing space
  /// (FK violation).
  Future<bool> spaceExists(String workspaceId, String spaceId);

  /// Creates a space in [workspaceId] with zero or more agents. The optional
  /// [mode] is set on the space row at creation time so the dispatch pipeline
  /// picks it up on the first message dispatched into the space.
  /// [createdByUserId] records the creating human as a participant.
  /// [repoIds] optionally scopes which of the workspace's repos the space's
  /// conversation worktree provisions. Null (the default) means all repos; an
  /// EMPTY list means the space explicitly checks out no repos at all.
  /// [repoBranches] pins a selected repo's worktree to the branch it is cut
  /// from, keyed by repo id. A repo absent from the map takes its own default
  /// branch. It is the BASE, not the working branch: the worktree still gets
  /// its own branch cut from here, so nothing an agent commits lands on it.
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
  });

  /// Creates a conversation (a message stream) inside an EXISTING space and
  /// returns its id.
  ///
  /// The space owns the worktree, the participants and the provisioning; its
  /// conversations are flat equals sharing all of that. This is what lets
  /// several agents work the same checkout in parallel while each keeps its own
  /// readable thread — a fan-out that creates a space per worker instead pays
  /// for one clone of every repo per worker and hides each thread in a room
  /// nobody is in.
  ///
  /// [createdByPrincipalId] records WHOSE stream this is. For a fan-out that
  /// opens one conversation per agent, that is the agent — which is what makes
  /// a later human reply in it wake THAT agent rather than whichever one the
  /// space's roster happens to list first.
  ///
  /// [reuseExisting] returns the space's existing ACTIVE conversation with the
  /// same [title] instead of opening a second one. It is off by default —
  /// a human who names two conversations the same way meant two — and on for
  /// machine callers whose work can be re-run: a pipeline step re-fired by a
  /// retry or a crash-resume otherwise leaves the room holding two "QA review"
  /// threads with no way to tell which one is live.
  ///
  /// Returns null when the space does not exist in [workspaceId] (so a caller
  /// can fall back to the space's standing conversation rather than writing a
  /// row against a missing space).
  Future<String?> createConversation({
    required String workspaceId,
    required String spaceId,
    required String title,
    String? createdByPrincipalId,
    bool reuseExisting = false,
  });

  /// Stops the in-flight provisioning of a space's workspace: the running
  /// clone/fetch is killed and no further repo is checked out.
  ///
  /// Called when the work the space was created FOR goes away — a pipeline run
  /// the operator stopped, or the operator pressing stop in the space itself.
  /// Without it, "stop" only stopped the waiting: the clone ran to completion
  /// and the agent was dispatched into a run that had already been cancelled.
  ///
  /// Idempotent, and a no-op on a host with no provisioner wired (a thin
  /// client, a bare test host) — provisioning is server-side work.
  Future<void> cancelSpaceProvisioning(String workspaceId, String spaceId);

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
    String spaceId,
    String content, {
    String? senderUserId,
    String? conversationId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    Map<String, dynamic>? metadata,
  });

  /// Dispatches an agent to respond in a space.
  ///
  /// The implementation resolves `agentName`, `workingDirectory` and
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
    required String spaceId,
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
    required String spaceId,
    required String feedback,
  });

  /// Re-dispatches the agent of a failed turn. [failedMessageId] is the
  /// errored agent message (carries `runId`); the implementation re-dispatches
  /// the same agent in the same space and stamps the failed message so the
  /// retry affordance hides.
  ///
  /// [workspaceId] must be the space's own workspace: the retry carries the
  /// same context as the turn it replaces and a retried run whose run log
  /// carried a different (or no) workspace would be invisible to every
  /// workspace-scoped surface — the composer's stop affordance, the run tree,
  /// presence — and rejected by the ownership check on
  /// `stopRun`/`pauseRun`/`steer`, i.e. an unstoppable run.
  /// [modelOverride] re-runs the turn on a DIFFERENT model.
  ///
  /// The case it exists for: a turn that failed because the model produced
  /// something the loop could not use (truncated output, a malformed tool
  /// call, a refusal) will usually fail the same way again on a retry. Handing
  /// the same prompt to a different model is the move that actually changes
  /// the outcome, and without this the only way to make it is to reconfigure
  /// the agent and retype the request.
  Future<void> retryAgentTurn({
    required String workspaceId,
    required String spaceId,
    required String failedMessageId,
    String? modelOverride,
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

  /// Queues a persisted steering message against the runs live in
  /// [conversationId] (the steering queue strip). The row is durable and
  /// workspace-scoped; live built-in-harness runs inject it at their next
  /// turn boundary, and anything still queued when the last run ends is
  /// converted to a normal user message. Returns the created message id and
  /// whether a live run can inject mid-run (`steerable` — false for
  /// external-CLI transports, so the client hides the "steer now" button),
  /// or null when no run is active (the caller falls through to a normal
  /// send).
  Future<({String messageId, bool steerable})?> enqueueSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
  });

  /// Edits the body of a still-queued steering message. Returns false when
  /// the row is not a queued steering message in [conversationId] — an
  /// injected or converted one is already part of the conversation and must
  /// not be rewritten.
  Future<bool> editSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
    required String content,
  });

  /// Deletes a still-queued steering message from the queue. Returns false
  /// for anything that is not queued steering.
  Future<bool> deleteSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
  });

  /// Persists a manual order for the conversation's queued steering messages
  /// ([orderedIds], ascending delivery priority). Ids not named keep their
  /// relative order behind the named ones.
  Future<void> reorderSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required List<String> orderedIds,
  });

  /// Jump-to-front delivery ("steer" button): makes [messageId] the next
  /// queued steering message a live run injects. Returns false when no live
  /// run can take mid-run steering (external-CLI transport, or no run at all).
  Future<bool> deliverSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
  });

  /// Forces an anchored-compaction pass over the conversation (the `/compact`
  /// command): older history is folded into a summary message so the
  /// conversation can continue within the model's context window. Unlike the
  /// automatic pass this skips the context-pressure gate, but it still refuses
  /// while an agent turn is streaming in the space (the prune pass would
  /// race the live transcript writes) and when there is nothing old enough to
  /// fold. [conversationId] selects the stream (defaults to `main`).
  Future<ConversationCompactionResult> compactConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
  });

  /// Drops heavy content from the conversation WITHOUT summarizing it (the
  /// `/shake` command).
  ///
  /// The move between doing nothing and compacting: compaction spends a model
  /// call and replaces the narrative with a summary, while shaking spends
  /// nothing and keeps every word — it only blanks the bulk nobody was going
  /// to re-read. [target] is `tool_output`, `images` or `all`.
  Future<ConversationShakeResult> shakeConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    String target,
  });

  /// Runs one step of the `/goal` objective interview.
  ///
  /// Persists nothing: the objective becomes real only when the human
  /// dispatches it, and an interview that wrote as it went would leave a
  /// half-specified goal behind every abandoned attempt.
  Future<GuidedGoalStepResult> guidedGoalStep({
    required String workspaceId,
    required String rough,
    List<String> transcript,
  });

  /// Asks the conversation a question WITHOUT adding to it (`/handoff`,
  /// `/btw`).
  ///
  /// [kind] is `handoff` or `aside`. [input] is the focus or the question
  /// respectively. The conversation is never mutated: the agent's next real
  /// turn sees exactly what it would have seen anyway, which is the entire
  /// value of a side question.
  Future<ConversationSideChannelResult> askAside({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required String kind,
    String input,
  });
}

/// One step of the objective interview, as the client sees it.
class GuidedGoalStepResult {
  /// Creates a [GuidedGoalStepResult].
  const GuidedGoalStepResult({
    this.question,
    this.objective,
    this.missing = const [],
    this.weaknesses = const [],
    this.unavailable = false,
  });

  /// The next question, or null when the objective is ready.
  final String? question;

  /// The finished objective, or null while the interview continues.
  final String? objective;

  /// Requirement names the draft still does not cover.
  final List<String> missing;

  /// Anti-patterns found in what it does say.
  final List<String> weaknesses;

  /// Whether no one-shot runner is configured for this workspace.
  final bool unavailable;

  /// Whether the interview is finished.
  bool get isReady => objective != null;
}

/// The answer to a side-channel request.
class ConversationSideChannelResult {
  /// Creates a [ConversationSideChannelResult].
  const ConversationSideChannelResult({
    this.text,
    this.unavailable = false,
    this.empty = false,
  });

  /// The answer, or null when there is none.
  final String? text;

  /// Whether the workspace has no one-shot runner configured.
  final bool unavailable;

  /// Whether the conversation had nothing to work from.
  final bool empty;
}

/// The outcome of a `/shake` pass, as the client sees it.
class ConversationShakeResult {
  /// Creates a [ConversationShakeResult].
  const ConversationShakeResult({
    this.tokensReclaimed = 0,
    this.messagesTouched = 0,
    this.imagesDropped = 0,
    this.unavailable = false,
  });

  /// Estimated tokens freed.
  final int tokensReclaimed;

  /// How many messages were rewritten.
  final int messagesTouched;

  /// How many images the model will no longer be charged for.
  final int imagesDropped;

  /// Whether the host has no dispatch engine to run the pass.
  final bool unavailable;

  /// Whether anything changed.
  bool get isEmpty => messagesTouched == 0 && imagesDropped == 0;
}
