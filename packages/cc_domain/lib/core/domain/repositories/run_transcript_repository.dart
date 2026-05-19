import 'package:cc_domain/core/domain/entities/run_transcript.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';

/// Persistence for a single agent run's activity timeline.
///
/// Separate from `AgentRunLogRepository` on purpose: that interface is consumed
/// via `implements` in ~25 places, so widening it for one run-scoped read would
/// touch every implementer. This is also the reason the read is not exposed as a
/// `watch*`: a stream over the segment blob would re-ship the whole transcript
/// on every mid-run flush, so live activity rides a relay port instead and this
/// repository serves crash recovery and replay.
abstract class RunTranscriptRepository {
  /// The run's persisted transcript, or null when none was recorded.
  ///
  /// Workspace-scoped: a run belonging to another workspace is simply not found.
  Future<RunTranscript?> getForRun(String workspaceId, String runId);

  /// Persists the run's transcript, replacing any prior snapshot.
  ///
  /// Takes ALREADY-ENCODED segment JSON because the recorder keeps an
  /// incremental encode cache: a mid-run flush re-encodes only the segments that
  /// changed instead of the whole transcript.
  Future<void> upsert({
    required String runId,
    required String workspaceId,
    required List<Map<String, dynamic>> segmentsJson,
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
