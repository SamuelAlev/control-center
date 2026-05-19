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
  });

  /// Deserializes from persisted JSON.
  factory QueuedMutation.fromJson(Map<String, dynamic> json) => QueuedMutation(
    idempotencyKey: json['k'] as String,
    op: json['op'] as String,
    args: (json['args'] as Map?)?.cast<String, dynamic>() ?? const {},
    enqueuedAtEpochMs: (json['at'] as num?)?.toInt() ?? 0,
  );

  /// The per-logical-action idempotency key (stable across the flush).
  final String idempotencyKey;

  /// The op name (e.g. `tickets.patch`).
  final String op;

  /// The op args (already workspace-scoped by the caller).
  final Map<String, dynamic> args;

  /// When it was enqueued (epoch ms) — FIFO order + staleness display.
  final int enqueuedAtEpochMs;

  /// Serializes for persistence.
  Map<String, dynamic> toJson() => {
    'k': idempotencyKey,
    'op': op,
    'args': args,
    'at': enqueuedAtEpochMs,
  };

  /// Approximate serialized size in bytes, for the byte cap.
  int get sizeBytes => utf8.encode(jsonEncode(toJson())).length;
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

  /// Persists the queue JSON (or clears it when [json] is null).
  void save(String? json);
}

/// A bounded, persisted FIFO of mutations captured while offline (PRD 19 §11).
///
/// Guarantees the spec's "bounded and honest" contract: explicit entry + byte
/// caps, a REFUSE-on-overflow policy (never silently drop the oldest), a
/// visible pending count, and a deterministic reconnect flush that applies in
/// enqueue order and removes each entry only after the server accepts it —
/// combined with the per-mutation idempotency key, a mid-flush disconnect
/// re-flushes with no duplicates.
class OfflineMutationQueue {
  /// Creates a queue over [_store]. [now] is injectable for tests.
  OfflineMutationQueue({
    required this._store,
    this.maxEntries = 200,
    this.maxBytes = 256 * 1024,
    int Function()? now,
  }) : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch) {
    _restore();
  }

  final OfflineQueueStore _store;
  final int Function() _now;

  /// Max queued mutations before new ones are refused.
  final int maxEntries;

  /// Max total serialized bytes before new ones are refused (the web client
  /// only has localStorage, so this cap is real).
  final int maxBytes;

  final List<QueuedMutation> _entries = [];

  /// The pending mutations, oldest first (a read-only view).
  List<QueuedMutation> get entries => List.unmodifiable(_entries);

  /// How many mutations are waiting to flush.
  int get length => _entries.length;

  /// Whether anything is pending.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// Current total serialized size.
  int get sizeBytes => _entries.fold(0, (sum, e) => sum + e.sizeBytes);

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
    _entries.add(mutation);
    _persist();
    return mutation;
  }

  /// Flushes the queue in FIFO order through [apply] (which performs the op
  /// over the live connection, carrying the entry's idempotency key). Each
  /// entry is removed only after [apply] succeeds; the first failure stops the
  /// flush and leaves that entry (and the rest) queued for the next attempt, so
  /// order and exactly-once semantics hold across a mid-flush disconnect.
  /// Returns the number applied.
  Future<int> flush(Future<void> Function(QueuedMutation) apply) async {
    var applied = 0;
    while (_entries.isNotEmpty) {
      final next = _entries.first;
      try {
        await apply(next);
      } catch (_) {
        break; // still offline / server rejected — keep it (and the tail).
      }
      _entries.removeAt(0);
      applied++;
      _persist();
    }
    return applied;
  }

  /// Clears the queue (e.g. workspace switch — those pending edits aren't valid
  /// in another workspace's context). Rarely needed; the flush is the norm.
  void clear() {
    _entries.clear();
    _persist();
  }

  void _persist() => _store.save(
    _entries.isEmpty
        ? null
        : jsonEncode([for (final e in _entries) e.toJson()]),
  );

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
            _entries.add(QueuedMutation.fromJson(e.cast<String, dynamic>()));
          }
        }
      }
    } catch (_) {
      // Corrupt persisted queue: drop it rather than crash on boot. Losing an
      // unreadable queue is better than a boot loop; this is the one place a
      // drop is acceptable (the data was already unrecoverable).
      _store.save(null);
    }
  }
}
