import 'dart:io';

import 'package:cc_domain/core/domain/ports/git_snapshot_port.dart';
import 'package:path/path.dart' as p;

/// A [GitSnapshotPort] that shells out to `git`.
///
/// Capture writes a tree object for the entire working tree using a TEMPORARY
/// index (via `GIT_INDEX_FILE`), so it never disturbs the real index or HEAD.
/// Restore replays that tree onto the worktree with `read-tree` +
/// `checkout-index -a -f`, which reverts modified and deleted files to the
/// snapshot. It does NOT delete files created after the snapshot (that would
/// require `git clean`, which is banned in this repo), so restore is a faithful
/// undo of edits, additive for brand-new files.
class ProcessGitSnapshotAdapter implements GitSnapshotPort {
  /// Creates a [ProcessGitSnapshotAdapter].
  const ProcessGitSnapshotAdapter();

  @override
  Future<String?> capture(String worktreePath) async {
    if (!await _isWorktree(worktreePath)) {
      return null;
    }
    final tmpIndex = p.join(
      Directory.systemTemp.path,
      'cc_snap_index_${worktreePath.hashCode.toUnsigned(32)}_${_counter++}',
    );
    try {
      final env = {'GIT_INDEX_FILE': tmpIndex};
      final add = await _run(['add', '-A'], worktreePath, env: env);
      if (add.exitCode != 0) {
        return null;
      }
      final tree = await _run(['write-tree'], worktreePath, env: env);
      if (tree.exitCode != 0) {
        return null;
      }
      final sha = tree.stdout.trim();
      return sha.isEmpty ? null : sha;
    } finally {
      final f = File(tmpIndex);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
  }

  @override
  Future<void> restore(String worktreePath, String ref) async {
    final read = await _run(['read-tree', ref], worktreePath);
    if (read.exitCode != 0) {
      throw StateError('git read-tree $ref failed: ${read.stderr}');
    }
    final checkout =
        await _run(['checkout-index', '-a', '-f'], worktreePath);
    if (checkout.exitCode != 0) {
      throw StateError('git checkout-index failed: ${checkout.stderr}');
    }
  }

  Future<bool> _isWorktree(String path) async {
    if (!Directory(path).existsSync()) {
      return false;
    }
    final result = await _run(['rev-parse', '--is-inside-work-tree'], path);
    return result.exitCode == 0 && result.stdout.trim() == 'true';
  }

  Future<({int exitCode, String stdout, String stderr})> _run(
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

  static int _counter = 0;
}
