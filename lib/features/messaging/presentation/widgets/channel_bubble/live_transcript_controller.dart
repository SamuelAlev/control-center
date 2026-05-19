import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_infra/cc_infra_web.dart';
import 'package:flutter/foundation.dart';

/// Fans one turn's [ActiveStreamRegistry] update stream out into two
/// [ValueNotifier] pulses so an agent-turn cell can rebuild *surgically*
/// instead of `setState`-ing the whole turn per token:
///
///   * [structure] bumps on segment open/close, turn finish, and turn
///     (re-)registration — anything that changes the row list. The turn body
///     re-reads the registry snapshot under a `ValueListenableBuilder` on it.
///   * [tail] bumps on every text delta. Only the still-open row(s) listen,
///     re-reading just their own segment via `segmentAt` — so a delta costs
///     one small row rebuild at frame cadence, not a whole-turn rebuild.
///
/// The controller also listens to [ActiveStreamRegistry.registrations] so a
/// cell mounted before its turn goes live (the list row lands first) or across
/// a relay reconnect re-seed adopts the new stream the moment it opens.
class LiveTranscriptController {
  /// Creates a controller for [messageId], attaching to the registry's stream
  /// if the turn is already live and adopting it later if not.
  LiveTranscriptController(this._registry, this.messageId) {
    _attach();
    _regSub = _registry.registrations.listen((id) {
      if (id == messageId) {
        _attach();
        structure.value++;
      }
    });
  }

  final ActiveStreamRegistry _registry;

  /// The agent-turn message this controller follows.
  final String messageId;

  /// Bumped when the segment list's shape changes (open/close/finish/register)
  /// — and once more when the live stream ends, so the body rebuilds onto the
  /// persisted/cached path.
  final ValueNotifier<int> structure = ValueNotifier(0);

  /// Bumped on every streamed text delta. Listeners re-read their segment via
  /// [segmentAt]; Flutter coalesces bumps into one rebuild per frame, so the
  /// (lazy) segment materialization runs at frame cadence, not delta cadence.
  final ValueNotifier<int> tail = ValueNotifier(0);

  StreamSubscription<TranscriptUpdate>? _sub;
  StreamSubscription<String>? _regSub;

  /// Whether the turn is currently streaming.
  bool get isLive => _registry.isActive(messageId);

  /// The live segment snapshot, or null when the turn is not active.
  List<TranscriptSegment>? get snapshot => _registry.snapshot(messageId);

  /// The current state of the segment at [index], materializing only it.
  TranscriptSegment? segmentAt(int index) =>
      _registry.segmentAt(messageId, index);

  void _attach() {
    _sub?.cancel();
    _sub = _registry
        .updatesFor(messageId)
        ?.listen(_onUpdate, onDone: () => structure.value++);
  }

  void _onUpdate(TranscriptUpdate update) {
    switch (update) {
      case SegmentDelta():
        tail.value++;
      case SegmentOpened():
      case SegmentClosed():
      case TurnFinished():
        structure.value++;
    }
  }

  /// Cancels the subscriptions and disposes the notifiers.
  void dispose() {
    _sub?.cancel();
    _regSub?.cancel();
    structure.dispose();
    tail.dispose();
  }
}
