import 'dart:async';
import 'dart:collection';

import 'package:cc_domain/core/utils/cancellation_token.dart';

/// A counting semaphore for limiting concurrency across independently
/// scheduled async work.
///
/// A `max <= 0` (or any non-finite input) means **unbounded** — every
/// [acquire] resolves immediately — matching a "0 = unlimited" concurrency
/// setting. Holders call [release] when their slot frees up; queued waiters are
/// admitted in FIFO order.
///
/// The ceiling can be changed in place via [resize] without replacing the
/// instance, so in-flight slots stay counted and a runtime limit change can
/// never push concurrency past the cap.
class Semaphore {
  /// Creates a semaphore admitting up to [max] concurrent holders.
  ///
  /// A `max <= 0` or non-finite [max] makes the semaphore unbounded: every
  /// [acquire] resolves immediately and [release] is a no-op on capacity.
  Semaphore(int max) {
    _setMax(max);
  }

  final Queue<_Waiter> _queue = Queue<_Waiter>();
  int _current = 0;
  int _max = 0;
  bool _unbounded = false;

  /// The number of holders currently occupying a slot.
  int get current => _current;

  /// The current ceiling, or `null` when the semaphore is unbounded.
  int? get max => _unbounded ? null : _max;

  /// Whether this semaphore admits an unlimited number of holders.
  bool get isUnbounded => _unbounded;

  /// Resolves when a slot is available.
  ///
  /// If [token] is already cancelled this throws [CancelledException]
  /// synchronously (well, on the returned future) without taking a slot. If
  /// the token cancels while this waiter is queued, the waiter is removed from
  /// the queue and the future completes with [CancelledException] — so a later
  /// [release] never resolves an abandoned waiter and permanently shrinks
  /// effective concurrency.
  Future<void> acquire([CancellationToken token = CancellationToken.none]) {
    if (token.isCancelled) {
      return Future<void>.error(CancelledException(token.reason));
    }
    if (_unbounded || _current < _max) {
      _current++;
      return Future<void>.value();
    }

    final completer = Completer<void>();
    final waiter = _Waiter(completer);
    _queue.add(waiter);

    if (token != CancellationToken.none) {
      // When the token cancels while still queued, drop the waiter so a later
      // release() does not resolve it (which would leak a slot).
      token.whenCancelled.then((_) {
        if (waiter.settled) {
          return;
        }
        waiter.settled = true;
        _queue.remove(waiter);
        if (!completer.isCompleted) {
          completer.completeError(CancelledException(token.reason));
        }
      });
    }

    return completer.future;
  }

  /// Releases a held slot, admitting the next FIFO waiter if one fits under the
  /// (possibly just-lowered) ceiling.
  void release() {
    if (_current > 0) {
      _current--;
    }
    _admitWaiters();
  }

  /// Adjusts the maximum concurrency in place.
  ///
  /// Raising the ceiling immediately admits queued waiters that now fit;
  /// lowering it lets in-flight holders drain naturally (new acquires keep
  /// blocking until [current] falls below the new max). A `max <= 0` or
  /// non-finite value switches the semaphore to unbounded.
  void resize(int max) {
    _setMax(max);
    _admitWaiters();
  }

  void _setMax(int max) {
    if (max <= 0) {
      _unbounded = true;
      _max = 0;
      return;
    }
    _unbounded = false;
    _max = max;
  }

  /// Admits as many queued waiters as currently fit under the ceiling.
  void _admitWaiters() {
    while (_unbounded || _current < _max) {
      if (_queue.isEmpty) {
        return;
      }
      final next = _queue.removeFirst();
      if (next.settled) {
        // Already cancelled and removed (or about to be); skip it.
        continue;
      }
      next.settled = true;
      _current++;
      if (!next.completer.isCompleted) {
        next.completer.complete();
      }
    }
  }
}

/// A single queued `acquire` waiter, tracked so cancellation and admission can
/// each claim it exactly once.
class _Waiter {
  _Waiter(this.completer);

  final Completer<void> completer;
  bool settled = false;
}
