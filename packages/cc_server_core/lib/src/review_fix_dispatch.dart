import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';

/// `dispatch.reviewFeedbackAgent`: send selected review findings to an agent as a turn.
///
/// Builds a scoped prompt from the chosen comments/threads; does not publish to the forge itself.
ReviewDispatchFn buildReviewFixDispatch({
  required MessagingPort messaging,
  required ConversationRepository conversations,
}) {
  return ({
    required String workspaceId,
    required String agentId,
    required String prompt,
    required String spaceId,
    String? conversationId,
    String? requestedByUserId,
  }) async {
    // A thread/parenthesis when the fix was branched off a finding; otherwise
    // the space's standing conversation — resolved, never aliased to the space
    // id (conversations own their own uuids).
    final convId =
        conversationId ??
        (await conversations.ensure(
          workspaceId: workspaceId,
          spaceId: spaceId,
        )).id;

    await messaging.sendUserMessage(
      workspaceId,
      spaceId,
      prompt,
      senderUserId: requestedByUserId,
      conversationId: convId,
    );

    await messaging.dispatchAgent(
      workspaceId: workspaceId,
      spaceId: spaceId,
      agentId: agentId,
      prompt: prompt,
      conversationId: convId,
      // The human who sent the findings to the fix agent: co-authors the
      // agent's commits and selects their own GitHub token when stored.
      requestedByUserId: requestedByUserId,
    );
  };
}
