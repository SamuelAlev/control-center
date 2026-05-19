import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// Pull request published.
class PullRequestPublished implements DomainEvent {
  /// Creates a [PullRequestPublished] event.
  const PullRequestPublished({
    required this.prId,
    required this.workspaceId,
    required this.repoOwner,
    required this.repoName,
    required this.occurredAt,
  });

  /// Pull request identifier.
  final String prId;

  /// Workspace that produced the PR.
  final String workspaceId;

  /// GitHub owner of the target repository.
  final String repoOwner;

  /// Repository name on GitHub.
  final String repoName;

  @override
  final DateTime occurredAt;
}

/// Fired when a pull request's lifecycle status changes (merged, closed,
/// opened, or reopened).
///
/// Pipeline triggers subscribe to this with an optional `status` match filter
/// (e.g. fire only on `merged`/`closed`). Distinct from [PrMerged], which is a
/// narrower merge-only signal kept for notifications.
class PullRequestStatusChanged implements DomainEvent {
  /// Creates a [PullRequestStatusChanged].
  const PullRequestStatusChanged({
    required this.status,
    required this.occurredAt,
    this.prId,
    this.workspaceId,
    this.repoFullName,
    this.prNumber,
  });

  /// New status: `merged`, `closed`, `opened`, `reopened`, or `approved`
  /// (the latter emitted when the local user submits an approving review).
  final String status;

  /// Internal PR draft identifier, if known.
  final String? prId;

  /// Workspace scope, if known.
  final String? workspaceId;

  /// GitHub repository in `owner/name` form, if known.
  final String? repoFullName;

  /// GitHub PR number, if known.
  final int? prNumber;

  @override
  final DateTime occurredAt;
}

/// Fired when a pull request is merged.
class PrMerged implements DomainEvent {
  /// Creates a [PrMerged].
  const PrMerged({
    required this.prId,
    required this.workspaceId,
    required this.agentId,
    required this.occurredAt,
  });

  /// Pull request identifier.
  final String prId;

  /// Workspace that produced the PR.
  final String workspaceId;

  /// Agent that authored or managed the PR.
  final String agentId;

  @override
  final DateTime occurredAt;
}

/// Fired when GitHub asks for the server user's review on a pull request,
/// detected via the notifications-API poll (`reason: review_requested`).
///
/// Workspace-scoped: the poll resolves the repo back to every workspace that
/// links it and publishes one event per workspace, so the notification can
/// deep-link into the right PR list.
class PrReviewRequested implements DomainEvent {
  /// Creates a [PrReviewRequested] event.
  const PrReviewRequested({
    required this.workspaceId,
    required this.repoOwner,
    required this.repoName,
    required this.prNumber,
    required this.prTitle,
    required this.occurredAt,
  });

  /// The workspace linking the repository.
  final String workspaceId;

  /// GitHub repository owner.
  final String repoOwner;

  /// GitHub repository name.
  final String repoName;

  /// Pull request number.
  final int prNumber;

  /// Pull request title (from the notification subject).
  final String prTitle;

  @override
  final DateTime occurredAt;
}

/// Fired when the server user is mentioned in a pull request, detected via
/// the notifications-API poll (`reason: mention`).
///
/// Like [PrReviewRequested], workspace-scoped: the poll resolves the repo to
/// every linking workspace and publishes one event per workspace. Together
/// with [PrReviewRequested], this is one of only two PR notifications the user
/// receives — so they are pinged solely when GitHub already decided the thread
/// concerns them (a review request on them/their team, or a direct mention),
/// never merely because a new PR appeared.
class PrMentioned implements DomainEvent {
  /// Creates a [PrMentioned].
  const PrMentioned({
    required this.workspaceId,
    required this.repoOwner,
    required this.repoName,
    required this.prNumber,
    required this.prTitle,
    required this.occurredAt,
  });

  /// The workspace linking the repository.
  final String workspaceId;

  /// GitHub repository owner.
  final String repoOwner;

  /// GitHub repository name.
  final String repoName;

  /// Pull request number.
  final int prNumber;

  /// Pull request title (from the notification subject).
  final String prTitle;

  @override
  final DateTime occurredAt;
}

/// Fired when a PR in the server user's GitHub inbox is merged, detected via
/// the notifications-API poll (`reason: state_change`, verified MERGED against
/// the live PR state — closed-without-merge and reopen never fire this).
/// Workspace-scoped like [PrMentioned]: one event per linking workspace.
class ExternalPrMerged implements DomainEvent {
  /// Creates an [ExternalPrMerged].
  const ExternalPrMerged({
    required this.workspaceId,
    required this.repoOwner,
    required this.repoName,
    required this.prNumber,
    required this.prTitle,
    required this.occurredAt,
  });

  /// The workspace linking the repository.
  final String workspaceId;

  /// GitHub repository owner.
  final String repoOwner;

  /// GitHub repository name.
  final String repoName;

  /// Pull request number.
  final int prNumber;

  /// Pull request title (from the notification subject).
  final String prTitle;

  @override
  final DateTime occurredAt;
}

/// Fired when a new external PR is detected via GitHub API polling.
///
/// "External" means authored by someone other than our agents — e.g. a
/// teammate opening a PR that needs review.
class ExternalPrDetected implements DomainEvent {
  /// Creates an [ExternalPrDetected] event.
  const ExternalPrDetected({
    required this.repoOwner,
    required this.repoName,
    required this.prNumber,
    required this.prTitle,
    required this.author,
    required this.workspaceId,
    required this.occurredAt,
  });

  /// Owning workspace, or null. External-PR polling runs once over all linked
  /// repos and a repo can belong to several workspaces, so a single owning
  /// workspace cannot be attributed — this is cross-workspace by design.
  /// Null-workspace notifications are excluded from the workspace-scoped
  /// dashboard activity feed but still surface in the global notification bell.
  final String? workspaceId;

  /// GitHub repository owner.
  final String repoOwner;

  /// GitHub repository name.
  final String repoName;

  /// Pull request number.
  final int prNumber;

  /// Pull request title.
  final String prTitle;

  /// GitHub username of the PR author.
  final String author;

  @override
  final DateTime occurredAt;
}
