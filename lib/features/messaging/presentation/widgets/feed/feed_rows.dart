import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_outline_entry.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_plan.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_items.dart';
import 'package:control_center/shared/widgets/transcript/util/nested_calls.dart'
    show isScriptTool;

/// One slot of the feed's list.
///
/// Most feed items are one row. An agent turn whose transcript is known is
/// laid out as several: its header, one row per transcript row, and its
/// footer. That is the granularity Delta's thread view works at — a turn with
/// a hundred tool calls is laid out only as far as the screen reaches, and the
/// scroll anchor can name the tool call the reader is looking at, not just the
/// turn.
sealed class FeedRow {
  const FeedRow();

  /// Stable identity of the row. A message's rows share the `m:<id>` prefix
  /// (see [messageIdOfRowKey]).
  String get key;
}

/// A feed item rendered whole: a separator, the unread divider, a non-turn
/// message, or an agent turn whose transcript is not known yet.
final class ItemRow extends FeedRow {
  /// Creates the row for [item].
  const ItemRow(this.item);

  /// The item.
  final FeedItem item;

  @override
  String get key => feedItemKey(item);
}

/// The header of an agent turn laid out row by row.
final class TurnHeadRow extends FeedRow {
  /// Creates the header row of [item]'s turn.
  const TurnHeadRow(this.item);

  /// The turn.
  final MessageItem item;

  @override
  String get key => turnRowKey(item.message.id, 'h');
}

/// One transcript row of an agent turn laid out row by row.
final class TurnPartRow extends FeedRow {
  /// Creates the row for [plan] in [item]'s turn.
  const TurnPartRow({
    required this.item,
    required this.plan,
    required this.segments,
    required this.isLive,
    required this.isFirst,
  });

  /// The turn.
  final MessageItem item;

  /// What this row renders.
  final TranscriptRowPlan plan;

  /// The transcript the plan was made from.
  final List<TranscriptSegment> segments;

  /// Whether the turn is streaming.
  final bool isLive;

  /// Whether this is the first transcript row (it carries the gap under the
  /// header instead of the plan's own gap).
  final bool isFirst;

  @override
  String get key => turnRowKey(item.message.id, plan.id);
}

/// The footer of an agent turn laid out row by row: trailer, badges, and the
/// message's hover rail.
final class TurnFootRow extends FeedRow {
  /// Creates the footer row of [item]'s turn.
  const TurnFootRow(this.item);

  /// The turn.
  final MessageItem item;

  @override
  String get key => turnRowKey(item.message.id, 'f');
}

/// A message outside the loaded messages: a stand-in sized from the outline.
///
/// Keyed like the message's own row (`m:<id>`), so when the message loads in
/// its place the list keeps the row's extent and element.
final class PlaceholderRow extends FeedRow {
  /// Creates the stand-in for [entry].
  const PlaceholderRow(this.entry);

  /// The message's outline.
  final ConversationOutlineEntry entry;

  @override
  String get key => 'm:${entry.id}';
}

/// A turn's transcript as the feed knows it.
typedef TurnTranscript = ({List<TranscriptSegment> segments, bool isLive});

/// Row key of a feed item.
String feedItemKey(FeedItem item) => switch (item) {
  MessageItem(:final message) => 'm:${message.id}',
  DayItem(:final day) => 'd:${day.year}-${day.month}-${day.day}',
  UnreadItem() => 'unread',
};

/// Row key of [part] of the turn [messageId].
String turnRowKey(String messageId, String part) => 'm:$messageId#$part';

/// The message a row key belongs to, or null for separators.
String? messageIdOfRowKey(String key) {
  if (!key.startsWith('m:')) {
    return null;
  }
  final hash = key.indexOf('#');
  return hash < 0 ? key.substring(2) : key.substring(2, hash);
}

/// Expands [items] into list rows: an agent turn whose transcript
/// [transcriptOf] knows (and that has at least one transcript row) becomes a
/// header, its transcript rows and a footer; everything else is one row.
List<FeedRow> expandFeedRows(
  List<FeedItem> items, {
  required TurnTranscript? Function(MessageItem item) transcriptOf,
}) {
  final out = <FeedRow>[];
  for (final item in items) {
    if (item is! MessageItem || !item.message.isAgentTurn) {
      out.add(ItemRow(item));
      continue;
    }
    final transcript = transcriptOf(item);
    if (transcript == null || transcript.segments.isEmpty) {
      out.add(ItemRow(item));
      continue;
    }
    final plan = planTranscriptRows(
      segments: transcript.segments,
      inlineMessages: item.inlineMessages,
      isLive: transcript.isLive,
    );
    if (plan.isEmpty) {
      out.add(ItemRow(item));
      continue;
    }
    out.add(TurnHeadRow(item));
    for (var i = 0; i < plan.length; i++) {
      out.add(
        TurnPartRow(
          item: item,
          plan: plan[i],
          segments: transcript.segments,
          isLive: transcript.isLive,
          isFirst: i == 0,
        ),
      );
    }
    out.add(TurnFootRow(item));
  }
  return out;
}

/// The index in [rows] (oldest first) of the newest transcript row that shows
/// the script whose call is [toolCallId], or -1 when none does: where "Show
/// script" on an approval or a question a script raised lands.
///
/// The newest, not the first: tool call ids repeat (local models reuse
/// `call_0` on every turn), and a request a script raises comes from the
/// script running now, which is the latest row with that id. Only a script's
/// row (`repl`, [isScriptTool]) counts: on the MCP lane the caller
/// names the script's id, and an id another call of the run also holds must
/// never land the person on that call's row instead of the script's.
int latestRowShowingToolCall(List<FeedRow> rows, String toolCallId) =>
    rows.lastIndexWhere(
      (row) => row is TurnPartRow && _rowShowsScript(row, toolCallId),
    );

bool _rowShowsScript(TurnPartRow row, String toolCallId) {
  final plan = row.plan;
  if (plan is! SegmentRowPlan) {
    return false;
  }
  bool isScript(TranscriptSegment seg) =>
      seg is ToolSegment &&
      seg.toolCallId == toolCallId &&
      isScriptTool(seg.toolName);
  return isScript(plan.segment) ||
      plan.children.any(
        (i) => i < row.segments.length && isScript(row.segments[i]),
      );
}
