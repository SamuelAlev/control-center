import 'package:cc_domain/core/domain/entities/message.dart';

/// One rendered row in the feed: a message (with optional paired thinking),
/// a day separator, or the unread divider.
sealed class FeedItem {
  const FeedItem();
}

/// A feed row that renders one [Message].
class MessageItem extends FeedItem {
  /// Creates a message row, optionally collapsing a consecutive sender header.
  const MessageItem(
    this.message, {
    this.collapseHeader = false,
    this.steeringMessages = const [],
  });

  /// The message to render.
  final Message message;

  /// Whether to hide the avatar/name because the previous row is the same sender.
  final bool collapseHeader;

  /// Injected user messages rendered inside this run, in injection order.
  final List<Message> steeringMessages;
}

/// A feed row that separates messages from different local calendar days.
class DayItem extends FeedItem {
  /// Creates a day-separator row for [day].
  const DayItem(this.day);

  /// Local calendar day this separator marks.
  final DateTime day;
}

/// A feed row marking the unread frontier.
class UnreadItem extends FeedItem {
  /// Creates the unread divider, optionally with a remaining [count].
  const UnreadItem({this.count});

  /// Unread count shown on the divider, when known.
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
  final steeringByRun = _steeringByRun(messages);
  DateTime? lastDay;
  Message? prevSender;
  bool dividerInserted = false;
  bool isUnread(Message m) =>
      readFrontier != null &&
      m.senderType == SenderType.agent &&
      m.createdAt.isAfter(readFrontier);
  final unreadCount = messages.where(isUnread).length;

  for (final display in messages) {
    // Queued cards stay in the composer. Injected cards whose run is in this
    // window belong inside its transcript, not after the whole agent turn.
    // Keep an orphaned card visible until pagination brings its run into view.
    if (display.isSteeringQueued ||
        (steeringByRun[display.steerRunId]?.contains(display) ?? false)) {
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

    out.add(
      MessageItem(
        display,
        collapseHeader: collapse,
        steeringMessages: steeringByRun[display.id] ?? const [],
      ),
    );
    prevSender = display;
  }
  return out;
}

Map<String, List<Message>> _steeringByRun(List<Message> messages) {
  if (!messages.any((m) => m.isSteeringInjected && m.steerRunId != null)) {
    return const {};
  }
  final byId = {for (final message in messages) message.id: message};
  final grouped = <String, List<Message>>{};
  for (final message in messages) {
    if (!message.isSteeringInjected) {
      continue;
    }
    final run = byId[message.steerRunId];
    if (run == null ||
        run.messageType != MessageType.agentTurn ||
        run.spaceId != message.spaceId ||
        run.conversationId != message.conversationId) {
      continue;
    }
    (grouped[run.id] ??= []).add(message);
  }
  for (final entries in grouped.values) {
    entries.sort((a, b) {
      final order = (a.steerInjectedAt ?? a.createdAt.millisecondsSinceEpoch)
          .compareTo(b.steerInjectedAt ?? b.createdAt.millisecondsSinceEpoch);
      return order != 0 ? order : a.id.compareTo(b.id);
    });
  }
  return grouped;
}
