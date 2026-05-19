import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/loop.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:path/path.dart' as p;

/// Persists harness transcripts as one JSON file per conversation.
///
/// **Why a file and not a table.** A transcript is bulk — whole tool results,
/// whole assistant turns, sometimes megabytes for one conversation — read
/// exactly once (at resume) and written on every turn. Putting that in the
/// workspace database would mean the server's single shared write connection
/// holding a transaction on the hot path of every turn, which is what queues
/// every RPC read behind it. On disk it is a write nobody waits on and a read
/// nobody repeats.
///
/// **Workspace-scoped by construction.** The file lives under the workspace's
/// own directory, the same place its database and blobs live, so deleting a
/// workspace deletes its transcripts with everything else and no query has to
/// remember a `workspaceId`.
class FileHarnessTranscriptStore implements HarnessTranscriptStore {
  /// Creates a [FileHarnessTranscriptStore].
  ///
  /// [workspaceDir] resolves a workspace's directory — passed as a callback so
  /// this stays free of a `cc_persistence` dependency, the same seam the blob
  /// store uses.
  FileHarnessTranscriptStore({
    required String Function(String workspaceId) workspaceDir,
    this.maxBytes = 32 * 1024 * 1024,
  }) : _workspaceDir = workspaceDir;

  final String Function(String workspaceId) _workspaceDir;

  /// Refuse to load a transcript larger than this.
  ///
  /// A runaway conversation should cost its own resume, not the server's
  /// memory: the run continues from an empty history exactly as it does today.
  final int maxBytes;

  /// Serializes writes per key.
  ///
  /// Two turns finishing close together would otherwise interleave their
  /// `writeAsString` calls and produce a file that is neither. The rename makes
  /// each write atomic; this makes the ORDER of them deterministic.
  final Map<String, Future<void>> _writes = {};

  /// Builds a storage key. The workspace is part of the path, not the key.
  static String keyFor({
    required String workspaceId,
    required String conversationId,
    String? agentId,
  }) =>
      // The agent is part of the key because two agents in one conversation
      // hold two different histories: they saw different tool results and were
      // given different system prompts, so merging them would hand each the
      // other's reasoning as its own.
      '$workspaceId/$conversationId${agentId == null ? '' : '#$agentId'}';

  @override
  Future<HarnessTranscript?> load(String key) async {
    final file = _fileFor(key);
    if (file == null || !file.existsSync()) {
      return null;
    }
    try {
      if (await file.length() > maxBytes) {
        CcInfraLog.warning(
          'transcript for $key exceeds ${maxBytes ~/ (1024 * 1024)}MB — '
          'starting fresh',
        );
        return null;
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return null;
      }
      return HarnessTranscript.fromJson(decoded.cast<String, dynamic>());
    } on Object catch (e) {
      // A truncated or unreadable transcript costs continuity, never the run.
      CcInfraLog.warning('transcript load failed for $key: $e');
      return null;
    }
  }

  @override
  Future<void> save(String key, HarnessTranscript transcript) {
    final previous = _writes[key] ?? Future<void>.value();
    final next = previous.then((_) => _write(key, transcript));
    _writes[key] = next;
    return next;
  }

  Future<void> _write(String key, HarnessTranscript transcript) async {
    final file = _fileFor(key);
    if (file == null) {
      return;
    }
    try {
      await file.parent.create(recursive: true);
      // Write-then-rename, so a crash mid-write leaves the PREVIOUS transcript
      // rather than a half-written one that fails to parse and silently loses
      // the whole conversation.
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(jsonEncode(transcript.toJson()));
      await temp.rename(file.path);
    } on Object catch (e) {
      CcInfraLog.warning('transcript save failed for $key: $e');
    }
  }

  @override
  Future<void> clear(String key) async {
    final file = _fileFor(key);
    if (file == null) {
      return;
    }
    try {
      if (file.existsSync()) {
        await file.delete();
      }
    } on Object {
      // Nothing to do: a transcript that will not delete is stale data, not a
      // failure the caller can act on.
    }
  }

  /// Deletes transcripts under [workspaceId] not touched within [maxAge].
  ///
  /// **Why a sweep rather than a delete on conversation removal.** A transcript
  /// is keyed by conversation AND agent, while the deletion signal we get is a
  /// SpaceDeleted carrying neither — a space holds many conversations and many
  /// agents. Reconstructing that mapping to delete precisely would mean the
  /// store querying the database, which is the dependency it exists without.
  /// A transcript is a cache: a stale one costs disk, never correctness,
  /// because a deleted conversation's id is never resumed. So it ages out.
  ///
  /// Deleting the workspace still removes them immediately, since they live in
  /// its directory.
  Future<int> prune({
    required String workspaceId,
    Duration maxAge = const Duration(days: 30),
  }) => _pruneDir(
    Directory(p.join(_workspaceDir(_sanitize(workspaceId)), 'transcripts')),
    maxAge,
  );

  /// Prunes every workspace's transcripts under [dataDir].
  ///
  /// Walks the directory layout rather than the workspace registry, so this
  /// needs no database handle and also reaches a workspace whose row is gone
  /// but whose directory a failed delete left behind.
  Future<int> pruneAll({
    required String dataDir,
    Duration maxAge = const Duration(days: 30),
  }) async {
    final root = Directory(dataDir);
    if (!root.existsSync()) {
      return 0;
    }
    var removed = 0;
    try {
      await for (final entity in root.list(followLinks: false)) {
        if (entity is! Directory) {
          continue;
        }
        removed += await _pruneDir(
          Directory(p.join(entity.path, 'transcripts')),
          maxAge,
        );
      }
    } on Object catch (e) {
      CcInfraLog.warning('transcript prune failed: $e');
    }
    return removed;
  }

  Future<int> _pruneDir(Directory dir, Duration maxAge) async {
    if (!dir.existsSync()) {
      return 0;
    }
    final cutoff = DateTime.now().subtract(maxAge);
    var removed = 0;
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.json')) {
          continue;
        }
        final stat = entity.statSync();
        if (stat.modified.isBefore(cutoff)) {
          await entity.delete();
          removed++;
        }
      }
    } on Object catch (e) {
      CcInfraLog.warning('transcript prune failed for ${dir.path}: $e');
    }
    return removed;
  }

  File? _fileFor(String key) {
    final slash = key.indexOf('/');
    if (slash <= 0 || slash == key.length - 1) {
      return null;
    }
    final workspaceId = key.substring(0, slash);
    final rest = key.substring(slash + 1);
    // Every component is sanitized, not just checked: these ids reach us from
    // a client, and `..` in either one would put the file outside the
    // workspace directory this store exists to keep it inside.
    final safeWorkspace = _sanitize(workspaceId);
    final safeName = _sanitize(rest);
    if (safeWorkspace.isEmpty || safeName.isEmpty) {
      return null;
    }
    return File(
      p.join(_workspaceDir(safeWorkspace), 'transcripts', '$safeName.json'),
    );
  }

  static String _sanitize(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_\-.#]'), '_').replaceAll('..', '_');
}
