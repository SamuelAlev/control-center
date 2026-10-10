import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Tree SHA of the working tree at [worktreePath], or null if git cannot
/// produce one.
///
/// Uses a private index (`GIT_INDEX_FILE`), so the real index and HEAD are
/// never touched.
///
/// Each capture resets the private index to HEAD (`git read-tree --reset`),
/// then `git add -A`. An index without HEAD's entries makes `git add -A` treat
/// a tracked file that also matches `.gitignore` as untracked and skip it, so
/// the tree is missing that file and a diff against HEAD reports a deletion
/// nobody made. That is `.vscode/launch.json.example` in a checkout that
/// ignores `.vscode/*` while the un-ignore rule names a different filename
/// (`launch.example.json`).
///
/// Seeding from the real index is the other trap: its stat cache makes
/// `git add -A` skip re-hashing a same-size edit whose mtime still matches,
/// so the tree keeps the stale blob. The private index's stat cache is only
/// ever written by this function's own `git add`, about the files that add
/// hashed, and git writes the index file itself, so racy-git detection holds.
/// Any later write changes the file's ctime, which no editor can restore, so
/// a forged mtime still re-hashes.
///
/// The private index persists per worktree so the stat cache carries over:
/// `read-tree --reset` keeps the stat data of entries whose blob still
/// matches HEAD, and the add re-hashes only paths that changed. A cold capture
/// hashes every file (seconds on a large repository); a warm one stats them.
/// Captures of one worktree run one at a time, since they share that index.
/// A warm capture that fails retries once from a fresh index.
///
/// A repository with no commit yet has nothing to seed; the add runs against
/// an empty index, which is the whole tree in that case.
Future<String?> captureWorkingTree(String worktreePath) {
  final key = p.normalize(p.absolute(worktreePath));
  final previous = _captures[key] ?? Future<void>.value();
  final run = previous.then((_) => _captureSerialized(key));
  final tail = run.then<void>((_) {}, onError: (Object _) {});
  _captures[key] = tail;
  unawaited(
    tail.whenComplete(() {
      if (identical(_captures[key], tail)) {
        _captures.remove(key);
      }
    }),
  );
  return run;
}

/// The last capture queued per worktree; the next one chains after it.
final _captures = <String, Future<void>>{};

/// Deletes the private index [captureWorkingTree] keeps for [worktreePath].
/// Call it when the worktree is torn down. Waits out a capture already
/// queued there, so that capture cannot write the index back afterwards.
Future<void> discardWorkingTreeCapture(String worktreePath) async {
  final key = p.normalize(p.absolute(worktreePath));
  await _captures[key];
  _deleteIndex(_privateIndexPath(key));
}

/// Deletes private indexes no capture has touched for [olderThan].
///
/// Teardown discards a worktree's index, but a worktree removed some other
/// way (by hand, a linked checkout unlinked, a server that died mid-destroy)
/// leaves one behind. The file name is a hash, so it cannot be traced back to
/// a path; age is the signal. Every capture rewrites its index, so one in use
/// stays young, and pruning one that is merely idle costs its next capture a
/// cold re-hash, never a wrong tree. Returns how many were deleted.
int pruneWorkingTreeCaptures({required Duration olderThan}) {
  final busy = {for (final key in _captures.keys) _privateIndexPath(key)};
  final cutoff = DateTime.now().subtract(olderThan);
  var pruned = 0;
  final List<FileSystemEntity> entries;
  try {
    entries = Directory.systemTemp.listSync(followLinks: false);
  } on FileSystemException {
    return 0;
  }
  for (final entry in entries) {
    if (entry is! File) {
      continue;
    }
    final name = p.basename(entry.path);
    if (!name.startsWith(_indexPrefix) || name.endsWith('.lock')) {
      continue;
    }
    if (busy.contains(entry.path)) {
      continue;
    }
    try {
      if (entry.lastModifiedSync().isAfter(cutoff)) {
        continue;
      }
    } on FileSystemException {
      continue;
    }
    _deleteIndex(entry.path);
    pruned++;
  }
  return pruned;
}

const _indexPrefix = 'cc_worktree_index_';

Future<String?> _captureSerialized(String worktreePath) async {
  final index = _privateIndexPath(worktreePath);
  final warm = File(index).existsSync();
  final sha = await _capture(worktreePath, index);
  if (sha != null || !warm) {
    return sha;
  }
  _deleteIndex(index);
  return _capture(worktreePath, index);
}

Future<String?> _capture(String worktreePath, String index) async {
  final env = {'GIT_INDEX_FILE': index};
  final head = await _git([
    'rev-parse',
    '--verify',
    '--quiet',
    'HEAD',
  ], worktreePath);
  if (head.exitCode == 0) {
    final read = await _git(
      ['read-tree', '--reset', 'HEAD'],
      worktreePath,
      env: env,
    );
    if (read.exitCode != 0) {
      return null;
    }
  } else {
    // No commit to reset to: an index left from before HEAD vanished would
    // carry stale entries into the tree.
    _deleteIndex(index);
  }
  final add = await _git(['add', '-A'], worktreePath, env: env);
  if (add.exitCode != 0) {
    return null;
  }
  final tree = await _git(['write-tree'], worktreePath, env: env);
  if (tree.exitCode != 0) {
    return null;
  }
  final sha = tree.stdout.trim();
  return sha.isEmpty ? null : sha;
}

/// Where [captureWorkingTree] keeps [worktreePath]'s private index.
@visibleForTesting
String workingTreeCaptureIndexPath(String worktreePath) =>
    _privateIndexPath(p.normalize(p.absolute(worktreePath)));

/// Stable across server restarts, so a restart reuses the warm index rather
/// than leaving one behind per run.
String _privateIndexPath(String worktreePath) {
  final digest = sha1.convert(utf8.encode(worktreePath)).toString();
  return p.join(
    Directory.systemTemp.path,
    '$_indexPrefix${digest.substring(0, 16)}',
  );
}

void _deleteIndex(String index) {
  for (final path in [index, '$index.lock']) {
    final file = File(path);
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (_) {}
    }
  }
}

Future<({int exitCode, String stdout, String stderr})> _git(
  List<String> args,
  String workdir, {
  Map<String, String>? env,
}) async {
  final result = await Process.run(
    'git',
    args,
    workingDirectory: workdir,
    environment: env,
  );
  return (
    exitCode: result.exitCode,
    stdout: result.stdout as String,
    stderr: result.stderr as String,
  );
}
