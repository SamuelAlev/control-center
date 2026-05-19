import 'dart:async';

import 'package:cc_rpc/cc_rpc.dart';

/// How a client store is currently fed (PRD 16 §6 staged adoption).
enum SyncedStoreMode {
  /// Delta packets ordered by the per-workspace sync id.
  delta,

  /// Today's full-snapshot subscriptions (the kill-switch OFF position and
  /// the automatic fallback when deltas cannot be trusted).
  snapshot,
}

/// A pending optimistic mutation: local field values that keep winning over
/// incoming deltas for their row until the server acknowledged the mutation
/// (Figma-style flicker avoidance — a remote change can never stomp what the
/// local user is still editing).
class OptimisticHandle {
  OptimisticHandle._(this._store, this._key, this.tbl, this.pk, this.fields);

  final SyncedStore _store;
  final int _key;

  /// The patched table.
  final String tbl;

  /// The patched row.
  final String pk;

  /// The locally-applied field values.
  final Map<String, dynamic> fields;

  /// The server executed the mutation: drop the overlay (the authoritative
  /// delta has landed or will land with the same values).
  void ack() => _store._resolveOptimistic(_key, revert: false);

  /// The mutation failed: drop the overlay and re-emit the authoritative
  /// state (the caller surfaces the error).
  void fail() => _store._resolveOptimistic(_key, revert: true);
}

/// The client half of the deterministic sync engine (PRD 16 §6): one store
/// ("tickets", "messaging", "notes") of plain wire rows kept live by delta
/// packets, with optimistic apply + rebase + per-field LWW + flicker
/// avoidance, gap-triggered ranged pulls and an automatic drop to snapshot
/// mode when deltas cannot be trusted (gap past retention, unknown wire
/// version, or subscription failure).
class SyncedStore {
  /// Creates a store for [store] in [workspaceId] over [client].
  SyncedStore({
    required RemoteRpcClient client,
    required this.store,
    required this.workspaceId,
    this.onDemoted,
    Set<String>? mirroredTables,
  }) : _client = client,
       _mirroredTables = mirroredTables;

  /// Supported delta wire version (must match the server's).
  static const int wireVersion = 1;

  /// Which of this store's tables are kept in the row mirror.
  ///
  /// Null means "all of them" (the conservative default, and what tests get).
  /// The registry passes the real set: the server ships every adopted table's
  /// changes for a store, but a client only READS some of them, and mirroring
  /// the rest is pure resident memory. `channel_messages` is the expensive
  /// one — during agent streaming it accumulates the full growing content of
  /// every message in the workspace, for nobody.
  ///
  /// [watchRows] asserts against this set, so adding a reader without adding
  /// its table fails loudly in debug instead of silently returning nothing.
  final Set<String>? _mirroredTables;

  bool _mirrors(String tbl) =>
      _mirroredTables == null || _mirroredTables.contains(tbl);

  /// The store name (`tickets` | `messaging` | `notes`).
  final String store;

  /// The workspace this store mirrors.
  final String workspaceId;

  /// Called once when the store demotes itself to snapshot mode (the
  /// kill-switch path) — consumers then re-read through the legacy
  /// subscriptions. The demotion never loses data: authoritative state
  /// always lives on the server.
  final void Function(String reason)? onDemoted;

  final RemoteRpcClient _client;

  final Map<String, Map<String, Map<String, dynamic>>> _rows = {};
  final Map<int, OptimisticHandle> _pending = {};
  final Map<String, StreamController<List<Map<String, dynamic>>>> _watchers =
      {};
  final StreamController<SyncedStoreMode> _modeChanges =
      StreamController.broadcast();

  StreamSubscription<Map<String, dynamic>>? _sub;
  int _lastSeq = -1;
  int _nextOptimisticKey = 0;
  bool _started = false;
  bool _pulling = false;
  SyncedStoreMode _mode = SyncedStoreMode.delta;

  /// The current feed mode.
  SyncedStoreMode get mode => _mode;

  /// Mode transitions (a demotion notifies consumers to re-subscribe via the
  /// legacy path).
  Stream<SyncedStoreMode> get modeChanges => _modeChanges.stream;

  /// The last applied sync sequence (diagnostics).
  int get lastSeq => _lastSeq;

  /// Seeds the store's base state for [tbl] (the first emission of the
  /// legacy snapshot subscription, fetched once by the adopting repository
  /// right after [start]). Optimistic overlays survive the seed.
  void seed(
    String tbl,
    List<Map<String, dynamic>> rows,
    String Function(Map<String, dynamic>) pkOf,
  ) {
    final table = _rows.putIfAbsent(tbl, () => {});
    table.clear();
    for (final row in rows) {
      table[pkOf(row)] = row;
    }
    _seeded.add(tbl);
    _emit(tbl);
  }

  /// Tables this store has already been seeded with.
  final Set<String> _seeded = {};

  /// Whether [tbl] already holds a full snapshot.
  ///
  /// The mirror is per (store, workspace) but every SUBSCRIBER used to run its
  /// own seeding pull: opening three ticket detail panes meant three full
  /// `tickets` snapshots off the wire at mount, on top of the delta feed that
  /// was already live and authoritative. A caller checks this before paying
  /// for a seed it does not need.
  bool isSeeded(String tbl) => _seeded.contains(tbl);

  /// Opens the delta subscription. Idempotent.
  void start() {
    if (_started) {
      return;
    }
    _started = true;
    _sub = _client
        .subscribe('sync.watch', {'workspace_id': workspaceId, 'store': store})
        .listen(
          _onFrame,
          onError: (Object e, StackTrace s) =>
              _demote('delta subscription failed: $e'),
        );
  }

  void _onFrame(Map<String, dynamic> frame) {
    if (_mode != SyncedStoreMode.delta) {
      return;
    }
    final version = frame['v'];
    if (version != wireVersion) {
      // An unknown schema version must never be misapplied (PRD 16 §6).
      _demote('unknown delta wire version: $version');
      return;
    }
    switch (frame['kind']) {
      case 'seed':
        // A seed arrives on first attach AND on every transparent
        // re-subscribe after a reconnect. Jumping `_lastSeq` forward
        // unconditionally discarded everything written while disconnected:
        // the mirror stayed stale, and nothing ever re-read it because the
        // gap check below only fires on a DELTA frame. If this store already
        // holds rows and the server's sequence has moved past ours, pull the
        // range we missed.
        final seeded = (frame['seq'] as num?)?.toInt() ?? 0;
        final previous = _lastSeq;
        final hasRows = _rows.values.any((t) => t.isNotEmpty);
        _lastSeq = seeded;
        if (hasRows && previous >= 0 && seeded > previous) {
          unawaited(_pull(from: previous));
        }
      case 'delta':
        final from = (frame['from'] as num?)?.toInt() ?? -1;
        final seq = (frame['seq'] as num?)?.toInt() ?? -1;
        if (_lastSeq >= 0 && from != _lastSeq) {
          // GAP: something between our last frame and this one was missed
          // (reconnect re-registered the subscription, or frames dropped).
          unawaited(_pull());
          return;
        }
        _applyChanges((frame['changes'] as List?) ?? const []);
        _lastSeq = seq;
    }
  }

  /// Pulls the changes after [from] (defaults to the store's own cursor).
  ///
  /// [from] is explicit for the post-reconnect seed path, where `_lastSeq` has
  /// already been advanced to the server's current sequence and the range we
  /// need is the one BEFORE that.
  Future<void> _pull({int? from}) async {
    if (_pulling || _mode != SyncedStoreMode.delta) {
      return;
    }
    _pulling = true;
    try {
      final result = await _client.call('sync.pull', {
        'workspace_id': workspaceId,
        'store': store,
        'from_seq': from ?? _lastSeq,
      });
      if (result['snapshot_required'] == true || result['v'] != wireVersion) {
        _demote('gap past the retained delta horizon');
        return;
      }
      _applyChanges((result['changes'] as List?) ?? const []);
      final pulledTo = (result['seq'] as num?)?.toInt();
      // Never move the cursor BACKWARD: on the seed path `_lastSeq` is already
      // the server's current sequence and the pull only filled the gap under
      // it.
      if (pulledTo != null && pulledTo > _lastSeq) {
        _lastSeq = pulledTo;
      }
    } catch (e) {
      // A failed pull drops the store to snapshot mode — the §6 kill-switch
      // path, exercised automatically.
      _demote('ranged pull failed: $e');
    } finally {
      _pulling = false;
    }
  }

  void _applyChanges(List<dynamic> changes) {
    final touched = <String>{};
    for (final raw in changes) {
      if (raw is! Map) {
        continue;
      }
      final change = raw.cast<String, dynamic>();
      final tbl = change['tbl'] as String? ?? '';
      final pk = change['pk'] as String? ?? '';
      if (tbl.isEmpty || pk.isEmpty) {
        continue;
      }
      if (!_mirrors(tbl)) {
        // A table nothing on this client reads is not worth mirroring. The
        // server ships every adopted table's changes, so `channel_messages`
        // — the whole growing content of every message in the workspace —
        // accumulated in memory during agent streaming for readers that do
        // not exist. Deletes still cascade below for the tables that ARE
        // mirrored.
        continue;
      }
      final table = _rows.putIfAbsent(tbl, () => {});
      if (change['op'] == 'delete') {
        table.remove(pk);
        // Cascade: removing a channel removes its child rows locally, the
        // same way the server's ON DELETE CASCADE removed them (child
        // deletions are not individually recorded — see the trigger notes).
        if (tbl == 'channels') {
          for (final childTbl in const [
            'channel_messages',
            'channel_participants',
            'message_reactions',
            'channel_notes',
          ]) {
            final child = _rows[childTbl];
            if (child == null) {
              continue;
            }
            child.removeWhere((_, row) => row['channel_id'] == pk);
            touched.add(childTbl);
          }
        }
      } else {
        final row = (change['row'] as Map?)?.cast<String, dynamic>();
        if (row != null) {
          table[pk] = row;
        }
      }
      touched.add(tbl);
    }
    for (final tbl in touched) {
      _emit(tbl);
    }
  }

  /// The live rows of [tbl], with optimistic overlays applied. The first
  /// emission is the current state.
  Stream<List<Map<String, dynamic>>> watchRows(String tbl) {
    assert(
      _mirrors(tbl),
      'watchRows("$tbl") on the "$store" store, which does not mirror it — '
      'add it to the store\'s mirroredTables in ClientSyncEngine',
    );
    // Lazily create the shared broadcast fan-out controller for [tbl]. It is
    // owned by this store and closed in [dispose]; we never close it here.
    _watchers.putIfAbsent(
      tbl,
      StreamController<List<Map<String, dynamic>>>.broadcast,
    );
    late StreamController<List<Map<String, dynamic>>> out;
    StreamSubscription<List<Map<String, dynamic>>>? sub;
    out = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        out.add(_snapshot(tbl));
        sub = _watchers[tbl]!.stream.listen(out.add);
      },
      onCancel: () async {
        await sub?.cancel();
        await out.close();
      },
    );
    return out.stream;
  }

  List<Map<String, dynamic>> _snapshot(String tbl) {
    final table = _rows[tbl] ?? const <String, Map<String, dynamic>>{};
    final overlays = <String, Map<String, dynamic>>{};
    for (final pending in _pending.values) {
      if (pending.tbl == tbl) {
        overlays.putIfAbsent(pending.pk, () => {}).addAll(pending.fields);
      }
    }
    return [
      for (final entry in table.entries)
        overlays.containsKey(entry.key)
            ? {...entry.value, ...overlays[entry.key]!}
            : entry.value,
    ];
  }

  /// Tables with an emission scheduled for the end of this microtask turn.
  final Set<String> _emitPending = {};

  /// Coalesces emissions to at most one per table per microtask turn.
  ///
  /// Nothing on the chain below this — store → repository `.map` → provider →
  /// widgets — batches, and every emission produces new list and entity
  /// instances, so there is no equality short-circuit anywhere either. A burst
  /// of 100 deltas (an agent streaming, a webhook mirror pass) therefore
  /// produced 100 whole-table re-maps and 100 widget rebuilds. A microtask
  /// coalescer collapses a burst that arrives in one turn — which is exactly
  /// the shape a drained frame has — into one, and costs nothing when
  /// emissions are already sparse.
  void _emit(String tbl) {
    if (!_emitPending.add(tbl)) {
      return;
    }
    scheduleMicrotask(() {
      _emitPending.remove(tbl);
      _emitNow(tbl);
    });
  }

  void _emitNow(String tbl) {
    // Broadcast fan-out controllers are shared and closed in [dispose]; just
    // fan out the latest snapshot to live listeners.
    if (_watchers[tbl] case final controller? when !controller.isClosed) {
      controller.add(_snapshot(tbl));
    }
  }

  /// Applies an optimistic field patch locally (instant UI) and returns the
  /// handle the caller resolves after the server call. Incoming deltas for
  /// the row keep the local unacknowledged values on top (per-field flicker
  /// avoidance); [OptimisticHandle.fail] reverts.
  OptimisticHandle applyOptimistic(
    String tbl,
    String pk,
    Map<String, dynamic> fields,
  ) {
    final handle = OptimisticHandle._(
      this,
      _nextOptimisticKey++,
      tbl,
      pk,
      Map.of(fields),
    );
    _pending[handle._key] = handle;
    _emit(tbl);
    return handle;
  }

  void _resolveOptimistic(int key, {required bool revert}) {
    final handle = _pending.remove(key);
    if (handle != null) {
      _emit(handle.tbl);
    }
  }

  void _demote(String reason) {
    if (_mode == SyncedStoreMode.snapshot) {
      return;
    }
    _mode = SyncedStoreMode.snapshot;
    unawaited(_sub?.cancel());
    _sub = null;
    // Release the row mirror. A demoted store answers nothing — `storeFor`
    // returns null for it and every reader has fallen back to snapshot RPCs —
    // but the tombstone is kept forever so the demotion is not silently
    // retried, and it was holding the WHOLE mirrored table as dead weight
    // until the next workspace switch. A messaging mirror is the big one.
    _rows.clear();
    _pending.clear();
    _seeded.clear();
    if (!_modeChanges.isClosed) {
      _modeChanges.add(_mode);
    }
    onDemoted?.call(reason);
  }

  /// Closes the store.
  Future<void> dispose() async {
    await _sub?.cancel();
    for (final c in _watchers.values) {
      await c.close();
    }
    _watchers.clear();
    await _modeChanges.close();
  }
}

/// The tables a client actually READS out of each delta store.
///
/// The server ships every adopted table's changes; this is the subset the
/// client keeps. Anything absent is applied to nothing and costs no memory —
/// most importantly `channel_messages`, whose rows carry the full text of
/// every message in the workspace and which no client reader watches (message
/// history rides the windowed `messaging.watchMessagesWindow` subscription,
/// not the delta mirror).
///
/// Returns null for an unknown store, which mirrors everything — a new store
/// works before anyone has thought about this list.
Set<String>? mirroredTablesFor(String store) => switch (store) {
  'messaging' => const {'channels', 'channel_participants'},
  'tickets' => const {'tickets'},
  'notes' => const {'channel_notes'},
  _ => null,
};

/// Client-side engine: one [SyncedStore] per (store, workspace), created
/// lazily and only when the per-store kill-switch flag allows delta mode
/// (PRD 16 §6 staged adoption: the OFF position is today's snapshot mode).
class ClientSyncEngine {
  /// Creates the engine. [storeEnabled] is the per-store kill-switch.
  ClientSyncEngine({
    required RemoteRpcClient client,
    required bool Function(String store) storeEnabled,
  }) : _client = client,
       _storeEnabled = storeEnabled;

  final RemoteRpcClient _client;
  final bool Function(String store) _storeEnabled;
  final Map<String, SyncedStore> _stores = {};

  /// The store for (store, workspace), or null when the kill-switch is OFF —
  /// callers then use their legacy snapshot subscriptions.
  SyncedStore? storeFor(String store, String workspaceId) {
    if (workspaceId.isEmpty || !_storeEnabled(store)) {
      return null;
    }
    final key = '$store|$workspaceId';
    final existing = _stores[key];
    if (existing != null) {
      return existing.mode == SyncedStoreMode.delta ? existing : null;
    }
    final created = SyncedStore(
      client: _client,
      store: store,
      workspaceId: workspaceId,
      mirroredTables: mirroredTablesFor(store),
      onDemoted: (reason) => CcDataLog.warning(
        'sync store $store/$workspaceId dropped to snapshot mode: $reason',
      ),
    )..start();
    _stores[key] = created;
    return created;
  }

  /// Disposes the stores of every workspace OTHER than [activeWorkspaceId],
  /// dropping their delta subscriptions and mirrored row maps.
  ///
  /// Called on workspace switch: without this, every workspace visited in a
  /// session keeps its full ticket/message row mirror resident (and its
  /// `sync.watch` subscription live) forever. The next visit recreates the
  /// store lazily via [storeFor] and re-seeds. Callers must invalidate any
  /// providers consuming the evicted stores' streams — those streams complete
  /// on dispose and would otherwise render a frozen snapshot on return.
  Future<void> evictInactive(String activeWorkspaceId) async {
    final evicted = _stores.keys
        .where((key) => !key.endsWith('|$activeWorkspaceId'))
        .toList();
    for (final key in evicted) {
      final store = _stores.remove(key);
      if (store != null) {
        await store.dispose();
      }
    }
  }

  /// Disposes every store.
  Future<void> dispose() async {
    for (final store in _stores.values) {
      await store.dispose();
    }
    _stores.clear();
  }
}

/// Minimal log seam for cc_data (mirrors CcHostLog's shape).
final class CcDataLog {
  CcDataLog._();

  /// Installable sink; defaults to a no-op.
  static void Function(String message) sink = (_) {};

  /// Logs a warning.
  static void warning(String message) => sink(message);
}
