import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';

/// Builds the `dispatch.reviewFeedbackAgent` implementation: the "send these
/// PR-review findings to an agent" button, executed server-side.
///
/// It goes through [messaging] rather than the dispatch service underneath it,
/// and that is the whole point of this seam. The `agent_turn` message row, the
/// stream processor that fills it as the agent works, and the terminal run-log
/// write all live in the messaging path. Calling `AgentDispatchService.dispatch`
/// directly does start the process — and then drops the returned event stream
/// on the floor, so the fix conversation stays EMPTY while its run log sits at
/// `pending` forever (the spinner never stops, and the boot reaper only looks
/// at `running`). The working directory's path lock, released when that stream
/// ends, is likewise held by a run nobody is reading, parking every later
/// dispatch into the same worktree until a restart.
///
/// The findings brief is posted as the requesting human's message before the
/// dispatch, so the conversation shows what was asked next to what the agent
/// does about it — the same shape as typing it.
///
/// No working directory crosses this seam: the agent's own directory and the
/// space's isolated worktree are both resolved server-side, so a thin client
/// cannot aim the run at an arbitrary path.
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
