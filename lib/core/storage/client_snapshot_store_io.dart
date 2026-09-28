import 'dart:io';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/core/storage/rpc_snapshot_scope.dart';
import 'package:path/path.dart' as p;

/// Render-only budget for each authenticated server/user.
const int snapshotCacheMaxBytes = 16 * 1024 * 1024;

/// Dedicated client-render cache. Neither the server DB nor synced preferences
/// contain these snapshots. Only callers with a verified fingerprint and a
/// freshly authenticated user id may construct a persistent scope.
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
  final root = await controlCenterRootDir();
  return FileRpcSnapshotStore(
    File(
      p.join(
        root.path,
        'client_rpc_snapshots',
        snapshotServerKey(serverId),
        '${snapshotIdentityKey(fingerprint, userId)}.json',
      ),
    ),
  );
}

/// Removes every scoped snapshot for a forgotten pairing, across users/pins.
Future<void> forgetSnapshotServer(String serverId) async {
  if (serverId.isEmpty) {
    return;
  }
  try {
    final root = await controlCenterRootDir();
    final directory = Directory(
      p.join(root.path, 'client_rpc_snapshots', snapshotServerKey(serverId)),
    );
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  } on FileSystemException {
    // Cache eviction is best effort; forgetting credentials still succeeds.
  }
}

/// Atomic, owner-private file storage; pass a temporary path in tests.
class FileRpcSnapshotStore implements RpcSnapshotStore {
  /// Creates a store for a single verified server/user scope.
  FileRpcSnapshotStore(this.file);

  /// Client cache file, outside server-owned databases.
  final File file;

  @override
  Future<String?> load() async {
    try {
      if (await file.length() > 20 * 1024 * 1024) {
        return null;
      }
      return await file.readAsString();
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> save(String value) async {
    final parent = file.parent;
    await parent.create(recursive: true);
    await _private(parent.path, directory: true);
    final temporary = File(
      '${file.path}.tmp.$pid.${DateTime.now().microsecondsSinceEpoch}',
    );
    try {
      await temporary.create(exclusive: true);
      await _private(temporary.path, directory: false);
      await temporary.writeAsString(value, flush: true);
      await temporary.rename(file.path);
    } finally {
      if (temporary.existsSync()) {
        await temporary.delete();
      }
    }
  }

  // The cache can contain private workspace data. Never write bytes before
  // making the new file owner-readable only (rather than trusting the umask).
  Future<void> _private(String path, {required bool directory}) =>
      protectOwnerOnly(path, directory: directory);
}
