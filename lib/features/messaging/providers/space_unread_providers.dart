/// Read cursors and unread signals for conversations, and the space signal
/// derived from them.
library;

import 'package:cc_domain/core/domain/value_objects/feed_position.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in person's read cursors across a workspace's conversations,
/// keyed by conversation id: ONE server subscription for the whole sidebar.
/// A conversation missing from the map has never been read by them.
final userConversationReadsProvider = StreamProvider.autoDispose
    .family<Map<String, FeedPosition>, String>((ref, workspaceId) {
      return ref
          .watch(conversationReadRepositoryProvider)
          .watchUserConversationReads(
            workspaceId,
            ref.watch(currentUserIdProvider) ?? '',
          );
    });

/// The person's cursor in one conversation of the active workspace: loading
/// until the cursors arrive, then null when they have never read it.
final conversationLastReadProvider = Provider.autoDispose
    .family<AsyncValue<FeedPosition?>, ConversationRef>((ref, key) {
      final workspaceId = workspaceOwningSpace(ref, key.spaceId);
      if (workspaceId == null) {
        return const AsyncValue.data(null);
      }
      return ref.watch(
        userConversationReadsProvider(
          workspaceId,
        ).select((reads) => reads.whenData((m) => m[key.conversationId])),
      );
    });

/// Whether one conversation has an agent message the person hasn't seen.
/// Archived conversations never do: the server leaves them out of
/// `SpaceActivity.lastAgentMessageByConversation`. False while the cursors
/// are loading, so rows do not flash a dot on connect.
final conversationUnreadProvider = Provider.autoDispose
    .family<bool, ConversationRef>((ref, key) {
      final lastRead = ref.watch(conversationLastReadProvider(key));
      if (!lastRead.hasValue) {
        return false;
      }
      return spaceActivityOf(
            ref,
            key.spaceId,
          )?.conversationUnread(key.conversationId, lastRead.value) ??
          false;
    });

/// Whether a space has unread work: one of its listed (not archived)
/// conversations is unread. A space keeps no read state of its own.
final spaceUnreadProvider = Provider.autoDispose.family<bool, String>((
  ref,
  spaceId,
) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return false;
  }
  final activity = spaceActivityOf(ref, spaceId);
  if (activity == null || activity.lastAgentMessageByConversation.isEmpty) {
    return false;
  }
  return ref.watch(
    userConversationReadsProvider(workspaceId).select(
      (reads) => reads.value != null && activity.unreadFor(reads.value!),
    ),
  );
});
