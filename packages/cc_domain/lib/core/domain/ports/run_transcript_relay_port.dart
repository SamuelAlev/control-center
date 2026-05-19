import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';

/// Client-side port for one run's activity relay
/// (`agent_run_log.watchRunTranscript`).
///
/// A client subscribes once per open run-activity surface; the stream opens with
/// a [RunTranscriptSeed] carrying the run's segments so far, then emits
/// [RunTranscriptUpdates] batches while it streams. One op serves both live and
/// replay: a finished run seeds from the persisted transcript with `live: false`
/// and the stream then completes.
///
/// Deliberately NOT part of `AgentRunLogRepository`: that interface is consumed
/// via `implements` in ~25 places, so widening it for a surface that only exists
/// on RPC-backed clients (the server owns the live registry in-process) would
/// touch every implementer and its test fakes.
/// The connected server does not serve run activity at all.
///
/// Distinct from "this run recorded nothing": it means the ops are absent, which
/// in practice is a server binary older than the feature. Worth its own type
/// because the two need opposite messages — one says the run has no timeline,
/// the other says the app is talking to a stale server and a restart fixes it.
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
