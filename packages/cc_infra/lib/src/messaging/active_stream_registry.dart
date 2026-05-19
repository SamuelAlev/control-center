import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';

/// Registry of in-flight agent turns.
///
/// For each active turn (keyed by message id) it maintains:
///   * a broadcast [Stream] of [TranscriptUpdate]s so UI cells can rebuild
///     individually as segments open / receive deltas / close, and
///   * a live [snapshot] of the current segment list so a cell that mounts
///     mid-run (or is recycled by the list and rebuilt) can seed itself with
///     everything streamed so far, then keep applying updates — no lost prefix.
///
/// [register] opens a turn; [apply] broadcasts an update and folds it into the
/// snapshot; [unregister] closes the stream and drops the snapshot.
class ActiveStreamRegistry {
  final Map<String, StreamController<TranscriptUpdate>> _streams = {};
  final Map<String, List<TranscriptSegment>> _snapshots = {};

  /// Live update stream for [messageId], or null when no turn is active.
  Stream<TranscriptUpdate>? updatesFor(String messageId) =>
      _streams[messageId]?.stream;

  /// Current in-flight segments for [messageId], or null when not active.
  ///
  /// Returns a copy so callers can't mutate the registry's state.
  List<TranscriptSegment>? snapshot(String messageId) {
    final snap = _snapshots[messageId];
    return snap == null ? null : List<TranscriptSegment>.unmodifiable(snap);
  }

  /// Whether a turn is currently streaming for [messageId].
  bool isActive(String messageId) => _streams[messageId]?.isClosed == false;

  /// Opens a turn for [messageId].
  void register(String messageId) {
    _streams[messageId] = StreamController<TranscriptUpdate>.broadcast();
    _snapshots[messageId] = <TranscriptSegment>[];
  }

  /// Broadcasts [update] and folds it into the snapshot for [messageId].
  void apply(String messageId, TranscriptUpdate update) {
    final snap = _snapshots[messageId];
    if (snap != null) {
      switch (update) {
        case SegmentOpened():
          if (update.index == snap.length) {
            snap.add(update.segment);
          } else if (update.index >= 0 && update.index < snap.length) {
            snap[update.index] = update.segment;
          }
        case SegmentDelta():
          if (update.index >= 0 && update.index < snap.length) {
            snap[update.index] = _appendDelta(snap[update.index], update.delta);
          }
        case SegmentClosed():
          if (update.index >= 0 && update.index < snap.length) {
            snap[update.index] = update.segment;
          }
        case TurnFinished():
          break;
      }
    }
    _streams[messageId]?.add(update);
  }

  /// Closes the turn for [messageId], releasing the stream and snapshot.
  Future<void> unregister(String messageId) async {
    final controller = _streams.remove(messageId);
    _snapshots.remove(messageId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
  }

  TranscriptSegment _appendDelta(TranscriptSegment segment, String delta) {
    switch (segment) {
      case ReasoningSegment():
        return segment.copyWith(text: segment.text + delta);
      case TextSegment():
        return segment.copyWith(text: segment.text + delta);
      case ToolSegment():
        return segment.copyWith(outputs: segment.outputs + delta);
      case ErrorSegment():
      case ViolationSegment():
        return segment;
    }
  }
}
