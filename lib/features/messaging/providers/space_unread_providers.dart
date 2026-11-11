/// Read cursors and unread signals for spaces and conversations.
library;

import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The user participant's read cursor for a space (when they last opened
/// it), or null when the space has never been opened under the user. A server
/// subscription that emits immediately.
final spaceUserLastReadAtProvider = StreamProvider.autoDispose
    .family<DateTime?, String>((ref, spaceId) {
      // Only open the read-cursor subscription for a space that actually
      // belongs to the active workspace, and subscribe AGAINST that same
      // workspace id — never a foreign, deleted or not-yet-loaded space. See
      // [workspaceOwningSpace] for why the pair has to be established here
      // rather than assembled from the ambient workspace at call time.
      final workspaceId = workspaceOwningSpace(ref, spaceId);
      if (workspaceId == null) {
        return Stream<DateTime?>.value(null);
      }
      return ref
          .watch(spaceReadRepositoryProvider)
          .watchUserLastReadAt(
            workspaceId,
            spaceId,
            ref.watch(currentUserIdProvider) ?? '',
          );
    });

/// Whether a space has agent messages the user hasn't seen yet (the sidebar's
/// notification-dot signal). True only when the user has opened the space
/// before (a non-null read cursor exists) AND a top-level agent message landed
/// after that cursor. A never-opened space shows no dot, so a space the user
/// never visited does not light up with its whole history. Reads the server-computed activity aggregate — no
/// per-space message-list subscription.
///
/// When the space lists its conversations, the matching [conversationUnreadProvider]
/// carries the same signal onto the conversation that actually has unseen
/// work; the space row suppresses its own dot in that case so one unseen
/// reply does not light both the parent and the child.
final spaceUnreadProvider = Provider.autoDispose.family<bool, String>((
  ref,
  spaceId,
) {
  final lastReadAt = ref.watch(spaceUserLastReadAtProvider(spaceId)).value;
  if (lastReadAt == null) {
    return false;
  }
  final lastAgentAt = spaceActivityOf(ref, spaceId)?.lastAgentMessageAt;
  return lastAgentAt != null && lastAgentAt.isAfter(lastReadAt);
});

/// Whether one conversation has agent messages the user hasn't seen yet.
///
/// Same cursor as [spaceUnreadProvider] (read marks are still space-scoped —
/// opening any conversation in the space clears the room) but compared against
/// THAT conversation's last agent message, so the unread dot can sit on the
/// row that has the unseen work instead of on the parent space.
final conversationUnreadProvider = Provider.autoDispose
    .family<bool, ConversationRef>((ref, key) {
      final lastReadAt = ref
          .watch(spaceUserLastReadAtProvider(key.spaceId))
          .value;
      if (lastReadAt == null) {
        return false;
      }
      final lastAgentAt = spaceActivityOf(
        ref,
        key.spaceId,
      )?.lastAgentMessageAtByConversation[key.conversationId];
      return lastAgentAt != null && lastAgentAt.isAfter(lastReadAt);
    });

/// Number of distinct conversations with agent mail after the space's read
/// cursor. Uses the workspace activity breakdown, not message or PR counts.
/// Never-opened spaces follow the existing unread policy and stay quiet.
final spaceUnreadConversationCountProvider = Provider.autoDispose
    .family<int, String>((ref, spaceId) {
      final lastReadAt = ref.watch(spaceUserLastReadAtProvider(spaceId)).value;
      if (lastReadAt == null) {
        return 0;
      }
      final activity = spaceActivityOf(ref, spaceId);
      if (activity == null) {
        return 0;
      }
      var count = 0;
      for (final at in activity.lastAgentMessageAtByConversation.values) {
        if (at.isAfter(lastReadAt)) {
          count++;
        }
      }
      return count;
    });
