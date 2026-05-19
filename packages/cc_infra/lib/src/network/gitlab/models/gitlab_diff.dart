/// One changed file of a merge request or commit, as returned by
/// `GET .../merge_requests/:iid/diffs`, the `changes` array of
/// `.../merge_requests/:iid/changes`, and
/// `GET /projects/:id/repository/commits/:sha/diff`.
///
/// All three endpoints share this shape, which is why one model serves the
/// merge-request diff, the file list and the per-commit file list.
///
/// [diff] holds only the hunks (`@@ …` onwards) — GitLab omits the
/// `diff --git`/`---`/`+++` framing that a unified-diff parser expects, so the
/// mapper synthesizes it.
class GitLabDiff {
  /// Creates a [GitLabDiff].
  const GitLabDiff({
    required this.oldPath,
    required this.newPath,
    required this.diff,
    this.aMode = '',
    this.bMode = '',
    this.newFile = false,
    this.renamedFile = false,
    this.deletedFile = false,
    this.generatedFile = false,
    this.tooLarge = false,
  });

  /// Reads a [GitLabDiff] off a decoded JSON object.
  factory GitLabDiff.fromJson(Map<String, dynamic> json) => GitLabDiff(
    oldPath: json['old_path'] as String? ?? '',
    newPath: json['new_path'] as String? ?? '',
    diff: json['diff'] as String? ?? '',
    aMode: json['a_mode'] as String? ?? '',
    bMode: json['b_mode'] as String? ?? '',
    newFile: json['new_file'] as bool? ?? false,
    renamedFile: json['renamed_file'] as bool? ?? false,
    deletedFile: json['deleted_file'] as bool? ?? false,
    generatedFile: json['generated_file'] as bool? ?? false,
    tooLarge: json['too_large'] as bool? ?? false,
  );

  /// Path before the change. Equals [newPath] for a plain modification.
  final String oldPath;

  /// Path after the change. Equals [oldPath] for a plain modification.
  final String newPath;

  /// The hunk text, starting at the first `@@`. Empty for a binary file, a
  /// mode-only change, or a diff GitLab refused to render ([tooLarge]).
  final String diff;

  /// File mode before the change (`100644`). Empty when not supplied.
  final String aMode;

  /// File mode after the change. Empty when not supplied.
  final String bMode;

  /// Whether the file was added.
  final bool newFile;

  /// Whether the file was renamed (possibly with content changes).
  final bool renamedFile;

  /// Whether the file was deleted.
  final bool deletedFile;

  /// Whether GitLab classified the file as generated (collapsed by default in
  /// its own UI).
  final bool generatedFile;

  /// Whether GitLab truncated this file's diff because it exceeded the
  /// instance limit. [diff] is then empty.
  final bool tooLarge;
}
