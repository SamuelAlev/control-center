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
/// avoidance, gap-triggered ranged pulls, and an automatic drop to snapshot
/// mode when deltas cannot be trusted (gap past retention, unknown wire
/// version, or subscription failure).
class SyncedStore {
  /// Creates a store for [store] in [workspaceId] over [client].
  SyncedStore({
    required RemoteRpcClient client,
    required this.store,
    required this.workspaceId,
    this.onDemoted,
  }) : _client = client;

  /// Supported delta wire version (must match the server's).
  static const int wireVersion = 1;

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
    _emit(tbl);
  }

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
        _lastSeq = (frame['seq'] as num?)?.toInt() ?? 0;
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

  Future<void> _pull() async {
    if (_pulling || _mode != SyncedStoreMode.delta) {
      return;
    }
    _pulling = true;
    try {
      final result = await _client.call('sync.pull', {
        'workspace_id': workspaceId,
        'store': store,
        'from_seq': _lastSeq,
      });
      if (result['snapshot_required'] == true || result['v'] != wireVersion) {
        _demote('gap past the retained delta horizon');
        return;
      }
      _applyChanges((result['changes'] as List?) ?? const []);
      _lastSeq = (result['seq'] as num?)?.toInt() ?? _lastSeq;
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

  void _emit(String tbl) {
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
