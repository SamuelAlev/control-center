import 'dart:async';

import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// In-process copy of the editor layouts this client has read or written.
///
/// The server cache is what roams a layout across devices, but reading it
/// is a round-trip. A host that waited on it every time it swapped contexts
/// drew the seeded layout first, then rebuilt every tab body again when the
/// restored one arrived. With the payload here, a revisit restores in the
/// same frame the host swaps.
///
/// An entry may be a known ABSENCE (`null`): the server holds nothing for
/// that key, so the seed is final and there is nothing to wait for.
///
/// An entry also records whether the server is known to hold exactly that
/// payload ([isSynced]): a host leaving a context it never changed then sends
/// nothing, rather than replacing a newer layout another device saved with
/// the copy this client happened to remember.
///
/// Keyed by workspace, kind and key, so one memo serves every workspace
/// without a lookup ever reaching across them. Bounded by entry count; a
/// payload is a few hundred bytes.
class EditorLayoutMemo {
  /// Creates a memo that keeps the [capacity] most recently used entries.
  EditorLayoutMemo({this.capacity = 128});

  /// Most entries kept before the least recently used is dropped.
  final int capacity;

  final _entries = <String, ({String? payload, bool synced})>{};
  final _inFlight = <String, Future<void>>{};

  static String _key(String workspaceId, String kind, String key) =>
      '$workspaceId\u0000$kind\u0000$key';

  /// Whether the memo knows the payload for this key (including that the
  /// server holds none).
  bool knows(String workspaceId, String kind, String key) =>
      _entries.containsKey(_key(workspaceId, kind, key));

  /// The payload for this key, or null when absent or unknown. Check
  /// [knows] to tell those apart.
  String? get(String workspaceId, String kind, String key) {
    final k = _key(workspaceId, kind, key);
    if (!_entries.containsKey(k)) {
      return null;
    }
    // Refresh recency.
    final entry = _entries.remove(k)!;
    _entries[k] = entry;
    return entry.payload;
  }

  /// Records [payload] (null for "the server holds nothing"). [synced] says
  /// the server is known to hold exactly it: true for a payload just read
  /// from the server, false for a local write still on its way.
  void put(
    String workspaceId,
    String kind,
    String key,
    String? payload, {
    bool synced = false,
  }) {
    final k = _key(workspaceId, kind, key);
    _entries
      ..remove(k)
      ..[k] = (payload: payload, synced: synced);
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Marks [payload] as held by the server, when it is still this key's
  /// entry (a newer local write keeps its own, unconfirmed state).
  void confirm(String workspaceId, String kind, String key, String payload) {
    final k = _key(workspaceId, kind, key);
    if (_entries[k]?.payload == payload) {
      _entries[k] = (payload: payload, synced: true);
    }
  }

  /// Whether this key holds a local write the server has not confirmed: one
  /// still on its way, or one that failed and awaits the next save.
  bool hasUnsyncedWrite(String workspaceId, String kind, String key) {
    final entry = _entries[_key(workspaceId, kind, key)];
    return entry != null && !entry.synced;
  }

  /// Whether the server is known to hold exactly [payload] for this key, so
  /// writing it again would change nothing.
  bool isSynced(String workspaceId, String kind, String key, String payload) {
    final entry = _entries[_key(workspaceId, kind, key)];
    return entry != null && entry.synced && entry.payload == payload;
  }

  /// Reads this key from [cache] into the memo unless it is already known
  /// or already being read. Failures leave it unknown, so the host falls
  /// back to its own read.
  Future<void> prefetch(
    CacheRepository cache,
    String workspaceId,
    String kind,
    String key,
  ) {
    if (knows(workspaceId, kind, key)) {
      return Future.value();
    }
    final k = _key(workspaceId, kind, key);
    return _inFlight[k] ??= () async {
      try {
        final payload = await cache.read(workspaceId, kind, key);
        // A write that landed while the read was in flight is newer.
        if (!knows(workspaceId, kind, key)) {
          put(workspaceId, kind, key, payload, synced: true);
        }
      } on RemoteRpcException {
        // Refused server-side: stay unknown.
      } on RemoteRpcClientClosedException {
        // Connection dropped: stay unknown.
      } on TimeoutException {
        // No answer: stay unknown.
      } finally {
        unawaited(_inFlight.remove(k));
      }
    }();
  }
}
