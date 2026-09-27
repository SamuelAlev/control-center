import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/storage/rpc_snapshot_scope.dart';
import 'package:web/web.dart' as web;

// Dedicated client-render database, outside observable/synced preferences and
// browser localStorage (whose small quota is shared with app configuration).
const _databasePrefix = 'cc_rpc_snapshots_v1_';
const _objectStore = 'snapshots';
const _maxPayloadBytes = 20 * 1024 * 1024;

/// Upper bound on retained render data for each verified server/user identity.
const int snapshotCacheMaxBytes = 16 * 1024 * 1024;

/// Creates an isolated IndexedDB scope for an authenticated user on a server
/// whose fingerprint was verified during the live handshake.
Future<RpcSnapshotStore> snapshotStoreFor({
  required String serverId,
  required String fingerprint,
  required String userId,
}) async {
  if (serverId.isEmpty || fingerprint.isEmpty || userId.isEmpty) {
    throw ArgumentError(
      'A verified server and authenticated user are required',
    );
  }
  return WebRpcSnapshotStore(
    '$_databasePrefix${snapshotServerKey(serverId)}',
    snapshotIdentityKey(fingerprint, userId),
  );
}

/// Forget all users and pins of this server without touching any preferences.
Future<void> forgetSnapshotServer(String serverId) async {
  if (serverId.isEmpty) {
    return;
  }
  try {
    final request = web.window.indexedDB.deleteDatabase(
      '$_databasePrefix${snapshotServerKey(serverId)}',
    );
    final completed = Completer<void>();
    request.onsuccess = ((web.Event _) {
      if (!completed.isCompleted) {
        completed.complete();
      }
    }).toJS;
    request.onerror = ((web.Event _) {
      if (!completed.isCompleted) {
        completed.completeError(StateError('IndexedDB delete failed'));
      }
    }).toJS;
    request.onblocked = ((web.Event _) {
      if (!completed.isCompleted) {
        completed.completeError(StateError('IndexedDB delete blocked'));
      }
    }).toJS;
    await completed.future.timeout(const Duration(seconds: 2));
  } on Object {
    // Browser storage can be disabled or blocked in another tab. No cache
    // can be read without another authenticated connection in either case.
  }
}

/// One 16 MiB-bounded snapshot record; each server has its own IndexedDB so a
/// server forget deletes all its users atomically without an origin-wide scan.
class WebRpcSnapshotStore implements RpcSnapshotStore {
  /// Creates a namespaced store (keys contain only non-secret hashes).
  WebRpcSnapshotStore(this.databaseName, this.key);

  /// IndexedDB database for one server.
  final String databaseName;

  /// Fingerprint/user identity key inside [databaseName].
  final String key;

  @override
  Future<String?> load() async {
    web.IDBDatabase? database;
    try {
      database = await _open(databaseName);
      final transaction = database.transaction(_objectStore.toJS, 'readonly');
      final request = transaction.objectStore(_objectStore).get(key.toJS);
      final completed = Completer<String?>();
      request.onsuccess = ((web.Event _) {
        final result = request.result;
        if (!completed.isCompleted) {
          completed.complete(
            result != null && result.isA<JSString>()
                ? (result as JSString).toDart
                : null,
          );
        }
      }).toJS;
      request.onerror = ((web.Event _) {
        if (!completed.isCompleted) {
          completed.complete(null);
        }
      }).toJS;
      final value = await completed.future.timeout(const Duration(seconds: 2));
      if (value != null && value.length > _maxPayloadBytes) {
        return null;
      }
      return value;
    } on Object {
      return null;
    } finally {
      database?.close();
    }
  }

  @override
  Future<void> save(String value) async {
    // The cache bounds its entries; this separately caps JSON framing and the
    // stored document even if a future caller bypasses that cache.
    if (value.length > _maxPayloadBytes ||
        utf8.encode(value).length > _maxPayloadBytes) {
      return;
    }
    web.IDBDatabase? database;
    try {
      database = await _open(databaseName);
      final transaction = database.transaction(_objectStore.toJS, 'readwrite');
      final completed = Completer<void>();
      transaction.oncomplete = ((web.Event _) {
        if (!completed.isCompleted) {
          completed.complete();
        }
      }).toJS;
      transaction.onabort = ((web.Event _) {
        if (!completed.isCompleted) {
          completed.completeError(StateError('IndexedDB write aborted'));
        }
      }).toJS;
      transaction.onerror = ((web.Event _) {
        if (!completed.isCompleted) {
          completed.completeError(StateError('IndexedDB write failed'));
        }
      }).toJS;
      transaction.objectStore(_objectStore).put(value.toJS, key.toJS);
      await completed.future.timeout(const Duration(seconds: 2));
    } on Object {
      // Quota, private browsing, and denied storage degrade to memory-only.
    } finally {
      database?.close();
    }
  }
}

Future<web.IDBDatabase> _open(String name) async {
  final request = web.window.indexedDB.open(name, 1);
  final completed = Completer<web.IDBDatabase>();
  request.onupgradeneeded = ((web.Event _) {
    final database = request.result! as web.IDBDatabase;
    if (!database.objectStoreNames.contains(_objectStore)) {
      database.createObjectStore(_objectStore);
    }
  }).toJS;
  request.onsuccess = ((web.Event _) {
    final database = request.result! as web.IDBDatabase;
    if (completed.isCompleted) {
      database.close();
    } else {
      completed.complete(database);
    }
  }).toJS;
  request.onerror = ((web.Event _) {
    if (!completed.isCompleted) {
      completed.completeError(StateError('IndexedDB open failed'));
    }
  }).toJS;
  request.onblocked = ((web.Event _) {
    if (!completed.isCompleted) {
      completed.completeError(StateError('IndexedDB upgrade blocked'));
    }
  }).toJS;
  return completed.future.timeout(const Duration(seconds: 2));
}
