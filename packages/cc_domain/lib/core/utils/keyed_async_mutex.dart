import 'dart:async';

/// A set of async mutexes addressed by key: [run] executes its action only
/// after every earlier [run] for the same key has finished, and actions for
/// different keys never wait on each other.
///
/// FIFO per key. An action that throws still releases the key. A key's entry
/// is dropped once its last waiter finishes, so the map holds only keys that
/// are busy right now.
///
/// Not re-entrant: running the same key from inside its own action deadlocks.
final class KeyedAsyncMutex {
  final Map<Object, Future<void>> _tails = {};

  /// Whether some action for [key] is running or waiting.
  bool isLocked(Object key) => _tails.containsKey(key);

  /// Runs [action] once every earlier action for [key] has completed.
  Future<T> run<T>(Object key, Future<T> Function() action) async {
    final previous = _tails[key];
    final done = Completer<void>();
    final tail = done.future;
    _tails[key] = tail;
    try {
      if (previous != null) {
        await previous;
      }
      return await action();
    } finally {
      done.complete();
      if (identical(_tails[key], tail)) {
        unawaited(_tails.remove(key));
      }
    }
  }
}
