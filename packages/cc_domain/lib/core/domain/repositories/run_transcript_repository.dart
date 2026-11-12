import 'package:cc_domain/core/domain/entities/run_transcript.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';

/// Persistence for the activity timeline of a run that has no message of its
/// own (a subagent run).
///
/// A space turn's timeline belongs to its message instead and is written and
/// read through the messaging repository as `metadata['segments']`; both are
/// stored the same way, one row per segment.
///
/// Separate from `AgentRunLogRepository` on purpose: that interface is consumed
/// via `implements` in ~25 places, so widening it for one run-scoped read would
/// touch every implementer. The read is not exposed as a `watch*` either: live
/// activity rides a relay port, and this repository serves crash recovery and
/// replay.
abstract class RunTranscriptRepository {
  /// The run's persisted transcript, or null when none was recorded.
  ///
  /// Workspace-scoped: a run belonging to another workspace is simply not found.
  Future<RunTranscript?> getForRun(String workspaceId, String runId);

  /// Persists one flush of the run's transcript.
  ///
  /// [changedSegments] maps a segment's position to its encoded JSON and holds
  /// only the segments that are new or changed since the previous flush: a
  /// segment that is not in it keeps its stored row untouched. [segmentCount]
  /// is the length of the whole transcript. The per-transcript facts
  /// ([transcriptChars], [outcome], [complete], the times) are written on
  /// every flush.
  Future<void> write({
    required String runId,
    required String workspaceId,
    required Map<int, Map<String, dynamic>> changedSegments,
    required int segmentCount,
    required int transcriptChars,
    required DateTime startedAt,
    required DateTime updatedAt,
    TurnOutcome? outcome,
    bool complete = false,
  });

  /// Deletes the run's transcript. Returns rows deleted (0 when it belongs to
  /// another workspace).
  Future<int> deleteForRun(String workspaceId, String runId);
}
