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
    this.inlineMessages = const [],
  });

  /// The message to render.
  final Message message;

  /// Whether to hide the avatar/name because the previous row is the same sender.
  final bool collapseHeader;

  /// Steering and resolved questions rendered chronologically inside this run.
  final List<Message> inlineMessages;
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
  final inlineByRun = _inlineMessagesByRun(messages);
  final inlineIds = inlineByRun.isEmpty
      ? const <String>{}
      : {
          for (final entries in inlineByRun.values)
            for (final message in entries) message.id,
        };
  DateTime? lastDay;
  Message? prevSender;
  bool dividerInserted = false;
  bool isUnread(Message m) =>
      readFrontier != null &&
      m.senderType == SenderType.agent &&
      m.createdAt.isAfter(readFrontier);
  final unreadCount = messages.where(isUnread).length;

  for (final display in messages) {
    // Pending questions stay standalone; queued steering stays in the composer.
    // Resolved interactions belong inside their loaded turn, not below it.
    if (display.isSteeringQueued || inlineIds.contains(display.id)) {
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
        inlineMessages: inlineByRun[display.id] ?? const [],
      ),
    );
    prevSender = display;
  }
  return out;
}

Map<String, List<Message>> _inlineMessagesByRun(List<Message> messages) {
  if (!messages.any(
    (m) =>
        (m.isSteeringInjected && m.steerRunId != null) ||
        (m.isUserQuestion && m.isQuestionAnswered),
  )) {
    return const {};
  }
  final byId = {
    for (final message in messages)
      if (message.isAgentTurn) message.id: message,
  };
  final latestRun = <(String, String, String), Message>{};
  final grouped = <String, List<Message>>{};
  for (final message in messages) {
    if (message.isAgentTurn) {
      latestRun[(message.spaceId, message.conversationId, message.senderId)] =
          message;
      continue;
    }
    // Questions carry their asking agent and creation time, not a run ID.
    // The ascending feed identifies that agent's preceding turn without
    // crossing a space/conversation or hiding an unloaded turn's question.
    final Message? run;
    if (message.isSteeringInjected) {
      run = byId[message.steerRunId];
    } else if (message.isUserQuestion && message.isQuestionAnswered) {
      run =
          latestRun[(
            message.spaceId,
            message.conversationId,
            message.senderId,
          )];
    } else {
      continue;
    }
    if (run == null ||
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
