import 'package:cc_domain/cc_domain.dart' show NotFoundException, RepoOpKind;
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_read_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/notifications/domain/repositories/notification_feed_repository.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, WatchQuery;
import 'package:cc_server_core/src/catalog/pr_data_gate.dart';

/// Per-person conversation read cursors:
///
/// * `conversation_read.markRead` moves the caller's cursor in one
///   conversation to its newest message and marks what the bell said about
///   that conversation read.
/// * `conversation_read.watchUserReads` streams the caller's cursors across
///   the workspace, one subscription for the whole sidebar.
///
/// The space comes from the conversation, never from the caller: the
/// conversation must be the call's workspace's, and the caller must pass
/// [prData]'s space gate for the space that owns it, the same gate the
/// conversation feed reads through. The watch returns only the caller's own
/// rows, so it needs no space gate.
({List<RepoOp> ops, List<WatchQuery> watches}) buildConversationReadOps({
  required ConversationReadRepository reads,
  required ConversationRepository conversations,
  required NotificationFeedRepository notificationFeed,
  required PrDataGate prData,
}) => (
  ops: [
    RepoOp(
      name: 'conversation_read.markRead',
      kind: RepoOpKind.mutate,
      // A per-person cursor: recording every read is noise.
      audited: false,
      requiredArgs: const ['workspace_id', 'conversation_id'],
      // Reading is not a workspace mutation; viewers and guests keep their
      // own cursors too.
      minRole: WorkspaceRole.guest,
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final conversationId = ctx.args['conversation_id'] as String;
        final conversation = await conversations.getById(
          workspaceId: workspaceId,
          conversationId: conversationId,
        );
        if (conversation == null || conversation.workspaceId != workspaceId) {
          throw const NotFoundException('Conversation not found');
        }
        await prData.requireSpace(
          workspaceId,
          ctx.userId,
          conversation.spaceId,
        );
        await reads.markConversationRead(
          workspaceId,
          conversationId,
          ctx.userId,
        );
        // Reading a conversation reads what the bell said about it. Only the
        // caller's own per-item states are written, scoped to this
        // workspace's feed and the space just verified.
        await notificationFeed.markConversationMessagesRead(
          workspaceId,
          ctx.userId,
          spaceId: conversation.spaceId,
          conversationId: conversationId,
        );
        return {'ok': true};
      },
    ),
  ],
  watches: [
    WatchQuery(
      name: 'conversation_read.watchUserReads',
      handler: (ctx) => reads
          .watchUserConversationReads(ctx.workspaceId!, ctx.userId)
          .map(
            (reads) => {
              'reads': [
                for (final entry in reads.entries)
                  {
                    'conversation_id': entry.key,
                    'last_read': entry.value.toJson(),
                  },
              ],
            },
          ),
    ),
  ],
);
