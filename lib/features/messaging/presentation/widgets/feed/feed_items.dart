import 'package:cc_domain/core/domain/entities/message.dart';

/// One rendered row in the feed: a message (with optional paired thinking),
/// a day separator, or the unread divider.
sealed class FeedItem {
  const FeedItem();
}

class MessageItem extends FeedItem {
  const MessageItem(this.message, {this.collapseHeader = false});
  final Message message;
  final bool collapseHeader;
}

class DayItem extends FeedItem {
  const DayItem(this.day);
  final DateTime day;
}

class UnreadItem extends FeedItem {
  const UnreadItem({this.count});
  final int? count;
}

/// Builds feed items from an ascending message list: inserts day separators on
/// local-date changes, marks consecutive same-sender messages (<5 min apart)
/// to collapse their header and inserts a single unread divider before the
/// first agent message past [readFrontier]. The user's own messages are never
/// unread to themselves.
///
/// [readFrontier] is a *witnessed* cutoff, not the raw open-time read cursor:
/// it starts at the cursor and then advances past every arrival the reader
/// demonstrably saw (see `_SpaceMessageFeedState._advanceReadFrontier`).
/// Testing against the frozen cursor instead is what drew "New · 1" above a
/// reply the reader was actively watching — every live arrival is trivially
/// after the moment they arrived. Turns that land while the pane is hidden, or
/// while the reader is reading history below the fold, never advance the
/// frontier and so still get their divider.
List<FeedItem> buildFeedItems(
  List<Message> messages, {
  required bool suppressOldestSeparator,
  DateTime? readFrontier,
}) {
  final out = <FeedItem>[];
  DateTime? lastDay;
  Message? prevSender;
  bool dividerInserted = false;
  bool isUnread(Message m) =>
      readFrontier != null &&
      m.senderType == SenderType.agent &&
      m.createdAt.isAfter(readFrontier);
  final unreadCount = messages.where(isUnread).length;

  for (final display in messages) {
    // A queued steering card renders in the strip below the trail, not here —
    // it has not reached the agent yet. The moment the server flips it to
    // `injected` (or converts it to text at run end) the row re-renders as a
    // trail message in this same feed.
    if (display.isSteeringQueued) {
      continue;
    }
    final day = DateTime(
      display.createdAt.year,
      display.createdAt.month,
      display.createdAt.day,
    );
    final isFirst = out.isEmpty;
    if (lastDay == null || day != lastDay) {
      if (!(isFirst && suppressOldestSeparator)) {
        out.add(DayItem(day));
      }
      lastDay = day;
      prevSender = null;
    }

    if (!dividerInserted && isUnread(display)) {
      out.add(UnreadItem(count: unreadCount > 0 ? unreadCount : null));
      dividerInserted = true;
    }

    final collapse =
        prevSender != null &&
        prevSender.senderId == display.senderId &&
        prevSender.senderType == display.senderType &&
        !display.isSystem &&
        !prevSender.isSystem &&
        display.createdAt.difference(prevSender.createdAt).inMinutes.abs() < 5;

    out.add(MessageItem(display, collapseHeader: collapse));
    prevSender = display;
  }
  return out;
}
