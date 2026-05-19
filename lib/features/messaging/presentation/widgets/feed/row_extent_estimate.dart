import 'dart:math' as math;

import 'package:cc_domain/core/domain/entities/message.dart';

/// Estimated height of a day separator or the unread divider: 10px of padding
/// either side of one caption line.
const double kSeparatorRowExtent = 38;

/// Extent used for a row nothing is known about (an index past the mirrored
/// item list, the load-more spinner).
const double kUnknownRowExtent = 96;

/// Segments assumed for a lite list row that carries a transcript the wire
/// elided and whose `segment_count` the server did not stamp (a row written
/// before that field existed). Deliberately modest: over-estimating the
/// scrollback pushes the load-more threshold out of reach.
const int kElidedSegmentGuess = 6;

/// Rendered line height of bubble body text (14px × `bodyLineHeight` 1.5).
const double _lineHeight = 21;

/// Average advance width of the UI font at body size, for wrapping arithmetic.
const double _charWidth = 7.4;

/// Chrome around every bubble: the row's own vertical padding plus the
/// bubble's.
const double _bubbleChrome = 20;

/// Sender avatar + name + timestamp line, drawn once per sender group.
const double _headerExtent = 26;

/// A collapsed-header message still leaves a small gap above it.
const double _collapsedHeaderExtent = 6;

/// Per-transcript-segment height: most rows are collapsed tool calls (a single
/// summary line), averaged up for the reasoning/prose segments between them and
/// the file edits that open expanded.
const double _segmentExtent = 40;

/// Ceiling on estimated prose lines, so one pathological paste cannot hand the
/// scrollbar a five-figure extent.
const int _maxProseLines = 200;

/// Estimated extent of a message row [columnWidth] wide, before it has been
/// laid out for real.
///
/// This is what the feed's `SuperListView` scrolls against until a row is
/// actually built — which, for a windowed feed opened at the live edge, is most
/// of the scrollback most of the time. The package's own default is a flat
/// 100px for every row, and an agent turn carrying twelve tool calls is nothing
/// like a one-line "ok": that error is what makes a scrollbar thumb jump as you
/// drag it.
///
/// It is an estimate on purpose. Measuring the truth means building the row —
/// markdown parse, syntax-highlighted diffs, and for a lite list row a
/// transcript round trip — which is the cost the windowed feed exists to avoid.
/// See `_IdlePrecalculationPolicy` in `message_feed.dart`.
double estimateMessageRowExtent(
  Message message, {
  required bool collapseHeader,
  required double columnWidth,
}) {
  final header = collapseHeader ? _collapsedHeaderExtent : _headerExtent;

  // Structured bubbles are card-shaped: their height comes from their own
  // chrome far more than from `content`, so a per-kind constant beats
  // measuring the text.
  final card = _cardExtent(message.messageType);
  if (card != null) {
    return header + card;
  }

  var extent =
      header + _bubbleChrome + _proseExtent(message.content, columnWidth);
  if (message.messageType == MessageType.agentTurn) {
    extent += _segmentCount(message) * _segmentExtent;
  }
  return extent;
}

/// Fixed extent for the message kinds that render as a card rather than as
/// prose, or null when the kind's height follows its text.
double? _cardExtent(MessageType type) => switch (type) {
  MessageType.system => 28,
  MessageType.compaction => 64,
  MessageType.steering => 56,
  MessageType.ticketCard => 76,
  MessageType.hireProposal => 140,
  MessageType.reviewNode => 150,
  MessageType.reviewSummary => 160,
  MessageType.plan => 180,
  MessageType.userQuestion => 200,
  MessageType.orchestrationProposal => 170,
  MessageType.artifact => 220,
  MessageType.text || MessageType.agentTurn => null,
};

/// Wrapped height of [content] at [columnWidth], counting hard line breaks.
double _proseExtent(String content, double columnWidth) {
  if (content.isEmpty) {
    return 0;
  }
  final charsPerLine = math.max(24, columnWidth ~/ _charWidth);
  var lines = 0;
  for (final paragraph in content.split('\n')) {
    lines += math.max(1, (paragraph.length + charsPerLine - 1) ~/ charsPerLine);
    if (lines >= _maxProseLines) {
      return _maxProseLines * _lineHeight;
    }
  }
  return lines * _lineHeight;
}

/// How many transcript segments this agent turn renders.
///
/// Read off the wire WITHOUT decoding the transcript: a full row's `segments`
/// list is counted in place and a lite row carries the count the server stamped
/// beside `segments_elided`. Calling `Message.transcript` here would decode
/// every visible turn's JSON purely to estimate a height.
int _segmentCount(Message message) {
  final metadata = message.metadata;
  if (metadata == null) {
    return 0;
  }
  final segments = metadata['segments'];
  if (segments is List) {
    return segments.length;
  }
  final stamped = (metadata['segment_count'] as num?)?.toInt();
  if (stamped != null) {
    return stamped;
  }
  return metadata['segments_elided'] == true ? kElidedSegmentGuess : 0;
}
