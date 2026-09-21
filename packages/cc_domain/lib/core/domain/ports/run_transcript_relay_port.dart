import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';

/// Client port for `agent_run_log.watchRunTranscript`.
///
/// Seeds with [RunTranscriptSeed], then [RunTranscriptUpdates]; finished runs
/// seed `live: false` and complete. Not on `AgentRunLogRepository` (RPC-only).
/// Missing ops mean a stale server binary, not an empty transcript.
class RunActivityUnsupportedException implements Exception {
  /// Creates a [RunActivityUnsupportedException].
  const RunActivityUnsupportedException();

  @override
  String toString() =>
      'RunActivityUnsupportedException: the connected server does not serve '
      'agent_run_log run-transcript ops';
}

abstract class RunTranscriptRelayPort {
  /// Live activity for [runId]: a seed frame, then update batches.
  ///
  /// The stream completes once the run reaches a terminal state, so a client
  /// holding a tab open for a finished run stops paying for a subscription.
  Stream<RunTranscriptEvent> watchRunTranscript(String runId);

  /// One-shot read of [runId]'s recorded activity.
  ///
  /// The degradation path for a host that serves the read op but not the watch
  /// op (no dispatch stack, so no live registry). Returns an empty list when
  /// nothing was recorded — never throws for a missing run or a missing op.
  Future<List<TranscriptSegment>> fetchRunTranscript(String runId);
}

/// The no-op relay: every run reads as "nothing recorded" and no updates
/// follow. Bound on hosts with no dispatch stack (so no live registry) and
/// used by tests.
class EmptyRunTranscriptRelayPort implements RunTranscriptRelayPort {
  /// Creates an [EmptyRunTranscriptRelayPort].
  const EmptyRunTranscriptRelayPort();

  @override
  Stream<RunTranscriptEvent> watchRunTranscript(String runId) =>
      Stream.value(const RunTranscriptSeed([], live: false));

  @override
  Future<List<TranscriptSegment>> fetchRunTranscript(String runId) async =>
      const [];
}
