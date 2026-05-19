/// A live rollup of one thread, rendered under the message it is anchored to.
///
/// Threads are ordinary conversations (`anchorMessageId != null`), so this
/// carries no state of its own — it is a projection the server computes once
/// per space instead of the client opening one message watch per thread, which
/// is what a Slack-style "N replies" row would otherwise cost.
class ThreadSummary {
  /// Creates a [ThreadSummary].
  const ThreadSummary({
    required this.threadId,
    required this.anchorMessageId,
    required this.title,
    required this.replyCount,
    this.lastReplyAt,
    this.participantIds = const [],
  });

  /// The thread's own conversation id — what opening the thread addresses.
  final String threadId;

  /// The message this thread hangs off, in a sibling conversation of the same
  /// space. The feed keys its indicator row on this.
  final String anchorMessageId;

  /// The thread's title, shown as the tab header and in tooltips.
  final String title;

  /// How many live (non-reverted) messages the thread holds.
  final int replyCount;

  /// When the newest reply landed; null while the thread is empty.
  final DateTime? lastReplyAt;

  /// Distinct sender principal ids, newest-first and capped server-side — the
  /// avatar stack. Never the full roster: the row shows a handful of faces,
  /// not an audit trail.
  final List<String> participantIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThreadSummary &&
          other.threadId == threadId &&
          other.anchorMessageId == anchorMessageId &&
          other.title == title &&
          other.replyCount == replyCount &&
          other.lastReplyAt == lastReplyAt &&
          _sameIds(other.participantIds, participantIds);

  @override
  int get hashCode => Object.hash(
    threadId,
    anchorMessageId,
    title,
    replyCount,
    lastReplyAt,
    Object.hashAll(participantIds),
  );

  static bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
