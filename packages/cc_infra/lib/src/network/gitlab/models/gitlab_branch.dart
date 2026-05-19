import 'package:cc_infra/src/network/gitlab/models/gitlab_commit.dart';

/// A repository branch, as returned by
/// `GET /projects/:id/repository/branches`.
///
/// The nested `commit` object is the branch tip and carries the full commit
/// shape, so it is read with [GitLabCommit] rather than duplicated here.
class GitLabBranch {
  /// Creates a [GitLabBranch].
  const GitLabBranch({
    required this.name,
    this.isDefault = false,
    this.merged = false,
    this.protected = false,
    this.webUrl = '',
    this.commit,
  });

  /// Reads a [GitLabBranch] off a decoded JSON object.
  factory GitLabBranch.fromJson(Map<String, dynamic> json) {
    final commit = json['commit'];
    return GitLabBranch(
      name: json['name'] as String? ?? '',
      isDefault: json['default'] as bool? ?? false,
      merged: json['merged'] as bool? ?? false,
      protected: json['protected'] as bool? ?? false,
      webUrl: json['web_url'] as String? ?? '',
      commit: commit is Map<String, dynamic>
          ? GitLabCommit.fromJson(commit)
          : null,
    );
  }

  /// Branch name, without a `refs/heads/` prefix.
  final String name;

  /// Whether this is the project's default branch.
  final bool isDefault;

  /// Whether the branch has been merged into the default branch.
  final bool merged;

  /// Whether push/merge protection applies.
  final bool protected;

  /// Link to the branch page.
  final String webUrl;

  /// The branch tip. Null when the payload omitted it.
  final GitLabCommit? commit;
}
