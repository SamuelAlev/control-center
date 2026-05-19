import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Drives the host's channel-lifecycle + agent-dispatch service over the RPC
/// client — the thin-client write path for the messaging composer.
///
/// Two op families back this wrapper. Channel LIFECYCLE (open DM, create group,
/// delete/clear channel, remove participant) is pure persistence, so it forwards
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
/// Every channel-addressed op names its `workspace_id`: a workspace id selects
/// the database file server-side, and a channel id resolves only inside its own
/// workspace. [stopRun] also names it, because it finalizes a persisted run log.
/// The purely in-memory controls ([pauseRun], [resumeRun], [steerRun]) act on a
/// run the server already holds registered, so they carry only the run id.
class RemoteMessagingDispatch {
  /// Creates a [RemoteMessagingDispatch] over [_client].
  RemoteMessagingDispatch(this._client);

  final RemoteRpcClient _client;

  /// Sends a user message into [channelId] in [workspaceId] (optionally a
  /// [conversationId] stream inside it; defaults to `main`).
  Future<void> sendUserMessage(
    String workspaceId,
    String channelId,
    String content, {
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) => _client.call('dispatch.sendUserMessage', {
    'workspace_id': workspaceId,
    'channel_id': channelId,
    'content': content,
    'conversation_id': ?conversationId,
    'metadata': ?metadata,
  });

  /// Adds [agentId] as a participant of [channelId] in [workspaceId].
  Future<void> addAgentToChannel(
    String workspaceId,
    String channelId,
    String agentId, {
    bool renameForGroup = true,
  }) => _client.call('dispatch.addAgentToChannel', {
    'workspace_id': workspaceId,
    'channel_id': channelId,
    'agent_id': agentId,
    'rename_for_group': renameForGroup,
  });

  /// Removes [agentId] from [channelId] in [workspaceId]. Channel lifecycle is
  /// DB-backed and served on every host (including a headless server), so it
  /// uses the always-available `messaging.*` op rather than the dispatch-gated
  /// one.
  Future<void> removeParticipant(
    String workspaceId,
    String channelId,
    String agentId,
  ) => _client.call('messaging.removeParticipant', {
    'workspace_id': workspaceId,
    'channel_id': channelId,
    'agent_id': agentId,
  });

  /// Deletes [channelId] in [workspaceId] and its messages/participants.
  Future<void> deleteChannel(String workspaceId, String channelId) =>
      _client.call('messaging.deleteChannel', {
        'workspace_id': workspaceId,
        'channel_id': channelId,
      });

  /// Clears all messages from [channelId] in [workspaceId] without deleting the
  /// channel.
  Future<void> clearChannelMessages(String workspaceId, String channelId) =>
      _client.call('messaging.clearChannelMessages', {
        'workspace_id': workspaceId,
        'channel_id': channelId,
      });

  /// Creates a channel named [name] with [agentIds] in [workspaceId].
  Future<ChannelDto> createChannel(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    List<String> repoIds = const [],
  }) async {
    final data = await _client.call('messaging.createChannel', {
      'workspace_id': workspaceId,
      'name': name,
      'agent_ids': agentIds,
      'mode': mode.toDbValue(),
      'pipeline_run_id': ?pipelineRunId,
      if (repoIds.isNotEmpty) 'repo_ids': repoIds,
    });
    return ChannelDto.fromJson(
      (data['channel'] as Map).cast<String, dynamic>(),
    );
  }

  /// Sends a user message into [workspaceId]'s [channelId] and auto-dispatches
  /// the channel's agents.
  Future<void> sendAndDispatch(
    String workspaceId,
    String channelId,
    String content, {
    String? conversationId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
  }) => _client.call('dispatch.sendAndDispatch', {
    'workspace_id': workspaceId,
    'channel_id': channelId,
    'content': content,
    'conversation_id': ?conversationId,
    'structured_mentions': ?structuredMentions
        ?.map((m) => {'agent_id': m.agentId, 'raw': m.raw})
        .toList(),
    'entity_refs': ?entityRefs?.map((e) => e.toJson()).toList(),
  });

  /// Dispatches [agentId] to respond in [channelId]; returns the run-log id (or
  /// null when the agent could not be resolved server-side).
  ///
  /// [requestedByUserId] is accepted for signature parity with the server-side
  /// port but is deliberately NOT sent over the wire: the server stamps the
  /// requesting identity from the session's authenticated user, so a client
  /// cannot attribute a run to someone else.
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
  }) async {
    final data = await _client.call('dispatch.dispatchAgent', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
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

  /// Re-dispatches a pending plan in [workspaceId]'s [channelId] with
  /// [feedback].
  Future<void> refinePlan({
    required String workspaceId,
    required String channelId,
    required String feedback,
  }) => _client.call('dispatch.refinePlan', {
    'workspace_id': workspaceId,
    'channel_id': channelId,
    'feedback': feedback,
  });

  /// Re-dispatches the agent of the failed turn [failedMessageId] in
  /// [workspaceId]'s [channelId].
  Future<void> retryAgentTurn({
    required String workspaceId,
    required String channelId,
    required String failedMessageId,
  }) => _client.call('dispatch.retryAgentTurn', {
    'workspace_id': workspaceId,
    'channel_id': channelId,
    'failed_message_id': failedMessageId,
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

  /// Forces an anchored-compaction pass over the conversation server-side
  /// (the `/compact` command). [conversationId] selects the stream (defaults
  /// to `main`).
  Future<ConversationCompactionResult> compactConversation({
    required String workspaceId,
    required String channelId,
    String? conversationId,
  }) async {
    final result = await _client.call('dispatch.compact', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'conversation_id': ?conversationId,
    });
    return ConversationCompactionResult(
      status:
          ConversationCompactionStatus.values.asNameMap()[result['status']] ??
          ConversationCompactionStatus.unavailable,
      compactedMessageCount: (result['compacted_count'] as num?)?.toInt() ?? 0,
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
      'channel_id': ?ctx.channelId,
      'message_id': ?ctx.messageId,
      'pipeline_run_id': ?ctx.pipelineRunId,
    };
  }
}
