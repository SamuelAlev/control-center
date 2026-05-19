/// One user's read/cleared state over a workspace's notification feed.
///
/// The feed itself is shared per workspace (see `NotificationFeedItem`); what
/// is *per user* is this watermark pair. An item is unread for a user when
/// `createdAt > lastSeenAt`, and hidden entirely when
/// `createdAt <= clearedBefore`. Both stamps are server clocks — "last writer"
/// is server receipt order, never a client clock.
class NotificationReadMark {
  /// Creates a [NotificationReadMark].
  NotificationReadMark({
    required this.workspaceId,
    required this.userId,
    this.lastSeenAt,
    this.clearedBefore,
  }) : assert(workspaceId != '', 'workspaceId must not be empty'),
       assert(userId != '', 'userId must not be empty');

  /// Owning workspace (the isolation boundary).
  final String workspaceId;

  /// The user this mark belongs to.
  final String userId;

  /// Everything created at or before this stamp has been seen (bell opened).
  /// Null means the user has never opened the bell in this workspace.
  final DateTime? lastSeenAt;

  /// Everything created at or before this stamp is hidden from the user's
  /// list ("clear all"). Null means nothing was cleared.
  final DateTime? clearedBefore;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationReadMark &&
          workspaceId == other.workspaceId &&
          userId == other.userId &&
          lastSeenAt == other.lastSeenAt &&
          clearedBefore == other.clearedBefore;

  @override
  int get hashCode =>
      Object.hash(workspaceId, userId, lastSeenAt, clearedBefore);
}
