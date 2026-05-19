/// Read-cursor port for messaging channels.
///
/// Kept separate from MessagingRepository so the sidebar's unread indicator
/// (the only consumer of read state) has a focused dependency, and so the many
/// test fakes of MessagingRepository don't have to stub read-cursor methods
/// they never exercise.
abstract class ChannelReadRepository {
  /// Marks the user participant's read cursor for [channelId] as now, clearing
  /// any sidebar unread indicator for the channel.
  Future<void> markChannelRead(String channelId);

  /// Watches the user participant's read cursor for [channelId] (null when the
  /// channel has never been opened under the user).
  Stream<DateTime?> watchUserLastReadAt(String channelId);
}
