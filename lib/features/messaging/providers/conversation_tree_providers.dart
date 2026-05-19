import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies one conversation's tree.
typedef ConversationTreeKey = ({String workspaceId, String conversationId});

/// The conversation's branch tree.
///
/// A plain future rather than a watch: the tree only changes when a message
/// lands or a branch pointer moves, and both of those already invalidate the
/// message stream the navigator is opened from. Streaming it would mean a
/// second subscription re-reading every message row on every keystroke of a
/// reply.
final conversationTreeProvider = FutureProvider.autoDispose
    .family<ConversationTree, ConversationTreeKey>((ref, key) {
      final repo = ref.watch(messagingRepositoryProvider);
      return repo.conversationTree(
        workspaceId: key.workspaceId,
        conversationId: key.conversationId,
      );
    });

/// Branch and fork operations on a conversation.
class ConversationBranchController {
  /// Creates a [ConversationBranchController].
  const ConversationBranchController(this._ref);

  final Ref _ref;

  MessagingRepository get _repo => _ref.read(messagingRepositoryProvider);

  /// Points the conversation at [messageId] so the next message continues
  /// from there.
  Future<void> continueFrom({
    required String conversationId,
    required String messageId,
  }) async {
    final workspaceId = _ref.requireWorkspaceId();
    await _repo.branchConversationAt(
      workspaceId: workspaceId,
      conversationId: conversationId,
      messageId: messageId,
    );
    _ref.invalidate(
      conversationTreeProvider((
        workspaceId: workspaceId,
        conversationId: conversationId,
      )),
    );
  }

  /// Copies the branch ending at [messageId] into a new conversation.
  Future<String> fork({
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async {
    final workspaceId = _ref.requireWorkspaceId();
    return _repo.forkConversation(
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      messageId: messageId,
      title: title,
    );
  }
}

/// The branch controller.
final conversationBranchControllerProvider = Provider.autoDispose(
  ConversationBranchController.new,
);
