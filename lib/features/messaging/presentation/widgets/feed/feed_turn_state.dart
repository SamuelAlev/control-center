import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/services/active_stream_registry.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/live_transcript_controller.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_flow.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_rows.dart';
import 'package:flutter/foundation.dart';

/// Whether the pointer is over any row of one message.
///
/// A turn laid out row by row still has one hover rail (on its footer row);
/// every row of the turn reports in here so hovering any part reveals it.
class TurnHover extends ValueNotifier<bool> {
  /// Creates a hover group, not hovered.
  TurnHover() : super(false);

  int _inside = 0;

  /// The pointer entered one of the message's rows.
  void enter() {
    _inside++;
    value = true;
  }

  /// The pointer left one of the message's rows.
  void exit() {
    if (_inside > 0) {
      _inside--;
    }
    value = _inside > 0;
  }
}

/// What the feed keeps for one agent turn while it is in the window.
///
/// The turn's rows are separate list slots, so the state a single bubble used
/// to own — the live stream controller, the transcript row memo and keys, the
/// hover group — lives here and is shared by all of them.
class FeedTurnState {
  /// Creates the state for [messageId], following its live stream in
  /// [registry] when there is one.
  FeedTurnState(ActiveStreamRegistry registry, this.messageId)
    : live = LiveTranscriptController(registry, messageId);

  /// The turn.
  final String messageId;

  /// The turn's live stream (structure + per-delta pulses).
  final LiveTranscriptController live;

  /// Row memo, prose keys and open-row listening for the turn's transcript.
  final TranscriptRowRenderer rows = TranscriptRowRenderer();

  /// Hover across the turn's rows.
  final TurnHover hover = TurnHover();

  List<TranscriptSegment>? _known;
  Message? _knownFor;

  /// The transcript the feed lays [message] out from, or null while it is not
  /// known (the turn then renders as one row that loads it).
  ///
  /// Live: the registry snapshot. Settled: the message's own segments, else
  /// [cached] (the transcript memo a read filled). A transcript found once is
  /// held for as long as the message is unchanged, so an eviction from the
  /// shared memo does not fold a turn on screen back into a single row.
  TurnTranscript? transcriptFor(
    Message message, {
    required List<TranscriptSegment>? Function() cached,
  }) {
    if (live.isLive && !message.isStreamingComplete) {
      final snapshot = live.snapshot;
      if (snapshot == null || snapshot.isEmpty) {
        return null;
      }
      return (segments: snapshot, isLive: true);
    }
    if (!identical(_knownFor, message)) {
      _known = null;
      _knownFor = message;
    }
    var segments = _known;
    if (segments == null) {
      final own = message.transcript;
      segments = own.isNotEmpty ? own : cached();
      if (segments != null && segments.isNotEmpty) {
        _known = segments;
      }
    }
    if (segments == null || segments.isEmpty) {
      return null;
    }
    return (segments: segments, isLive: false);
  }

  /// Releases the stream subscription and notifiers.
  void dispose() {
    live.dispose();
    hover.dispose();
  }
}
