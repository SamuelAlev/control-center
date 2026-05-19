import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
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
/// Carries no `workspace_id`: every op is workspace-scoped, so the host injects
/// the authoritative bound workspace per session and a client can never reach
/// another workspace's channels (the workspace-isolation invariant).
class RemoteMessagingDispatch {
  /// Creates a [RemoteMessagingDispatch] over [_client].
  RemoteMessagingDispatch(this._client);

  final RemoteRpcClient _client;

  /// Sends a user message into [channelId].
  Future<void> sendUserMessage(
    String channelId,
    String content, {
    String? parentMessageId,
    Map<String, dynamic>? metadata,
  }) => _client.call('dispatch.sendUserMessage', {
    'channel_id': channelId,
    'content': content,
    'parent_message_id': ?parentMessageId,
    'metadata': ?metadata,
  });

  /// Adds [agentId] as a participant of [channelId].
  Future<void> addAgentToChannel(String channelId, String agentId) =>
      _client.call('dispatch.addAgentToChannel', {
        'channel_id': channelId,
        'agent_id': agentId,
      });

  /// Removes [agentId] from [channelId]. Channel lifecycle is DB-backed and
  /// served on every host (including a headless server), so it uses the
  /// always-available `messaging.*` op rather than the dispatch-gated one.
  Future<void> removeParticipant(String channelId, String agentId) =>
      _client.call('messaging.removeParticipant', {
        'channel_id': channelId,
        'agent_id': agentId,
      });

  /// Opens (or reuses) a DM channel with [agentId] in the bound workspace.
  Future<ChannelDto> openDm(String agentId) async {
    final data = await _client.call('messaging.openDm', {'agent_id': agentId});
    return ChannelDto.fromJson(
      (data['channel'] as Map).cast<String, dynamic>(),
    );
  }

  /// Deletes [channelId] and its messages/participants.
  Future<void> deleteChannel(String channelId) =>
      _client.call('messaging.deleteChannel', {'channel_id': channelId});

  /// Clears all messages from [channelId] without deleting the channel.
  Future<void> clearChannelMessages(String channelId) => _client.call(
    'messaging.clearChannelMessages',
    {'channel_id': channelId},
  );

  /// Creates a group channel named [name] with [agentIds] in the bound
  /// workspace.
  Future<ChannelDto> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? pipelineRunId,
  }) async {
    final data = await _client.call('messaging.createGroup', {
      'name': name,
      'agent_ids': agentIds,
      'mode': mode.toDbValue(),
      'pipeline_run_id': ?pipelineRunId,
    });
    return ChannelDto.fromJson(
      (data['channel'] as Map).cast<String, dynamic>(),
    );
  }

  /// Sends a user message and auto-dispatches the channel's agents.
  Future<void> sendAndDispatch(
    String channelId,
    String content, {
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    String? parentMessageId,
  }) => _client.call('dispatch.sendAndDispatch', {
    'channel_id': channelId,
    'content': content,
    'structured_mentions': ?structuredMentions
        ?.map((m) => {'agent_id': m.agentId, 'raw': m.raw})
        .toList(),
    'entity_refs': ?entityRefs?.map((e) => e.toJson()).toList(),
    'parent_message_id': ?parentMessageId,
  });

  /// Dispatches [agentId] to respond in [channelId]; returns the run-log id (or
  /// null when the agent could not be resolved server-side).
  Future<String?> dispatchAgent({
    required String channelId,
    required String agentId,
    required String prompt,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    WakeContext? wakeContext,
    String? parentMessageId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
  }) async {
    final data = await _client.call('dispatch.dispatchAgent', {
      'channel_id': channelId,
      'agent_id': agentId,
      'prompt': prompt,
      'ticket_id': ?ticketId,
      'pipeline_run_id': ?pipelineRunId,
      'pipeline_step_id': ?pipelineStepId,
      'in_reply_to_agent_id': ?inReplyToAgentId,
      'wake_context': ?_wakeContextToWire(wakeContext),
      'parent_message_id': ?parentMessageId,
      'expected_output_schema': ?expectedOutputSchema,
      'output_contract_mode': outputContractMode.toStorageString(),
    });
    return data['run_id'] as String?;
  }

  /// Re-dispatches a pending plan in [channelId] with [feedback].
  Future<void> refinePlan({
    required String channelId,
    required String feedback,
  }) => _client.call('dispatch.refinePlan', {
    'channel_id': channelId,
    'feedback': feedback,
  });

  /// Re-dispatches the agent of the failed turn [failedMessageId] in
  /// [channelId].
  Future<void> retryAgentTurn({
    required String channelId,
    required String failedMessageId,
  }) => _client.call('dispatch.retryAgentTurn', {
    'channel_id': channelId,
    'failed_message_id': failedMessageId,
  });

  /// Stops the in-flight agent run [runLogId] (== the agent turn's message id)
  /// server-side.
  Future<void> stopRun(String runLogId) =>
      _client.call('dispatch.stopRun', {'run_id': runLogId});

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
