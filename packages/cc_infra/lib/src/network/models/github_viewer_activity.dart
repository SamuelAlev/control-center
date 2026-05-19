/// One pull request the viewer is involved with, as returned by the
/// viewer-activity search.
///
/// Deliberately thin: the activity sweep only needs enough to route a
/// notification (which repo, which PR, what to call it) and to dedupe it. Every
/// richer read — diff size, checks, reviewers — belongs to the PR list/detail
/// queries, which fetch it for the handful of PRs actually on screen.
class GitHubViewerPr {
  /// Creates a [GitHubViewerPr].
  const GitHubViewerPr({
    required this.repoFullName,
    required this.number,
    required this.title,
    this.updatedAt,
    this.mergedByLogin,
  });

  /// Decodes one GraphQL `PullRequest` search node, or null when the node is
  /// missing the identity fields (a non-PR hit deserializes as an empty map).
  static GitHubViewerPr? fromNode(Map<String, dynamic> node) {
    final number = (node['number'] as num?)?.toInt() ?? 0;
    final repo =
        (node['repository'] as Map<String, dynamic>?)?['nameWithOwner']
            as String? ??
        '';
    if (number <= 0 || repo.isEmpty) {
      return null;
    }
    return GitHubViewerPr(
      repoFullName: repo,
      number: number,
      title: node['title'] as String? ?? '',
      updatedAt: DateTime.tryParse(node['updatedAt'] as String? ?? '')?.toUtc(),
      mergedByLogin:
          (node['mergedBy'] as Map<String, dynamic>?)?['login'] as String?,
    );
  }

  /// The repository in `owner/name` form.
  final String repoFullName;

  /// The pull request number.
  final int number;

  /// The pull request title.
  final String title;

  /// When the pull request last updated.
  final DateTime? updatedAt;

  /// The GitHub login of whoever merged the pull request, when it is merged.
  ///
  /// Null on every unmerged PR (and on a merge GitHub attributes to no user,
  /// e.g. a deleted account), which reads as "unknown merger" — the client's
  /// self-suppression then degrades to notifying rather than guessing.
  final String? mergedByLogin;

  /// The stable dedupe key, `owner/name#123`.
  ///
  /// This replaces the notification inbox's opaque thread id. A thread id was
  /// per-subscription and could be retired by GitHub; a `repo#number` is the PR
  /// itself, so the dedupe survives anything short of the PR being deleted.
  String get key => '$repoFullName#$number';

  /// The `owner` half of [repoFullName], or empty when malformed.
  String get owner {
    final slash = repoFullName.indexOf('/');
    return slash > 0 ? repoFullName.substring(0, slash) : '';
  }

  /// The `name` half of [repoFullName], or empty when malformed.
  String get name {
    final slash = repoFullName.indexOf('/');
    return slash > 0 ? repoFullName.substring(slash + 1) : '';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitHubViewerPr &&
          other.repoFullName == repoFullName &&
          other.number == number &&
          other.title == title &&
          other.updatedAt == updatedAt &&
          other.mergedByLogin == mergedByLogin;

  @override
  int get hashCode =>
      Object.hash(repoFullName, number, title, updatedAt, mergedByLogin);
}

/// One sweep of the viewer's GitHub pull-request activity, assembled from a
/// single aliased `search` request.
///
/// The four lanes answer the four things the old `GET /notifications` poll used
/// a thread `reason` for — except that each lane is *already* the verified
/// answer, because GitHub applied the predicate server-side:
///
///  * [reviewRequested] is the viewer's **currently pending** review set. GitHub
///    drops a reviewer from `review-requested:` results the moment they submit a
///    review, so membership is the pending bit — no per-PR review-state probe.
///    It includes reviews requested of a **team the viewer belongs to**, which
///    is most of them in practice, and needs no org-teams lookup to do it.
///  * [mentioned] is PRs that @-mentioned the viewer in the window.
///  * [merged] is PRs the viewer was involved with that are merged — `is:merged`
///    is the verification, so no per-PR merge-state probe.
///  * [updated] is open PRs the viewer is involved with that moved in the
///    window. It drives cache-freshness signals only and never notifies.
class GitHubViewerActivity {
  /// Creates a [GitHubViewerActivity].
  const GitHubViewerActivity({
    this.reviewRequested = const [],
    this.mentioned = const [],
    this.merged = const [],
    this.updated = const [],
  });

  /// Open, non-draft PRs whose review is pending on the viewer (directly or via
  /// one of their teams).
  final List<GitHubViewerPr> reviewRequested;

  /// PRs that mentioned the viewer in the window.
  final List<GitHubViewerPr> mentioned;

  /// Merged PRs the viewer was involved with in the window.
  final List<GitHubViewerPr> merged;

  /// Open PRs the viewer is involved with that updated in the window.
  final List<GitHubViewerPr> updated;

  /// Every PR across every lane, deduped by [GitHubViewerPr.key].
  Iterable<GitHubViewerPr> get all {
    final seen = <String>{};
    return [
      ...reviewRequested,
      ...mentioned,
      ...merged,
      ...updated,
    ].where((pr) => seen.add(pr.key));
  }
}
