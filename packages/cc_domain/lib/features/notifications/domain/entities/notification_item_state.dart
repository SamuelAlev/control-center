/// One user's state for ONE item in a workspace's notification feed.
///
/// The per-item counterpart to `NotificationReadMark`'s watermarks, and an
/// **override** of them rather than an addition: where a state exists it is the
/// answer, and where none exists the watermark decides. That is what makes
/// "mark this one unread" expressible at all — a watermark is a single instant,
/// so it cannot say anything about one row without saying it about every older
/// row too.
///
/// A dismissal is per user because the feed row is shared by the whole
/// workspace: deleting a notification hides it for the person who deleted it,
/// it does not erase workspace history for everyone else.
class NotificationItemState {
  /// Creates a [NotificationItemState].
  NotificationItemState({
    required this.workspaceId,
    required this.userId,
    required this.itemId,
    this.readAt,
    this.dismissedAt,
  }) {
    if (workspaceId.isEmpty) {
      throw ArgumentError('workspaceId must not be empty');
    }
    if (userId.isEmpty) {
      throw ArgumentError('userId must not be empty');
    }
    if (itemId.isEmpty) {
      throw ArgumentError('itemId must not be empty');
    }
  }

  /// Owning workspace (the isolation boundary).
  final String workspaceId;

  /// The user this state belongs to.
  final String userId;

  /// The feed item this state describes.
  final String itemId;

  /// When the user marked this item read. Null means **explicitly unread** —
  /// the row exists, so it wins over the watermark.
  final DateTime? readAt;

  /// When the user deleted this item from their own list. Null: not dismissed.
  final DateTime? dismissedAt;

  /// Whether the user has read this item.
  bool get isRead => readAt != null;

  /// Whether this item is hidden from the user's list.
  bool get isDismissed => dismissedAt != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationItemState &&
          workspaceId == other.workspaceId &&
          userId == other.userId &&
          itemId == other.itemId &&
          readAt == other.readAt &&
          dismissedAt == other.dismissedAt;

  @override
  int get hashCode =>
      Object.hash(workspaceId, userId, itemId, readAt, dismissedAt);
}
