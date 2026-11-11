import 'dart:convert';

import 'package:control_center/core/providers/session_scope_provider.dart';

/// One mutation held while the client is offline (PRD 19 §11). It carries the
/// idempotency key minted when the operator committed the intent, so a
/// reconnect flush applies exactly once (dedup at the server write ledger) —
/// no duplicates, no lost intent.
///
/// It is bound to who queued it: the server ([serverId]), the signed-in user
/// ([userId]) and the workspace ([workspaceId]). A mutation only ever replays
/// in that same session; anywhere else it is dropped, never sent as someone
/// else.
class QueuedMutation {
  /// Creates a [QueuedMutation].
  const QueuedMutation({
    required this.idempotencyKey,
    required this.op,
    required this.args,
    required this.enqueuedAtEpochMs,
    required this.serverId,
    required this.userId,
    required this.workspaceId,
    this.attempts = 0,
    this.awaitingSignIn,
  });

  /// Deserializes from persisted JSON. Throws [FormatException] for an entry
  /// that does not name its server, user and workspace: an unbound entry can
  /// never be replayed safely.
  factory QueuedMutation.fromJson(Map<String, dynamic> json) {
    String bound(String key) => switch (json[key]) {
      final String v when v.isNotEmpty => v,
      _ => throw FormatException('Queued mutation without "$key"'),
    };
    return QueuedMutation(
      idempotencyKey: bound('k'),
      op: bound('op'),
      args: (json['args'] as Map?)?.cast<String, dynamic>() ?? const {},
      enqueuedAtEpochMs: (json['at'] as num?)?.toInt() ?? 0,
      serverId: bound('srv'),
      userId: bound('usr'),
      workspaceId: bound('ws'),
      attempts: (json['n'] as num?)?.toInt() ?? 0,
      awaitingSignIn: json['s'] as String?,
    );
  }

  /// The per-logical-action idempotency key (stable across the flush).
  final String idempotencyKey;

  /// The op name (e.g. `tickets.patch`).
  final String op;

  /// The op args (already workspace-scoped by the caller).
  final Map<String, dynamic> args;

  /// When it was enqueued (epoch ms) — FIFO order, staleness display and
  /// the [OfflineMutationQueue.maxAge] cut-off.
  final int enqueuedAtEpochMs;

  /// The identity of the server it was queued against.
  final String serverId;

  /// The user signed in on [serverId] who queued it.
  final String userId;

  /// The workspace it acts in.
  final String workspaceId;

  /// Whether it belongs to [scope] (same server, same user).
  bool belongsTo(SessionScope scope) =>
      serverId == scope.serverId && userId == scope.userId;

  /// How many flush attempts this mutation has already failed. Persisted so a
  /// mutation that fails on every boot still reaches the dead-letter ceiling
  /// instead of blocking the queue head forever.
  final int attempts;

  /// The sign-in lane (`github`, `linear`, `gitlab` …) the server said the
  /// person must sign in to before this mutation can run (`needs_sign_in`).
  /// A parked mutation is not retried, does not spend attempts and does not
  /// block the rest of the queue; [OfflineMutationQueue.resumeAfterSignIn]
  /// releases it once that sign-in succeeds. Null for a runnable mutation.
  final String? awaitingSignIn;

  /// This mutation with one more recorded failed attempt.
  QueuedMutation withFailedAttempt() => QueuedMutation(
    idempotencyKey: idempotencyKey,
    op: op,
    args: args,
    enqueuedAtEpochMs: enqueuedAtEpochMs,
    serverId: serverId,
    userId: userId,
    workspaceId: workspaceId,
    attempts: attempts + 1,
    awaitingSignIn: awaitingSignIn,
  );

  /// This mutation parked until [lane]'s sign-in succeeds (null: runnable
  /// again). Attempts are unchanged: a missing sign-in is not a failure of
  /// the mutation.
  QueuedMutation withAwaitingSignIn(String? lane) => QueuedMutation(
    idempotencyKey: idempotencyKey,
    op: op,
    args: args,
    enqueuedAtEpochMs: enqueuedAtEpochMs,
    serverId: serverId,
    userId: userId,
    workspaceId: workspaceId,
    attempts: attempts,
    awaitingSignIn: lane,
  );

  /// Serializes for persistence.
  Map<String, dynamic> toJson() => {
    'k': idempotencyKey,
    'op': op,
    'args': args,
    'at': enqueuedAtEpochMs,
    'srv': serverId,
    'usr': userId,
    'ws': workspaceId,
    if (attempts > 0) 'n': attempts,
    if (awaitingSignIn != null) 's': awaitingSignIn,
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

/// Thrown by [OfflineMutationQueue.enqueue] when the mutation cannot be bound
/// to a session: the queue has no [SessionScope] (the signed-in user could
/// not be named), or its `args` name a different workspace than the one
/// given.
class OfflineQueueUnboundException implements Exception {
  /// Creates an [OfflineQueueUnboundException].
  const OfflineQueueUnboundException(this.reason);

  /// Why the mutation could not be queued.
  final String reason;

  @override
  String toString() => 'OfflineQueueUnboundException: $reason';
}

/// Why a queued mutation was dropped without being sent (the
/// [DeadLetteredMutation.error] of such a drop).
class QueuedMutationDiscarded implements Exception {
  /// Creates a [QueuedMutationDiscarded].
  const QueuedMutationDiscarded(this.reason);

  /// Why it was dropped (expired, or bound to another session or workspace).
  final String reason;

  @override
  String toString() => 'QueuedMutationDiscarded: $reason';
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
  ///
  /// [signInLaneOf] recognises a refusal that only a sign-in can lift (the
  /// server's `needs_sign_in`) and names its lane: such a mutation is parked
  /// ([QueuedMutation.awaitingSignIn]) rather than dead-lettered, checked
  /// before [isPermanentFailure].
  ///
  /// [scope] is the session the queue serves. Only its own mutations are
  /// restored, flushed or resumed; another server's or user's are dropped
  /// unsent, and so is any older than [maxAge]. Without a scope (the signed-in
  /// user could not be named) the queue restores nothing and refuses
  /// [enqueue].
  OfflineMutationQueue({
    required this._store,
    required this.scope,
    this.maxAge = const Duration(hours: 24),
    this.maxEntries = 200,
    this.maxBytes = 256 * 1024,
    this.maxAttempts = 5,
    int Function()? now,
    bool Function(Object error)? isPermanentFailure,
    String? Function(Object error)? signInLaneOf,
    this.onDeadLetter,
  }) : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch),
       _isPermanentFailure = isPermanentFailure ?? _neverPermanent,
       _signInLaneOf = signInLaneOf ?? _noSignIn {
    _restore();
  }

  static bool _neverPermanent(Object error) => false;

  static String? _noSignIn(Object error) => null;

  final OfflineQueueStore _store;

  /// The session whose mutations this queue holds (null: none can be bound).
  final SessionScope? scope;

  /// How long a mutation may wait before it is dropped instead of sent: a
  /// change replayed a day later is no longer the intent it captured.
  final Duration maxAge;

  final int Function() _now;
  final bool Function(Object error) _isPermanentFailure;
  final String? Function(Object error) _signInLaneOf;

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

  /// How many mutations are waiting to flush (parked ones included: they
  /// are still pending, just not runnable yet).
  int get length => _entries.length;

  /// Whether anything is pending.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// Whether anything is pending that a flush would try now (not parked for
  /// a sign-in).
  bool get hasRunnable => _entries.any((e) => e.awaitingSignIn == null);

  /// Mutations parked until a sign-in succeeds, oldest first.
  List<QueuedMutation> get awaitingSignIn => List.unmodifiable([
    for (final e in _entries)
      if (e.awaitingSignIn != null) e,
  ]);

  /// Releases every mutation of this session parked for [lane] (its sign-in
  /// just succeeded): they keep their place and the next [flush] tries them.
  /// Expired or foreign entries are dropped first, never released. Returns
  /// how many were released.
  int resumeAfterSignIn(String lane) {
    final session = scope;
    if (session == null) {
      return 0;
    }
    var released = 0;
    var dirty = _dropUnsendable();
    for (var i = 0; i < _entries.length; i++) {
      if (_entries[i].awaitingSignIn == lane &&
          _entries[i].belongsTo(session)) {
        _replaceEntryAt(i, _entries[i].withAwaitingSignIn(null));
        released++;
        dirty = true;
      }
    }
    if (dirty) {
      _persist();
    }
    return released;
  }

  /// Why [mutation] must not be sent in this session, or null when it may.
  String? _unsendableReason(QueuedMutation mutation) {
    final session = scope;
    if (session == null || !mutation.belongsTo(session)) {
      return 'queued by another server or user';
    }
    final argsWorkspace = mutation.args['workspace_id'];
    if (argsWorkspace != null && argsWorkspace != mutation.workspaceId) {
      return 'bound to another workspace';
    }
    if (_now() - mutation.enqueuedAtEpochMs > maxAge.inMilliseconds) {
      return 'waited longer than ${maxAge.inHours}h';
    }
    return null;
  }

  /// Drops every entry [_unsendableReason] refuses. This session's own are
  /// dead-lettered (the operator learns the change was lost); another
  /// session's leave no trace here (they were never this person's to see).
  /// Returns whether anything was dropped; the caller persists.
  bool _dropUnsendable() {
    var dropped = false;
    for (var i = _entries.length - 1; i >= 0; i--) {
      final entry = _entries[i];
      final reason = _unsendableReason(entry);
      if (reason == null) {
        continue;
      }
      _removeEntryAt(i);
      dropped = true;
      final session = scope;
      if (session != null && entry.belongsTo(session)) {
        _deadLetter(
          DeadLetteredMutation(entry, QueuedMutationDiscarded(reason), true),
        );
      }
    }
    return dropped;
  }

  void _deadLetter(DeadLetteredMutation dropped) {
    _deadLettered.add(dropped);
    if (_deadLettered.length > 20) {
      _deadLettered.removeAt(0);
    }
    onDeadLetter?.call(dropped);
  }

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

  /// Enqueues a mutation with its logical-action [idempotencyKey], bound to
  /// this session and [workspaceId]. Throws [OfflineQueueFullException] when a
  /// cap would be exceeded, and [OfflineQueueUnboundException] when it cannot
  /// be bound (no session, or [args] naming another workspace) — the caller
  /// surfaces the message and the mutation is NOT applied (never a silent
  /// drop).
  QueuedMutation enqueue({
    required String workspaceId,
    required String idempotencyKey,
    required String op,
    required Map<String, dynamic> args,
  }) {
    final session = scope;
    if (session == null) {
      throw const OfflineQueueUnboundException(
        'no signed-in session to queue changes for',
      );
    }
    final argsWorkspace = args['workspace_id'];
    if (workspaceId.isEmpty ||
        (argsWorkspace != null && argsWorkspace != workspaceId)) {
      throw const OfflineQueueUnboundException(
        'the change names a different workspace',
      );
    }
    final mutation = QueuedMutation(
      idempotencyKey: idempotencyKey,
      op: op,
      args: args,
      enqueuedAtEpochMs: _now(),
      serverId: session.serverId,
      userId: session.userId,
      workspaceId: workspaceId,
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
  /// not block every later mutation. One refused for a missing sign-in is
  /// parked (kept, not retried) and the flush continues past it; parked
  /// entries are skipped until [resumeAfterSignIn]. Returns the number
  /// applied.
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
      while (true) {
        final next = _entries
            .where((e) => e.awaitingSignIn == null)
            .firstOrNull;
        if (next == null) {
          break;
        }
        // Expired, or not this session's: dropped, never replayed.
        final unsendable = _unsendableReason(next);
        if (unsendable != null) {
          if (_dropUnsendable()) {
            dirty = true;
          }
          continue;
        }
        try {
          await apply(next);
        } on Object catch (error) {
          // Remove by IDENTITY, never by index: another drain (or an enqueue)
          // may have reshaped the list while `apply` was in flight.
          final at = _indexOf(next);
          if (at < 0) {
            continue; // Already handled by a concurrent drain.
          }
          // Only a sign-in can lift it: park it (no attempt spent, never
          // dead-lettered) and keep draining the rest.
          final lane = _signInLaneOf(error);
          if (lane != null) {
            _replaceEntryAt(at, next.withAwaitingSignIn(lane));
            dirty = true;
            continue;
          }
          final permanent = _isPermanentFailure(error);
          final attempted = next.withFailedAttempt();
          if (permanent || attempted.attempts >= maxAttempts) {
            _removeEntryAt(at);
            dirty = true;
            _deadLetter(DeadLetteredMutation(attempted, error, permanent));
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

  /// Drops every pending mutation unsent: the session is ending (sign-out or
  /// a switch to another server), and nothing queued in it may replay in the
  /// next one.
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
    // No session to bind to: load nothing, so nothing can replay as anyone.
    if (scope == null) {
      return;
    }
    final raw = _store.load();
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final list = jsonDecode(raw);
      var dropped = list is! List;
      if (list is List) {
        for (final e in list) {
          // An unbound or malformed entry is dropped: it cannot prove whose
          // it is.
          final entry = e is Map ? _parse(e.cast<String, dynamic>()) : null;
          if (entry == null) {
            dropped = true;
          } else {
            _addEntry(entry);
          }
        }
      }
      // Another session's (a different server or user), or expired.
      if (_dropUnsendable() || dropped) {
        _persist();
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

  static QueuedMutation? _parse(Map<String, dynamic> json) {
    try {
      return QueuedMutation.fromJson(json);
    } on Object {
      return null;
    }
  }
}
