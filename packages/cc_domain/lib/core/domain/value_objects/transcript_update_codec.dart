import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';

/// Wire codec for [TranscriptUpdate], used by the live turn relay
/// (`messaging.watchSpaceTurns`) to ship per-segment updates from the
/// server's `ActiveStreamRegistry` to a thin client's registry.
///
/// Shape (compact keys — these ride the socket per delta batch):
/// `'t'` = `'open'|'delta'|'close'|'finish'`, `'i'` = segment index,
/// `'seg'` = segment JSON (open/close), `'d'` = delta text (delta),
/// `'outcome'` = turn outcome string (finish).
Map<String, dynamic> transcriptUpdateToWire(TranscriptUpdate update) =>
    switch (update) {
      SegmentOpened(:final index, :final segment) => {
        't': 'open',
        'i': index,
        'seg': segment.toJson(),
      },
      SegmentDelta(:final index, :final delta) => {
        't': 'delta',
        'i': index,
        'd': delta,
      },
      SegmentClosed(:final index, :final segment) => {
        't': 'close',
        'i': index,
        'seg': segment.toJson(),
      },
      TurnFinished(:final index, :final outcome) => {
        't': 'finish',
        'i': index,
        'outcome': turnOutcomeToString(outcome),
      },
    };

/// One event on the live turn relay (`messaging.watchSpaceTurns`), decoded
/// from a wire frame by [spaceTurnEventFromWire].
sealed class SpaceTurnEvent {
  const SpaceTurnEvent();
}

/// The first frame of a relay subscription: every turn currently streaming in
/// the space, each with its full segment snapshot so a late subscriber (or a
/// reconnect) adopts the in-flight state with no lost prefix.
class TurnRelaySeed extends SpaceTurnEvent {
  /// Creates a [TurnRelaySeed].
  const TurnRelaySeed(this.turns);

  /// The active turns: message id + full snapshot each. Empty when nothing
  /// is streaming (the frame still marks the subscription as established).
  final List<({String messageId, List<TranscriptSegment> segments})> turns;
}

/// A coalesced batch of updates for one in-flight turn, in emission order.
class TurnRelayUpdates extends SpaceTurnEvent {
  /// Creates a [TurnRelayUpdates].
  const TurnRelayUpdates(this.messageId, this.updates);

  /// The turn (agent-turn message id) the updates belong to.
  final String messageId;

  /// The updates, in order. Consecutive same-segment deltas may have been
  /// merged by the relay's coalescing buffer.
  final List<TranscriptUpdate> updates;
}

/// Decodes a relay frame into a [SpaceTurnEvent], or null for unknown
/// frames (tolerant, so protocol additions degrade to a skip).
SpaceTurnEvent? spaceTurnEventFromWire(Map<String, dynamic> frame) {
  switch (frame['kind'] as String?) {
    case 'seed':
      final turns = frame['turns'];
      if (turns is! List) {
        return const TurnRelaySeed([]);
      }
      return TurnRelaySeed([
        for (final t in turns)
          if (t is Map && t['message_id'] is String)
            (
              messageId: t['message_id'] as String,
              segments: decodeTranscript(t['segments']),
            ),
      ]);
    case 'updates':
      final messageId = frame['message_id'];
      final updates = frame['updates'];
      if (messageId is! String || updates is! List) {
        return null;
      }
      return TurnRelayUpdates(messageId, [
        for (final u in updates)
          if (u is Map) ?transcriptUpdateFromWire(u.cast<String, dynamic>()),
      ]);
    default:
      return null;
  }
}

/// One event on the run-activity relay (`agent_run_log.watchRunTranscript`),
/// decoded from a wire frame by [runTranscriptEventFromWire].
///
/// Run-scoped rather than space-scoped, so no id rides each frame: the
/// subscription already names the run. Deliberately not reusing
/// [SpaceTurnEvent] — that would force a run id into a `message_id` field and
/// leave a permanently confusing wire contract.
sealed class RunTranscriptEvent {
  const RunTranscriptEvent();
}

/// The first frame of a run-activity subscription: the run's segments so far.
///
/// [live] is false when the run has already finished and the seed came from the
/// persisted transcript — no updates will follow, so a client can stop showing
/// streaming affordances immediately.
class RunTranscriptSeed extends RunTranscriptEvent {
  /// Creates a [RunTranscriptSeed].
  const RunTranscriptSeed(this.segments, {this.live = true});

  /// The run's activity so far. Empty when nothing was recorded (the frame
  /// still marks the subscription as established).
  final List<TranscriptSegment> segments;

  /// Whether the run is still streaming.
  final bool live;
}

/// A coalesced batch of updates for the subscribed run, in emission order.
class RunTranscriptUpdates extends RunTranscriptEvent {
  /// Creates a [RunTranscriptUpdates].
  const RunTranscriptUpdates(this.updates);

  /// The updates, in order. Consecutive same-segment deltas may have been
  /// merged by the relay's coalescing buffer.
  final List<TranscriptUpdate> updates;
}

/// Decodes a run-activity relay frame into a [RunTranscriptEvent], or null for
/// unknown frames (tolerant, so protocol additions degrade to a skip).
RunTranscriptEvent? runTranscriptEventFromWire(Map<String, dynamic> frame) {
  switch (frame['kind'] as String?) {
    case 'seed':
      return RunTranscriptSeed(
        decodeTranscript(frame['segments']),
        live: frame['live'] as bool? ?? true,
      );
    case 'updates':
      final updates = frame['updates'];
      if (updates is! List) {
        return null;
      }
      return RunTranscriptUpdates([
        for (final u in updates)
          if (u is Map) ?transcriptUpdateFromWire(u.cast<String, dynamic>()),
      ]);
    default:
      return null;
  }
}

/// Decodes a wire frame produced by [transcriptUpdateToWire].
///
/// Tolerant: returns null for unknown/malformed frames so a relay stream with
/// a newer update kind degrades to skipping it rather than throwing.
TranscriptUpdate? transcriptUpdateFromWire(Map<String, dynamic> wire) {
  final index = (wire['i'] as num?)?.toInt();
  if (index == null) {
    return null;
  }
  switch (wire['t'] as String?) {
    case 'open':
      final seg = wire['seg'];
      if (seg is! Map) {
        return null;
      }
      return SegmentOpened(
        index,
        TranscriptSegment.fromJson(seg.cast<String, dynamic>()),
      );
    case 'delta':
      final delta = wire['d'];
      if (delta is! String) {
        return null;
      }
      return SegmentDelta(index, delta);
    case 'close':
      final seg = wire['seg'];
      if (seg is! Map) {
        return null;
      }
      return SegmentClosed(
        index,
        TranscriptSegment.fromJson(seg.cast<String, dynamic>()),
      );
    case 'finish':
      final outcome = turnOutcomeFromString(wire['outcome'] as String?);
      if (outcome == null) {
        return null;
      }
      return TurnFinished(index, outcome);
    default:
      return null;
  }
}
