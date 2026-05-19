import 'dart:convert';

/// One mutation held while the client is offline (PRD 19 §11). It carries the
/// idempotency key minted when the operator committed the intent, so a
/// reconnect flush applies exactly once (dedup at the server write ledger) —
/// no duplicates, no lost intent.
class QueuedMutation {
  /// Creates a [QueuedMutation].
  const QueuedMutation({
    required this.idempotencyKey,
    required this.op,
    required this.args,
    required this.enqueuedAtEpochMs,
    this.attempts = 0,
  });

  /// Deserializes from persisted JSON.
  factory QueuedMutation.fromJson(Map<String, dynamic> json) => QueuedMutation(
    idempotencyKey: json['k'] as String,
    op: json['op'] as String,
    args: (json['args'] as Map?)?.cast<String, dynamic>() ?? const {},
    enqueuedAtEpochMs: (json['at'] as num?)?.toInt() ?? 0,
    attempts: (json['n'] as num?)?.toInt() ?? 0,
  );

  /// The per-logical-action idempotency key (stable across the flush).
  final String idempotencyKey;

  /// The op name (e.g. `tickets.patch`).
  final String op;

  /// The op args (already workspace-scoped by the caller).
  final Map<String, dynamic> args;

  /// When it was enqueued (epoch ms) — FIFO order + staleness display.
  final int enqueuedAtEpochMs;

  /// How many flush attempts this mutation has already failed. Persisted so a
  /// mutation that fails on every boot still reaches the dead-letter ceiling
  /// instead of blocking the queue head forever.
  final int attempts;

  /// This mutation with one more recorded failed attempt.
  QueuedMutation withFailedAttempt() => QueuedMutation(
    idempotencyKey: idempotencyKey,
    op: op,
    args: args,
    enqueuedAtEpochMs: enqueuedAtEpochMs,
    attempts: attempts + 1,
  );

  /// Serializes for persistence.
  Map<String, dynamic> toJson() => {
    'k': idempotencyKey,
    'op': op,
    'args': args,
    'at': enqueuedAtEpochMs,
    if (attempts > 0) 'n': attempts,
  };

  /// Approximate serialized size in bytes, for the byte cap.
  ///
  /// Memoized. A `QueuedMutation` is immutable (a failed attempt makes a NEW
  /// one via `withFailedAttempt`), and the queue's running total asks every
  /// entry for this — so without the memo, measuring the queue re-encoded
  /// every entry in it. An `Expando` rather than a `late final` field because
  /// the class keeps its `const` constructor.
  int get sizeBytes =>
      _sizeBytesMemo[this] ??= utf8.encode(jsonEncode(toJson())).length;
}

/// Per-mutation serialized-size memo, kept off the type so it stays `const`
/// constructible and a dropped mutation is still collected.
final Expando<int> _sizeBytesMemo = Expando<int>('queuedMutationSizeBytes');

/// A mutation the queue gave up on, with the error that killed it. Surfaced to
/// the operator instead of being silently swallowed — the queue's contract is
/// "never lose intent SILENTLY", not "never fail".
class DeadLetteredMutation {
  /// Creates a [DeadLetteredMutation].
  const DeadLetteredMutation(this.mutation, this.error, this.permanent);

  /// The mutation that was dropped.
  final QueuedMutation mutation;

  /// The last error the server/transport returned for it.
  final Object error;

  /// Whether it was dropped because the failure was classified permanent
  /// (`false` = it simply exhausted its retry budget).
  final bool permanent;
}

/// Thrown when a mutation would exceed a queue cap. The queue REFUSES the new
/// mutation with a clear reason (surfaced to the operator) rather than silently
/// dropping the oldest — never lose intent (PRD 19 §11 "bounded and honest").
class OfflineQueueFullException implements Exception {
  /// Creates an [OfflineQueueFullException].
  const OfflineQueueFullException(this.reason);

  /// Human-readable reason ("offline queue is full (200 changes)").
  final String reason;

  @override
  String toString() => 'OfflineQueueFullException: $reason';
}

/// Persistence boundary for the queue (web = localStorage; desktop = a file /
/// prefs). Synchronous string get/set keeps the queue's own API simple.
abstract interface class OfflineQueueStore {
  /// The persisted queue JSON, or null when empty/unset.
  String? load();

  /// Persists the queue JSON (or clears it when [json] is null). Returns when
  /// the write has actually landed — [OfflineMutationQueue.persisted] chains on
  /// this so a caller can await durability before reporting success.
  Future<void> save(String? json);
}

/// A bounded, persisted FIFO of mutations captured while offline (PRD 19 §11).
///
/// Guarantees the spec's "bounded and honest" contract: explicit entry + byte
/// caps, a REFUSE-on-overflow policy (never silently drop the oldest), a
/// visible pending count and a deterministic reconnect flush that applies in
/// enqueue order and removes each entry only after the server accepts it —
/// combined with the per-mutation idempotency key, a mid-flush disconnect
/// re-flushes with no duplicates.
class OfflineMutationQueue {
  /// Creates a queue over [_store]. [now] is injectable for tests.
  ///
  /// [isPermanentFailure] classifies a flush error: `true` means the server
  /// answered and refused (validation, unknown op, forbidden …) so retrying the
  /// same frame can never succeed; `false` means transient (still offline, 5xx)
  /// and the entry keeps its place. [onDeadLetter] is notified for every
  /// dropped mutation so the operator can be told rather than watching a
  /// pending count sit still forever.
  OfflineMutationQueue({
    required this._store,
    this.maxEntries = 200,
    this.maxBytes = 256 * 1024,
    this.maxAttempts = 5,
    int Function()? now,
    bool Function(Object error)? isPermanentFailure,
    this.onDeadLetter,
  }) : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch),
       _isPermanentFailure = isPermanentFailure ?? _neverPermanent {
    _restore();
  }

  static bool _neverPermanent(Object error) => false;

  final OfflineQueueStore _store;
  final int Function() _now;
  final bool Function(Object error) _isPermanentFailure;

  /// Notified for every mutation the queue gives up on.
  final void Function(DeadLetteredMutation dropped)? onDeadLetter;

  /// How many times one mutation may fail transiently before it is
  /// dead-lettered. Without a ceiling a single poisoned entry blocks every
  /// later mutation for the process lifetime (head-of-line blocking).
  final int maxAttempts;

  /// Serializes concurrent drains. `flush` is called from the reconnect
  /// listener AND from a build-time microtask AND on every later reconnect, so
  /// two drains could previously interleave: both captured `_entries.first`,
  /// both awaited `apply`, and the second `removeAt(0)` deleted the entry AFTER
  /// the one it had actually sent — a mutation vanished having never been sent.
  Future<void> _draining = Future<void>.value();

  /// Max queued mutations before new ones are refused.
  final int maxEntries;

  /// Max total serialized bytes before new ones are refused (the web client
  /// only has localStorage, so this cap is real).
  final int maxBytes;

  final List<QueuedMutation> _entries = [];
  final List<DeadLetteredMutation> _deadLettered = [];

  /// The pending mutations, oldest first (a read-only view).
  List<QueuedMutation> get entries => List.unmodifiable(_entries);

  /// Mutations this queue gave up on (most recent last, capped at 20). Read by
  /// the controller so the UI can say *which* change was lost and why.
  List<DeadLetteredMutation> get deadLettered =>
      List.unmodifiable(_deadLettered);

  /// How many mutations are waiting to flush.
  int get length => _entries.length;

  /// Whether anything is pending.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// Running total of [QueuedMutation.sizeBytes] across [_entries].
  ///
  /// Maintained incrementally rather than folded on demand: the fold ran on
  /// every enqueue and each element re-encoded itself, so admitting one
  /// mutation cost a full re-serialization of the whole queue — quadratic in
  /// bytes over a burst.
  int _sizeBytes = 0;

  /// Current total serialized size.
  int get sizeBytes => _sizeBytes;

  void _addEntry(QueuedMutation mutation) {
    _entries.add(mutation);
    _sizeBytes += mutation.sizeBytes;
  }

  QueuedMutation _removeEntryAt(int index) {
    final removed = _entries.removeAt(index);
    _sizeBytes -= removed.sizeBytes;
    return removed;
  }

  void _replaceEntryAt(int index, QueuedMutation next) {
    _sizeBytes += next.sizeBytes - _entries[index].sizeBytes;
    _entries[index] = next;
  }

  /// Enqueues a mutation with its logical-action [idempotencyKey]. Throws
  /// [OfflineQueueFullException] when a cap would be exceeded — the caller
  /// surfaces the message and the mutation is NOT applied (never a silent drop).
  QueuedMutation enqueue({
    required String idempotencyKey,
    required String op,
    required Map<String, dynamic> args,
  }) {
    final mutation = QueuedMutation(
      idempotencyKey: idempotencyKey,
      op: op,
      args: args,
      enqueuedAtEpochMs: _now(),
    );
    if (_entries.length >= maxEntries) {
      throw OfflineQueueFullException(
        'offline queue is full ($maxEntries changes) — reconnect to sync',
      );
    }
    if (sizeBytes + mutation.sizeBytes > maxBytes) {
      throw const OfflineQueueFullException(
        'offline queue is full (size limit) — reconnect to sync',
      );
    }
    _addEntry(mutation);
    _persist();
    return mutation;
  }

  /// Flushes the queue in FIFO order through [apply] (which performs the op
  /// over the live connection, carrying the entry's idempotency key). Each
  /// entry is removed only after [apply] succeeds; a transient failure stops
  /// the flush and leaves that entry (and the rest) queued for the next
  /// attempt, so order and exactly-once semantics hold across a mid-flush
  /// disconnect. A permanently-rejected entry (or one past [maxAttempts]) is
  /// dead-lettered and the flush continues with the tail — a poisoned head must
  /// not block every later mutation. Returns the number applied.
  ///
  /// Concurrent calls are SERIALIZED: a second `flush` chains onto the drain
  /// already in flight rather than racing it over the same entries.
  Future<int> flush(Future<void> Function(QueuedMutation) apply) {
    final drain = _draining.then((_) => _drainOnce(apply));
    // Keep the chain alive even when this drain throws, so a failure doesn't
    // poison every later flush.
    _draining = drain.then<void>((_) {}, onError: (Object _) {});
    return drain;
  }

  Future<int> _drainOnce(Future<void> Function(QueuedMutation) apply) async {
    var applied = 0;
    // Persisting after EVERY removal re-encoded the whole queue and made a
    // synchronous native store write per entry: a 200-entry reconnect flush
    // was 200 full-queue encodes and 200 writes, quadratic in bytes moved.
    // One write at the end of the drain is enough — the queue only shrinks
    // during it, so a crash mid-flush replays entries that already applied,
    // which their idempotency keys collapse server-side. That is exactly the
    // guarantee the keys exist for.
    var dirty = false;
    try {
      while (_entries.isNotEmpty) {
        final next = _entries.first;
        try {
          await apply(next);
        } on Object catch (error) {
          final permanent = _isPermanentFailure(error);
          final attempted = next.withFailedAttempt();
          // Remove by IDENTITY, never by index: another drain (or an enqueue)
          // may have reshaped the list while `apply` was in flight.
          final at = _indexOf(next);
          if (at < 0) {
            continue; // Already handled by a concurrent drain.
          }
          if (permanent || attempted.attempts >= maxAttempts) {
            _removeEntryAt(at);
            dirty = true;
            final dropped = DeadLetteredMutation(attempted, error, permanent);
            _deadLettered.add(dropped);
            if (_deadLettered.length > 20) {
              _deadLettered.removeAt(0);
            }
            onDeadLetter?.call(dropped);
            continue; // The tail is not this entry's fault — keep draining.
          }
          _replaceEntryAt(at, attempted);
          dirty = true;
          // Transient: still offline — keep it (and the tail) in order. The
          // bumped attempt count MUST reach disk, so persist before leaving.
          break;
        }
        final at = _indexOf(next);
        if (at >= 0) {
          _removeEntryAt(at);
        }
        applied++;
        dirty = true;
      }
    } finally {
      // One write covering everything this drain changed, on every exit path
      // (including a throw from `apply`'s error handling).
      if (dirty) {
        _persist();
      }
    }
    return applied;
  }

  int _indexOf(QueuedMutation mutation) =>
      _entries.indexWhere((e) => identical(e, mutation));

  /// Clears the queue (e.g. workspace switch — those pending edits aren't valid
  /// in another workspace's context). Rarely needed; the flush is the norm.
  void clear() {
    _entries.clear();
    _sizeBytes = 0;
    _persist();
  }

  /// Completes when every write issued so far has landed in the store. Await
  /// this before telling the operator a mutation is safely queued — the store
  /// write is asynchronous on both backends, so a hard kill right after
  /// [enqueue] would otherwise lose the intent the queue exists to protect.
  Future<void> get persisted => _persistChain;

  Future<void> _persistChain = Future<void>.value();

  void _persist() {
    final json = _entries.isEmpty
        ? null
        : jsonEncode([for (final e in _entries) e.toJson()]);
    // Chained (not concurrent) so writes land in the order they were made:
    // two racing `setString`s could otherwise persist a stale snapshot last.
    _persistChain = _persistChain.then(
      (_) => _store.save(json),
      onError: (Object _) => _store.save(json),
    );
  }

  void _restore() {
    final raw = _store.load();
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        for (final e in list) {
          if (e is Map) {
            _addEntry(QueuedMutation.fromJson(e.cast<String, dynamic>()));
          }
        }
      }
    } catch (_) {
      // Corrupt persisted queue: drop it rather than crash on boot. Losing an
      // unreadable queue is better than a boot loop; this is the one place a
      // drop is acceptable (the data was already unrecoverable).
      _entries.clear();
      _sizeBytes = 0;
      _persist();
    }
  }
}
