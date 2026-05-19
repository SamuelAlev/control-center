// The single-flight, order-preserving queue behind a rig's input surface.
library;

import 'dart:async';

/// Sends one rig action and completes when the server has taken it.
typedef RigActionSender = Future<void> Function(Map<String, dynamic> action);

/// Delivers input actions to a rig, one at a time, in the order they happened.
///
/// **Single-flight is the point.** `rig.act` calls are awaited sequentially so
/// a `left_mouse_up` can never overtake the `mouse_move` before it — with
/// parallel RPCs the guest sees clicks land where the pointer USED to be.
///
/// **Coalescing is what keeps that affordable.** Consecutive actions of the
/// same kind (a fast drag's stream of moves) collapse to the newest one, so a
/// slow link produces a late pointer rather than a growing backlog of stale
/// positions.
class RigActionQueue {
  /// Creates a queue that delivers through [send].
  RigActionQueue({required this.send});

  /// Delivers one action to the server.
  final RigActionSender send;
  final List<Map<String, dynamic>> _pending = [];
  bool _pumping = false;

  /// Actions waiting to go out (diagnostics and tests).
  int get pendingCount => _pending.length;

  Completer<void>? _idle;

  /// Completes once everything queued so far has reached the server.
  ///
  /// The clipboard path needs it and nothing else does: copying means telling
  /// the guest to copy and THEN reading what it put on its clipboard, and
  /// reading before the chord has arrived reads whatever was there before —
  /// which is stale content the user did not ask for, written over their own
  /// clipboard.
  Future<void> drain() {
    if (_pending.isEmpty && !_pumping) {
      return Future<void>.value();
    }
    return (_idle ??= Completer<void>()).future;
  }

  /// Enqueues [action].
  ///
  /// With [coalesce], an identical-verb action already at the tail is REPLACED
  /// rather than followed.
  void add(Map<String, dynamic> action, {bool coalesce = false}) {
    if (coalesce &&
        _pending.isNotEmpty &&
        _pending.last['action'] == action['action']) {
      _pending.last = action;
    } else {
      _pending.add(action);
    }
    unawaited(_pump());
  }

  Future<void> _pump() async {
    if (_pumping) {
      return;
    }
    _pumping = true;
    try {
      // Deliberately NOT gated on a widget's `mounted`: the queue is
      // single-flight and coalesced, so at most a couple of actions are ever
      // in it — and the one that matters at teardown is the keystroke run
      // flushed by the surface's `dispose`. Dropping it would silently
      // swallow keys the user pressed.
      while (_pending.isNotEmpty) {
        final action = _pending.removeAt(0);
        try {
          await send(action);
        } on Object {
          // A refused action (control lost, rig closed) must not wedge the
          // queue; the panel's status header is what reports state changes.
        }
      }
    } finally {
      _pumping = false;
      final idle = _idle;
      _idle = null;
      idle?.complete();
    }
  }
}
