import 'package:cc_data/src/repositories/remote_messaging_dispatch.dart';
import 'package:cc_data/src/repositories/remote_messaging_repository.dart';
import 'package:cc_data/src/repositories/rpc_conversation_repository.dart';
import 'package:cc_data/src/repositories/rpc_messaging_repository.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [MessagingPort] backed by the RPC client — the thin-client write path for
/// the messaging composer (send-and-dispatch, retry, refine, open a DM, create
/// a group, …).
///
/// Every action runs SERVER-SIDE: this port forwards to the host's `dispatch.*`
/// ops (the space-lifecycle + agent-dispatch `MessagingService` running on a
/// host that links the dispatch engine — the desktop in-process host). The
/// streaming agent reply needs no surface here: the server-side
/// `AgentStreamProcessor` persists transcript segments to the message rows and
/// the UI is already subscribed to `messaging.watchMessages`, so the reply
/// streams in automatically. Against a HEADLESS server (which omits the
/// `dispatch.*` ops) the calls fail loudly — the web composer then surfaces an
/// honest "agent dispatch runs on the server host" state.
///
/// Every space-addressed action names its `workspace_id` on the wire: a
/// workspace id selects the database file server-side and a space id resolves
/// only inside its own workspace.
class RpcMessagingPort implements MessagingPort {
  /// Creates an [RpcMessagingPort] over [client].
  RpcMessagingPort(RemoteRpcClient client)
    : _dispatch = RemoteMessagingDispatch(client),
      _reads = RemoteMessagingRepository(client),
      _conversations = RpcConversationRepository(client);

  final RemoteMessagingDispatch _dispatch;
  final RemoteMessagingRepository _reads;
  final RpcConversationRepository _conversations;

  // The server stamps authorship from the session's authenticated user; the
  // [senderUserId] / [createdByUserId] the interface carries are never sent
  // over the wire (a client cannot attribute an action to another user).
  @override
  Future<void> sendUserMessage(
    String workspaceId,
    String spaceId,
    String content, {
    String? senderUserId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) => _dispatch.sendUserMessage(
    workspaceId,
    spaceId,
    content,
    conversationId: conversationId,
    metadata: metadata,
  );

  @override
  Future<void> addAgentToSpace(
    String workspaceId,
    String spaceId,
    String agentId, {
    bool renameForGroup = true,
  }) => _dispatch.addAgentToSpace(
    workspaceId,
    spaceId,
    agentId,
    renameForGroup: renameForGroup,
  );

  @override
  Future<void> removeParticipant(
    String workspaceId,
    String spaceId,
    String agentId,
  ) => _dispatch.removeParticipant(workspaceId, spaceId, agentId);

  @override
  Future<void> deleteSpace(String workspaceId, String spaceId) =>
      _dispatch.deleteSpace(workspaceId, spaceId);

  @override
  Future<void> archiveSpace(String workspaceId, String spaceId) =>
      _dispatch.archiveSpace(workspaceId, spaceId);

  @override
  Future<void> unarchiveSpace(String workspaceId, String spaceId) =>
      _dispatch.unarchiveSpace(workspaceId, spaceId);

  @override
  Future<void> updateSpaceName(
    String workspaceId,
    String spaceId,
    String name,
  ) => _dispatch.updateSpaceName(workspaceId, spaceId, name);

  @override
  Future<List<String>?> getSpaceRepos(String workspaceId, String spaceId) =>
      _dispatch.getSpaceRepos(workspaceId, spaceId);

  @override
  Future<void> setSpaceRepos(
    String workspaceId,
    String spaceId,
    List<String>? repoIds,
  ) => _dispatch.setSpaceRepos(workspaceId, spaceId, repoIds);

  @override
  Future<void> clearSpaceMessages(String workspaceId, String spaceId) =>
      _dispatch.clearSpaceMessages(workspaceId, spaceId);

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) =>
      // Served by the existing `messaging.spaceExists` read op.
      _reads.spaceExists(workspaceId, spaceId);

  @override
  Future<void> cancelSpaceProvisioning(String workspaceId, String spaceId) =>
      // Provisioning is the server's work, so stopping it is a server op —
      // the same one the space's stop button calls.
      _reads.cancelSpaceProvisioning(workspaceId, spaceId);

  @override
  Future<String?> createConversation({
    required String workspaceId,
    required String spaceId,
    required String title,
    String? createdByPrincipalId,
    bool reuseExisting = false,
  }) async {
    if (!await _reads.spaceExists(workspaceId, spaceId)) {
      return null;
    }
    if (reuseExisting) {
      final wanted = title.trim().toLowerCase();
      final siblings = await _conversations.listForSpace(
        workspaceId: workspaceId,
        spaceId: spaceId,
      );
      for (final c in siblings) {
        if (!c.isArchived &&
            !c.isThread &&
            c.title.trim().toLowerCase() == wanted) {
          return c.id;
        }
      }
    }
    final conversation = await _conversations.create(
      workspaceId: workspaceId,
      spaceId: spaceId,
      title: title,
      createdByPrincipalId: createdByPrincipalId,
    );
    return conversation.id;
  }

  @override
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
  }) async {
    final dto = await _dispatch.createSpace(
      workspaceId,
      name,
      agentIds,
      mode: mode,
      pipelineRunId: pipelineRunId,
      repoIds: repoIds,
      repoBranches: repoBranches,
    );
    return RpcMessagingRepository.spaceFromDto(dto);
  }

  // [metadata] is accepted for interface parity but never sent over the wire:
  // it carries server-side provenance (the chat bridge's `chat` block) and a
  // client must not be able to stamp a message as having come from elsewhere.
  @override
  Future<void> sendAndDispatch(
    String workspaceId,
    String spaceId,
    String content, {
    String? senderUserId,
    String? conversationId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    Map<String, dynamic>? metadata,
  }) => _dispatch.sendAndDispatch(
    workspaceId,
    spaceId,
    content,
    conversationId: conversationId,
    structuredMentions: structuredMentions,
    entityRefs: entityRefs,
    // What the composer attached. This used to be accepted and dropped on the
    // floor: the blobs were uploaded, the message metadata was built, and none
    // of it left the client — so the transcript showed no attachments and the
    // dispatched agent was handed a sentence naming pictures it had never been
    // given.
    metadata: metadata,
  );

  // [requestedByUserId] is accepted for interface parity but never sent over
  // the wire: the server stamps the requesting identity from the session's
  // authenticated user, so a client cannot attribute a run to someone else.
  @override
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
  }) => _dispatch.dispatchAgent(
    workspaceId: workspaceId,
    spaceId: spaceId,
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
    required String spaceId,
    required String feedback,
  }) => _dispatch.refinePlan(
    workspaceId: workspaceId,
    spaceId: spaceId,
    feedback: feedback,
  );

  @override
  Future<void> retryAgentTurn({
    required String workspaceId,
    required String spaceId,
    required String failedMessageId,
    String? modelOverride,
  }) => _dispatch.retryAgentTurn(
    workspaceId: workspaceId,
    spaceId: spaceId,
    failedMessageId: failedMessageId,
    modelOverride: modelOverride,
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
  Future<({String messageId, bool steerable})?> enqueueSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
  }) => _dispatch.enqueueSteering(
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    content: content,
  );

  @override
  Future<bool> editSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
    required String content,
  }) => _dispatch.editSteering(
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    messageId: messageId,
    content: content,
  );

  @override
  Future<bool> deleteSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
  }) => _dispatch.deleteSteering(
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    messageId: messageId,
  );

  @override
  Future<void> reorderSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required List<String> orderedIds,
  }) => _dispatch.reorderSteering(
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    orderedIds: orderedIds,
  );

  @override
  Future<bool> deliverSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
  }) => _dispatch.deliverSteering(
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    messageId: messageId,
  );

  @override
  Future<ConversationCompactionResult> compactConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
  }) => _dispatch.compactConversation(
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
  );

  @override
  Future<ConversationShakeResult> shakeConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    String target = 'tool_output',
  }) => _dispatch.shakeConversation(
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    target: target,
  );

  @override
  Future<GuidedGoalStepResult> guidedGoalStep({
    required String workspaceId,
    required String rough,
    List<String> transcript = const [],
  }) => _dispatch.guidedGoalStep(
    workspaceId: workspaceId,
    rough: rough,
    transcript: transcript,
  );

  @override
  Future<ConversationSideChannelResult> askAside({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required String kind,
    String input = '',
  }) => _dispatch.askAside(
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    kind: kind,
    input: input,
  );
}
