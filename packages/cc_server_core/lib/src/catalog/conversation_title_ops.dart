import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_domain/features/messaging/domain/ports/conversation_title_port.dart';
import 'package:cc_host/cc_host.dart' show RepoOp;

/// `conversation.suggestTitle`: a title for the rename dialog to offer.
///
/// Empty when the host wires no [ConversationTitlePort]. Injected via
/// `extraOps` so `remote_rpc_catalog.dart` does not grow. The title is read
/// from the conversation, so [requireConversation] (its space's read gate)
/// runs first.
List<RepoOp> buildConversationTitleOps(
  ConversationTitlePort? titles, {
  required Future<void> Function(
    String workspaceId,
    String conversationId,
    String userId,
  )
  requireConversation,
}) {
  if (titles == null) {
    return const [];
  }
  return [
    RepoOp(
      name: 'conversation.suggestTitle',
      // A read: it spends a model call but writes nothing — the human
      // keeps or discards the suggestion in the rename dialog.
      kind: RepoOpKind.read,
      requiredArgs: ['conversation_id'],
      handler: (ctx) async {
        await requireConversation(
          ctx.workspaceId!,
          ctx.args['conversation_id'] as String,
          ctx.userId,
        );
        // Scoped by the bound workspace: a foreign id is not found.
        final suggestion = await titles.suggestTitle(
          workspaceId: ctx.workspaceId!,
          requestedByUserId: ctx.userId,
          conversationId: ctx.args['conversation_id'] as String,
        );
        return {
          'title': ?suggestion.title,
          'unavailable': suggestion.unavailable,
          'empty': suggestion.empty,
        };
      },
    ),
  ];
}
