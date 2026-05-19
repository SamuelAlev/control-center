import 'dart:async';

import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/host/editor_layout_codec.dart';

/// Debounced, workspace-scoped persistence of an editor split tree.
///
/// Wraps the [EditorLayoutCodec] and a [CacheRepository] (server-backed
/// `cache.read`/`cache.write`, so layouts roam across devices). Writes are
/// debounced (`debounce`, default 400ms) and coalesced; the host flushes
/// synchronously on dispose / context switch. All I/O is fire-and-forget — a
/// failed cache write must never surface in the UI.
///
/// The host owns the `workspaceId` + `cacheKey` (channel id for messaging, PR
/// identity for the workbench) and passes them per call, so one persistence
/// instance can follow a host across context switches.
class EditorLayoutPersistence {
  /// Creates a persistence helper writing under [_cacheKind] using [_codec].
  EditorLayoutPersistence({
    required this._codec,
    required this._cache,
    required this._cacheKind,
    this._debounce = const Duration(milliseconds: 400),
  });

  final EditorLayoutCodec _codec;
  final CacheRepository _cache;
  final String _cacheKind;
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

  void _write(String workspaceId, String cacheKey, EditorLayoutController l) {
    // Fire-and-forget: a failed cache write must not surface in the UI.
    _cache.put(workspaceId, _cacheKind, cacheKey, _codec.encode(l));
  }

  /// Reads and decodes the persisted layout for ([workspaceId], [cacheKey]), or
  /// null when nothing is stored / the payload is unrestorable.
  Future<EditorLayoutController?> restore({
    required String workspaceId,
    required String cacheKey,
  }) async {
    final payload = await _cache.read(workspaceId, _cacheKind, cacheKey);
    if (payload == null) {
      return null;
    }
    return _codec.decode(payload);
  }

  /// Cancels any pending debounced write. Call from the host's `dispose` after
  /// a final [flushNow].
  void dispose() {
    _timer?.cancel();
  }
}
