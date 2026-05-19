import 'dart:async';
import 'dart:collection';

/// A held lease on a path lock. Call [release] when the task no longer needs
/// the path (idempotent); the next waiter in line then acquires it.
class PathLockHandle {
  PathLockHandle._(this._manager, this.path, this.taskId);

  final PathLockManager _manager;

  /// The locked on-disk path.
  final String path;

  /// The task holding the lease.
  final String taskId;

  bool _released = false;

  /// Releases the lease, handing the path to the next waiter (if any).
  void release() {
    if (_released) {
      return;
    }
    _released = true;
    _manager._release(path, taskId);
  }
}

class _Waiter {
  _Waiter(this.taskId, this.completer);
  final String taskId;
  final Completer<PathLockHandle> completer;
}

/// Serializes access to on-disk paths so two dispatched tasks never operate on
/// the same working directory concurrently. A task that requests a held path is
/// **parked** (its future completes only when the path frees), which is what
/// surfaces as the `waiting_local_directory` task state.
///
/// Pure-Dart and FIFO-fair: waiters acquire in arrival order. It coordinates
/// futures only (no I/O), so it is fully unit-testable.
class PathLockManager {
  final Map<String, String> _holder = {};
  final Map<String, Queue<_Waiter>> _waiters = {};

  /// Whether [path] is currently locked.
  bool isHeld(String path) => _holder.containsKey(path);

  /// The task currently holding [path], or null.
  String? holderOf(String path) => _holder[path];

  /// Acquires [path] for [taskId]. If the path is free the returned future
  /// completes immediately; otherwise the task is parked until the path frees,
  /// and [onWait] is invoked once with the current holder's id so the caller
  /// can surface the `waiting_local_directory` state.
  Future<PathLockHandle> acquire(
    String path,
    String taskId, {
    void Function(String holderTaskId)? onWait,
  }) {
    final holder = _holder[path];
    if (holder == null) {
      _holder[path] = taskId;
      return Future.value(PathLockHandle._(this, path, taskId));
    }
    onWait?.call(holder);
    final completer = Completer<PathLockHandle>();
    (_waiters[path] ??= Queue<_Waiter>()).add(_Waiter(taskId, completer));
    return completer.future;
  }

  void _release(String path, String taskId) {
    if (_holder[path] != taskId) {
      return;
    }
    final queue = _waiters[path];
    if (queue == null || queue.isEmpty) {
      _holder.remove(path);
      _waiters.remove(path);
      return;
    }
    final next = queue.removeFirst();
    _holder[path] = next.taskId;
    if (queue.isEmpty) {
      _waiters.remove(path);
    }
    next.completer.complete(PathLockHandle._(this, path, next.taskId));
  }
}
