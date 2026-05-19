/// Raw review-state of a single PR as returned by the GraphQL detail query
/// (`reviewRequests` + `latestReviews`). Deliberately holds undecoded,
/// network-shaped values so this model stays free of feature-domain types —
/// the pr_review mapper turns it into the enriched `PrReviewer` list.
///
/// This data is unavailable over REST: the REST `GET /pulls/{n}` only returns
/// *user* `requested_reviewers` (never teams), and exposes neither the
/// `asCodeOwner` flag nor `onBehalfOf` (which team a completed review counts
/// for). Both are needed to render team reviewers, code-owner shields, and the
/// team↔member review merge.
class GitHubPrReviewState {
  /// Creates a [GitHubPrReviewState].
  const GitHubPrReviewState({
    this.pendingUsers = const [],
    this.pendingTeams = const [],
    this.completedReviews = const [],
  });

  /// Individual users requested for review who have not yet submitted.
  final List<GitHubPendingUserRequest> pendingUsers;

  /// Teams requested for review that have not yet been satisfied by a member.
  final List<GitHubPendingTeamRequest> pendingTeams;

  /// The latest review per reviewer (approved / changes requested / commented /
  /// dismissed), each carrying the teams it was submitted on behalf of.
  final List<GitHubCompletedReview> completedReviews;
}

/// A pending user review request.
class GitHubPendingUserRequest {
  /// Creates a [GitHubPendingUserRequest].
  const GitHubPendingUserRequest({
    required this.login,
    required this.avatarUrl,
    required this.asCodeOwner,
  });

  /// The requested user's login.
  final String login;

  /// The requested user's avatar URL.
  final String avatarUrl;

  /// Whether GitHub flagged this request as coming from CODEOWNERS.
  final bool asCodeOwner;
}

/// A pending team review request.
class GitHubPendingTeamRequest {
  /// Creates a [GitHubPendingTeamRequest].
  const GitHubPendingTeamRequest({
    required this.name,
    required this.slug,
    required this.asCodeOwner,
  });

  /// The requested team's display name.
  final String name;

  /// The requested team's slug (the identity used for add/remove + merge).
  final String slug;

  /// Whether GitHub flagged this request as coming from CODEOWNERS.
  final bool asCodeOwner;
}

/// A completed review (the latest one per reviewer).
class GitHubCompletedReview {
  /// Creates a [GitHubCompletedReview].
  const GitHubCompletedReview({
    required this.authorLogin,
    required this.authorAvatarUrl,
    required this.state,
    this.onBehalfOf = const [],
  });

  /// Login of the reviewer who submitted this review.
  final String authorLogin;

  /// Avatar URL of the reviewer.
  final String authorAvatarUrl;

  /// Raw GraphQL `PullRequestReviewState` enum string: `APPROVED`,
  /// `CHANGES_REQUESTED`, `COMMENTED`, `DISMISSED`, or `PENDING`.
  final String state;

  /// Teams this review was submitted on behalf of (drives the team↔member
  /// merge — a team's required-review row collapses with the member's review).
  final List<GitHubReviewTeamRef> onBehalfOf;
}

/// A lightweight team reference (name + slug) used inside review state.
class GitHubReviewTeamRef {
  /// Creates a [GitHubReviewTeamRef].
  const GitHubReviewTeamRef({required this.name, required this.slug});

  /// The team's display name.
  final String name;

  /// The team's slug.
  final String slug;
}
