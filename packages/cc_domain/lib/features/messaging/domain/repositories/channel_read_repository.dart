/// Read-cursor port for messaging channels.
///
/// Kept separate from MessagingRepository so the sidebar's unread indicator
/// (the only consumer of read state) has a focused dependency and so the many
/// test fakes of MessagingRepository don't have to stub read-cursor methods
/// they never exercise.
///
/// Cursors are per-user: each human member of a channel keeps their own
/// read state, so one member opening a channel never clears another's unread
/// indicator.
abstract class ChannelReadRepository {
  /// Marks [userId]'s read cursor for [channelId] within [workspaceId] as now,
  /// clearing that user's sidebar unread indicator for the channel.
  ///
  /// [workspaceId] is required and names the workspace the caller validated
  /// [channelId] against; the channel id resolves only inside it, so a cursor
  /// in another workspace can never be stamped.
  Future<void> markChannelRead(
    String workspaceId,
    String channelId,
    String userId,
  );

  /// Watches [userId]'s read cursor for [channelId] within [workspaceId] (null
  /// when the channel has never been opened by that user).
  ///
  /// [workspaceId] is required and names the workspace the caller validated
  /// [channelId] against. Carrying it explicitly (rather than relying on an
  /// ambient "active workspace") keeps the subscription self-consistent across
  /// a workspace switch: the transport can never pair this channel with a
  /// different, newly-active workspace and trip the server's ownership check.
  Stream<DateTime?> watchUserLastReadAt(
    String workspaceId,
    String channelId,
    String userId,
  );
}
