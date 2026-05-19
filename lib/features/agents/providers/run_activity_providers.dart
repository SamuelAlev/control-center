import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';
import 'package:collection/collection.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/conversation_run_tree_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies one run inside the conversation it belongs to.
///
/// A record, so it works as a provider-family key by value.
typedef RunInConversationKey = ({
  String workspaceId,
  String channelId,
  String runId,
});

/// Identifies one run for a run-scoped server read.
typedef RunKey = ({String workspaceId, String runId});

/// One run's log row, derived from the conversation's live run-log stream.
///
/// Status, liveness, cost and token updates therefore land with no second
/// subscription — and with no unscoped `getById`, which would not be a workspace
/// boundary.
///
/// Stays [AsyncLoading] until the conversation's stream produces its first value,
/// then resolves to null when the run is not (or no longer) in the conversation's
/// set — which is how a surface renders "this run is no longer available" without
/// confusing it with "still loading".
final runInConversationProvider = Provider.autoDispose
    .family<AsyncValue<AgentRunLog?>, RunInConversationKey>((ref, key) {
      return ref
          .watch(
            conversationRunLogsProvider((
              workspaceId: key.workspaceId,
              conversationId: key.channelId,
            )),
          )
          .whenData(
            (logs) => logs.firstWhereOrNull((log) => log.id == key.runId),
          );
    });

/// One run's ordered activity timeline: the tool calls, reasoning, text and
/// errors it produced.
///
/// Live while the run streams and replayed from the persisted record afterwards —
/// the server's single relay op covers both. Folds the relay's seed + update
/// frames into a flat segment list so callers render the same
/// `List<TranscriptSegment>` a channel turn does.
///
/// Falls back to a one-shot read when the relay op is unavailable (a host with no
/// dispatch stack) and to an empty list when nothing was recorded.
final runTranscriptProvider = StreamProvider.autoDispose
    .family<List<TranscriptSegment>, RunKey>((ref, key) async* {
      final port = ref.watch(runTranscriptRelayPortProvider);
      var segments = <TranscriptSegment>[];
      var sawSeed = false;

      try {
        await for (final event in port.watchRunTranscript(key.runId)) {
          switch (event) {
            case RunTranscriptSeed():
              segments = [...event.segments];
              sawSeed = true;
            case RunTranscriptUpdates(:final updates):
              segments = _apply(segments, updates);
          }
          yield List<TranscriptSegment>.unmodifiable(segments);
        }
      } on Object {
        // The watch op is absent or the subscription failed. A finished run's
        // transcript is still readable one-shot, so degrade instead of erroring —
        // but only when we never got a seed, so a mid-stream drop keeps what it had.
        //
        // A RunActivityUnsupportedException from the one-shot read propagates on
        // purpose: "the server cannot serve this" needs a different message from
        // "this run recorded nothing".
        if (sawSeed) {
          rethrow;
        }
        yield List<TranscriptSegment>.unmodifiable(
          await port.fetchRunTranscript(key.runId),
        );
      }
    });

/// Folds relay updates into [segments], returning a new list.
///
/// Mirrors `ActiveStreamRegistry.apply`, minus the delta-buffer optimization: a
/// run-activity surface renders far fewer, far shorter segments than a live chat
/// feed, so a straight rebuild is simpler and fast enough.
List<TranscriptSegment> _apply(
  List<TranscriptSegment> segments,
  List<TranscriptUpdate> updates,
) {
  final out = [...segments];
  for (final update in updates) {
    switch (update) {
      case SegmentOpened(:final index, :final segment):
        if (index == out.length) {
          out.add(segment);
        } else if (index >= 0 && index < out.length) {
          out[index] = segment;
        }
      case SegmentDelta(:final index, :final delta):
        if (index >= 0 && index < out.length) {
          out[index] = _appendText(out[index], delta);
        }
      case SegmentClosed(:final index, :final segment):
        if (index >= 0 && index < out.length) {
          out[index] = segment;
        }
      case TurnFinished():
        break;
    }
  }
  return out;
}

TranscriptSegment _appendText(TranscriptSegment segment, String delta) =>
    switch (segment) {
      final ReasoningSegment s => s.copyWith(text: s.text + delta),
      final TextSegment s => s.copyWith(text: s.text + delta),
      final ToolSegment s => s.copyWith(outputs: s.outputs + delta),
      final ErrorSegment s => s,
      final ViolationSegment s => s,
    };

/// The number of tool calls in a run's activity, for its stat bar.
final runToolCountProvider = Provider.autoDispose.family<int, RunKey>((
  ref,
  key,
) {
  final segments = ref.watch(runTranscriptProvider(key)).asData?.value;
  return segments?.whereType<ToolSegment>().length ?? 0;
});

/// The run that a parent's `task` tool call spawned, or null when the parent's
/// transcript predates spawn correlation (or the child row is gone).
///
/// Lets the `task` cell rendered in a parent's timeline open the child's own
/// activity. Matched on the recorded [AgentRunLog.spawnToolCallId] rather than by
/// label and time, which would mis-link concurrent `task` calls.
final runIdForSpawnToolCallProvider = Provider.autoDispose
    .family<String?, RunInConversationKey>((ref, key) {
      final logs = ref
          .watch(
            conversationRunLogsProvider((
              workspaceId: key.workspaceId,
              conversationId: key.channelId,
            )),
          )
          .asData
          ?.value;
      // `runId` carries the TOOL CALL id here — the caller has a transcript cell,
      // not a run.
      return logs
          ?.firstWhereOrNull((log) => log.spawnToolCallId == key.runId)
          ?.id;
    });
