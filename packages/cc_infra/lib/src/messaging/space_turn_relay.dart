import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';

/// How long the relay buffers updates before flushing a frame, merging
/// consecutive same-segment deltas. Keeps a fast token stream from producing
/// one WebSocket frame per token without adding perceptible latency.
const Duration kTurnRelayCoalesceWindow = Duration(milliseconds: 30);

/// The server half of the live turn relay (`messaging.watchSpaceTurns`).
///
/// Emits wire frames for one space from [registry]:
///   * first a `seed` frame carrying every currently-active turn's full
///     snapshot (`{'kind': 'seed', 'turns': [{'message_id', 'segments'}]}`) —
///     always emitted, even when empty, so the client knows the subscription
///     is established and a reconnect reconciles from the snapshot;
///   * then `updates` frames (`{'kind': 'updates', 'message_id', 'updates'}`),
///     coalesced over [coalesce] with consecutive deltas for the same
///     `(message id, segment index)` merged into one.
///
/// Subscribing and snapshotting happen in one synchronous block, so no update
/// can fall between the seed and the relayed stream (single-threaded event
/// loop: an `apply` either lands in the snapshot or is delivered, never both
/// or neither).
Stream<Map<String, dynamic>> watchSpaceTurnFrames(
  ActiveStreamRegistry registry,
  String spaceId, {
  Duration coalesce = kTurnRelayCoalesceWindow,
}) {
  late StreamController<Map<String, dynamic>> out;
  StreamSubscription<SpaceTurnUpdate>? sub;
  Timer? flushTimer;

  // Buffered updates in arrival order. Per-message ordering is what matters
  // (segment indices are per turn); the flush groups by message id.
  final pending = <(String, TranscriptUpdate)>[];

  void flush() {
    flushTimer?.cancel();
    flushTimer = null;
    if (pending.isEmpty || out.isClosed) {
      return;
    }
    final byMessage = <String, List<Map<String, dynamic>>>{};
    for (final (messageId, update) in pending) {
      (byMessage[messageId] ??= []).add(transcriptUpdateToWire(update));
    }
    pending.clear();
    for (final entry in byMessage.entries) {
      out.add({
        'kind': 'updates',
        'message_id': entry.key,
        'updates': entry.value,
      });
    }
  }

  void enqueue(SpaceTurnUpdate event) {
    final update = event.update;
    // Merge a delta into the immediately preceding delta for the same
    // segment of the same message — the dominant streaming shape.
    if (update is SegmentDelta && pending.isNotEmpty) {
      final (lastId, lastUpdate) = pending.last;
      if (lastId == event.messageId &&
          lastUpdate is SegmentDelta &&
          lastUpdate.index == update.index) {
        pending.last = (
          lastId,
          SegmentDelta(update.index, lastUpdate.delta + update.delta),
        );
        flushTimer ??= Timer(coalesce, flush);
        return;
      }
    }
    pending.add((event.messageId, update));
    // Structural updates (open/close/finish) flush immediately so tool rows
    // and turn completion stay snappy; deltas ride the coalescing window.
    if (update is SegmentDelta) {
      flushTimer ??= Timer(coalesce, flush);
    } else {
      flush();
    }
  }

  out = StreamController<Map<String, dynamic>>(
    onListen: () {
      // Subscribe BEFORE snapshotting (same synchronous block — see doc).
      sub = registry.spaceUpdates(spaceId).listen(enqueue);
      out.add({
        'kind': 'seed',
        'turns': [
          for (final messageId in registry.activeIn(spaceId).toList())
            {
              'message_id': messageId,
              'segments': encodeTranscript(
                registry.snapshot(messageId) ?? const <TranscriptSegment>[],
              ),
            },
        ],
      });
    },
    onCancel: () async {
      flushTimer?.cancel();
      flushTimer = null;
      pending.clear();
      await sub?.cancel();
      sub = null;
      await out.close();
    },
  );
  return out.stream;
}
