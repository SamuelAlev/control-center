/// Result shapes [GitHubGraphQLClient]'s queries return.
/// @docImport 'package:cc_infra/src/network/github_graphql_client.dart';
library;

/// Raw open-pull-request nodes for a single repo, as returned by the batched
/// GraphQL query. Holds undecoded GraphQL `PullRequest` maps so this network
/// model stays free of feature-domain types — the pr_review mapper turns the
/// nodes into `PullRequest` entities.
class GitHubRepoPrNodes {
  /// Creates a [GitHubRepoPrNodes].
  const GitHubRepoPrNodes({
    required this.nodes,
    required this.hasMore,
    this.totalCount,
  });

  /// Raw GraphQL `PullRequest` node maps (created-desc, first page).
  final List<Map<String, dynamic>> nodes;

  /// Whether the repo has more open PRs beyond this first page.
  final bool hasMore;

  /// The repo's total open PR count across every page, or null when GitHub
  /// did not report it.
  final int? totalCount;
}

/// Result of [GitHubGraphQLClient.fetchOpenPullRequestsBatch]: the viewer's
/// login (for `reviewed-by-me` derivation) plus the per-repo nodes keyed by the
/// caller's input index. Repos that errored/are inaccessible are simply absent
/// from [byIndex] (GraphQL returns partial data + an errors array; one bad repo
/// must not blank the whole dashboard).
class GitHubPrBatchResult {
  /// Creates a [GitHubPrBatchResult].
  const GitHubPrBatchResult({required this.viewerLogin, required this.byIndex});

  /// The authenticated user's login, or null if the query couldn't resolve it.
  final String? viewerLogin;

  /// Per-repo nodes keyed by the index of the repo in the caller's input list.
  final Map<int, GitHubRepoPrNodes> byIndex;
}

/// One PR's slice of the checks/review enrichment pass
/// ([GitHubGraphQLClient.fetchOpenPullRequestsChecks]): the raw
/// `statusCheckRollup.state` string (null when no checks are configured) and
/// the raw `reviewDecision` string (null when no reviews are required/given).
typedef GitHubPrStatusOverlay = ({
  String? checksRollup,
  String? reviewDecision,
});

/// One inline review thread's conversation state, from
/// [GitHubGraphQLClient.listReviewThreads].
///
/// [commentIds] are REST `databaseId`s, so a thread's state can be stamped onto
/// the comments the diff already fetched without a per-comment round trip.
class GitHubReviewThread {
  /// Creates a [GitHubReviewThread].
  const GitHubReviewThread({
    required this.id,
    required this.isResolved,
    required this.isOutdated,
    required this.commentIds,
    this.resolvedByLogin,
  });

  /// GraphQL node id of the thread — the handle the resolve mutations take.
  final String id;

  /// Whether the conversation is marked resolved.
  final bool isResolved;

  /// Whether the thread's anchor line is gone from the current diff.
  final bool isOutdated;

  /// Numeric ids of the thread's comments.
  final List<int> commentIds;

  /// Login of the user who resolved the thread (`resolvedBy.login`), or `null`
  /// when unresolved, deleted, or withheld.
  final String? resolvedByLogin;
}

/// One reaction on a review summary, from
/// [GitHubGraphQLClient.listReviewReactions].
class GitHubReviewReaction {
  /// Creates a [GitHubReviewReaction].
  const GitHubReviewReaction({
    required this.id,
    required this.content,
    required this.login,
  });

  /// GraphQL node id of the reaction — the handle `removeReaction` takes.
  final String id;

  /// Reaction content in the REST shortcode vocabulary (`+1`, `rocket`, …).
  final String content;

  /// Login of the account that reacted (empty when withheld).
  final String login;
}

/// One review's reactions plus the handles reacting to it requires, from
/// [GitHubGraphQLClient.listReviewReactions].
class GitHubReviewReactionSet {
  /// Creates a [GitHubReviewReactionSet].
  const GitHubReviewReactionSet({
    required this.databaseId,
    required this.nodeId,
    required this.reactions,
  });

  /// The review's REST numeric id — what joins this back to the REST review.
  final int databaseId;

  /// GraphQL node id of the review — the `addReaction` subject handle.
  final String nodeId;

  /// The reactions themselves.
  final List<GitHubReviewReaction> reactions;
}

/// A head branch plus its last-commit activity, from
/// [GitHubGraphQLClient.listBranchesWithActivity].
class GitHubBranchActivity {
  /// Creates a [GitHubBranchActivity].
  const GitHubBranchActivity({
    required this.name,
    required this.committedDate,
    required this.authorLogin,
  });

  /// Branch name (without the `refs/heads/` prefix).
  final String name;

  /// Date of the branch's tip commit, or null if unavailable.
  final DateTime? committedDate;

  /// GitHub login of the tip commit's author, or null if the author doesn't
  /// map to a GitHub user.
  final String? authorLogin;
}

/// A single pull-request template discovered in a repo: a display [name] and
/// the markdown [body] used to seed a new PR's description. [isDefault] marks
/// the repo's single conventional `pull_request_template.md` (as opposed to a
/// named template from a `PULL_REQUEST_TEMPLATE/` directory) so the UI can
/// localise its label.
class GitHubPrTemplate {
  /// Creates a [GitHubPrTemplate].
  const GitHubPrTemplate({
    required this.name,
    required this.body,
    this.isDefault = false,
  });

  /// Display name — derived from the template's filename, or empty for the
  /// single default template (the UI substitutes a localised "Default").
  final String name;

  /// The template's markdown content.
  final String body;

  /// Whether this is the repo's single default template (not a named one).
  final bool isDefault;
}
