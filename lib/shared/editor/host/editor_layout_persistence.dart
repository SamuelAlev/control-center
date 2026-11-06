import 'dart:async';

import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/host/editor_layout_codec.dart';
import 'package:control_center/shared/editor/host/editor_layout_memo.dart';

/// One read of a layout from the server, from [EditorLayoutPersistence.fetch].
typedef EditorLayoutFetch = ({
  /// The decoded layout; null when the server holds none, its payload is
  /// unrestorable, or the read [failed].
  EditorLayoutController? layout,

  /// The read itself failed, so nothing is known about the server's copy.
  /// The host keeps what it shows and must not save over the server's copy.
  bool failed,

  /// The server's payload differs from what the memo held when the read
  /// began: another device (or session) saved this layout since.
  bool changed,
});

/// Debounced, workspace-scoped persistence of an editor split tree.
///
/// Wraps the [EditorLayoutCodec] and a [CacheRepository] (server-backed
/// `cache.read`/`cache.write`, stored per person, so a layout roams across
/// that person's devices). A write the server is known to already hold is
/// skipped. Writes are
/// debounced (`debounce`, default 400ms) and coalesced; the host flushes
/// synchronously on dispose / context switch. All I/O is fire-and-forget — a
/// failed cache read or write must never surface in the UI: a transient RPC
/// failure (the session's in-flight cap refusing the call, a timeout while
/// the server restarts, a dropped connection) degrades to "no persisted
/// layout" instead of an unhandled async error hitting the global boundary.
///
/// The host owns the `workspaceId` + `cacheKey` (space id for messaging, PR
/// identity for the workbench) and passes them per call, so one persistence
/// instance can follow a host across context switches.
class EditorLayoutPersistence {
  /// Creates a persistence helper writing under [_cacheKind] using [_codec].
  EditorLayoutPersistence({
    required this._codec,
    required this._cache,
    required this._cacheKind,
    this._debounce = const Duration(milliseconds: 400),
    this._memo,
  });

  final EditorLayoutCodec _codec;
  final CacheRepository _cache;
  final String _cacheKind;

  /// In-process copy of every layout read or written, so [peek] can restore
  /// synchronously. Null keeps the server as the only store.
  final EditorLayoutMemo? _memo;
  final Duration _debounce;
  Timer? _timer;

  /// Schedules a debounced write of `layout` under (`workspaceId`, `cacheKey`).
  /// Successive calls within `debounce` coalesce into one write.
  void schedule({
    required String workspaceId,
    required String cacheKey,
    required EditorLayoutController layout,
  }) {
    _timer?.cancel();
    _timer = Timer(_debounce, () => _write(workspaceId, cacheKey, layout));
  }

  /// Cancels any pending debounce and writes `layout` immediately (used on
  /// dispose and before a context switch so no edit is lost).
  void flushNow({
    required String workspaceId,
    required String cacheKey,
    required EditorLayoutController layout,
  }) {
    _timer?.cancel();
    _write(workspaceId, cacheKey, layout);
  }

  Future<void> _write(
    String workspaceId,
    String cacheKey,
    EditorLayoutController l,
  ) async {
    // Fire-and-forget, and failure-forgetting: a transient RPC failure drops
    // the write (the next layout change re-schedules one); it must never
    // surface in the UI or the zone's unhandled-error handler.
    final payload = _codec.encode(l);
    final memo = _memo;
    // Unchanged since the server last confirmed it: writing it back would
    // only replace a newer layout another device saved in the meantime.
    if (memo != null &&
        memo.isSynced(workspaceId, _cacheKind, cacheKey, payload)) {
      return;
    }
    // Recorded before the RPC: a host that switches away and straight back
    // restores this, not whatever the server answered earlier.
    memo?.put(workspaceId, _cacheKind, cacheKey, payload);
    try {
      await _cache.put(workspaceId, _cacheKind, cacheKey, payload);
      memo?.confirm(workspaceId, _cacheKind, cacheKey, payload);
    } on RemoteRpcException {
      // Refused / errored server-side — the layout cache is a nicety.
    } on RemoteRpcClientClosedException {
      // The server connection dropped mid-call (restart, network).
    } on TimeoutException {
      // The call never answered within the RPC timeout.
    }
  }

  /// Reads and decodes the persisted layout for ([workspaceId], [cacheKey]), or
  /// null when nothing is stored / the payload is unrestorable / the read
  /// failed transiently (the caller keeps its seeded layout).
  Future<EditorLayoutController?> restore({
    required String workspaceId,
    required String cacheKey,
  }) async {
    final warm = peek(workspaceId: workspaceId, cacheKey: cacheKey);
    if (warm != null) {
      return warm.layout;
    }
    return (await fetch(workspaceId: workspaceId, cacheKey: cacheKey)).layout;
  }

  /// Reads the server's copy of ([workspaceId], [cacheKey]), bypassing the
  /// memo: a memo entry is only as fresh as this client's last read or write,
  /// and the same person may have moved on to another tab on another device
  /// since. The memo takes the answer unless it holds a local write the
  /// server has not confirmed, or one landed while the read was in flight:
  /// that write is newer than the answer, so the answer is not reported as
  /// changed.
  Future<EditorLayoutFetch> fetch({
    required String workspaceId,
    required String cacheKey,
  }) async {
    final memo = _memo;
    final knewBefore = memo?.knows(workspaceId, _cacheKind, cacheKey) ?? false;
    final before = memo?.get(workspaceId, _cacheKind, cacheKey);
    final unsynced =
        memo?.hasUnsyncedWrite(workspaceId, _cacheKind, cacheKey) ?? false;
    final String? payload;
    try {
      payload = await _cache.read(workspaceId, _cacheKind, cacheKey);
    } on RemoteRpcException {
      return (layout: null, failed: true, changed: false);
    } on RemoteRpcClientClosedException {
      return (layout: null, failed: true, changed: false);
    } on TimeoutException {
      return (layout: null, failed: true, changed: false);
    }
    final localIsNewer =
        unsynced ||
        (memo != null &&
            (memo.knows(workspaceId, _cacheKind, cacheKey) != knewBefore ||
                memo.get(workspaceId, _cacheKind, cacheKey) != before));
    if (!localIsNewer) {
      memo?.put(workspaceId, _cacheKind, cacheKey, payload, synced: true);
    }
    return (
      layout: payload == null ? null : _codec.decode(payload),
      failed: false,
      changed: !localIsNewer && (!knewBefore || before != payload),
    );
  }

  /// The layout for ([workspaceId], [cacheKey]) when the memo already knows
  /// it, without a round-trip. Null means unknown: call [restore]. A known
  /// absence, or an unrestorable payload, comes back as `(layout: null)`, so
  /// the seed is final.
  ({EditorLayoutController? layout})? peek({
    required String workspaceId,
    required String cacheKey,
  }) {
    final memo = _memo;
    if (memo == null || !memo.knows(workspaceId, _cacheKind, cacheKey)) {
      return null;
    }
    final payload = memo.get(workspaceId, _cacheKind, cacheKey);
    return (layout: payload == null ? null : _codec.decode(payload));
  }

  /// Cancels any pending debounced write. Call from the host's `dispose` after
  /// a final [flushNow].
  void dispose() {
    _timer?.cancel();
  }
}
