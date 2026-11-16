import 'package:cc_domain/cc_domain.dart' show NotFoundException;
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';

/// The conversation (stream) a caller means within [spaceId]: the one it
/// named ([supplied]), or the space's standing conversation when it named
/// none.
///
/// A named conversation must belong to [spaceId]: callers are authorized for
/// the space, and the message queries filter on the conversation alone, so a
/// conversation of another space named here would stream that space's
/// messages. One that does not is [NotFoundException].
///
/// There is no space-id aliasing to fall back on. A conversation owns its own
/// uuid, so the retired `?? spaceId` shortcut named a row that does not
/// exist: a watch keyed on it streamed nothing and a write against it violated
/// `conversation_messages.conversation_id`'s foreign key.
Future<String> resolveSpaceConversation(
  ConversationRepository? conversations, {
  required String workspaceId,
  required String spaceId,
  required Object? supplied,
}) async {
  if (supplied is String && supplied.isNotEmpty) {
    if (conversations != null) {
      final conversation = await conversations.getById(
        workspaceId: workspaceId,
        conversationId: supplied,
      );
      if (conversation == null ||
          conversation.workspaceId != workspaceId ||
          conversation.spaceId != spaceId) {
        throw const NotFoundException('Conversation not found in this space');
      }
    }
    return supplied;
  }
  if (conversations == null) {
    throw StateError(
      'No ConversationRepository is wired, so a caller that names no '
      'conversation cannot be served',
    );
  }
  final conversation = await conversations.ensure(
    workspaceId: workspaceId,
    spaceId: spaceId,
  );
  return conversation.id;
}
