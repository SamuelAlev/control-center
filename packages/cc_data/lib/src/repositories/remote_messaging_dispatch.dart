import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Drives the host's space-lifecycle + agent-dispatch service over the RPC
/// client — the thin-client write path for the messaging composer.
///
/// Two op families back this wrapper. Space LIFECYCLE (open DM, create group,
/// delete/clear space, remove participant) is pure persistence, so it forwards
/// to the always-available `messaging.*` ops and works on EVERY host — including
/// a pure-Dart headless server. Agent DISPATCH (send-and-dispatch, retry, refine,
/// …) actually executes an agent run, so it forwards to `dispatch.*` ops that
/// only a host linking the dispatch engine registers (the desktop in-process
/// host); against a headless server those calls fail loudly. The agent run
/// executes SERVER-SIDE; the reply streams back via the existing
/// `messaging.watch*` subscriptions (the server-side `AgentStreamProcessor`
/// persists segments to the message rows), so this wrapper has no streaming
/// surface of its own.
///
/// Every space-addressed op names its `workspace_id`: a workspace id selects
/// the database file server-side and a space id resolves only inside its own
/// workspace. [stopRun] also names it, because it finalizes a persisted run log.
/// The purely in-memory controls ([pauseRun], [resumeRun], [steerRun]) act on a
/// run the server already holds registered, so they carry only the run id.
class RemoteMessagingDispatch {
  /// Creates a [RemoteMessagingDispatch] over [_client].
  RemoteMessagingDispatch(this._client);

  final RemoteRpcClient _client;

  /// Sends a user message into [spaceId] in [workspaceId] (optionally a
  /// [conversationId] stream inside it; defaults to `main`).
  Future<void> sendUserMessage(
    String workspaceId,
    String spaceId,
    String content, {
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) => _client.call('dispatch.sendUserMessage', {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'content': content,
    'conversation_id': ?conversationId,
    'metadata': ?metadata,
  });

  /// Adds [agentId] as a participant of [spaceId] in [workspaceId].
  Future<void> addAgentToSpace(
    String workspaceId,
    String spaceId,
    String agentId, {
    bool renameForGroup = true,
  }) => _client.call('dispatch.addAgentToSpace', {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'agent_id': agentId,
    'rename_for_group': renameForGroup,
  });

  /// Removes [agentId] from [spaceId] in [workspaceId]. Space lifecycle is
  /// DB-backed and served on every host (including a headless server), so it
  /// uses the always-available `messaging.*` op rather than the dispatch-gated
  /// one.
  Future<void> removeParticipant(
    String workspaceId,
    String spaceId,
    String agentId,
  ) => _client.call('messaging.removeParticipant', {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'agent_id': agentId,
  });

  /// Deletes [spaceId] in [workspaceId] and its messages/participants.
  Future<void> deleteSpace(String workspaceId, String spaceId) => _client.call(
    'messaging.deleteSpace',
    {'workspace_id': workspaceId, 'space_id': spaceId},
  );

  /// Archives [spaceId] in [workspaceId] (a reversible soft hide).
  Future<void> archiveSpace(String workspaceId, String spaceId) => _client.call(
    'messaging.archiveSpace',
    {'workspace_id': workspaceId, 'space_id': spaceId},
  );

  /// Restores an archived [spaceId] in [workspaceId].
  Future<void> unarchiveSpace(String workspaceId, String spaceId) =>
      _client.call('messaging.unarchiveSpace', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
      });

  /// Renames [spaceId] in [workspaceId] to [name].
  Future<void> updateSpaceName(
    String workspaceId,
    String spaceId,
    String name,
  ) => _client.call('messaging.updateSpaceName', {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'name': name,
  });

  /// The effective repo selection of [spaceId] in [workspaceId]: null → all
  /// workspace repos, an EMPTY list → explicitly none.
  Future<List<String>?> getSpaceRepos(String workspaceId, String spaceId) async {
    final data = await _client.call('messaging.getSpaceRepos', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
    });
    return (data['repo_ids'] as List?)?.cast<String>();
  }

  /// Replaces the repo selection of [spaceId] in [workspaceId] (same contract
  /// as [getSpaceRepos]). Deselected repos lose their worktree folder.
  Future<void> setSpaceRepos(
    String workspaceId,
    String spaceId,
    List<String>? repoIds,
  ) => _client.call('messaging.setSpaceRepos', {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'repo_ids': ?repoIds,
  });

  /// Clears all messages from [spaceId] in [workspaceId] without deleting the
  /// space.
  Future<void> clearSpaceMessages(String workspaceId, String spaceId) =>
      _client.call('messaging.clearSpaceMessages', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
      });

  /// Creates a space named [name] with [agentIds] in [workspaceId].
  ///
  /// [repoIds] null → the arg is omitted (all workspace repos); an EMPTY list
  /// is sent as-is and means "check out no repos" — the distinction must
  /// survive the wire.
  Future<SpaceDto> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
  }) async {
    final data = await _client.call('messaging.createSpace', {
      'workspace_id': workspaceId,
      'name': name,
      'agent_ids': agentIds,
      'mode': mode.toDbValue(),
      'pipeline_run_id': ?pipelineRunId,
      'repo_ids': ?repoIds,
      'repo_branches': ?repoBranches,
    });
    return SpaceDto.fromJson((data['space'] as Map).cast<String, dynamic>());
  }

  /// Sends a user message into [workspaceId]'s [spaceId] and auto-dispatches
  /// the space's agents.
  ///
  /// [metadata] carries what the composer attached — `attachments`, each
  /// already uploaded and named by its `blob:sha256:` reference. It is the ONLY
  /// way a picture or a file reaches the far side: the server writes it onto
  /// the message row (so the transcript can show it again) and resolves it into
  /// the dispatched run's prompt (so the agent can actually open it). Omitting
  /// it here is what made a message with four screenshots arrive as four
  /// filenames, and the server sanitizes what it accepts.
  Future<void> sendAndDispatch(
    String workspaceId,
    String spaceId,
    String content, {
    String? conversationId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    Map<String, dynamic>? metadata,
  }) => _client.call('dispatch.sendAndDispatch', {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'content': content,
    'conversation_id': ?conversationId,
    'structured_mentions': ?structuredMentions
        ?.map((m) => {'agent_id': m.agentId, 'raw': m.raw})
        .toList(),
    'entity_refs': ?entityRefs?.map((e) => e.toJson()).toList(),
    'metadata': ?metadata,
  });

  /// Dispatches [agentId] to respond in [spaceId]; returns the run-log id (or
  /// null when the agent could not be resolved server-side).
  ///
  /// [requestedByUserId] is accepted for signature parity with the server-side
  /// port but is deliberately NOT sent over the wire: the server stamps the
  /// requesting identity from the session's authenticated user, so a client
  /// cannot attribute a run to someone else.
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
  }) async {
    final data = await _client.call('dispatch.dispatchAgent', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'agent_id': agentId,
      'prompt': prompt,
      'ticket_id': ?ticketId,
      'pipeline_run_id': ?pipelineRunId,
      'pipeline_step_id': ?pipelineStepId,
      'in_reply_to_agent_id': ?inReplyToAgentId,
      'wake_context': ?_wakeContextToWire(wakeContext),
      'conversation_id': ?conversationId,
      'expected_output_schema': ?expectedOutputSchema,
      'output_contract_mode': outputContractMode.toStorageString(),
    });
    return data['run_id'] as String?;
  }

  /// Re-dispatches a pending plan in [workspaceId]'s [spaceId] with
  /// [feedback].
  Future<void> refinePlan({
    required String workspaceId,
    required String spaceId,
    required String feedback,
  }) => _client.call('dispatch.refinePlan', {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'feedback': feedback,
  });

  /// Re-dispatches the agent of the failed turn [failedMessageId] in
  /// [workspaceId]'s [spaceId].
  Future<void> retryAgentTurn({
    required String workspaceId,
    required String spaceId,
    required String failedMessageId,
    String? modelOverride,
  }) => _client.call('dispatch.retryAgentTurn', {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'failed_message_id': failedMessageId,
    'model_override': ?modelOverride,
  });

  /// Stops the in-flight agent run [runLogId] (== the agent turn's message id)
  /// server-side. [workspaceId] scopes the run log this finalizes as
  /// interrupted; a run id from another workspace resolves to no row.
  Future<void> stopRun(String workspaceId, String runLogId) => _client.call(
    'dispatch.stopRun',
    {'workspace_id': workspaceId, 'run_id': runLogId},
  );

  /// Pauses the in-flight run [runLogId] at its next turn boundary server-side.
  /// Returns true when a pausable run accepted it (false for a finished run or
  /// an external-CLI transport with no safe boundary).
  Future<bool> pauseRun(String runLogId) async {
    final result = await _client.call('dispatch.pauseRun', {
      'run_id': runLogId,
    });
    return result['paused'] == true;
  }

  /// Resumes a previously paused run [runLogId] server-side. Returns true when a
  /// live paused run received it.
  Future<bool> resumeRun(String runLogId) async {
    final result = await _client.call('dispatch.resumeRun', {
      'run_id': runLogId,
    });
    return result['resumed'] == true;
  }

  /// Delivers a mid-run steering [message] to the in-flight run [runLogId]
  /// server-side. Returns true when a live run received it.
  Future<bool> steerRun(
    String runLogId,
    String message, {
    bool followUp = false,
  }) async {
    final result = await _client.call('dispatch.steer', {
      'run_id': runLogId,
      'message': message,
      'follow_up': followUp,
    });
    return result['delivered'] == true;
  }

  /// Queues a persisted steering message against the conversation's live runs
  /// server-side (the steering queue strip). Returns the created message id
  /// and whether a live run can inject mid-run, or null when no run is active.
  Future<({String messageId, bool steerable})?> enqueueSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
  }) async {
    final result = await _client.call('steering.enqueue', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'conversation_id': conversationId,
      'message': content,
    });
    final messageId = result['message_id'] as String?;
    if (messageId == null) {
      return null;
    }
    return (messageId: messageId, steerable: result['steerable'] == true);
  }

  /// Edits a still-queued steering message server-side. Returns false when
  /// the row is no longer queued steering.
  Future<bool> editSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
    required String content,
  }) async {
    final result = await _client.call('steering.update', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'conversation_id': conversationId,
      'message_id': messageId,
      'message': content,
    });
    return result['ok'] == true;
  }

  /// Deletes a still-queued steering message server-side. Returns false for
  /// anything that is not queued steering.
  Future<bool> deleteSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
  }) async {
    final result = await _client.call('steering.delete', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'conversation_id': conversationId,
      'message_id': messageId,
    });
    return result['ok'] == true;
  }

  /// Persists a manual order for the conversation's queued steering cards.
  Future<void> reorderSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required List<String> orderedIds,
  }) => _client.call('steering.reorder', {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'conversation_id': conversationId,
    'message_ids': orderedIds,
  });

  /// Jump-to-front delivery ("steer now") server-side. Returns false when no
  /// live run can take mid-run steering.
  Future<bool> deliverSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
  }) async {
    final result = await _client.call('steering.deliver', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'conversation_id': conversationId,
      'message_id': messageId,
    });
    return result['delivered'] == true;
  }

  /// Forces an anchored-compaction pass over the conversation server-side
  /// (the `/compact` command). [conversationId] selects the stream (defaults
  /// to `main`).
  Future<ConversationCompactionResult> compactConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
  }) async {
    final result = await _client.call('dispatch.compact', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'conversation_id': ?conversationId,
    });
    return ConversationCompactionResult(
      status:
          _conversationCompactionStatusByName[result['status']] ??
          ConversationCompactionStatus.unavailable,
      compactedMessageCount: (result['compacted_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Drops heavy content from the conversation without summarizing it
  /// (`/shake`). See `MessagingPort.shakeConversation`.
  Future<ConversationShakeResult> shakeConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    String target = 'tool_output',
  }) async {
    final result = await _client.call('dispatch.shake', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'conversation_id': ?conversationId,
      'target': target,
    });
    return ConversationShakeResult(
      tokensReclaimed: (result['tokens_reclaimed'] as num?)?.toInt() ?? 0,
      messagesTouched: (result['messages_touched'] as num?)?.toInt() ?? 0,
      imagesDropped: (result['images_dropped'] as num?)?.toInt() ?? 0,
      unavailable: result['unavailable'] == true,
    );
  }

  /// Asks the conversation a question without adding to it (`/handoff`,
  /// `/btw`). See `MessagingPort.askAside`.
  /// One step of the `/goal` objective interview.
  /// See `MessagingPort.guidedGoalStep`.
  Future<GuidedGoalStepResult> guidedGoalStep({
    required String workspaceId,
    required String rough,
    List<String> transcript = const [],
  }) async {
    final result = await _client.call('dispatch.guidedGoalStep', {
      'workspace_id': workspaceId,
      'rough': rough,
      'transcript': transcript,
    });
    return GuidedGoalStepResult(
      question: result['question'] as String?,
      objective: result['objective'] as String?,
      missing: [
        for (final m in (result['missing'] as List?) ?? const [])
          if (m is String) m,
      ],
      weaknesses: [
        for (final w in (result['weaknesses'] as List?) ?? const [])
          if (w is String) w,
      ],
      unavailable: result['unavailable'] == true,
    );
  }

  /// Asks the conversation a question WITHOUT adding to it (`/handoff`,
  /// `/btw`). See `MessagingPort.askAside`.
  Future<ConversationSideChannelResult> askAside({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required String kind,
    String input = '',
  }) async {
    final result = await _client.call('dispatch.aside', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'conversation_id': ?conversationId,
      'kind': kind,
      'input': input,
    });
    return ConversationSideChannelResult(
      text: result['text'] as String?,
      unavailable: result['unavailable'] == true,
      empty: result['empty'] == true,
    );
  }

  /// Encodes a [WakeContext] to its wire map. [WakeContext] carries no JSON
  /// serializer, so the shape is mapped inline here (and symmetrically decoded
  /// on the host). Returns null for a null context.
  static Map<String, dynamic>? _wakeContextToWire(WakeContext? ctx) {
    if (ctx == null) {
      return null;
    }
    return {
      'run_id': ctx.runId,
      'agent_id': ctx.agentId,
      'workspace_id': ctx.workspaceId,
      'wake_reason': ctx.wakeReason.name,
      'ticket_id': ?ctx.ticketId,
      'space_id': ?ctx.spaceId,
      'message_id': ?ctx.messageId,
      'pipeline_run_id': ?ctx.pipelineRunId,
    };
  }
}

// Enum name→value lookups, built ONCE.
//
// `EnumType.values.asNameMap()` ALLOCATES A NEW MAP on every call, and
// these run per field per row per emission — the delta path re-maps a whole
// table on every frame, so a single ticket change built four fresh maps per
// ticket in the workspace.
final Map<String, ConversationCompactionStatus>
_conversationCompactionStatusByName = ConversationCompactionStatus.values
    .asNameMap();
