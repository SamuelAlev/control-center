import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/reaction_group.dart';
import 'package:cc_infra/src/network/models/github_check_run.dart';
import 'package:cc_infra/src/network/models/github_commit.dart';
import 'package:cc_infra/src/network/models/github_issue_comment.dart';
import 'package:cc_infra/src/network/models/github_pr_review_state.dart';
import 'package:cc_infra/src/network/models/github_pull_request.dart';
import 'package:cc_infra/src/network/models/github_pull_request_file.dart';
import 'package:cc_infra/src/network/models/github_reaction.dart';
import 'package:cc_infra/src/network/models/github_review.dart';
import 'package:cc_infra/src/network/models/github_review_comment.dart';
import 'package:cc_infra/src/network/models/github_user.dart';

PrUser _toPrUser(GitHubUser? u) {
  if (u == null) {
    return const PrUser(login: '', avatarUrl: '');
  }

  return PrUser(login: u.login, avatarUrl: u.avatarUrl);
}

/// Converts a [GitHubReactionSummary] to a list of [ReactionGroup]s.
List<ReactionGroup> reactionGroupsFromSummary(GitHubReactionSummary? s) {
  if (s == null || s.totalCount == 0) {
    return const [];
  }
  return [
    for (final r in ReactionGroup.supportedReactions)
      if ((r.content == '+1' && s.plusOne > 0) ||
          (r.content == '-1' && s.minusOne > 0) ||
          (r.content == 'laugh' && s.laugh > 0) ||
          (r.content == 'hooray' && s.hooray > 0) ||
          (r.content == 'confused' && s.confused > 0) ||
          (r.content == 'heart' && s.heart > 0) ||
          (r.content == 'rocket' && s.rocket > 0) ||
          (r.content == 'eyes' && s.eyes > 0))
        ReactionGroup(
          content: r.content,
          emoji: r.emoji,
          count: switch (r.content) {
            '+1' => s.plusOne,
            '-1' => s.minusOne,
            'laugh' => s.laugh,
            'hooray' => s.hooray,
            'confused' => s.confused,
            'heart' => s.heart,
            'rocket' => s.rocket,
            'eyes' => s.eyes,
            _ => 0,
          },
          userReacted: false,
        ),
  ];
}

/// Pull request from git hub.
PullRequest pullRequestFromGitHub(
  GitHubPullRequest gh, {
  required String repoFullName,
  bool reviewedByMe = false,
}) {
  return PullRequest(
    id: gh.number,
    number: gh.number,
    title: gh.title,
    body: gh.body,
    state: PrStateExtension.fromString(gh.state),
    isDraft: gh.isDraft,
    author: _toPrUser(gh.author),
    createdAt: gh.createdAt,
    updatedAt: gh.updatedAt,
    repoFullName: repoFullName,
    htmlUrl: gh.htmlUrl,
    nodeId: gh.nodeId,
    headSha: gh.headSha,
    baseRef: gh.baseRef,
    baseSha: gh.baseSha,
    headRef: gh.headRef,
    requestedReviewers: gh.requestedReviewers
        .map(_toPrUser)
        .toList(growable: false),
    assignees: gh.assignees.map(_toPrUser).toList(growable: false),
    mergedAt: gh.mergedAt,
    reviewedByMe: reviewedByMe,
    reactions: reactionGroupsFromSummary(gh.reactions),
    bodyHtml: gh.bodyHtml,
    changedFiles: gh.changedFiles,
    commitsCount: gh.commitsCount,
    mergeableState: PrMergeableState.fromString(gh.mergeableState),
  );
}

/// Maps GitHub's GraphQL `StatusState` rollup string to [PrChecksStatus].
///
/// `SUCCESS` → passing, `FAILURE`/`ERROR` → failing, `PENDING`/`EXPECTED`
/// → pending, anything else (including null) → none.
PrChecksStatus prChecksStatusFromRollup(String? state) {
  switch (state) {
    case 'SUCCESS':
      return PrChecksStatus.passing;
    case 'FAILURE':
    case 'ERROR':
      return PrChecksStatus.failing;
    case 'PENDING':
    case 'EXPECTED':
      return PrChecksStatus.pending;
    default:
      return PrChecksStatus.none;
  }
}

PrUser _prUserFromGraphQl(Map<String, dynamic>? u) {
  if (u == null) {
    return const PrUser(login: '', avatarUrl: '');
  }
  return PrUser(
    login: u['login'] as String? ?? '',
    avatarUrl: u['avatarUrl'] as String? ?? '',
  );
}

/// Builds a [PullRequest] from a single GraphQL `PullRequest` node returned by
/// `GitHubGraphQLClient.fetchOpenPullRequestsBatch`.
///
/// Carries the list fields plus the metrics (diff size, comment count, check
/// rollup, merge state) and requested reviewers, so the decision-lane
/// classification has every signal it reads — no follow-up REST calls. `body`/
/// `bodyHtml` and reactions are intentionally empty (the list doesn't show
/// them; the detail view fetches the full PR).
///
/// `reviewed-by-me` is derived from `latestReviews` against `viewerLogin`: the
/// PR counts as reviewed when the viewer authored any of its latest reviews.
PullRequest pullRequestFromGraphQlNode(
  Map<String, dynamic> node, {
  required String repoFullName,
  String? viewerLogin,
}) {
  final number = (node['number'] as num?)?.toInt() ?? 0;
  final comments = node['comments'] as Map<String, dynamic>?;
  final commitsTotal = node['commitsTotal'] as Map<String, dynamic>?;
  final lastCommit = node['lastCommit'] as Map<String, dynamic>?;
  final lastCommitNodes = lastCommit?['nodes'] as List?;
  final firstCommit = (lastCommitNodes != null && lastCommitNodes.isNotEmpty)
      ? lastCommitNodes.first as Map<String, dynamic>?
      : null;
  final commit = firstCommit?['commit'] as Map<String, dynamic>?;
  final rollup = commit?['statusCheckRollup'] as Map<String, dynamic>?;

  final requestedReviewers = <PrUser>[];
  final reviewRequests = node['reviewRequests'] as Map<String, dynamic>?;
  final reviewRequestNodes = reviewRequests?['nodes'] as List?;
  if (reviewRequestNodes != null) {
    for (final rr in reviewRequestNodes.whereType<Map<String, dynamic>>()) {
      final reviewer = rr['requestedReviewer'] as Map<String, dynamic>?;
      if (reviewer == null) {
        continue;
      }
      final login = reviewer['login'] as String?;
      if (login != null && login.isNotEmpty) {
        requestedReviewers.add(
          PrUser(
            login: login,
            avatarUrl: reviewer['avatarUrl'] as String? ?? '',
          ),
        );
        continue;
      }
      // Team reviewers expose `name`, not `login`. Keep them so `isPriority`
      // and lane counts stay correct; the per-user "awaiting me" check ignores
      // them since it matches on the operator's login.
      final teamName = reviewer['name'] as String?;
      if (teamName != null && teamName.isNotEmpty) {
        requestedReviewers.add(PrUser(login: teamName, avatarUrl: ''));
      }
    }
  }

  return PullRequest(
    id: number,
    number: number,
    title: node['title'] as String? ?? '',
    body: '',
    state: PrState.open,
    isDraft: node['isDraft'] as bool? ?? false,
    author: _prUserFromGraphQl(node['author'] as Map<String, dynamic>?),
    createdAt: DateTime.tryParse(node['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(node['updatedAt'] as String? ?? ''),
    repoFullName: repoFullName,
    htmlUrl: node['url'] as String? ?? '',
    nodeId: node['id'] as String? ?? '',
    headSha: node['headRefOid'] as String? ?? '',
    baseRef: node['baseRefName'] as String? ?? '',
    headRef: node['headRefName'] as String? ?? '',
    requestedReviewers: requestedReviewers,
    mergedAt: DateTime.tryParse(node['mergedAt'] as String? ?? ''),
    reviewedByMe: _graphQlNodeReviewedByViewer(node, viewerLogin),
    changedFiles: (node['changedFiles'] as num?)?.toInt() ?? 0,
    commitsCount: (commitsTotal?['totalCount'] as num?)?.toInt() ?? 0,
    additions: (node['additions'] as num?)?.toInt() ?? 0,
    deletions: (node['deletions'] as num?)?.toInt() ?? 0,
    commentsCount: (comments?['totalCount'] as num?)?.toInt() ?? 0,
    checksStatus: prChecksStatusFromRollup(rollup?['state'] as String?),
    mergeableState: PrMergeableState.fromString(
      (node['mergeStateStatus'] as String?)?.toLowerCase(),
    ),
  );
}

bool _graphQlNodeReviewedByViewer(
  Map<String, dynamic> node,
  String? viewerLogin,
) {
  if (viewerLogin == null || viewerLogin.isEmpty) {
    return false;
  }
  final me = viewerLogin.toLowerCase();
  final latestReviews = node['latestReviews'] as Map<String, dynamic>?;
  final reviewNodes = latestReviews?['nodes'] as List?;
  if (reviewNodes == null) {
    return false;
  }
  for (final r in reviewNodes.whereType<Map<String, dynamic>>()) {
    final author = r['author'] as Map<String, dynamic>?;
    final login = author?['login'] as String?;
    if (login != null && login.toLowerCase() == me) {
      return true;
    }
  }
  return false;
}

/// Maps one node from the dashboard's review-requested GraphQL `search` into a
/// [PullRequest] plus the `owner/name` it belongs to (for grouping under the
/// workspace's `Repo` set). Returns null for a node that isn't a usable PR
/// (a non-PR search hit comes back as an empty map, and `repository` is absent).
///
/// The priority-reviews panel renders only title/number/branch/age/diff/
/// comments, so the fields the lean search query deliberately omits (author,
/// reviewers, checks, sha, base ref, …) keep their [PullRequest] defaults. The
/// server-side `review-requested:<login>` filter already guarantees membership,
/// so `requestedReviewers` need not be recovered here.
({PullRequest pr, String repoFullName})? priorityReviewFromSearchNode(
  Map<String, dynamic> node,
) {
  final number = (node['number'] as num?)?.toInt() ?? 0;
  final title = node['title'] as String? ?? '';
  final repository = node['repository'] as Map<String, dynamic>?;
  final repoFullName = repository?['nameWithOwner'] as String? ?? '';
  if (number <= 0 || title.isEmpty || repoFullName.isEmpty) {
    return null;
  }
  final comments = node['comments'] as Map<String, dynamic>?;
  final pr = PullRequest(
    id: number,
    number: number,
    title: title,
    body: '',
    state: PrState.open,
    isDraft: node['isDraft'] as bool? ?? false,
    author: null,
    createdAt: DateTime.tryParse(node['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(node['updatedAt'] as String? ?? ''),
    repoFullName: repoFullName,
    htmlUrl: node['url'] as String? ?? '',
    headRef: node['headRefName'] as String? ?? '',
    additions: (node['additions'] as num?)?.toInt() ?? 0,
    deletions: (node['deletions'] as num?)?.toInt() ?? 0,
    commentsCount: (comments?['totalCount'] as num?)?.toInt() ?? 0,
  );
  return (pr: pr, repoFullName: repoFullName);
}

/// Maps a GraphQL `PullRequestReviewState` string to [PrReviewSubmissionState].
///
/// `DISMISSED` and `PENDING` both map to `pending`: a dismissed review no
/// longer satisfies the request, so for the rail it reads as "still awaited".
PrReviewSubmissionState prReviewerStateFromGraphQl(String state) {
  switch (state) {
    case 'APPROVED':
      return PrReviewSubmissionState.approved;
    case 'CHANGES_REQUESTED':
      return PrReviewSubmissionState.changesRequested;
    case 'COMMENTED':
      return PrReviewSubmissionState.commented;
    default:
      return PrReviewSubmissionState.pending;
  }
}

/// The set of reviewer identities (`user:<login>` / `team:<slug>`) that GitHub
/// currently flags as code owners (pending requests only — the flag is dropped
/// once the request is satisfied). Persisted by the repository so the shield
/// survives the pending→reviewed transition without parsing CODEOWNERS.
Set<String> codeOwnerIdentitiesFromReviewState(GitHubPrReviewState raw) {
  final ids = <String>{};
  for (final u in raw.pendingUsers) {
    if (u.asCodeOwner && u.login.isNotEmpty) {
      ids.add('user:${u.login.toLowerCase()}');
    }
  }
  for (final t in raw.pendingTeams) {
    if (t.asCodeOwner && t.slug.isNotEmpty) {
      ids.add('team:${t.slug.toLowerCase()}');
    }
  }
  return ids;
}

/// Resolves the raw GraphQL review state into the enriched reviewer rows.
///
/// - Pending user/team requests become `pending` rows; `isCodeOwner` is the
///   GraphQL `asCodeOwner` flag OR-ed with membership in `knownCodeOwnerIds`.
/// - A completed review with `onBehalfOf` merges into the team's row, carrying
///   the member who reviewed and the team's review verdict.
/// - A completed review without `onBehalfOf` is an individual review and
///   overrides any pending row for that user (completed state wins).
/// Users dedupe by login, teams by slug. Users render before teams.
List<PrReviewer> prReviewersFromReviewState(
  GitHubPrReviewState raw, {
  Set<String> knownCodeOwnerIds = const {},
}) {
  final users = <String, PrUserReviewer>{};
  final teams = <String, PrTeamReviewer>{};

  for (final u in raw.pendingUsers) {
    if (u.login.isEmpty) {
      continue;
    }
    final key = u.login.toLowerCase();
    users[key] = PrUserReviewer(
      user: PrUser(login: u.login, avatarUrl: u.avatarUrl),
      isCodeOwner: u.asCodeOwner || knownCodeOwnerIds.contains('user:$key'),
      state: PrReviewSubmissionState.pending,
    );
  }

  for (final t in raw.pendingTeams) {
    if (t.slug.isEmpty) {
      continue;
    }
    final key = t.slug.toLowerCase();
    teams[key] = PrTeamReviewer(
      name: t.name,
      slug: t.slug,
      isCodeOwner: t.asCodeOwner || knownCodeOwnerIds.contains('team:$key'),
      state: PrReviewSubmissionState.pending,
    );
  }

  for (final r in raw.completedReviews) {
    final state = prReviewerStateFromGraphQl(r.state);
    final author = PrUser(login: r.authorLogin, avatarUrl: r.authorAvatarUrl);
    if (r.onBehalfOf.isEmpty) {
      final key = r.authorLogin.toLowerCase();
      final existing = users[key];
      users[key] = PrUserReviewer(
        user: author,
        isCodeOwner:
            (existing?.isCodeOwner ?? false) ||
            knownCodeOwnerIds.contains('user:$key'),
        state: state,
      );
    } else {
      for (final team in r.onBehalfOf) {
        final key = team.slug.toLowerCase();
        final existing = teams[key];
        teams[key] = PrTeamReviewer(
          name: (existing?.name.isNotEmpty ?? false)
              ? existing!.name
              : team.name,
          slug: team.slug,
          isCodeOwner:
              (existing?.isCodeOwner ?? false) ||
              knownCodeOwnerIds.contains('team:$key'),
          state: state,
          reviewedBy: author,
        );
      }
    }
  }

  return <PrReviewer>[...users.values, ...teams.values];
}

/// Pr file from git hub.
PrFile prFileFromGitHub(GitHubPullRequestFile f) {
  return PrFile(
    filename: f.filename,
    status: PrFileStatusExtension.fromString(f.status),
    additions: f.additions,
    deletions: f.deletions,
    patch: f.patch,
    previousFilename: f.previousFilename,
  );
}

/// Pr commit from git hub.
PrCommit prCommitFromGitHub(GitHubCommit c) {
  return PrCommit(
    sha: c.sha,
    message: c.message,
    author: _toPrUser(c.author),
    date: c.committedAt,
  );
}

/// Pr code review comment from git hub.
PrCodeReviewComment prCodeReviewCommentFromGitHub(GitHubReviewComment c) {
  return PrCodeReviewComment(
    id: c.id,
    body: c.body,
    user: _toPrUser(c.user),
    path: c.path,
    position: c.line ?? c.originalLine,
    createdAt: c.createdAt,
    side: c.side,
    inReplyToId: c.inReplyToId,
    startLine: c.startLine,
    diffHunk: c.diffHunk,
    line: c.line,
    originalLine: c.originalLine,
    reactions: reactionGroupsFromSummary(c.reactions),
  );
}

/// Check run from git hub.
CheckRun checkRunFromGitHub(GitHubCheckRun c) {
  return CheckRun(
    name: c.name,
    status: _checkRunStatusFromGitHub(c.status),
    conclusion: _checkRunConclusionFromGitHub(c.conclusion),
    htmlUrl: c.htmlUrl,
    completedAt: c.completedAt,
    output: c.output,
    checkSuiteId: c.checkSuiteId,
  );
}

PrReviewSubmissionState _reviewStateFromGitHub(GitHubReviewState s) {
  switch (s) {
    case GitHubReviewState.approved:
      return PrReviewSubmissionState.approved;
    case GitHubReviewState.changesRequested:
      return PrReviewSubmissionState.changesRequested;
    case GitHubReviewState.commented:
      return PrReviewSubmissionState.commented;
    case GitHubReviewState.dismissed:
    case GitHubReviewState.pending:
    case GitHubReviewState.unknown:
      return PrReviewSubmissionState.commented;
  }
}

/// Pr review submission from git hub.
PrReviewSubmission prReviewSubmissionFromGitHub(GitHubReview r) {
  return PrReviewSubmission(
    state: _reviewStateFromGitHub(r.state),
    author: _toPrUser(r.user),
    body: r.body,
  );
}

/// Issue comment from git hub.
IssueComment issueCommentFromGitHub(GitHubIssueComment c) {
  return IssueComment(
    id: c.id,
    body: c.body,
    user: _toPrUser(c.user),
    createdAt: c.createdAt,
    reactions: reactionGroupsFromSummary(c.reactions),
  );
}

CheckRunStatus _checkRunStatusFromGitHub(GitHubCheckStatus s) {
  switch (s) {
    case GitHubCheckStatus.queued:
      return CheckRunStatus.queued;
    case GitHubCheckStatus.inProgress:
      return CheckRunStatus.inProgress;
    case GitHubCheckStatus.completed:
      return CheckRunStatus.completed;
    case GitHubCheckStatus.unknown:
      return CheckRunStatus.queued;
  }
}

CheckRunConclusion? _checkRunConclusionFromGitHub(GitHubCheckConclusion c) {
  switch (c) {
    case GitHubCheckConclusion.success:
      return CheckRunConclusion.success;
    case GitHubCheckConclusion.failure:
      return CheckRunConclusion.failure;
    case GitHubCheckConclusion.neutral:
      return CheckRunConclusion.neutral;
    case GitHubCheckConclusion.cancelled:
      return CheckRunConclusion.cancelled;
    case GitHubCheckConclusion.skipped:
      return CheckRunConclusion.skipped;
    case GitHubCheckConclusion.timedOut:
      return CheckRunConclusion.timedOut;
    case GitHubCheckConclusion.actionRequired:
      return CheckRunConclusion.actionRequired;
    case GitHubCheckConclusion.stale:
      return CheckRunConclusion.stale;
    case GitHubCheckConclusion.none:
      return null;
  }
}
