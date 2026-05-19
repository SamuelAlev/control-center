/// Read-cursor port for messaging spaces.
///
/// Kept separate from MessagingRepository so the sidebar's unread indicator
/// (the only consumer of read state) has a focused dependency and so the many
/// test fakes of MessagingRepository don't have to stub read-cursor methods
/// they never exercise.
///
/// Cursors are per-user: each human member of a space keeps their own
/// read state, so one member opening a space never clears another's unread
/// indicator.
abstract class SpaceReadRepository {
  /// Marks [userId]'s read cursor for [spaceId] within [workspaceId] as now,
  /// clearing that user's sidebar unread indicator for the space.
  ///
  /// [workspaceId] is required and names the workspace the caller validated
  /// [spaceId] against; the space id resolves only inside it, so a cursor
  /// in another workspace can never be stamped.
  Future<void> markSpaceRead(String workspaceId, String spaceId, String userId);

  /// Watches [userId]'s read cursor for [spaceId] within [workspaceId] (null
  /// when the space has never been opened by that user).
  ///
  /// [workspaceId] is required and names the workspace the caller validated
  /// [spaceId] against. Carrying it explicitly (rather than relying on an
  /// ambient "active workspace") keeps the subscription self-consistent across
  /// a workspace switch: the transport can never pair this space with a
  /// different, newly-active workspace and trip the server's ownership check.
  Stream<DateTime?> watchUserLastReadAt(
    String workspaceId,
    String spaceId,
    String userId,
  );
}
