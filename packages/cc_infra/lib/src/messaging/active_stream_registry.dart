import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';

/// A single relayed turn event on a channel stream: which in-flight message
/// the update belongs to, plus the update itself.
typedef ChannelTurnUpdate = ({String messageId, TranscriptUpdate update});

/// Registry of in-flight agent turns.
///
/// For each active turn (keyed by message id) it maintains:
///   * a broadcast [Stream] of [TranscriptUpdate]s so UI cells can rebuild
///     individually as segments open / receive deltas / close and
///   * a live [snapshot] of the current segment list so a cell that mounts
///     mid-run (or is recycled by the list and rebuilt) can seed itself with
///     everything streamed so far, then keep applying updates — no lost prefix.
///
/// It also maintains a per-channel index + broadcast so the server's live turn
/// relay (`messaging.watchChannelTurns`) can seed a late subscriber with every
/// active turn in a channel and then forward updates as they happen. The same
/// class runs on the thin client, which [seed]s it from relay frames.
///
/// Delta text is accumulated in per-segment [StringBuffer]s and materialized
/// into segments lazily on read ([snapshot] / [segmentAt]), so a long
/// streaming segment costs O(delta) per delta instead of O(accumulated text)
/// (the old `text + delta` concat was quadratic over a turn).
///
/// [register] opens a turn; [apply] broadcasts an update and folds it into the
/// snapshot; [unregister] closes the stream and drops the snapshot.
class ActiveStreamRegistry {
  final Map<String, StreamController<TranscriptUpdate>> _streams = {};
  final Map<String, List<TranscriptSegment>> _snapshots = {};

  // Channel index for the live turn relay.
  final Map<String, Set<String>> _byChannel = {};
  final Map<String, String> _channelOf = {};
  final Map<String, StreamController<ChannelTurnUpdate>> _channelStreams = {};

  // Lazy delta accumulation: per message, per open segment index.
  final Map<String, Map<int, StringBuffer>> _openBufs = {};
  final Map<String, Set<int>> _dirty = {};

  // Memoized unmodifiable snapshot views, keyed by a per-message revision so
  // per-rebuild snapshot() calls don't re-copy an unchanged list.
  final Map<String, int> _revision = {};
  final Map<String, (int, List<TranscriptSegment>)> _views = {};

  // Message ids as they (re-)register, so a cell built before its turn went
  // live (or across a reconnect re-seed) can adopt the new stream.
  final StreamController<String> _registrations =
      StreamController<String>.broadcast();

  /// Message ids as turns (re-)register — including [seed]s. A UI cell whose
  /// message is not (yet) active listens here to pick up the stream the
  /// moment it opens, instead of relying on an unrelated rebuild.
  Stream<String> get registrations => _registrations.stream;

  /// Live update stream for [messageId], or null when no turn is active.
  Stream<TranscriptUpdate>? updatesFor(String messageId) =>
      _streams[messageId]?.stream;

  /// Current in-flight segments for [messageId], or null when not active.
  ///
  /// Returns an unmodifiable view; the same instance is returned until the
  /// next [apply] so per-rebuild reads don't allocate.
  List<TranscriptSegment>? snapshot(String messageId) {
    final snap = _snapshots[messageId];
    if (snap == null) {
      return null;
    }
    final revision = _revision[messageId] ?? 0;
    final cached = _views[messageId];
    if (cached != null && cached.$1 == revision) {
      return cached.$2;
    }
    _materialize(messageId);
    final view = List<TranscriptSegment>.unmodifiable(snap);
    _views[messageId] = (revision, view);
    return view;
  }

  /// The current state of the segment at [index] for [messageId], or null.
  ///
  /// Materializes only that segment — the cheap read for a live tail cell
  /// that updates at delta cadence.
  TranscriptSegment? segmentAt(String messageId, int index) {
    final snap = _snapshots[messageId];
    if (snap == null || index < 0 || index >= snap.length) {
      return null;
    }
    if (_dirty[messageId]?.contains(index) ?? false) {
      _materializeIndex(messageId, index);
    }
    return snap[index];
  }

  /// Whether a turn is currently streaming for [messageId].
  bool isActive(String messageId) => _streams[messageId]?.isClosed == false;

  /// Message ids of the turns currently streaming in [channelId].
  Iterable<String> activeIn(String channelId) =>
      _byChannel[channelId] ?? const <String>{};

  /// Broadcast of every active turn's updates in [channelId], for the relay.
  ///
  /// The stream survives individual turns (a channel can stream several turns
  /// over a subscription's lifetime) and is torn down when the last listener
  /// cancels and no turn is active.
  Stream<ChannelTurnUpdate> channelUpdates(String channelId) =>
      _channelController(channelId).stream;

  StreamController<ChannelTurnUpdate> _channelController(String channelId) {
    return _channelStreams.putIfAbsent(channelId, () {
      late final StreamController<ChannelTurnUpdate> controller;
      controller = StreamController<ChannelTurnUpdate>.broadcast(
        onCancel: () {
          // Last listener gone: drop the controller unless turns are active
          // (they would still need to broadcast to a future subscriber).
          if (!controller.hasListener &&
              (_byChannel[channelId]?.isEmpty ?? true)) {
            _channelStreams.remove(channelId);
            controller.close();
          }
        },
      );
      return controller;
    });
  }

  /// Opens a turn for [messageId]. [channelId] indexes the turn for the
  /// channel relay; the thin client may omit it (it folds per channel anyway).
  void register(String messageId, {String? channelId}) {
    _streams[messageId] = StreamController<TranscriptUpdate>.broadcast();
    _snapshots[messageId] = <TranscriptSegment>[];
    _openBufs[messageId] = <int, StringBuffer>{};
    _dirty[messageId] = <int>{};
    _revision[messageId] = 0;
    if (channelId != null) {
      _channelOf[messageId] = channelId;
      (_byChannel[channelId] ??= <String>{}).add(messageId);
    }
    _registrations.add(messageId);
  }

  /// Registers [messageId] pre-populated with [segments] — how a thin client
  /// adopts a turn already in flight from a relay seed frame.
  void seed(
    String messageId,
    List<TranscriptSegment> segments, {
    String? channelId,
  }) {
    register(messageId, channelId: channelId);
    _snapshots[messageId] = List<TranscriptSegment>.of(segments);
  }

  /// Broadcasts [update] and folds it into the snapshot for [messageId].
  void apply(String messageId, TranscriptUpdate update) {
    final snap = _snapshots[messageId];
    if (snap != null) {
      _revision[messageId] = (_revision[messageId] ?? 0) + 1;
      switch (update) {
        case SegmentOpened():
          if (update.index == snap.length) {
            snap.add(update.segment);
          } else if (update.index >= 0 && update.index < snap.length) {
            snap[update.index] = update.segment;
          } else {
            break;
          }
          // Fresh accumulation buffer seeded with the opened segment's text.
          _openBufs[messageId]?[update.index] = StringBuffer(
            _textOf(update.segment),
          );
          _dirty[messageId]?.remove(update.index);
        case SegmentDelta():
          if (update.index >= 0 && update.index < snap.length) {
            final bufs = _openBufs[messageId];
            if (bufs != null) {
              // A missing buffer means the turn was seeded mid-flight; adopt
              // the segment's current text as the accumulated prefix.
              (bufs[update.index] ??= StringBuffer(
                _textOf(snap[update.index]),
              )).write(update.delta);
              _dirty[messageId]?.add(update.index);
            }
          }
        case SegmentClosed():
          if (update.index >= 0 && update.index < snap.length) {
            snap[update.index] = update.segment;
            _openBufs[messageId]?.remove(update.index);
            _dirty[messageId]?.remove(update.index);
          }
        case TurnFinished():
          break;
      }
    }
    _streams[messageId]?.add(update);
    final channelId = _channelOf[messageId];
    // Broadcast fan-out controllers are owned by the registry (closed in
    // `unregister`); read through the map so they aren't treated as local sinks.
    if (channelId != null) {
      if (_channelStreams[channelId] case final controller?
          when !controller.isClosed) {
        controller.add((messageId: messageId, update: update));
      }
    }
  }

  /// Closes the turn for [messageId], releasing the stream and snapshot.
  Future<void> unregister(String messageId) async {
    final controller = _streams.remove(messageId);
    _snapshots.remove(messageId);
    _openBufs.remove(messageId);
    _dirty.remove(messageId);
    _views.remove(messageId);
    _revision.remove(messageId);
    final channelId = _channelOf.remove(messageId);
    if (channelId != null) {
      final set = _byChannel[channelId];
      set?.remove(messageId);
      if (set != null && set.isEmpty) {
        _byChannel.remove(channelId);
        final channel = _channelStreams[channelId];
        if (channel != null && !channel.hasListener) {
          _channelStreams.remove(channelId);
          await channel.close();
        }
      }
    }
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
  }

  void _materialize(String messageId) {
    final dirty = _dirty[messageId];
    if (dirty == null || dirty.isEmpty) {
      return;
    }
    for (final index in dirty.toList()) {
      _materializeIndex(messageId, index);
    }
  }

  void _materializeIndex(String messageId, int index) {
    final snap = _snapshots[messageId];
    final buf = _openBufs[messageId]?[index];
    if (snap == null || buf == null || index < 0 || index >= snap.length) {
      _dirty[messageId]?.remove(index);
      return;
    }
    final text = buf.toString();
    snap[index] = switch (snap[index]) {
      final ReasoningSegment s => s.copyWith(text: text),
      final TextSegment s => s.copyWith(text: text),
      final ToolSegment s => s.copyWith(outputs: text),
      final ErrorSegment s => s,
      final ViolationSegment s => s,
    };
    _dirty[messageId]?.remove(index);
  }

  static String _textOf(TranscriptSegment segment) => switch (segment) {
    ReasoningSegment(:final text) => text,
    TextSegment(:final text) => text,
    ToolSegment(:final outputs) => outputs,
    ErrorSegment() || ViolationSegment() => '',
  };
}
