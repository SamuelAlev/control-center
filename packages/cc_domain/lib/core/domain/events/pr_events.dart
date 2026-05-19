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
    required this.workspaceId,
    this.prId,
    this.repoFullName,
    this.prNumber,
  });

  /// New status: `merged`, `closed`, `opened`, `reopened`, or `approved`
  /// (the latter emitted when the local user submits an approving review).
  final String status;

  /// Internal PR draft identifier, if known.
  final String? prId;

  /// Workspace scope.
  ///
  /// Required. `pull_requests` rows live in a per-workspace database file, so
  /// a status change that could not name its workspace was a change no
  /// listener could route — and every production publisher already had it.
  final String workspaceId;

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

/// A pull request the operator authored became mergeable, or stopped being.
///
/// Published by the open-PR poller from the snapshot diff it already computes.
/// Author-gated at the source: the poller sweeps every open PR in every linked
/// repo, so without the gate a busy monorepo would announce strangers' work.
class PrMergeReadinessChanged implements DomainEvent {
  /// Creates a [PrMergeReadinessChanged].
  const PrMergeReadinessChanged({
    required this.workspaceId,
    required this.repoOwner,
    required this.repoName,
    required this.prNumber,
    required this.prTitle,
    required this.ready,
    required this.reason,
    required this.occurredAt,
    this.forUserId,
  });

  /// The workspace linking the repository.
  final String workspaceId;

  /// GitHub repository owner.
  final String repoOwner;

  /// GitHub repository name.
  final String repoName;

  /// Pull request number.
  final int prNumber;

  /// Pull request title.
  final String prTitle;

  /// True on the edge into mergeable, false on the edge out of it.
  final bool ready;

  /// `PrBlockReason.name` when [ready] is false, `none` otherwise. A string
  /// rather than the enum so this core event does not import a feature type —
  /// the same choice [PullRequestStatusChanged.status] already makes.
  final String reason;

  /// The Control Center user this concerns.
  final String? forUserId;

  @override
  final DateTime occurredAt;
}

/// A reviewer decided on a pull request the operator authored.
class PrReviewDecisionChanged implements DomainEvent {
  /// Creates a [PrReviewDecisionChanged].
  const PrReviewDecisionChanged({
    required this.workspaceId,
    required this.repoOwner,
    required this.repoName,
    required this.prNumber,
    required this.prTitle,
    required this.decision,
    required this.reviewersRemaining,
    required this.occurredAt,
    this.approverLogin,
    this.forUserId,
  });

  /// The workspace linking the repository.
  final String workspaceId;

  /// GitHub repository owner.
  final String repoOwner;

  /// GitHub repository name.
  final String repoName;

  /// Pull request number.
  final int prNumber;

  /// Pull request title.
  final String prTitle;

  /// `approved`, `changesRequested` or `dismissed`.
  final String decision;

  /// Reviewers and teams still to respond. This is the outstanding-request
  /// count, NOT "N of M required" — branch protection is not modelled, so the
  /// copy must not imply a requirement total the server cannot know.
  final int reviewersRemaining;

  /// Who decided, when it could be determined. Null is normal and never blocks
  /// the notification.
  final String? approverLogin;

  /// The Control Center user this concerns.
  final String? forUserId;

  @override
  final DateTime occurredAt;
}

/// CI on a pull request the operator authored went red, or recovered.
class PrChecksStatusChanged implements DomainEvent {
  /// Creates a [PrChecksStatusChanged].
  const PrChecksStatusChanged({
    required this.workspaceId,
    required this.repoOwner,
    required this.repoName,
    required this.prNumber,
    required this.prTitle,
    required this.failing,
    required this.occurredAt,
    this.failingCheckName,
    this.failingCheckUrl,
    this.forUserId,
  });

  /// The workspace linking the repository.
  final String workspaceId;

  /// GitHub repository owner.
  final String repoOwner;

  /// GitHub repository name.
  final String repoName;

  /// Pull request number.
  final int prNumber;

  /// Pull request title.
  final String prTitle;

  /// True on the edge into failing, false on the edge back to passing.
  final bool failing;

  /// The first failing check, when a targeted fetch named it. Null renders an
  /// unattributed "checks failed" rather than delaying the notification.
  final String? failingCheckName;

  /// Link to the failing run.
  final String? failingCheckUrl;

  /// The Control Center user this concerns.
  final String? forUserId;

  @override
  final DateTime occurredAt;
}

/// The operator was @mentioned in a specific comment on a pull request.
///
/// Strictly better than [PrMentioned], which knows only that GitHub's
/// `mentions:@me` search matched the PR: this one is resolved down to the
/// comment, so the notification can name the file and line and deep-link the
/// reader straight to it. Both exist because the comment sweep is capped per
/// sweep — [PrMentioned] is the fallback for a PR the cap did not reach, and
/// the two lanes suppress each other so one mention never pings twice.
class PrCommentMentioned implements DomainEvent {
  /// Creates a [PrCommentMentioned].
  const PrCommentMentioned({
    required this.workspaceId,
    required this.repoOwner,
    required this.repoName,
    required this.prNumber,
    required this.prTitle,
    required this.commentId,
    required this.authorLogin,
    required this.bodyPreview,
    required this.isReviewComment,
    required this.occurredAt,
    this.threadId,
    this.path,
    this.line,
    this.forUserId,
  });

  /// The workspace linking the repository.
  final String workspaceId;

  /// GitHub repository owner.
  final String repoOwner;

  /// GitHub repository name.
  final String repoName;

  /// Pull request number.
  final int prNumber;

  /// Pull request title.
  final String prTitle;

  /// REST id of the comment carrying the mention — the deep-link anchor.
  final int commentId;

  /// Who wrote it.
  final String authorLogin;

  /// A short excerpt for the notification body.
  final String bodyPreview;

  /// Whether this is an inline review comment (which has a file and line) or a
  /// conversation-timeline comment (which does not).
  final bool isReviewComment;

  /// GraphQL node id of the review thread, when known.
  final String? threadId;

  /// File the comment is anchored to, for a review comment.
  final String? path;

  /// Line the comment is anchored to, for a review comment.
  final int? line;

  /// The Control Center user this concerns. Null on an older server; the
  /// client then falls back to notifying rather than silently dropping.
  final String? forUserId;

  @override
  final DateTime occurredAt;
}

/// Someone replied in a review thread the operator participates in.
///
/// Distinct from [PrCommentMentioned]: no mention is needed, because having
/// written in a thread is itself the subscription. A comment that BOTH mentions
/// them and replies in their thread fires only the mention — it is the stronger
/// signal and two notifications for one comment is noise.
class PrThreadReplied implements DomainEvent {
  /// Creates a [PrThreadReplied].
  const PrThreadReplied({
    required this.workspaceId,
    required this.repoOwner,
    required this.repoName,
    required this.prNumber,
    required this.prTitle,
    required this.commentId,
    required this.authorLogin,
    required this.bodyPreview,
    required this.occurredAt,
    this.threadId,
    this.path,
    this.line,
    this.forUserId,
  });

  /// The workspace linking the repository.
  final String workspaceId;

  /// GitHub repository owner.
  final String repoOwner;

  /// GitHub repository name.
  final String repoName;

  /// Pull request number.
  final int prNumber;

  /// Pull request title.
  final String prTitle;

  /// REST id of the reply — the deep-link anchor.
  final int commentId;

  /// Who replied.
  final String authorLogin;

  /// A short excerpt for the notification body.
  final String bodyPreview;

  /// GraphQL node id of the review thread, when known.
  final String? threadId;

  /// File the thread is anchored to.
  final String? path;

  /// Line the thread is anchored to.
  final int? line;

  /// The Control Center user this concerns.
  final String? forUserId;

  @override
  final DateTime occurredAt;
}

/// A review thread the operator participates in was resolved.
///
/// Fires on the `false -> true` edge only. A thread that is re-opened leaves
/// the tracked unresolved set and so fires again if it is resolved a second
/// time — which is correct: that is a second thing that happened.
class PrThreadResolved implements DomainEvent {
  /// Creates a [PrThreadResolved].
  const PrThreadResolved({
    required this.workspaceId,
    required this.repoOwner,
    required this.repoName,
    required this.prNumber,
    required this.prTitle,
    required this.threadId,
    required this.occurredAt,
    this.commentId,
    this.path,
    this.line,
    this.forUserId,
  });

  /// The workspace linking the repository.
  final String workspaceId;

  /// GitHub repository owner.
  final String repoOwner;

  /// GitHub repository name.
  final String repoName;

  /// Pull request number.
  final int prNumber;

  /// Pull request title.
  final String prTitle;

  /// GraphQL node id of the resolved thread.
  final String threadId;

  /// REST id of the thread's root comment, for the deep-link anchor.
  final int? commentId;

  /// File the thread is anchored to.
  final String? path;

  /// Line the thread is anchored to.
  final int? line;

  /// The Control Center user this concerns.
  final String? forUserId;

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
    this.mergedByLogin,
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

  /// The forge login of whoever merged it, when known.
  ///
  /// Carried so the CLIENT can drop the notification when the merger is the
  /// person reading it — nobody needs to be told they merged something. It is
  /// deliberately not filtered server-side: this event reaches every member of
  /// the workspace, and one member merging a pull request is still news to the
  /// others. Null (an unmerged-looking node, or a deleted account) degrades to
  /// notifying.
  final String? mergedByLogin;

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

/// A pull request's head commit moved — the author pushed.
///
/// Distinct from [PullRequestStatusChanged], which is lifecycle (opened,
/// merged, closed). This is the signal that the CODE changed, and it exists
/// for one reason: a review is about one commit, so a push is what makes an
/// existing review stale. The poller already noticed the head move on every
/// sweep and discarded the fact; publishing it is what lets anything act on
/// it.
///
/// Carries both shas so a consumer can decide whether it cares — a listener
/// holding a review's commit can compare directly instead of re-fetching.
class PrHeadChanged implements DomainEvent {
  /// Creates a [PrHeadChanged] event.
  const PrHeadChanged({
    required this.repoOwner,
    required this.repoName,
    required this.prNumber,
    required this.prTitle,
    required this.previousHeadSha,
    required this.headSha,
    required this.workspaceId,
    required this.occurredAt,
  });

  /// Owning workspace. Unlike the external-PR sweep this comes from the
  /// per-workspace open-PR poller, so the workspace is always known.
  final String workspaceId;

  /// GitHub repository owner.
  final String repoOwner;

  /// GitHub repository name.
  final String repoName;

  /// Pull request number.
  final int prNumber;

  /// Pull request title, for a notification that reads like something.
  final String prTitle;

  /// The commit the pull request was on before the push.
  final String previousHeadSha;

  /// The commit it is on now.
  final String headSha;

  @override
  final DateTime occurredAt;
}

/// A finalized review no longer describes the pull request it reviewed.
///
/// Deliberately NOT the same as [PrHeadChanged]. Every push moves a head, and
/// notifying on every push would make the review surface exactly the kind of
/// noise the reviewer itself is tuned to avoid. This fires only when there IS
/// a finished review and the code underneath it has moved — the one case where
/// a person has something to act on.
class ReviewBecameStale implements DomainEvent {
  /// Creates a [ReviewBecameStale] event.
  const ReviewBecameStale({
    required this.workspaceId,
    required this.spaceId,
    required this.repoOwner,
    required this.repoName,
    required this.prNumber,
    required this.prTitle,
    required this.reviewedHeadSha,
    required this.headSha,
    required this.occurredAt,
  });

  /// Owning workspace.
  final String workspaceId;

  /// The review space holding the now-stale review.
  final String spaceId;

  /// GitHub repository owner.
  final String repoOwner;

  /// GitHub repository name.
  final String repoName;

  /// Pull request number.
  final int prNumber;

  /// Pull request title.
  final String prTitle;

  /// The commit the review actually read.
  final String reviewedHeadSha;

  /// The commit the pull request is on now.
  final String headSha;

  @override
  final DateTime occurredAt;
}
