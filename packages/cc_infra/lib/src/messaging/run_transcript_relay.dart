import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/channel_turn_relay.dart'
    show kTurnRelayCoalesceWindow;

/// The server half of one run's activity relay
/// (`agent_run_log.watchRunTranscript`).
///
/// Emits wire frames for a single run from [registry]:
///   * first a `seed` frame — `{'kind': 'seed', 'segments': [...],
///     'live': bool}`. Always emitted, even when empty, so the client knows the
///     subscription is established. `live` is false when the run already
///     finished and [persisted] supplied the segments, which is how ONE op
///     serves both live streaming and replay;
///   * then `updates` frames (`{'kind': 'updates', 'updates': [...]}`),
///     coalesced over [coalesce] with consecutive deltas for the same segment
///     index merged into one.
///
/// Run-scoped, so no id rides each frame — the subscription already names the
/// run. Subscribing and snapshotting happen in one synchronous block, so no
/// update can fall between the seed and the relayed stream.
///
/// Also watches [ActiveStreamRegistry.registrations]: a subscription opened in
/// the window before the run registers (the tab can be clicked the instant the
/// row appears) adopts the run and re-seeds when it goes live, instead of
/// silently receiving nothing.
Stream<Map<String, dynamic>> watchRunTranscriptFrames(
  ActiveStreamRegistry registry,
  String runId, {
  List<TranscriptSegment> persisted = const [],
  Duration coalesce = kTurnRelayCoalesceWindow,
}) {
  late StreamController<Map<String, dynamic>> out;
  StreamSubscription<TranscriptUpdate>? sub;
  StreamSubscription<String>? registrationSub;
  Timer? flushTimer;
  var seeded = false;

  final pending = <TranscriptUpdate>[];

  void flush() {
    flushTimer?.cancel();
    flushTimer = null;
    if (pending.isEmpty || out.isClosed) {
      return;
    }
    final updates = [for (final u in pending) transcriptUpdateToWire(u)];
    pending.clear();
    out.add({'kind': 'updates', 'updates': updates});
  }

  void enqueue(TranscriptUpdate update) {
    // Merge a delta into the immediately preceding delta for the same segment —
    // the dominant streaming shape.
    if (update is SegmentDelta && pending.isNotEmpty) {
      final last = pending.last;
      if (last is SegmentDelta && last.index == update.index) {
        pending.last = SegmentDelta(update.index, last.delta + update.delta);
        flushTimer ??= Timer(coalesce, flush);
        return;
      }
    }
    pending.add(update);
    // Structural updates (open/close/finish) flush immediately so tool rows and
    // completion stay snappy; deltas ride the coalescing window.
    if (update is SegmentDelta) {
      flushTimer ??= Timer(coalesce, flush);
    } else {
      flush();
    }
  }

  /// Subscribes to the live stream and emits the seed in one synchronous block.
  void attachLive() {
    sub = registry
        .updatesFor(runId)
        ?.listen(
          enqueue,
          // The registry closes the stream when the run finishes; complete the
          // subscription rather than leaving the client waiting forever.
          onDone: () {
            flush();
            if (!out.isClosed) {
              out.close();
            }
          },
        );
    out.add({
      'kind': 'seed',
      'segments': encodeTranscript(
        registry.snapshot(runId) ?? const <TranscriptSegment>[],
      ),
      'live': true,
    });
    seeded = true;
  }

  out = StreamController<Map<String, dynamic>>(
    onListen: () {
      if (registry.isActive(runId)) {
        attachLive();
        return;
      }
      // Not streaming: replay the persisted transcript. Still watch for a
      // registration, because the run may go live a beat later.
      registrationSub = registry.registrations
          .where((id) => id == runId)
          .listen((_) {
            if (seeded && sub != null) {
              return;
            }
            attachLive();
          });
      out.add({
        'kind': 'seed',
        'segments': encodeTranscript(persisted),
        'live': false,
      });
      seeded = true;
    },
    onCancel: () async {
      flushTimer?.cancel();
      flushTimer = null;
      pending.clear();
      await sub?.cancel();
      sub = null;
      await registrationSub?.cancel();
      registrationSub = null;
      if (!out.isClosed) {
        await out.close();
      }
    },
  );
  return out.stream;
}
