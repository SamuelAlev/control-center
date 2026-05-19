import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';

/// A live update to an agent turn's transcript, addressed to a single segment
/// position so the UI can rebuild only the affected cell.
///
/// Atomic segments (errors, sandbox violations, orphan tool results) emit a
/// [SegmentOpened] immediately followed by a [SegmentClosed] so cell logic
/// stays uniform: opened = insert, delta = append into the open segment,
/// closed = finalize.
sealed class TranscriptUpdate {
  /// Creates a [TranscriptUpdate] targeting the segment at [index].
  const TranscriptUpdate(this.index);

  /// Position of the affected segment within the transcript.
  final int index;
}

/// A new segment was appended to the transcript.
class SegmentOpened extends TranscriptUpdate {
  /// Creates a [SegmentOpened].
  const SegmentOpened(super.index, this.segment);

  /// The newly-inserted segment (open, no duration yet).
  final TranscriptSegment segment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SegmentOpened && index == other.index && segment == other.segment;

  @override
  int get hashCode => Object.hash(index, segment);
}

/// Append-only delta to the currently-open segment (reasoning/text chars or
/// partial tool output).
class SegmentDelta extends TranscriptUpdate {
  /// Creates a [SegmentDelta].
  const SegmentDelta(super.index, this.delta);

  /// The appended text.
  final String delta;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SegmentDelta && index == other.index && delta == other.delta;

  @override
  int get hashCode => Object.hash(index, delta);
}

/// The segment at [index] reached its final state (result, status, duration).
class SegmentClosed extends TranscriptUpdate {
  /// Creates a [SegmentClosed].
  const SegmentClosed(super.index, this.segment);

  /// The finalized segment snapshot.
  final TranscriptSegment segment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SegmentClosed && index == other.index && segment == other.segment;

  @override
  int get hashCode => Object.hash(index, segment);
}

/// Terminal update for the whole turn.
class TurnFinished extends TranscriptUpdate {
  /// Creates a [TurnFinished]. [index] points at the last segment.
  const TurnFinished(super.index, this.outcome);

  /// How the turn ended.
  final TurnOutcome outcome;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TurnFinished && index == other.index && outcome == other.outcome;

  @override
  int get hashCode => Object.hash(index, outcome);
}
