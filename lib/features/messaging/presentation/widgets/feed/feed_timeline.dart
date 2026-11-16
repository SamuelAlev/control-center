import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_outline_entry.dart';

/// A stretch of the conversation the feed shows in one way.
///
/// The feed lays out the whole conversation: the live window (the newest
/// messages, always loaded), any history range loaded around where the reader
/// is, and placeholders for everything else, sized from the outline.
sealed class TimelineSpan {
  const TimelineSpan();
}

/// Consecutive messages that are loaded.
final class LoadedSpan extends TimelineSpan {
  /// Creates a span of [messages] (ascending).
  const LoadedSpan(
    this.messages, {
    required this.afterGap,
    required this.reachesNewest,
  });

  /// The messages, oldest first.
  final List<Message> messages;

  /// Whether something comes before the span that is not loaded (placeholders,
  /// or older messages not yet known): its oldest day separator is not drawn,
  /// since the day of the message above is not known.
  final bool afterGap;

  /// Whether the span runs to the newest message (it holds the live window).
  final bool reachesNewest;
}

/// Consecutive messages that are not loaded.
final class StandInSpan extends TimelineSpan {
  /// Creates a run of placeholders for [entries] (ascending).
  const StandInSpan(this.entries);

  /// The messages, oldest first.
  final List<ConversationOutlineEntry> entries;
}

/// The feed's layout of a conversation, and whether the outline it was made
/// from is out of step with the messages loaded.
typedef FeedTimeline = ({List<TimelineSpan> spans, bool outlineStale});

/// Lays the conversation out from the [live] window (newest messages,
/// ascending; [liveHasMore] when older ones exist), the [outline] of every
/// message (null while it loads) and a loaded history [range] (ascending).
///
/// Without an outline, or when the live window already holds everything, the
/// feed is the live window alone. Otherwise every message older than the live
/// window is a range message when the range holds it and a placeholder when
/// not; a range that runs into the live window merges with it.
///
/// `outlineStale` is set when the outline does not account for the loaded
/// messages: none of the live window is in it (the outline predates the
/// window) or the range holds a message it does not list.
FeedTimeline composeFeedTimeline({
  required List<Message> live,
  required bool liveHasMore,
  List<ConversationOutlineEntry>? outline,
  List<Message>? range,
}) {
  if (outline == null || !liveHasMore || live.isEmpty) {
    return (
      spans: [LoadedSpan(live, afterGap: liveHasMore, reachesNewest: true)],
      outlineStale: false,
    );
  }
  final liveIds = {for (final m in live) m.id};
  final oldestLive = live.first.createdAt;
  final older = <ConversationOutlineEntry>[];
  var liveFound = false;
  for (final entry in outline) {
    if (liveIds.contains(entry.id)) {
      liveFound = true;
      break;
    }
    if (entry.createdAt.isAfter(oldestLive)) {
      break;
    }
    older.add(entry);
  }

  final rangeById = {for (final m in range ?? const <Message>[]) m.id: m};
  var stale = !liveFound;
  if (rangeById.isNotEmpty) {
    final listed = {for (final e in outline) e.id};
    stale =
        stale ||
        rangeById.keys.any(
          (id) => !liveIds.contains(id) && !listed.contains(id),
        );
  }

  final spans = <TimelineSpan>[];
  var placeholders = <ConversationOutlineEntry>[];
  var loaded = <Message>[];
  var loadedAfterGap = false;

  void flushPlaceholders() {
    if (placeholders.isNotEmpty) {
      spans.add(StandInSpan(placeholders));
      placeholders = <ConversationOutlineEntry>[];
    }
  }

  void flushLoaded() {
    if (loaded.isNotEmpty) {
      spans.add(
        LoadedSpan(loaded, afterGap: loadedAfterGap, reachesNewest: false),
      );
      loaded = <Message>[];
    }
  }

  for (final entry in older) {
    final message = rangeById[entry.id];
    if (message == null) {
      flushLoaded();
      placeholders.add(entry);
    } else {
      if (loaded.isEmpty) {
        loadedAfterGap = placeholders.isNotEmpty || spans.isNotEmpty;
      }
      flushPlaceholders();
      loaded.add(message);
    }
  }
  flushPlaceholders();
  if (loaded.isNotEmpty) {
    // The range runs into the live window: one contiguous span to the newest
    // message.
    spans.add(
      LoadedSpan(
        [...loaded, ...live],
        afterGap: loadedAfterGap,
        reachesNewest: true,
      ),
    );
  } else {
    spans.add(
      LoadedSpan(live, afterGap: older.isNotEmpty, reachesNewest: true),
    );
  }
  return (spans: spans, outlineStale: stale);
}

/// The id of the earliest message the reader has not read: the first message
/// after [readFrontier] that is not their own, across loaded spans and
/// placeholders alike. Null when nothing is unread.
String? firstUnreadId(List<TimelineSpan> spans, DateTime? readFrontier) {
  if (readFrontier == null) {
    return null;
  }
  for (final span in spans) {
    switch (span) {
      case StandInSpan(:final entries):
        for (final e in entries) {
          if (e.senderType != SenderType.user &&
              e.createdAt.isAfter(readFrontier)) {
            return e.id;
          }
        }
      case LoadedSpan(:final messages):
        for (final m in messages) {
          if (m.senderType != SenderType.user &&
              !m.isSteeringQueued &&
              m.createdAt.isAfter(readFrontier)) {
            return m.id;
          }
        }
    }
  }
  return null;
}
