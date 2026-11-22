import 'package:cc_host/cc_host.dart' show RepoOpContext;
import 'package:cc_infra/cc_infra.dart'
    show PersonGoalCommand, isPersonCommand;

/// `dispatch.dispatchAgent` for a person's own `/goal …`, `/loop …` or
/// `/schedule …` to one agent: starts the durable goal (or creates the wake
/// rule) and returns the op's result, or returns null when the call is an
/// ordinary dispatch.
///
/// A call that carries a ticket, a pipeline step, a peer reply or a wake is
/// work the server routes, not a person's message, and its `/goal` is
/// ordinary text; so is any `/goal` when no [command] is wired.
///
/// The goal runs in the conversation the call named, which must belong to
/// [spaceId] (the space the caller was authorized for): [resolveConversation]
/// refuses one of another space, and picks the space's standing conversation
/// when none was named. A refusal of the goal itself
/// (`goal_already_active`) reaches the caller with its `data.kind`.
Future<Map<String, dynamic>?> startPersonGoalIfAsked(
  RepoOpContext ctx, {
  required PersonGoalCommand? command,
  required String spaceId,
  required Future<String> Function(Object? supplied) resolveConversation,
}) async {
  final prompt = ctx.args['prompt'] as String;
  if (command == null ||
      ctx.userId.isEmpty ||
      !isPersonCommand(prompt) ||
      ctx.args['ticket_id'] != null ||
      ctx.args['pipeline_run_id'] != null ||
      ctx.args['pipeline_step_id'] != null ||
      ctx.args['in_reply_to_agent_id'] != null ||
      ctx.args['wake_context'] != null) {
    return null;
  }
  final conversationId = await resolveConversation(ctx.args['conversation_id']);
  final runId = await command(
    workspaceId: ctx.workspaceId!,
    spaceId: spaceId,
    agentId: ctx.args['agent_id'] as String,
    prompt: prompt,
    requestedByUserId: ctx.userId,
    conversationId: conversationId,
  );
  return {'run_id': runId};
}
