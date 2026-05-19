import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';

/// Rebuilds a domain [PullRequest] from its [PullRequestDto] wire shape.
///
/// Shared by the PR-list / search / profile RPC repositories (mirrors the
/// per-field mapping in `RpcPrReviewRepository`). Reactions are not carried by
/// the list/search/profile queries, so rows have none (those surfaces don't
/// render reactions).
PullRequest pullRequestFromWireDto(PullRequestDto d) => PullRequest(
  id: d.id,
  number: d.number,
  title: d.title,
  body: d.body,
  state: PrStateExtension.fromString(d.state),
  isDraft: d.isDraft,
  author: d.author == null
      ? null
      : PrUser(login: d.author!.login, avatarUrl: d.author!.avatarUrl),
  createdAt: d.createdAt == null ? null : DateTime.tryParse(d.createdAt!),
  updatedAt: d.updatedAt == null ? null : DateTime.tryParse(d.updatedAt!),
  repoFullName: d.repoFullName,
  htmlUrl: d.htmlUrl,
  externalId: d.externalId,
  headSha: d.headSha,
  baseRef: d.baseRef,
  baseSha: d.baseSha,
  headRef: d.headRef,
  requestedReviewers: d.requestedReviewers
      .map((u) => PrUser(login: u.login, avatarUrl: u.avatarUrl))
      .toList(),
  requestedTeamSlugs: d.requestedTeamSlugs,
  assignees: d.assignees
      .map((u) => PrUser(login: u.login, avatarUrl: u.avatarUrl))
      .toList(),
  mergedAt: d.mergedAt == null ? null : DateTime.tryParse(d.mergedAt!),
  reviewedByMe: d.reviewedByMe,
  bodyHtml: d.bodyHtml,
  changedFiles: d.changedFiles,
  commitsCount: d.commitsCount,
  additions: d.additions,
  deletions: d.deletions,
  commentsCount: d.commentsCount,
  checksStatus: _prChecksStatusByName[d.checksStatus] ?? PrChecksStatus.none,
  mergeableState:
      _prMergeableStateByName[d.mergeableState] ?? PrMergeableState.unknown,
  reviewDecision: PrReviewDecision.fromString(d.reviewDecision),
);

/// Rebuilds a domain [PrFile] from its [PrFileDto] wire shape. Mirrors the
/// per-field mapping in `RpcPrReviewRepository`; shared by the compose-PR
/// branch-comparison RPC path.
PrFile prFileFromWireDto(PrFileDto d) => PrFile(
  filename: d.filename,
  status: PrFileStatusExtension.fromString(d.status),
  additions: d.additions,
  deletions: d.deletions,
  patch: d.patch,
  previousFilename: d.previousFilename,
  viewerViewedState: PrFileViewedStateExtension.fromWireName(
    d.viewerViewedState,
  ),
);

/// Rebuilds a domain [PrCommit] from its [PrCommitDto] wire shape.
PrCommit prCommitFromWireDto(PrCommitDto d) => PrCommit(
  sha: d.sha,
  message: d.message,
  author: d.author == null
      ? null
      : PrUser(login: d.author!.login, avatarUrl: d.author!.avatarUrl),
  date: d.date == null ? null : DateTime.tryParse(d.date!),
);

// Enum name→value lookups, built ONCE.
//
// `EnumType.values.asNameMap()` ALLOCATES A NEW MAP on every call, and
// these run per field per row per emission — the delta path re-maps a whole
// table on every frame, so a single ticket change built four fresh maps per
// ticket in the workspace.
final Map<String, PrChecksStatus> _prChecksStatusByName = PrChecksStatus.values
    .asNameMap();
final Map<String, PrMergeableState> _prMergeableStateByName = PrMergeableState
    .values
    .asNameMap();
