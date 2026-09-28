import 'dart:async';
import 'dart:convert';

/// Persistence boundary for snapshots belonging to one authenticated server/user.
/// The owner must give each identity its own store and discard it on sign-out.
abstract interface class RpcSnapshotStore {
  /// Loads the serialized snapshot set, or null when absent.
  Future<String?> load();

  /// Atomically replaces the serialized snapshot set when storage permits.
  Future<void> save(String value);
}

/// Bounded, JSON-only snapshots for rendering while a live RPC is revalidated.
/// Nothing in this cache is an authorization decision or mutation authority.
class RpcSnapshotCache {
  /// Creates a bounded working set with optional identity-scoped persistence.
  RpcSnapshotCache({
    this._store,
    this.maxEntries = 256,
    this.maxBytes = 15 * 1024 * 1024,
  }) {
    if (maxEntries <= 0) {
      throw ArgumentError.value(maxEntries, 'maxEntries', 'must be positive');
    }
    if (maxBytes <= 0) {
      throw ArgumentError.value(maxBytes, 'maxBytes', 'must be positive');
    }
  }

  final RpcSnapshotStore? _store;

  /// Maximum number of retained query variants.
  final int maxEntries;

  /// Maximum UTF-8 bytes for retained keys and JSON values.
  final int maxBytes;
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
      final decoded = jsonDecode(saved);
      if (decoded is! Map ||
          decoded['version'] != 1 ||
          decoded['entries'] is! List ||
          _clearedDuringHydration) {
        return;
      }
      for (final item in decoded['entries'] as List) {
        if (item is! Map || item['key'] is! String || item['value'] is! Map) {
          continue;
        }
        final key = item['key'] as String;
        if (_touchedDuringHydration.contains(key) ||
            _entries.containsKey(key)) {
          continue;
        }
        try {
          _putEncoded(
            key,
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

  /// Returns a detached JSON map, so callers cannot mutate retained data.
  Map<String, dynamic>? read(String key) {
    final data = _entries.remove(key);
    if (data == null) {
      return null;
    }
    _entries[key] = data; // LRU, including offline reads.
    return (jsonDecode(data) as Map).cast<String, dynamic>();
  }

  /// Stores an independent JSON snapshot, including empty maps.
  void write(String key, Map<String, dynamic> value) {
    try {
      final encoded = jsonEncode(value);
      if (_hydratingNow) {
        _touchedDuringHydration.add(key);
      }
      if (_entries[key] == encoded) {
        _entries.remove(key);
        _entries[key] = encoded; // Refresh LRU without rewriting storage.
        return;
      }
      _putEncoded(key, encoded);
      _changed();
    } catch (_) {
      // Non-JSON values cannot be rendered from persistent storage.
    }
  }

  void _putEncoded(String key, String encoded) {
    final size = utf8.encode(key).length + utf8.encode(encoded).length;
    final previous = _entries.remove(key);
    if (previous != null) {
      _bytes -= utf8.encode(key).length + utf8.encode(previous).length;
    }
    if (size > maxBytes) {
      return;
    }
    _entries[key] = encoded;
    _bytes += size;
    while (_entries.length > maxEntries || _bytes > maxBytes) {
      final oldest = _entries.keys.first;
      final removed = _entries.remove(oldest)!;
      _bytes -= utf8.encode(oldest).length + utf8.encode(removed).length;
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
    _bytes -= utf8.encode(key).length + utf8.encode(value).length;
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
    _saveTimer?.cancel();
    // Many active subscription snapshots can arrive in one short burst.
    // Debounce whole-store serialization and persistence across frames.
    _saveTimer = Timer(const Duration(milliseconds: 350), () {
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
      final payload = jsonEncode({
        'version': 1,
        'entries': [
          for (final entry in _entries.entries)
            {'key': entry.key, 'value': jsonDecode(entry.value)},
        ],
      });
      try {
        await store.save(payload);
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
