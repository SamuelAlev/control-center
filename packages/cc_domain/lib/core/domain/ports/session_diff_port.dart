import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';

/// Computes the set of files an agent session changed in a worktree, so the
/// changes can be reviewed file-by-file before they are committed.
///
/// Pairs with `GitSnapshotPort`: a session captures a `start` working-tree ref
/// when it begins; diffing that ref against the current working tree (or a
/// later `head` ref) yields exactly what the session produced.
abstract interface class SessionDiffPort {
  /// Returns the changed files between [baseRef] and the current working tree
  /// of [worktreePath] — or between [baseRef] and [headRef] when [headRef] is
  /// given. Each [PrFile] carries its status, +/- counts and unified-diff
  /// patch. Returns an empty list when nothing changed or the path is not a
  /// git worktree.
  Future<List<PrFile>> changedFiles(
    String worktreePath,
    String baseRef, {
    String? headRef,
  });

  /// The worktree's changes split into git's two buckets — the VS Code Source
  /// Control model:
  ///  * `staged`: the index vs HEAD (`git diff --cached`);
  ///  * `unstaged`: the working tree vs the index (`git diff`) plus untracked
  ///    files (shown as additions).
  ///
  /// A partially-staged file appears in BOTH lists. Each [PrFile] carries its
  /// status, +/- counts and unified-diff patch. Both lists are empty when the
  /// tree is clean or [worktreePath] is not a git worktree.
  Future<({List<PrFile> staged, List<PrFile> unstaged})> groupedChanges(
    String worktreePath,
  );
}
