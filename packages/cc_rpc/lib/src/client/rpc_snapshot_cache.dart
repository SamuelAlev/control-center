import 'dart:async';
import 'dart:convert';

import 'package:cc_rpc/src/channel/frame_codec.dart' show decodeJsonFrame;

/// Persistence boundary for snapshots belonging to one authenticated server/user.
/// The owner must give each identity its own store and discard it on sign-out.
abstract interface class RpcSnapshotStore {
  /// Loads the serialized snapshot set, or null when absent.
  Future<String?> load();

  /// Atomically replaces the serialized snapshot set when storage permits.
  Future<void> save(String value);
}

/// Largest single snapshot (key + JSON, in characters) the cache retains.
///
/// A snapshot past this is not worth holding as a render shortcut: it crowds
/// the whole working set out of [RpcSnapshotCache.maxBytes] and rewrites
/// megabytes of storage per flush. Generous enough for a chat window or a PR
/// diff; meant to stop the occasional giant blob.
const int kRpcSnapshotMaxEntryChars = 1024 * 1024;

/// Bounded, JSON-only snapshots for rendering while a live RPC is revalidated.
/// Nothing in this cache is an authorization decision or mutation authority.
///
/// Entries are held ENCODED and only ever encoded once: persistence
/// concatenates the stored strings (no decode/re-encode of the store), and
/// hydration slices the saved document into per-entry strings without
/// decoding the values — each is decoded when a screen actually reads it.
class RpcSnapshotCache {
  /// Creates a bounded working set with optional identity-scoped persistence.
  RpcSnapshotCache({
    this._store,
    this.maxEntries = 256,
    this.maxBytes = 15 * 1024 * 1024,
    this.maxEntryChars = kRpcSnapshotMaxEntryChars,
    this.persistDelay = const Duration(seconds: 3),
  }) {
    if (maxEntries <= 0) {
      throw ArgumentError.value(maxEntries, 'maxEntries', 'must be positive');
    }
    if (maxBytes <= 0) {
      throw ArgumentError.value(maxBytes, 'maxBytes', 'must be positive');
    }
    if (maxEntryChars <= 0) {
      throw ArgumentError.value(
        maxEntryChars,
        'maxEntryChars',
        'must be positive',
      );
    }
  }

  final RpcSnapshotStore? _store;

  /// Maximum number of retained query variants.
  final int maxEntries;

  /// Maximum retained size of keys and JSON values, counted in string
  /// characters (UTF-16 code units). A cheap, monotone stand-in for UTF-8
  /// bytes: measuring real bytes meant UTF-8-encoding the key, the new value
  /// AND the value it replaced on every single snapshot.
  final int maxBytes;

  /// Largest single entry (key + JSON characters) that is retained. A larger
  /// snapshot also evicts the entry it would have replaced, so a stale render
  /// is never served for a query whose current value was not kept.
  final int maxEntryChars;

  /// How long persistence waits after the last change. Snapshots stream in
  /// continuously while anything is live; the store is a render shortcut for
  /// the next launch, so it is written in a few-second rhythm, not per burst.
  final Duration persistDelay;

  final Map<String, String> _entries = {};
  final Set<String> _touchedDuringHydration = {};
  int _bytes = 0;
  int _revision = 0;
  Future<void>? _hydrating;
  Future<void> _saving = Future<void>.value();
  Timer? _saveTimer;
  bool _clearedDuringHydration = false;
  bool _hydratingNow = false;

  /// Loads intact entries, without overwriting writes/removals made while
  /// storage was being read. A corrupt or unavailable store is simply empty.
  Future<void> hydrate() => _hydrating ??= _hydrate();

  Future<void> _hydrate() async {
    final store = _store;
    if (store == null) {
      return;
    }
    _hydratingNow = true;
    try {
      final saved = await store.load();
      if (saved == null || saved.length > maxBytes * 4) {
        return;
      }
      if (_clearedDuringHydration) {
        return;
      }
      // Fast path: the document this cache writes, sliced into its entries
      // without decoding a single value. Anything else (a hand-written or
      // reordered document) takes the full decode below.
      final sliced = _sliceStore(saved);
      if (sliced != null) {
        for (final (keyLiteral, value) in sliced) {
          try {
            final key = jsonDecode(keyLiteral);
            if (key is! String || !value.startsWith('{')) {
              continue;
            }
            _hydrateEntry(key, value);
          } catch (_) {
            // One broken entry must not hide the rest of the offline surface.
          }
        }
        return;
      }
      final decoded = jsonDecode(saved);
      if (decoded is! Map ||
          decoded['version'] != 1 ||
          decoded['entries'] is! List) {
        return;
      }
      for (final item in decoded['entries'] as List) {
        if (item is! Map || item['key'] is! String || item['value'] is! Map) {
          continue;
        }
        try {
          _hydrateEntry(
            item['key'] as String,
            jsonEncode((item['value'] as Map).cast<String, dynamic>()),
          );
        } catch (_) {
          // One broken entry must not hide the rest of the offline surface.
        }
      }
    } catch (_) {
      // Corrupt or unavailable persistence cannot block a live RPC request.
    } finally {
      _hydratingNow = false;
      _touchedDuringHydration.clear();
    }
  }

  void _hydrateEntry(String key, String encoded) {
    if (_touchedDuringHydration.contains(key) || _entries.containsKey(key)) {
      return;
    }
    if (key.length + encoded.length > maxEntryChars) {
      return;
    }
    _putEncoded(key, encoded);
  }

  /// Returns a detached JSON map, so callers cannot mutate retained data.
  Map<String, dynamic>? read(String key) {
    final data = _touch(key);
    if (data == null) {
      return null;
    }
    try {
      return (jsonDecode(data) as Map).cast<String, dynamic>();
    } catch (_) {
      remove(key); // Hydrated lazily: a corrupt entry surfaces here.
      return null;
    }
  }

  /// [read], decoding a large entry off the UI isolate (see
  /// [decodeJsonFrame]). For a screen mounting onto a big cached snapshot —
  /// a chat window, a PR diff — the synchronous decode was a frame-sized
  /// stall exactly when the screen was trying to paint.
  Future<Map<String, dynamic>?> readAsync(String key) async {
    final data = _touch(key);
    if (data == null) {
      return null;
    }
    try {
      return await decodeJsonFrame(data);
    } catch (_) {
      if (identical(_entries[key], data)) {
        remove(key);
      }
      return null;
    }
  }

  /// Whether [key] is currently retained (no LRU refresh, no decode).
  bool contains(String key) => _entries.containsKey(key);

  /// The encoded entry for [key], refreshed as most recently used.
  String? _touch(String key) {
    final data = _entries.remove(key);
    if (data == null) {
      return null;
    }
    _entries[key] = data; // LRU, including offline reads.
    return data;
  }

  /// Stores an independent JSON snapshot, including empty maps.
  void write(String key, Map<String, dynamic> value) {
    final String encoded;
    try {
      encoded = jsonEncode(value);
    } catch (_) {
      // Non-JSON values cannot be rendered from persistent storage.
      return;
    }
    if (key.length + encoded.length > maxEntryChars) {
      // Not retained — and neither is the older value it supersedes, which
      // would otherwise render as current on the next mount.
      remove(key);
      return;
    }
    if (_hydratingNow) {
      _touchedDuringHydration.add(key);
    }
    final current = _entries.remove(key);
    if (current != null) {
      if (current == encoded) {
        _entries[key] = current; // Refresh LRU without rewriting storage.
        return;
      }
      _bytes -= key.length + current.length;
    }
    _putEncoded(key, encoded);
    _changed();
  }

  void _putEncoded(String key, String encoded) {
    final size = key.length + encoded.length;
    final previous = _entries.remove(key);
    if (previous != null) {
      _bytes -= key.length + previous.length;
    }
    if (size > maxBytes) {
      return;
    }
    _entries[key] = encoded;
    _bytes += size;
    while (_entries.length > maxEntries || _bytes > maxBytes) {
      final oldest = _entries.keys.first;
      final removed = _entries.remove(oldest)!;
      _bytes -= oldest.length + removed.length;
    }
  }

  /// Evicts one query variant, including an in-flight hydration of that key.
  void remove(String key) {
    if (_hydratingNow) {
      _touchedDuringHydration.add(key);
    }
    final value = _entries.remove(key);
    if (value == null) {
      // It may still exist in the store whose load is in flight.
      if (_hydratingNow) {
        _changed();
      }
      return;
    }
    _bytes -= key.length + value.length;
    _changed();
  }

  /// Clears this identity's entire working set and schedules persistence.
  void clear() {
    if (_hydratingNow) {
      _clearedDuringHydration = true;
    }
    _touchedDuringHydration.clear();
    _entries.clear();
    _bytes = 0;
    _changed();
  }

  /// Discards snapshots not proven to belong to a currently authorized
  /// workspace. Invoke after fresh identity/membership verification. Known
  /// global views retain only rows for still-authorized workspaces; malformed
  /// views are discarded rather than risk disclosing a revoked workspace.
  void retainWorkspaces(Set<String> allowedIds) {
    for (final key in _entries.keys.toList()) {
      try {
        final coordinates = jsonDecode(key);
        if (coordinates is! List ||
            coordinates.length != 3 ||
            coordinates[1] is! String ||
            coordinates[2] is! Map) {
          remove(key);
          continue;
        }
        final query = coordinates[1] as String;
        final rowShape = _crossWorkspaceRows[query];
        if (rowShape != null) {
          final snapshot = jsonDecode(_entries[key]!);
          if (snapshot is! Map ||
              snapshot.length != 1 ||
              snapshot[rowShape.$1] is! List) {
            remove(key);
            continue;
          }
          final rows = snapshot[rowShape.$1] as List;
          if (rows.any((row) => row is! Map)) {
            remove(key);
            continue;
          }
          final permitted = rows
              .where((row) => allowedIds.contains((row as Map)[rowShape.$2]))
              .toList();
          if (permitted.length != rows.length) {
            snapshot[rowShape.$1] = permitted;
            _putEncoded(key, jsonEncode(snapshot));
            _changed();
          }
          continue;
        }
        final workspace = (coordinates[2] as Map)['workspace_id'];
        if (workspace is! String || !allowedIds.contains(workspace)) {
          remove(key);
        }
      } catch (_) {
        remove(key);
      }
    }
  }

  /// Invalidates all offline renders for a workspace after the server reports
  /// that this identity no longer has access to it. Also drops global views
  /// that might still embed that workspace's rows.
  void evictWorkspace(String workspaceId) {
    for (final key in _entries.keys.toList()) {
      try {
        final coordinates = jsonDecode(key);
        if (coordinates is! List ||
            coordinates.length != 3 ||
            coordinates[1] is! String ||
            coordinates[2] is! Map) {
          continue;
        }
        final args = coordinates[2] as Map;
        if (args['workspace_id'] == workspaceId ||
            _crossWorkspaceRows.containsKey(coordinates[1])) {
          remove(key);
        }
      } catch (_) {
        // Unknown application keys carry no workspace coordinates.
      }
    }
  }

  void _changed() {
    _revision++;
    if (_store == null) {
      return;
    }
    // Many active subscription snapshots arrive continuously while anything
    // is live. One pending timer, not one per change: the store is written
    // [persistDelay] after the first unsaved change, so a steady stream
    // still persists on a bounded rhythm instead of postponing forever.
    _saveTimer ??= Timer(persistDelay, () {
      _saveTimer = null;
      unawaited(flush());
    });
  }

  /// Persists the latest bounded state. Writes serialize so an older write
  /// cannot finish after a newer one. Storage failures do not affect live RPC.
  Future<void> flush() {
    final store = _store;
    if (store == null) {
      return Future<void>.value();
    }
    _saveTimer?.cancel();
    _saveTimer = null;
    final revision = _revision;
    return _saving = _saving.then((_) async {
      // Hydration cannot merge an older on-disk snapshot over a live write.
      final hydrating = _hydrating;
      if (hydrating != null) {
        await hydrating;
      }
      if (revision != _revision) {
        return;
      }
      // The stored values are already JSON text: splice them in verbatim.
      // Decoding every entry only to re-encode the whole store was the
      // single most expensive thing this cache did, every few hundred ms.
      // The document is byte-compatible with the decoded-then-encoded form
      // (same keys, same order), so older builds still load it.
      final payload = StringBuffer('{"version":1,"entries":[');
      var first = true;
      for (final entry in _entries.entries) {
        if (!first) {
          payload.write(',');
        }
        first = false;
        payload
          ..write('{"key":')
          ..write(jsonEncode(entry.key))
          ..write(',"value":')
          ..write(entry.value)
          ..write('}');
      }
      payload.write(']}');
      try {
        await store.save(payload.toString());
      } catch (_) {
        // Retry is possible via a later write or explicit flush.
      }
    });
  }
}

const _crossWorkspaceRows = <String, (String, String)>{
  'workspace.watchAll': ('workspaces', 'id'),
  'agents.watchAll': ('agents', 'workspace_id'),
  'pipeline_run.watchAll': ('runs', 'workspace_id'),
  'agent_run_log.watchRecent': ('logs', 'workspace_id'),
};

/// Slices a store document in exactly the shape [RpcSnapshotCache.flush]
/// writes — `{"version":1,"entries":[{"key":K,"value":V},…]}`, no whitespace —
/// into `(key literal, value JSON)` pairs WITHOUT decoding the values. Null
/// for any other shape; the caller then falls back to a full decode.
///
/// A purely lexical walk (strings and nesting only), so a value it returns is
/// well-formed only as far as its brackets go; readers decode defensively.
List<(String, String)>? _sliceStore(String saved) {
  const head = '{"version":1,"entries":[';
  const keyHead = '{"key":';
  const valueHead = ',"value":';
  if (!saved.startsWith(head)) {
    return null;
  }
  final out = <(String, String)>[];
  var i = head.length;
  if (saved.length == i + 2 && saved.startsWith(']}', i)) {
    return out;
  }
  while (true) {
    if (!saved.startsWith(keyHead, i)) {
      return null;
    }
    i += keyHead.length;
    final keyEnd = _skipJsonString(saved, i);
    if (keyEnd < 0) {
      return null;
    }
    final keyLiteral = saved.substring(i, keyEnd);
    i = keyEnd;
    if (!saved.startsWith(valueHead, i)) {
      return null;
    }
    i += valueHead.length;
    final valueEnd = _skipJsonValue(saved, i);
    if (valueEnd < 0) {
      return null;
    }
    out.add((keyLiteral, saved.substring(i, valueEnd)));
    i = valueEnd;
    if (!saved.startsWith('}', i)) {
      return null;
    }
    i++;
    if (saved.startsWith(',', i)) {
      i++;
      continue;
    }
    if (saved.length == i + 2 && saved.startsWith(']}', i)) {
      return out;
    }
    return null;
  }
}

const int _quote = 0x22;
const int _backslash = 0x5C;

/// The index just past the JSON string starting at [start], or -1.
int _skipJsonString(String s, int start) {
  if (start >= s.length || s.codeUnitAt(start) != _quote) {
    return -1;
  }
  var i = start + 1;
  while (i < s.length) {
    final c = s.codeUnitAt(i);
    if (c == _backslash) {
      i += 2;
      continue;
    }
    if (c == _quote) {
      return i + 1;
    }
    i++;
  }
  return -1;
}

/// The index just past the JSON value starting at [start], or -1.
int _skipJsonValue(String s, int start) {
  if (start >= s.length) {
    return -1;
  }
  final first = s.codeUnitAt(start);
  if (first == _quote) {
    return _skipJsonString(s, start);
  }
  if (first != 0x7B /* { */ && first != 0x5B /* [ */ ) {
    // A scalar: runs to the next structural delimiter.
    var i = start;
    while (i < s.length) {
      final c = s.codeUnitAt(i);
      if (c == 0x2C /* , */ || c == 0x7D /* } */ || c == 0x5D /* ] */ ) {
        break;
      }
      i++;
    }
    return i == start ? -1 : i;
  }
  var depth = 0;
  var i = start;
  while (i < s.length) {
    final c = s.codeUnitAt(i);
    if (c == _quote) {
      i = _skipJsonString(s, i);
      if (i < 0) {
        return -1;
      }
      continue;
    }
    if (c == 0x7B || c == 0x5B) {
      depth++;
    } else if (c == 0x7D || c == 0x5D) {
      depth--;
      if (depth == 0) {
        return i + 1;
      }
    }
    i++;
  }
  return -1;
}
