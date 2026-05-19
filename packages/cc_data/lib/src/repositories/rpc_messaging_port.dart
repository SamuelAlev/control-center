import 'package:cc_data/src/repositories/remote_messaging_dispatch.dart';
import 'package:cc_data/src/repositories/remote_messaging_repository.dart';
import 'package:cc_data/src/repositories/rpc_messaging_repository.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [MessagingPort] backed by the RPC client — the thin-client write path for
/// the messaging composer (send-and-dispatch, retry, refine, open a DM, create
/// a group, …).
///
/// Every action runs SERVER-SIDE: this port forwards to the host's `dispatch.*`
/// ops (the channel-lifecycle + agent-dispatch `MessagingService` running on a
/// host that links the dispatch engine — the desktop in-process host). The
/// streaming agent reply needs no surface here: the server-side
/// `AgentStreamProcessor` persists transcript segments to the message rows, and
/// the UI is already subscribed to `messaging.watchMessages`, so the reply
/// streams in automatically. Against a HEADLESS server (which omits the
/// `dispatch.*` ops) the calls fail loudly — the web composer then surfaces an
/// honest "agent dispatch runs on the server host" state.
///
/// Carries no `workspace_id`: every `dispatch.*` op is workspace-scoped, so the
/// host injects the authoritative bound workspace per session and a client can
/// never reach another workspace's channels (the workspace-isolation invariant).
class RpcMessagingPort implements MessagingPort {
  /// Creates an [RpcMessagingPort] over [client].
  RpcMessagingPort(RemoteRpcClient client)
    : _dispatch = RemoteMessagingDispatch(client),
      _reads = RemoteMessagingRepository(client);

  final RemoteMessagingDispatch _dispatch;
  final RemoteMessagingRepository _reads;

  @override
  Future<void> sendUserMessage(
    String channelId,
    String content, {
    String? parentMessageId,
    Map<String, dynamic>? metadata,
  }) => _dispatch.sendUserMessage(
    channelId,
    content,
    parentMessageId: parentMessageId,
    metadata: metadata,
  );

  @override
  Future<void> addAgentToChannel(String channelId, String agentId) =>
      _dispatch.addAgentToChannel(channelId, agentId);

  @override
  Future<void> removeParticipant(String channelId, String agentId) =>
      _dispatch.removeParticipant(channelId, agentId);

  @override
  Future<Channel> openDm(String agentId, {String? workspaceId}) async {
    // The host binds the authoritative workspace per session, so the DM is
    // created there — the workspaceId arg is informational only.
    final dto = await _dispatch.openDm(agentId);
    return RpcMessagingRepository.channelFromDto(dto);
  }

  @override
  Future<void> deleteChannel(String channelId) =>
      _dispatch.deleteChannel(channelId);

  @override
  Future<void> clearChannelMessages(String channelId) =>
      _dispatch.clearChannelMessages(channelId);

  @override
  Future<bool> channelExists(String channelId) =>
      // Served by the existing `messaging.channelExists` read op.
      _reads.channelExists(channelId);

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
    String? pipelineRunId,
  }) async {
    final dto = await _dispatch.createGroup(
      name,
      agentIds,
      mode: mode,
      pipelineRunId: pipelineRunId,
    );
    return RpcMessagingRepository.channelFromDto(dto);
  }

  @override
  Future<void> sendAndDispatch(
    String channelId,
    String content, {
    String? workspaceId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    String? parentMessageId,
  }) => _dispatch.sendAndDispatch(
    channelId,
    content,
    structuredMentions: structuredMentions,
    entityRefs: entityRefs,
    parentMessageId: parentMessageId,
  );

  @override
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
  }) => _dispatch.dispatchAgent(
    channelId: channelId,
    agentId: agentId,
    prompt: prompt,
    ticketId: ticketId,
    pipelineRunId: pipelineRunId,
    pipelineStepId: pipelineStepId,
    inReplyToAgentId: inReplyToAgentId,
    wakeContext: wakeContext,
    parentMessageId: parentMessageId,
    expectedOutputSchema: expectedOutputSchema,
    outputContractMode: outputContractMode,
  );

  @override
  Future<void> refinePlan({
    required String channelId,
    required String feedback,
    String? workspaceId,
  }) => _dispatch.refinePlan(channelId: channelId, feedback: feedback);

  @override
  Future<void> retryAgentTurn({
    required String channelId,
    required String failedMessageId,
  }) => _dispatch.retryAgentTurn(
    channelId: channelId,
    failedMessageId: failedMessageId,
  );

  @override
  Future<void> stopRun(String runLogId) => _dispatch.stopRun(runLogId);
}
