import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show repoGrantRequiredData, repoGrantRequiredKind;
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_harness/tools.dart' show ReadOnlyRoot;
import 'package:path/path.dart' as p;

/// Which of a space's repository worktrees a run may change.
///
/// Changing a repository's checkout takes Control Center's write grant on it,
/// for agent runs as for people. The server answers, from grants, the
/// worktrees the run's accountable person may write ([of]); every other
/// directory in the space's `repos/` is read-only for the run: bound
/// read-only in its sandbox and refused by every tool that changes files.
// ignore: avoid_classes_with_only_static_members
abstract final class ReadOnlyWorktrees {
  /// The worktree directories in [reposDir] that are not in [writable]
  /// (both compared with symlinks resolved), sorted. With [writable] null the
  /// grants could not be resolved, and every worktree is read-only.
  static List<String> of(String reposDir, List<String>? writable) {
    final List<FileSystemEntity> entries;
    try {
      entries = Directory(reposDir).listSync(followLinks: false);
    } on FileSystemException {
      return const [];
    }
    final allowed = {
      for (final dir in writable ?? const <String>[]) _real(dir),
    };
    return [
      for (final entry in entries.whereType<Directory>())
        if (!allowed.contains(_real(entry.path))) entry.path,
    ]..sort();
  }

  /// What a run is told when it tries to change [worktree].
  static String refusal(String worktree) =>
      '${p.basename(worktree)} is read-only for this run: changing a '
      "repository's checkout takes Control Center's write grant on it "
      '($repoGrantRequiredKind, level ${RepoGrantLevel.write.wireName}), and '
      'the person this run acts for does not hold it. Reading it is fine; ask '
      'a workspace admin for write access to change it';

  /// [worktree] as the harness file tools' read-only root.
  static ReadOnlyRoot root(String worktree) => ReadOnlyRoot(
    path: worktree,
    reason: refusal(worktree),
    refusal: repoGrantRequiredData(RepoGrantLevel.write),
  );

  /// The one of [worktrees] that [path] lies in, symlinks resolved on both
  /// sides (a path not created yet resolves through its deepest existing
  /// ancestor), or null.
  static String? containing(String path, List<String> worktrees) {
    if (worktrees.isEmpty) {
      return null;
    }
    final target = _real(path);
    for (final worktree in worktrees) {
      final dir = _real(worktree);
      if (p.equals(dir, target) || p.isWithin(dir, target)) {
        return worktree;
      }
    }
    return null;
  }

  /// [path] with `..` and symlinks gone, resolved through its deepest
  /// existing ancestor.
  static String _real(String path) {
    var existing = p.normalize(p.absolute(path));
    final missing = <String>[];
    while (true) {
      try {
        return p.joinAll([
          File(existing).resolveSymbolicLinksSync(),
          ...missing.reversed,
        ]);
      } on FileSystemException {
        final parent = p.dirname(existing);
        if (parent == existing) {
          return p.joinAll([existing, ...missing.reversed]);
        }
        missing.add(p.basename(existing));
        existing = parent;
      }
    }
  }
}
