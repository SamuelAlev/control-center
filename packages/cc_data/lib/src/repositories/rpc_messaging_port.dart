import 'package:cc_data/src/repositories/remote_messaging_dispatch.dart';
import 'package:cc_data/src/repositories/remote_messaging_repository.dart';
import 'package:cc_data/src/repositories/rpc_messaging_repository.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
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
/// Every channel-addressed action names its `workspace_id` on the wire: a
/// workspace id selects the database file server-side, and a channel id resolves
/// only inside its own workspace.
class RpcMessagingPort implements MessagingPort {
  /// Creates an [RpcMessagingPort] over [client].
  RpcMessagingPort(RemoteRpcClient client)
    : _dispatch = RemoteMessagingDispatch(client),
      _reads = RemoteMessagingRepository(client);

  final RemoteMessagingDispatch _dispatch;
  final RemoteMessagingRepository _reads;

  // The server stamps authorship from the session's authenticated user; the
  // [senderUserId] / [createdByUserId] the interface carries are never sent
  // over the wire (a client cannot attribute an action to another user).
  @override
  Future<void> sendUserMessage(
    String workspaceId,
    String channelId,
    String content, {
    String? senderUserId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) => _dispatch.sendUserMessage(
    workspaceId,
    channelId,
    content,
    conversationId: conversationId,
    metadata: metadata,
  );

  @override
  Future<void> addAgentToChannel(
    String workspaceId,
    String channelId,
    String agentId, {
    bool renameForGroup = true,
  }) => _dispatch.addAgentToChannel(
    workspaceId,
    channelId,
    agentId,
    renameForGroup: renameForGroup,
  );

  @override
  Future<void> removeParticipant(
    String workspaceId,
    String channelId,
    String agentId,
  ) => _dispatch.removeParticipant(workspaceId, channelId, agentId);

  @override
  Future<void> deleteChannel(String workspaceId, String channelId) =>
      _dispatch.deleteChannel(workspaceId, channelId);

  @override
  Future<void> clearChannelMessages(String workspaceId, String channelId) =>
      _dispatch.clearChannelMessages(workspaceId, channelId);

  @override
  Future<bool> channelExists(String workspaceId, String channelId) =>
      // Served by the existing `messaging.channelExists` read op.
      _reads.channelExists(workspaceId, channelId);

  @override
  Future<Channel> createChannel(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    List<String> repoIds = const [],
  }) async {
    final dto = await _dispatch.createChannel(
      workspaceId,
      name,
      agentIds,
      mode: mode,
      pipelineRunId: pipelineRunId,
      repoIds: repoIds,
    );
    return RpcMessagingRepository.channelFromDto(dto);
  }

  // [metadata] is accepted for interface parity but never sent over the wire:
  // it carries server-side provenance (the chat bridge's `chat` block), and a
  // client must not be able to stamp a message as having come from elsewhere.
  @override
  Future<void> sendAndDispatch(
    String workspaceId,
    String channelId,
    String content, {
    String? senderUserId,
    String? conversationId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    Map<String, dynamic>? metadata,
  }) => _dispatch.sendAndDispatch(
    workspaceId,
    channelId,
    content,
    conversationId: conversationId,
    structuredMentions: structuredMentions,
    entityRefs: entityRefs,
  );

  // [requestedByUserId] is accepted for interface parity but never sent over
  // the wire: the server stamps the requesting identity from the session's
  // authenticated user, so a client cannot attribute a run to someone else.
  @override
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
  }) => _dispatch.dispatchAgent(
    workspaceId: workspaceId,
    channelId: channelId,
    agentId: agentId,
    prompt: prompt,
    ticketId: ticketId,
    pipelineRunId: pipelineRunId,
    pipelineStepId: pipelineStepId,
    inReplyToAgentId: inReplyToAgentId,
    wakeContext: wakeContext,
    conversationId: conversationId,
    expectedOutputSchema: expectedOutputSchema,
    outputContractMode: outputContractMode,
  );

  @override
  Future<void> refinePlan({
    required String workspaceId,
    required String channelId,
    required String feedback,
  }) => _dispatch.refinePlan(
    workspaceId: workspaceId,
    channelId: channelId,
    feedback: feedback,
  );

  @override
  Future<void> retryAgentTurn({
    required String workspaceId,
    required String channelId,
    required String failedMessageId,
  }) => _dispatch.retryAgentTurn(
    workspaceId: workspaceId,
    channelId: channelId,
    failedMessageId: failedMessageId,
  );

  @override
  Future<void> stopRun(String workspaceId, String runLogId) =>
      _dispatch.stopRun(workspaceId, runLogId);

  @override
  Future<bool> pauseRun(String runLogId) => _dispatch.pauseRun(runLogId);

  @override
  Future<bool> resumeRun(String runLogId) => _dispatch.resumeRun(runLogId);

  @override
  Future<bool> steerRun(
    String runLogId,
    String message, {
    bool followUp = false,
  }) => _dispatch.steerRun(runLogId, message, followUp: followUp);

  @override
  Future<ConversationCompactionResult> compactConversation({
    required String workspaceId,
    required String channelId,
    String? conversationId,
  }) => _dispatch.compactConversation(
    workspaceId: workspaceId,
    channelId: channelId,
    conversationId: conversationId,
  );
}
