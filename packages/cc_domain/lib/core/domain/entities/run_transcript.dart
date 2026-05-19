import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:collection/collection.dart';

/// One agent run's own activity timeline.
///
/// For a subagent run (an `AgentRunLog` with `role == AgentRunRole.sub`) this is
/// the only place its tool calls, reasoning and text survive: the child's events
/// are folded here rather than into the parent's channel message, so the run has
/// an activity view of its own. Live activity streams from the server's
/// in-memory registry; this is the durable record behind it.
class RunTranscript {
  /// Creates a [RunTranscript].
  RunTranscript({
    required this.runId,
    required this.workspaceId,
    required this.startedAt,
    required this.updatedAt,
    this.segments = const [],
    this.transcriptChars = 0,
    this.outcome,
    this.complete = false,
  }) {
    if (runId.isEmpty) {
      throw ArgumentError('runId must not be empty');
    }
    if (workspaceId.isEmpty) {
      throw ArgumentError('workspaceId must not be empty');
    }
  }

  /// The run this transcript belongs to.
  final String runId;

  /// Owning workspace — the isolation boundary for every read.
  final String workspaceId;

  /// The ordered activity timeline.
  final List<TranscriptSegment> segments;

  /// Running character count, for context-window estimates.
  final int transcriptChars;

  /// How the run's turn ended, or null while it is still streaming.
  final TurnOutcome? outcome;

  /// Whether the recording was finalized. False on a row a crash left behind
  /// mid-run — a reader should then present still-`running` tool segments as
  /// interrupted rather than live.
  final bool complete;

  /// When the recording started.
  final DateTime startedAt;

  /// When the transcript was last flushed.
  final DateTime updatedAt;

  /// Whether anything at all was recorded.
  bool get isEmpty => segments.isEmpty;

  static const _segmentsEquality = ListEquality<TranscriptSegment>();

  @override
  bool operator ==(Object other) =>
      other is RunTranscript &&
      other.runId == runId &&
      other.workspaceId == workspaceId &&
      other.transcriptChars == transcriptChars &&
      other.outcome == outcome &&
      other.complete == complete &&
      other.startedAt == startedAt &&
      other.updatedAt == updatedAt &&
      _segmentsEquality.equals(other.segments, segments);

  @override
  int get hashCode => Object.hash(
    runId,
    workspaceId,
    transcriptChars,
    outcome,
    complete,
    startedAt,
    updatedAt,
    _segmentsEquality.hash(segments),
  );
}
