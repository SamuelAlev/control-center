import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:cc_harness/cancellation.dart';

/// The server-wide runner slots, shared fairly between workspaces and,
/// within a workspace, between run trees; and the pool of runners parked on
/// a person, shared between workspaces the same way.
///
/// A run tree is a run together with its subagents: their scripts are one
/// tree's (`CodeExecutionRequest.runTree`). One tree holds at most
/// [treeShare] slots, half its workspace's share, so a run cannot take its
/// whole workspace's share by spreading scripts over subagents.
///
/// A slot is granted at once while the cap has room, the workspace and the
/// tree are under their shares and no other script that could use the slot
/// is waiting. Otherwise the script waits; a freed slot goes to the next
/// workspace in turn that has a waiting script with room in its workspace's
/// and its tree's share, its oldest such script first (a script whose tree
/// holds its share lets later scripts of other trees pass), and that
/// workspace moves to the back of the turn.
///
/// A script holds its slots through one [ScriptSlot]; nothing else calls
/// [acquire], [release], [tryPark] or [unpark].
class CodeRunnerSlots {
  /// Creates the slots for at most [cap] scripts running at once.
  CodeRunnerSlots(this.cap)
    : parkedCap = 4 * cap,
      workspaceShare = shareOf(cap),
      treeShare = math.max(1, shareOf(cap) ~/ 2),
      parkedShare = shareOf(4 * cap);

  /// What one workspace may hold of [total]: the total less a quarter of it
  /// (at least one), so other workspaces always find room; all of it when it
  /// is 1.
  static int shareOf(int total) =>
      total >= 2 ? total - math.max(1, total ~/ 4) : total;

  /// The most scripts running at once.
  final int cap;

  /// The most runners parked on a person without a slot: four times [cap].
  final int parkedCap;

  /// The most slots one workspace holds at once.
  final int workspaceShare;

  /// The most slots one run tree holds at once: half of [workspaceShare],
  /// at least one.
  final int treeShare;

  /// The most parked places one workspace holds at once.
  final int parkedShare;

  int _used = 0;
  int _parked = 0;
  bool _closed = false;
  final Map<String, int> _byWorkspace = {};
  final Map<String, int> _byTree = {};
  final Map<String, int> _parkedByWorkspace = {};

  /// Waiting scripts by workspace, in turn order, each queue oldest first.
  final LinkedHashMap<String, List<_Waiter>> _waiting = LinkedHashMap();

  /// Slots held now.
  int get used => _used;

  /// Runners parked now.
  int get parked => _parked;

  /// Slots [workspaceId] holds now.
  int heldBy(String workspaceId) => _byWorkspace[workspaceId] ?? 0;

  /// Slots the run tree [tree] holds now.
  int heldByTree(String tree) => _byTree[tree] ?? 0;

  /// Parked places [workspaceId] holds now.
  int parkedBy(String workspaceId) => _parkedByWorkspace[workspaceId] ?? 0;

  /// Scripts waiting for a slot now.
  int get waiting => _waiting.values.fold(0, (sum, q) => sum + q.length);

  /// Whether nothing is held, parked or waited for, in any workspace.
  bool get isIdle =>
      _used == 0 &&
      _parked == 0 &&
      _byWorkspace.isEmpty &&
      _byTree.isEmpty &&
      _parkedByWorkspace.isEmpty &&
      _waiting.isEmpty;

  /// Whether the server is shutting down: no slot is granted any more.
  bool get closed => _closed;

  bool _hasRoom(String workspaceId, String tree) =>
      _used < cap &&
      heldBy(workspaceId) < workspaceShare &&
      heldByTree(tree) < treeShare;

  /// A slot for a script of [workspaceId] and run tree [tree]: true once
  /// granted, false when [timeout] passes, [cancel] fires or the server
  /// shuts down first. A waiter that gives up keeps no place in the queue.
  Future<bool> acquire(
    String workspaceId, {
    required String tree,
    Duration? timeout,
    CancellationToken cancel = CancellationToken.none,
  }) {
    if (cancel.isCancelled || _closed) {
      return Future.value(false);
    }
    if (_hasRoom(workspaceId, tree) && _nextEligible() == null) {
      _grant(workspaceId, tree);
      return Future.value(true);
    }
    final waiter = _Waiter(tree);
    (_waiting[workspaceId] ??= []).add(waiter);
    void giveUp() {
      if (!waiter.done.isCompleted) {
        final queue = _waiting[workspaceId];
        queue?.remove(waiter);
        if (queue != null && queue.isEmpty) {
          _waiting.remove(workspaceId);
        }
        waiter.done.complete(false);
        // A waiter that gave up may have been the one blocking another
        // workspace's turn.
        _dispatch();
      }
    }

    final timer = timeout == null ? null : Timer(timeout, giveUp);
    unawaited(cancel.whenCancelled.then((_) => giveUp()));
    return waiter.done.future.whenComplete(() => timer?.cancel());
  }

  void _grant(String workspaceId, String tree) {
    _used++;
    _byWorkspace[workspaceId] = heldBy(workspaceId) + 1;
    _byTree[tree] = heldByTree(tree) + 1;
  }

  /// The first workspace in turn with a waiting script that has room, and
  /// that workspace's oldest such script.
  (String, _Waiter)? _nextEligible() {
    for (final MapEntry(key: workspaceId, value: queue) in _waiting.entries) {
      for (final waiter in queue) {
        if (_hasRoom(workspaceId, waiter.tree)) {
          return (workspaceId, waiter);
        }
      }
    }
    return null;
  }

  void _dispatch() {
    while (true) {
      final next = _nextEligible();
      if (next == null) {
        return;
      }
      final (workspaceId, waiter) = next;
      final queue = _waiting.remove(workspaceId)!..remove(waiter);
      if (queue.isNotEmpty) {
        // To the back of the turn.
        _waiting[workspaceId] = queue;
      }
      _grant(workspaceId, waiter.tree);
      waiter.done.complete(true);
    }
  }

  /// Gives back a slot a script of [workspaceId] and run tree [tree] holds.
  void release(String workspaceId, String tree) {
    final held = heldBy(workspaceId);
    final heldByItsTree = heldByTree(tree);
    if (held <= 0 || heldByItsTree <= 0) {
      throw StateError('$workspaceId holds no runner slot to release');
    }
    _used--;
    _decrement(_byWorkspace, workspaceId, held);
    _decrement(_byTree, tree, heldByItsTree);
    _dispatch();
  }

  /// Takes a parked place for [workspaceId], or says there is none: the pool
  /// is full, or the workspace holds its share of it.
  bool tryPark(String workspaceId) {
    if (_parked >= parkedCap || parkedBy(workspaceId) >= parkedShare) {
      return false;
    }
    _parked++;
    _parkedByWorkspace[workspaceId] = parkedBy(workspaceId) + 1;
    return true;
  }

  /// Gives back a parked place [workspaceId] holds.
  void unpark(String workspaceId) {
    final held = parkedBy(workspaceId);
    if (held <= 0) {
      throw StateError('$workspaceId holds no parked place to give back');
    }
    _parked--;
    _decrement(_parkedByWorkspace, workspaceId, held);
  }

  static void _decrement(Map<String, int> counts, String key, int held) {
    if (held == 1) {
      counts.remove(key);
    } else {
      counts[key] = held - 1;
    }
  }

  /// Refuses every waiting script and every later one: the server is
  /// shutting down.
  void closeAll() {
    _closed = true;
    final waiting = [for (final q in _waiting.values) ...q];
    _waiting.clear();
    for (final waiter in waiting) {
      if (!waiter.done.isCompleted) {
        waiter.done.complete(false);
      }
    }
  }
}

/// A script waiting for a slot.
class _Waiter {
  _Waiter(this.tree);

  final String tree;
  final Completer<bool> done = Completer();
}

/// One script's hold on the [CodeRunnerSlots], from admission to its end.
///
/// The script holds a slot, or (while it waits on a person and the pool has
/// room) a parked place instead, or nothing once it has ended. At most one
/// re-acquire is in flight at a time, so the bookkeeping cannot come apart
/// however the script's waits interleave: a slot granted when the script
/// no longer wants it (it already holds one, a new wait began, it ended) is
/// given straight back, and [end] gives back exactly what is held.
class ScriptSlot {
  /// Creates the hold of one script of [workspaceId] and run [tree]; it
  /// holds nothing yet.
  ScriptSlot(this._slots, this.workspaceId, this.tree);

  final CodeRunnerSlots _slots;

  /// The script's workspace.
  final String workspaceId;

  /// The script's run tree ([CodeRunnerSlots.treeShare]).
  final String tree;

  _Hold _hold = _Hold.none;
  bool _waiting = false;
  bool _ended = false;
  bool _reacquiring = false;
  CancellationTokenSource? _reacquireCancel;
  Completer<void>? _back;

  /// Whether the script holds a runner slot now.
  bool get holding => _hold == _Hold.slot;

  /// Whether the script's runner is parked now, holding no slot.
  bool get parked => _hold == _Hold.parked;

  /// Whether a re-acquire is in flight.
  bool get reacquiring => _reacquiring;

  /// Admits the script: true once it holds a slot, false when [timeout]
  /// passes, [cancel] fires or the server shuts down first.
  Future<bool> admit({
    Duration? timeout,
    CancellationToken cancel = CancellationToken.none,
  }) async {
    if (_ended || _hold != _Hold.none) {
      throw StateError('a script is admitted once');
    }
    final got = await _slots.acquire(
      workspaceId,
      tree: tree,
      timeout: timeout,
      cancel: cancel,
    );
    if (!got) {
      return false;
    }
    if (_ended) {
      _slots.release(workspaceId, tree);
      return false;
    }
    _hold = _Hold.slot;
    return true;
  }

  /// The script started waiting on a person: its slot goes to the next
  /// script while the pool, and the workspace's share of it, have room;
  /// otherwise it keeps the slot while it waits. A re-acquire still in
  /// flight is withdrawn.
  void waitBegan() {
    if (_ended) {
      return;
    }
    _waiting = true;
    _reacquireCancel?.cancel();
    if (_hold == _Hold.slot && _slots.tryPark(workspaceId)) {
      _hold = _Hold.parked;
      _slots.release(workspaceId, tree);
    }
  }

  /// The script's last wait on a person ended: a parked script asks for a
  /// slot back, and [back] completes once it has one.
  void waitEnded() {
    if (_ended) {
      return;
    }
    _waiting = false;
    if (_hold == _Hold.parked && !_reacquiring) {
      _reacquire();
    }
  }

  /// Completes when the script may run: at once while it holds a slot (or
  /// kept it through its wait), else when it has a slot back or has ended.
  Future<void> get back {
    if (_ended || _hold != _Hold.parked) {
      return Future.value();
    }
    return (_back ??= Completer<void>()).future;
  }

  /// Ends the hold: gives back the slot or the parked place, once, and
  /// withdraws a re-acquire in flight (a grant that already landed is given
  /// back when it arrives).
  void end() {
    if (_ended) {
      return;
    }
    _ended = true;
    _reacquireCancel?.cancel();
    switch (_hold) {
      case _Hold.slot:
        _slots.release(workspaceId, tree);
      case _Hold.parked:
        _slots.unpark(workspaceId);
      case _Hold.none:
        break;
    }
    _hold = _Hold.none;
    _completeBack();
  }

  void _reacquire() {
    _reacquiring = true;
    final cancel = _reacquireCancel = CancellationTokenSource();
    unawaited(
      _slots
          .acquire(workspaceId, tree: tree, cancel: cancel.token)
          .then(_granted),
    );
  }

  void _granted(bool got) {
    _reacquiring = false;
    _reacquireCancel = null;
    if (got) {
      if (_ended || _hold != _Hold.parked || _waiting) {
        // Not wanted any more: the script ended, holds a slot, or waits on
        // a person again (and stays parked).
        _slots.release(workspaceId, tree);
        return;
      }
      _hold = _Hold.slot;
      _slots.unpark(workspaceId);
      _completeBack();
      return;
    }
    // Not granted: withdrawn by a new wait or the end, or the server is
    // shutting down.
    if (_ended) {
      return;
    }
    if (_slots.closed) {
      _completeBack();
      return;
    }
    if (_hold == _Hold.parked && !_waiting) {
      // The wait that withdrew it has ended meanwhile.
      _reacquire();
    }
  }

  void _completeBack() {
    final back = _back;
    _back = null;
    if (back != null && !back.isCompleted) {
      back.complete();
    }
  }
}

enum _Hold { none, slot, parked }

/// A counting semaphore with a FIFO queue.
class CountingSemaphore {
  /// Creates a semaphore with [cap] permits.
  CountingSemaphore(this.cap);

  /// The permits.
  final int cap;
  int _used = 0;
  final Queue<Completer<bool>> _waiters = Queue();

  /// A permit: true once granted, false when [cancel] fires first.
  Future<bool> acquire({CancellationToken cancel = CancellationToken.none}) {
    if (cancel.isCancelled) {
      return Future.value(false);
    }
    if (_used < cap && _waiters.isEmpty) {
      _used++;
      return Future.value(true);
    }
    final waiter = Completer<bool>();
    _waiters.add(waiter);
    unawaited(
      cancel.whenCancelled.then((_) {
        if (!waiter.isCompleted) {
          _waiters.remove(waiter);
          waiter.complete(false);
        }
      }),
    );
    return waiter.future;
  }

  /// Gives back a permit.
  void release() {
    _used--;
    while (_waiters.isNotEmpty && _used < cap) {
      final next = _waiters.removeFirst();
      if (!next.isCompleted) {
        _used++;
        next.complete(true);
      }
    }
  }
}
