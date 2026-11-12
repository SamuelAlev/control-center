import 'package:cc_domain/core/domain/value_objects/feed_position.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';

/// One user's read/cleared state over a workspace's notification feed.
///
/// The feed itself is shared per workspace (see `NotificationFeedItem`); what
/// is *per user* is this watermark pair. Each watermark is the
/// [FeedPosition] of the newest item the user had in front of them: an item
/// is unread when its position is after [lastSeen] and hidden entirely when
/// it is not after [cleared]. Positions, not times: several items share a
/// second, and one recorded later in the second of a "clear all" must still
/// show. Both marks are taken by the server — "last writer" is server
/// receipt order, never a client clock.
class NotificationReadMark {
  /// Creates a [NotificationReadMark].
  NotificationReadMark({
    required this.workspaceId,
    required this.userId,
    this.lastSeen,
    this.cleared,
  }) {
    if (workspaceId.isEmpty) {
      throw ArgumentError('workspaceId must not be empty');
    }
    if (userId.isEmpty) {
      throw ArgumentError('userId must not be empty');
    }
  }

  /// Owning workspace (the isolation boundary).
  final String workspaceId;

  /// The user this mark belongs to.
  final String userId;

  /// Everything at or before this position has been seen (bell opened).
  /// Null means the user has never opened the bell in this workspace.
  final FeedPosition? lastSeen;

  /// Everything at or before this position is hidden from the user's list
  /// ("clear all"). Null means nothing was cleared.
  final FeedPosition? cleared;

  /// Whether [item] is at or before [lastSeen].
  bool hasSeen(NotificationFeedItem item) {
    final mark = lastSeen;
    return mark != null && !item.position.isAfter(mark);
  }

  /// Whether [item] is at or before [cleared].
  bool hides(NotificationFeedItem item) {
    final mark = cleared;
    return mark != null && !item.position.isAfter(mark);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationReadMark &&
          workspaceId == other.workspaceId &&
          userId == other.userId &&
          lastSeen == other.lastSeen &&
          cleared == other.cleared;

  @override
  int get hashCode => Object.hash(workspaceId, userId, lastSeen, cleared);
}
