import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';

/// One window over a workspace's notification feed: the newest feed items,
/// most-recent-first, and whether older ones exist beyond it.
///
/// [hasMore] is about the STORED feed, not about what a viewer is shown: a
/// window can come back short because some of its rows were filtered for this
/// viewer, so "fewer items than asked for" never means "nothing older". The
/// notification center grows its window while this is true.
class NotificationFeedPage {
  /// Creates a [NotificationFeedPage].
  NotificationFeedPage({
    required List<NotificationFeedItem> items,
    required this.hasMore,
  }) : items = List.unmodifiable(items);

  /// An empty feed with nothing beyond it.
  static final NotificationFeedPage empty = NotificationFeedPage(
    items: const [],
    hasMore: false,
  );

  /// The window's items, most-recent-first.
  final List<NotificationFeedItem> items;

  /// Whether the stored feed holds items older than this window.
  final bool hasMore;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! NotificationFeedPage ||
        hasMore != other.hasMore ||
        items.length != other.items.length) {
      return false;
    }
    for (var i = 0; i < items.length; i++) {
      if (items[i] != other.items[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(hasMore, Object.hashAll(items));
}
