import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/providers/space_message_send_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Asks the pull-request workbench to focus Chat on [conversationId].
///
/// [nonce] changes on every send so focusing the same conversation twice
/// still notifies the listener.
class PrChatFocus {
  /// Creates a [PrChatFocus].
  const PrChatFocus({required this.conversationId, required this.nonce});

  /// The conversation the comment was sent into.
  final String conversationId;

  /// Monotonic token so a repeat send still focuses Chat.
  final int nonce;
}

/// The conversation a "send to agent" should open, keyed by the pull request.
final prChatFocusProvider = StateProvider.autoDispose
    .family<PrChatFocus?, PrRef>((ref, pr) => null);

/// Sends [prompt] into the pull request's chat.
///
/// An empty conversation is reused: the standing one when nobody has talked
/// there yet, otherwise any other empty conversation in the space. Only when
/// every conversation already has messages does this open a new one, so a
/// comment does not land in the middle of an unrelated thread.
///
/// Returns the conversation id the message was sent to.
Future<String> sendCommentToAgent(
  WidgetRef ref, {
  required PrRef prRef,
  required String prompt,
}) async {
  final text = prompt.trim();
  if (text.isEmpty) {
    throw StateError('Nothing to send');
  }
  final workspaceId = ref.requireWorkspaceId();
  final pull = ref.read(prDetailProvider(prRef)).value;
  if (pull == null) {
    throw StateError('Pull request is not loaded');
  }
  final spaceId = await ref.read(prSpaceProvider(pull).future);
  final conversationId = await _emptyOrNewConversation(
    ref,
    workspaceId: workspaceId,
    spaceId: spaceId,
  );
  await ref
      .read(spaceMessageSendProvider.notifier)
      .send(
        content: text,
        spaceId: spaceId,
        workspaceId: workspaceId,
        conversationId: conversationId,
        entityRefs: [
          EntityRef(
            type: EntityRefType.pullRequest,
            id: '${pull.number}',
            label: pull.title,
            repoFullName: pull.repoFullName,
          ),
        ],
      );
  final nonce = (ref.read(prChatFocusProvider(prRef))?.nonce ?? 0) + 1;
  ref.read(prChatFocusProvider(prRef).notifier).state = PrChatFocus(
    conversationId: conversationId,
    nonce: nonce,
  );
  return conversationId;
}

/// The oldest empty active conversation in the space, or a newly created one.
Future<String> _emptyOrNewConversation(
  WidgetRef ref, {
  required String workspaceId,
  required String spaceId,
}) async {
  final conversations = await ref
      .read(conversationRepositoryProvider)
      .watchForSpace(workspaceId: workspaceId, spaceId: spaceId)
      .first;
  final candidates =
      conversations.where((c) => !c.isThread && !c.isArchived).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final messaging = ref.read(messagingRepositoryProvider);
  for (final conversation in candidates) {
    if (await _isEmpty(messaging, workspaceId, spaceId, conversation)) {
      return conversation.id;
    }
  }
  final created = await ref
      .read(conversationRepositoryProvider)
      .create(workspaceId: workspaceId, spaceId: spaceId, title: '');
  return created.id;
}

Future<bool> _isEmpty(
  MessagingRepository messaging,
  String workspaceId,
  String spaceId,
  Conversation conversation,
) async {
  final window = await messaging
      .watchMessagesWindow(workspaceId, spaceId, conversation.id, limit: 1)
      .first;
  return window.messages.isEmpty;
}
