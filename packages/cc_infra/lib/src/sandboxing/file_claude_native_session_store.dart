import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/sandboxing/claude_native_session.dart';
import 'package:path/path.dart' as p;

/// Durable [ClaudeNativeSessionStore] backed by one small JSON file per scope.
///
/// **Why files and not a table.** A record is a session id, a policy
/// fingerprint and a handful of counters — bytes, read once at the top of a
/// dispatch and written once at a turn boundary. Putting it in the workspace
/// database would add a transaction to the hot path of every turn for data a
/// same-process cache already holds.
///
/// **Workspace-scoped by construction.** Files live under the workspace's own
/// directory (the same place its database and blobs live), so deleting a
/// workspace deletes its session mapping with everything else and no query has
/// to remember a `workspaceId`. The scope hash is the FILE NAME, never a path
/// segment a host supplies, so no scope can address another scope's file.
class FileClaudeNativeSessionStore implements ClaudeNativeSessionStore {
  /// Creates a [FileClaudeNativeSessionStore].
  ///
  /// [_workspaceDir] resolves a workspace's directory — a callback so this
  /// stays free of a `cc_persistence` dependency, the same seam the harness
  /// transcript store and blob store use.
  FileClaudeNativeSessionStore({required this._workspaceDir});

  final String Function(String workspaceId) _workspaceDir;

  /// Serializes writes per (workspace, scope) so two turns finishing together
  /// cannot interleave into a file that is neither. The rename is atomic; this
  /// makes the ORDER of the writes deterministic.
  final Map<String, Future<void>> _writes = {};

  /// Subdirectory under the workspace root holding session mappings.
  static const subdirectory = 'claude-sessions';

  /// The file a scope's record lives in. [workspaceId] scopes the directory;
  /// the opaque [storageKey] is the file name.
  static String pathFor({
    required String Function(String) workspaceDir,
    required String workspaceId,
    required String storageKey,
  }) => p.join(workspaceDir(workspaceId), subdirectory, '$storageKey.json');

  String _filePath(String workspaceId, String storageKey) => pathFor(
    workspaceDir: _workspaceDir,
    workspaceId: workspaceId,
    storageKey: storageKey,
  );

  static String _mapKey(String workspaceId, String storageKey) =>
      '$workspaceId\u0000$storageKey';

  /// Waits for an in-flight write to the same file, so a read never sees a
  /// half-renamed state (the rename is atomic; the order is what the
  /// serializer fixes).
  Future<void> _awaitWrite(String workspaceId, String storageKey) async {
    final pending = _writes[_mapKey(workspaceId, storageKey)];
    if (pending != null) {
      await pending;
    }
  }

  @override
  Future<ClaudeNativeSessionRecord?> load({
    required String workspaceId,
    required String storageKey,
  }) async {
    if (workspaceId.isEmpty || storageKey.isEmpty) {
      return null;
    }
    await _awaitWrite(workspaceId, storageKey);
    final file = File(_filePath(workspaceId, storageKey));
    try {
      if (!file.existsSync()) {
        return null;
      }
      final raw = await file.readAsString();
      if (raw.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return ClaudeNativeSessionRecord.fromJson(decoded);
    } on Object catch (e) {
      // A corrupt or unreadable record degrades to "no resume" — never a
      // failed run.
      CcInfraLog.warning('claude-session: unreadable record $storageKey: $e');
      return null;
    }
  }

  @override
  Future<void> save({
    required String workspaceId,
    required ClaudeNativeSessionRecord record,
  }) async {
    final storageKey = record.storageKey;
    if (workspaceId.isEmpty || storageKey.isEmpty) {
      return;
    }
    final mapKey = _mapKey(workspaceId, storageKey);
    final previous = _writes[mapKey] ?? Future<void>.value();
    final next = previous.then((_) async {
      final file = File(_filePath(workspaceId, storageKey));
      try {
        await file.parent.create(recursive: true);
        // Atomic replace: a reader sees the old file or the new one, never a
        // partial write.
        final tmp = File('${file.path}.tmp');
        await tmp.writeAsString(jsonEncode(record.toJson()), flush: true);
        await tmp.rename(file.path);
      } on Object catch (e) {
        CcInfraLog.warning('claude-session: failed to persist $storageKey: $e');
      }
    });
    _writes[mapKey] = next;
    await next;
    if (identical(_writes[mapKey], next)) {
      unawaited(_writes.remove(mapKey));
    }
  }

  @override
  Future<void> clear({
    required String workspaceId,
    required String storageKey,
  }) async {
    if (workspaceId.isEmpty || storageKey.isEmpty) {
      return;
    }
    await _awaitWrite(workspaceId, storageKey);
    final file = File(_filePath(workspaceId, storageKey));
    try {
      if (file.existsSync()) {
        await file.delete();
      }
    } on Object catch (e) {
      CcInfraLog.warning('claude-session: failed to clear $storageKey: $e');
    }
  }
}
