import 'dart:io';

import 'package:path/path.dart' as p;

/// Tree SHA of the working tree at [worktreePath], or null if git cannot
/// produce one.
///
/// Uses a temporary index (`GIT_INDEX_FILE`), so the real index and HEAD are
/// never touched.
///
/// The temp index is seeded with `git read-tree HEAD`, then `git add -A`.
/// An empty index makes `git add -A` treat a tracked file that also matches
/// `.gitignore` as untracked and skip it, so the tree is missing that file
/// and a diff against HEAD reports a deletion nobody made. That is
/// `.vscode/launch.json.example` in a checkout that ignores `.vscode/*` while
/// the un-ignore rule names a different filename (`launch.example.json`).
///
/// Seeding from the real index is the other trap: its stat cache makes
/// `git add -A` skip re-hashing a same-size edit whose mtime still matches,
/// so the tree keeps the stale blob. `read-tree` writes entries with an empty
/// stat cache, so the following add re-hashes every path from disk.
///
/// A repository with no commit yet has nothing to seed; the add runs against
/// an empty index, which is the whole tree in that case.
Future<String?> captureWorkingTree(String worktreePath) async {
  final tmpIndex = p.join(
    Directory.systemTemp.path,
    'cc_worktree_index_${worktreePath.hashCode.toUnsigned(32)}_${_counter++}',
  );
  try {
    final env = {'GIT_INDEX_FILE': tmpIndex};
    final head = await _git([
      'rev-parse',
      '--verify',
      '--quiet',
      'HEAD',
    ], worktreePath);
    if (head.exitCode == 0) {
      final read = await _git(['read-tree', 'HEAD'], worktreePath, env: env);
      if (read.exitCode != 0) {
        return null;
      }
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
  } finally {
    final index = File(tmpIndex);
    if (index.existsSync()) {
      try {
        index.deleteSync();
      } catch (_) {}
    }
  }
}

int _counter = 0;

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
