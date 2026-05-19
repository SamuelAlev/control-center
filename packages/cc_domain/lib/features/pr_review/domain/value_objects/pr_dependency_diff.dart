// One changed lockfile in a PR, with its computed dependency delta.
//
// `LockfileDiffer` produces the pure delta; this binds it to the PR row that
// owns it so the UI can say WHICH lockfile moved, not just that something did
// (a monorepo routinely changes three at once).
//
// ignore_for_file: sort_constructors_first

import 'package:cc_domain/features/pr_review/domain/services/lockfile_diff.dart';

/// A PR's dependency diff for one lockfile.
class PrDependencyDiff {
  /// Creates a [PrDependencyDiff].
  const PrDependencyDiff({
    required this.id,
    required this.workspaceId,
    required this.prExternalId,
    required this.filePath,
    required this.diff,
    this.baseSha,
    this.headSha,
  });

  /// Row id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The PR this diff belongs to.
  final String prExternalId;

  /// Repository-relative path of the lockfile.
  final String filePath;

  /// The computed delta.
  final DependencyDiff diff;

  /// Base SHA the diff was computed from.
  final String? baseSha;

  /// Head SHA the diff was computed against.
  final String? headSha;

  /// The ecosystem this lockfile belongs to.
  LockfileEcosystem get ecosystem => diff.ecosystem;

  /// Added + removed + upgraded count.
  int get churn => diff.churn;

  /// Whether any dependency moved.
  bool get isEmpty => diff.isEmpty;

  /// Whether any upgrade crossed a major version.
  bool get hasMajorBump => diff.upgraded.any((u) => u.majorBump);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrDependencyDiff &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          prExternalId == other.prExternalId &&
          filePath == other.filePath &&
          diff == other.diff &&
          baseSha == other.baseSha &&
          headSha == other.headSha;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    prExternalId,
    filePath,
    diff,
    baseSha,
    headSha,
  );
}
