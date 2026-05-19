import 'dart:convert';

import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/commit_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/job_run_detail.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_approval.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_award_emoji.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_branch.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_commit.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_commit_status.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_comparison.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_diff.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_job.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_member.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_merge_request.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_note.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_pipeline.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_project.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_user.dart';
import 'package:crypto/crypto.dart';

// ── Users ──────────────────────────────────────────────────────────────────

/// Maps a GitLab user onto the domain's [PrUser].
///
/// GitLab's `username` is the login; `name` is the display name and is dropped
/// when empty so `displayLabel` does not render an empty parenthesis.
PrUser prUserFromGitLab(GitLabUser? user) {
  if (user == null) {
    return const PrUser(login: '', avatarUrl: '');
  }
  return PrUser(
    login: user.username,
    avatarUrl: user.avatarUrl,
    name: user.name.isEmpty ? null : user.name,
  );
}

/// Maps a project/group member onto the domain's [PrUser].
PrUser prUserFromGitLabMember(GitLabMember member) => PrUser(
  login: member.username,
  avatarUrl: member.avatarUrl,
  name: member.name.isEmpty ? null : member.name,
);

/// Builds the reviewer/assignee picker candidates from a project's members and
/// the groups it is shared with.
///
/// Groups become team candidates keyed by their full path (`acme/platform`),
/// which is both the stable slug and the value the group-members endpoint is
/// addressed by — so a team selection round-trips without a second lookup.
List<PrReviewerCandidate> reviewerCandidatesFromGitLab({
  required Iterable<GitLabMember> members,
  Iterable<GitLabGroupRef> groups = const <GitLabGroupRef>[],
}) {
  final candidates = <PrReviewerCandidate>[];
  final seen = <String>{};
  for (final member in members) {
    if (!member.isAssignable) {
      continue;
    }
    final candidate = PrReviewerCandidate.user(prUserFromGitLabMember(member));
    if (seen.add(candidate.selectionKey)) {
      candidates.add(candidate);
    }
  }
  for (final group in groups) {
    if (group.fullPath.isEmpty) {
      continue;
    }
    final candidate = PrReviewerCandidate(
      kind: ReviewerKind.team,
      key: group.fullPath,
      label: group.name.isNotEmpty ? group.name : group.fullPath,
      avatarUrl: group.avatarUrl.isEmpty ? null : group.avatarUrl,
    );
    if (seen.add(candidate.selectionKey)) {
      candidates.add(candidate);
    }
  }
  return candidates;
}

// ── Merge request ──────────────────────────────────────────────────────────

/// Matches the draft markers GitLab recognizes at the head of a title:
/// `Draft:`, `[Draft]`, `(Draft)` and the legacy `WIP` spellings.
final RegExp _draftTitlePrefix = RegExp(
  r'^\s*(?:\[\s*(?:draft|wip)\s*\]|\(\s*(?:draft|wip)\s*\)|(?:draft|wip)\s*:)\s*',
  caseSensitive: false,
);

/// Strips GitLab's draft marker from [title].
///
/// On GitLab the title prefix *is* the draft state — there is no boolean to
/// set — so a raw title would render as "Draft: Fix login" beside a draft
/// badge that says the same thing. The domain carries the flag separately, so
/// the prefix comes off here. Falls back to the untouched title if stripping
/// would leave nothing.
String stripGitLabDraftPrefix(String title) {
  final stripped = title.replaceFirst(_draftTitlePrefix, '').trim();
  return stripped.isEmpty ? title : stripped;
}

/// Re-applies GitLab's `Draft: ` marker to [title], unless one is already
/// there.
///
/// The inverse of [stripGitLabDraftPrefix], and mandatory on any title write
/// against a draft MR: sending a bare title to GitLab silently marks the merge
/// request ready for review.
String applyGitLabDraftPrefix(String title) =>
    _draftTitlePrefix.hasMatch(title) ? title : 'Draft: $title';

/// Maps GitLab's `state` (plus `merged_at`) onto the domain [PrState].
PrState prStateFromGitLab(GitLabMergeRequest mr) {
  if (mr.mergedAt != null || mr.state == 'merged') {
    return PrState.merged;
  }
  return switch (mr.state) {
    'closed' => PrState.closed,
    // `locked` is an open MR whose discussion is frozen; it is not closed.
    _ => PrState.open,
  };
}

/// Maps a GitLab pipeline status onto the rolled-up [PrChecksStatus].
///
/// `canceled` counts as failing rather than neutral: a cancelled pipeline
/// proves nothing passed, and reporting it as "no checks" would hide a red MR.
PrChecksStatus prChecksStatusFromGitLabPipeline(String? status) =>
    switch (status) {
      'success' => PrChecksStatus.passing,
      'failed' || 'canceled' || 'cancelled' => PrChecksStatus.failing,
      'created' ||
      'waiting_for_resource' ||
      'preparing' ||
      'pending' ||
      'running' ||
      'scheduled' ||
      'manual' => PrChecksStatus.pending,
      _ => PrChecksStatus.none,
    };

/// Maps GitLab's mergeability onto the domain [PrMergeableState].
///
/// Prefers `detailed_merge_status` (GitLab 15.6+) and falls back to the legacy
/// `merge_status`. `need_rebase` is GitLab's exact equivalent of GitHub's
/// `behind`; every "a rule is stopping this" reason collapses to `blocked`,
/// which is what GitHub reports for branch protection.
PrMergeableState prMergeableStateFromGitLab(GitLabMergeRequest mr) {
  if (mr.hasConflicts) {
    return PrMergeableState.dirty;
  }
  if (mr.detailedMergeStatus.isNotEmpty) {
    return switch (mr.detailedMergeStatus) {
      'mergeable' => PrMergeableState.clean,
      'conflict' || 'broken_status' => PrMergeableState.dirty,
      'need_rebase' => PrMergeableState.behind,
      'checking' ||
      'unchecked' ||
      'preparing' ||
      'approvals_syncing' => PrMergeableState.unknown,
      'ci_must_pass' || 'ci_still_running' => PrMergeableState.unstable,
      'not_approved' ||
      'blocked_status' ||
      'discussions_not_resolved' ||
      'draft_status' ||
      'policies_denied' ||
      'requested_changes' ||
      'external_status_checks' ||
      'security_policy_violations' ||
      'locked_paths' ||
      'locked_lfs_files' ||
      'jira_association_missing' => PrMergeableState.blocked,
      _ => PrMergeableState.unrecognized,
    };
  }
  return switch (mr.mergeStatus) {
    'can_be_merged' => PrMergeableState.clean,
    'cannot_be_merged' => PrMergeableState.dirty,
    'checking' ||
    'unchecked' ||
    'cannot_be_merged_recheck' => PrMergeableState.unknown,
    _ => PrMergeableState.unrecognized,
  };
}

/// Derives the rolled-up review decision from the merge request alone.
///
/// GitLab has no `reviewDecision` field. `detailed_merge_status` is the only
/// signal a single MR fetch carries, so anything it does not name reads as
/// [PrReviewDecision.none] — the same "not enriched" value the GitHub REST
/// mapper produces. The reviewer rail resolves the full picture through
/// `getReviewerState`.
PrReviewDecision prReviewDecisionFromGitLab(GitLabMergeRequest mr) =>
    switch (mr.detailedMergeStatus) {
      'requested_changes' => PrReviewDecision.changesRequested,
      'not_approved' => PrReviewDecision.reviewRequired,
      _ => PrReviewDecision.none,
    };

/// Maps a GitLab merge request onto the domain [PullRequest].
///
/// Field notes worth knowing:
/// - `number` is the per-project `iid`; `externalId` is the instance-wide
///   `id`, stringified and never parsed by callers.
/// - `requestedTeamSlugs` stays empty: a GitLab merge request cannot have a
///   group reviewer, only an approval *rule* can name a group, and that lives
///   behind `getReviewerState`.
/// - `additions`/`deletions`/`commitsCount` stay 0 — the merge-request payload
///   carries none of them, exactly as GitHub's REST list endpoint does not.
PullRequest pullRequestFromGitLab(
  GitLabMergeRequest mr, {
  required String repoFullName,
  bool reviewedByMe = false,
}) {
  final diffRefs = mr.diffRefs;
  return PullRequest(
    id: mr.iid,
    number: mr.iid,
    title: mr.draft ? stripGitLabDraftPrefix(mr.title) : mr.title,
    body: mr.description,
    state: prStateFromGitLab(mr),
    isDraft: mr.draft,
    author: prUserFromGitLab(mr.author),
    createdAt: mr.createdAt,
    updatedAt: mr.updatedAt,
    repoFullName: repoFullName,
    htmlUrl: mr.webUrl,
    externalId: mr.id == 0 ? '' : '${mr.id}',
    headSha: diffRefs?.headSha.isNotEmpty ?? false ? diffRefs!.headSha : mr.sha,
    baseRef: mr.targetBranch,
    baseSha: diffRefs?.baseSha ?? '',
    headRef: mr.sourceBranch,
    requestedReviewers: mr.reviewers
        .map(prUserFromGitLab)
        .toList(growable: false),
    assignees: mr.assignees.map(prUserFromGitLab).toList(growable: false),
    mergedAt: mr.mergedAt,
    reviewedByMe: reviewedByMe,
    changedFiles: gitLabChangedFileCount(mr.changesCount),
    commentsCount: mr.userNotesCount,
    checksStatus: prChecksStatusFromGitLabPipeline(mr.headPipeline?.status),
    mergeableState: prMergeableStateFromGitLab(mr),
    reviewDecision: prReviewDecisionFromGitLab(mr),
  );
}

/// Parses GitLab's `changes_count`, which is a string and may carry a `+`
/// suffix (`"1000+"`) when the diff overflowed the instance limit.
int gitLabChangedFileCount(String changesCount) {
  final digits = changesCount.replaceAll(RegExp('[^0-9]'), '');
  return digits.isEmpty ? 0 : int.tryParse(digits) ?? 0;
}

// ── Diffs and files ────────────────────────────────────────────────────────

/// Maps GitLab's change flags onto the domain [PrFileStatus].
PrFileStatus prFileStatusFromGitLab(GitLabDiff diff) {
  if (diff.newFile) {
    return PrFileStatus.added;
  }
  if (diff.deletedFile) {
    return PrFileStatus.removed;
  }
  if (diff.renamedFile) {
    return PrFileStatus.renamed;
  }
  return PrFileStatus.modified;
}

/// Counts added and removed lines in a hunk body.
///
/// GitLab reports no per-file line counts anywhere, so they are derived from
/// the hunk text. `+++`/`---` are the file headers, not content, and are
/// skipped — though GitLab's `diff` normally starts at the first `@@` and
/// carries neither.
({int additions, int deletions}) gitLabDiffLineCounts(String diff) {
  var additions = 0;
  var deletions = 0;
  for (final line in const LineSplitter().convert(diff)) {
    if (line.startsWith('+++') || line.startsWith('---')) {
      continue;
    }
    if (line.startsWith('+')) {
      additions++;
    } else if (line.startsWith('-')) {
      deletions++;
    }
  }
  return (additions: additions, deletions: deletions);
}

/// Maps one GitLab change onto the domain [PrFile].
PrFile prFileFromGitLab(GitLabDiff diff) {
  final counts = gitLabDiffLineCounts(diff.diff);
  return PrFile(
    filename: diff.newPath.isNotEmpty ? diff.newPath : diff.oldPath,
    status: prFileStatusFromGitLab(diff),
    additions: counts.additions,
    deletions: counts.deletions,
    patch: diff.diff,
    previousFilename: diff.renamedFile && diff.oldPath.isNotEmpty
        ? diff.oldPath
        : null,
  );
}

/// Assembles a real unified diff from GitLab's per-file changes.
///
/// GitLab hands back only the hunks (`@@ …` onwards) with the paths as
/// separate fields; a unified-diff parser needs the `diff --git` /
/// `---` / `+++` framing around them, so it is synthesized here. Renames get
/// their `rename from`/`rename to` lines, added and deleted files get
/// `/dev/null` on the appropriate side, and a change with no hunks (binary, a
/// mode-only edit, or a diff GitLab refused to render) contributes its header
/// and nothing else — emitting `---`/`+++` with no hunk behind them would
/// invite a parser to read the next file's header as content.
String unifiedDiffFromGitLab(Iterable<GitLabDiff> diffs) {
  final buffer = StringBuffer();
  for (final diff in diffs) {
    final oldPath = diff.oldPath.isNotEmpty ? diff.oldPath : diff.newPath;
    final newPath = diff.newPath.isNotEmpty ? diff.newPath : diff.oldPath;
    if (oldPath.isEmpty && newPath.isEmpty) {
      continue;
    }
    buffer.writeln('diff --git a/$oldPath b/$newPath');
    if (diff.newFile) {
      buffer.writeln(
        'new file mode ${diff.bMode.isNotEmpty ? diff.bMode : '100644'}',
      );
    } else if (diff.deletedFile) {
      buffer.writeln(
        'deleted file mode ${diff.aMode.isNotEmpty ? diff.aMode : '100644'}',
      );
    } else if (diff.renamedFile) {
      buffer.writeln('rename from $oldPath');
      buffer.writeln('rename to $newPath');
    } else if (diff.aMode.isNotEmpty &&
        diff.bMode.isNotEmpty &&
        diff.aMode != diff.bMode) {
      buffer.writeln('old mode ${diff.aMode}');
      buffer.writeln('new mode ${diff.bMode}');
    }
    if (diff.diff.isEmpty) {
      continue;
    }
    buffer.writeln(diff.newFile ? '--- /dev/null' : '--- a/$oldPath');
    buffer.writeln(diff.deletedFile ? '+++ /dev/null' : '+++ b/$newPath');
    buffer.write(diff.diff);
    if (!diff.diff.endsWith('\n')) {
      buffer.write('\n');
    }
  }
  return buffer.toString();
}

// ── Commits ────────────────────────────────────────────────────────────────

/// Maps a GitLab commit onto the domain [PrCommit].
///
/// The author is synthesized from the git author name: GitLab's commit payload
/// never resolves a commit to the GitLab account that pushed it, so there is
/// no handle and no avatar to carry. The name doubles as the login so the
/// activity feed still attributes the commit to someone.
PrCommit prCommitFromGitLab(GitLabCommit commit) => PrCommit(
  sha: commit.id,
  message: commit.message.isNotEmpty ? commit.message : commit.title,
  author: commit.authorName.isEmpty
      ? null
      : PrUser(
          login: commit.authorName,
          avatarUrl: '',
          name: commit.authorName,
        ),
  date: commit.committedDate ?? commit.authoredDate ?? commit.createdAt,
);

// ── Compose-PR surface ─────────────────────────────────────────────────────

/// Maps a GitLab branch onto the domain [ForgeBranch].
///
/// Activity comes from the branch tip: the commit date and the git author
/// name, which is all GitLab's branch payload carries (no linked account, so
/// no handle and no avatar).
ForgeBranch forgeBranchFromGitLab(GitLabBranch branch) => ForgeBranch(
  name: branch.name,
  lastCommitAt:
      branch.commit?.committedDate ??
      branch.commit?.authoredDate ??
      branch.commit?.createdAt,
  lastCommitAuthor: branch.commit?.authorName ?? '',
  isDefault: branch.isDefault,
);

/// Maps and orders branches most-recently-committed first.
///
/// Branches with no known tip date sort last rather than leading the picker,
/// which is the ordering the port asks for. [limit] truncates *after* the
/// sort, so a capped list is still the newest ones.
List<ForgeBranch> forgeBranchesFromGitLab(
  Iterable<GitLabBranch> branches, {
  int? limit,
}) {
  final mapped =
      <ForgeBranch>[
        for (final branch in branches)
          if (branch.name.isNotEmpty) forgeBranchFromGitLab(branch),
      ]..sort((a, b) {
        final left = a.lastCommitAt;
        final right = b.lastCommitAt;
        if (left == null && right == null) {
          return a.name.compareTo(b.name);
        }
        if (left == null) {
          return 1;
        }
        if (right == null) {
          return -1;
        }
        return right.compareTo(left);
      });
  if (limit != null && limit >= 0 && mapped.length > limit) {
    return mapped.sublist(0, limit);
  }
  return mapped;
}

/// Maps a GitLab comparison onto the domain [ForgeBranchComparison].
///
/// The diffs go through the same `diff → PrFile` mapping the merge-request
/// file list uses, line counts included, so the compose screen previews
/// exactly what the merge request will show. Commits are re-sorted oldest
/// first (the port's contract) with the original order as the tie-break, so
/// same-second commits keep GitLab's topological ordering.
ForgeBranchComparison forgeBranchComparisonFromGitLab(
  GitLabComparison comparison,
) {
  final files = comparison.diffs.map(prFileFromGitLab).toList(growable: false);
  var additions = 0;
  var deletions = 0;
  for (final file in files) {
    additions += file.additions;
    deletions += file.deletions;
  }

  final indexed =
      <(int, GitLabCommit)>[
        for (var i = 0; i < comparison.commits.length; i++)
          (i, comparison.commits[i]),
      ]..sort((a, b) {
        final left = a.$2.committedDate ?? a.$2.authoredDate;
        final right = b.$2.committedDate ?? b.$2.authoredDate;
        if (left == null || right == null || left == right) {
          return a.$1.compareTo(b.$1);
        }
        return left.compareTo(right);
      });

  return ForgeBranchComparison(
    files: files,
    commits: <PrCommit>[
      for (final entry in indexed) prCommitFromGitLab(entry.$2),
    ],
    additions: additions,
    deletions: deletions,
    totalCommits: comparison.commits.length,
  );
}

/// The display name of a merge-request template file.
///
/// GitLab only recognizes `.md` files in `.gitlab/merge_request_templates/`
/// and shows them by their bare filename, so that extension — and only that
/// one — comes off.
String gitLabTemplateName(String filename) {
  const suffix = '.md';
  if (filename.length > suffix.length &&
      filename.toLowerCase().endsWith(suffix)) {
    return filename.substring(0, filename.length - suffix.length);
  }
  return filename;
}

// ── Reviews, reviewers, comments ───────────────────────────────────────────

/// Maps a GitLab reviewer state onto the domain [PrReviewSubmissionState].
PrReviewSubmissionState prReviewSubmissionStateFromGitLab(String state) =>
    switch (state) {
      'approved' => PrReviewSubmissionState.approved,
      'requested_changes' => PrReviewSubmissionState.changesRequested,
      'reviewed' => PrReviewSubmissionState.commented,
      // `unreviewed` / `unapproved` / anything new: still awaited.
      _ => PrReviewSubmissionState.pending,
    };

/// Synthesizes review submissions from GitLab's two verdict sources.
///
/// GitLab has no review object, so a submission is assembled from an approval
/// (`approvals.approved_by`) or from a reviewer sitting in the
/// `requested_changes` state. Comment-only "reviews" are deliberately **not**
/// synthesized: on GitLab a comment is a note, and inventing a review around
/// it would put a verdict on the timeline that nobody cast.
///
/// One submission per person — a `requested_changes` state overrides an
/// approval, since it is the later and more restrictive word. `id` carries the
/// author's user id: GitLab has no review ids, and a stable non-zero value
/// keeps list keys unique.
List<PrReviewSubmission> prReviewSubmissionsFromGitLab({
  required GitLabApprovals approvals,
  required List<GitLabMergeRequestReviewer> reviewers,
}) {
  final byLogin = <String, PrReviewSubmission>{};

  for (final user in approvals.approvedBy) {
    if (user.username.isEmpty) {
      continue;
    }
    byLogin[user.username.toLowerCase()] = PrReviewSubmission(
      id: user.id,
      state: PrReviewSubmissionState.approved,
      author: prUserFromGitLab(user),
      body: '',
    );
  }

  for (final reviewer in reviewers) {
    final user = reviewer.user;
    if (user == null || user.username.isEmpty) {
      continue;
    }
    final key = user.username.toLowerCase();
    if (reviewer.state == 'requested_changes') {
      byLogin[key] = PrReviewSubmission(
        id: user.id,
        state: PrReviewSubmissionState.changesRequested,
        author: prUserFromGitLab(user),
        body: '',
        submittedAt: reviewer.updatedAt,
      );
    } else if (reviewer.state == 'approved' && !byLogin.containsKey(key)) {
      byLogin[key] = PrReviewSubmission(
        id: user.id,
        state: PrReviewSubmissionState.approved,
        author: prUserFromGitLab(user),
        body: '',
        submittedAt: reviewer.updatedAt,
      );
    }
  }

  final submissions = byLogin.values.toList()
    ..sort((a, b) {
      final left = a.submittedAt;
      final right = b.submittedAt;
      if (left == null && right == null) {
        return 0;
      }
      if (left == null) {
        return -1;
      }
      if (right == null) {
        return 1;
      }
      return left.compareTo(right);
    });
  return List<PrReviewSubmission>.unmodifiable(submissions);
}

/// Reconciles GitLab's reviewer assignments, approvals and approval rules into
/// the one [PrReviewerState] the reviewer rail renders.
///
/// - Assigned reviewers become user rows carrying their own state.
/// - Anyone in `approvals.approved_by` is promoted to `approved`, including
///   approvers who were never assigned as reviewers (GitLab allows that).
/// - An approval rule naming a group becomes a team row; a `code_owner` rule
///   is what sets `isCodeOwner`, GitLab's CODEOWNERS equivalent.
/// - `codeOwnerIdentities` collects both halves of that in `PrReviewer.identity`
///   spelling: `user:<login>` for a code-owner rule's eligible approvers and
///   `team:<full/path>` for a group it names.
///
/// Approval rules are a paid-tier feature; on an instance without them
/// [approvalState] arrives empty and the result is simply user rows with no
/// code-owner shields — never a false claim that nobody owns the code.
PrReviewerState prReviewerStateFromGitLab({
  required List<GitLabMergeRequestReviewer> reviewers,
  required GitLabApprovals approvals,
  required GitLabApprovalState approvalState,
}) {
  final codeOwnerIdentities = <String>{};
  for (final rule in approvalState.rules) {
    if (!rule.isCodeOwner) {
      continue;
    }
    for (final user in rule.eligibleApprovers) {
      if (user.username.isNotEmpty) {
        codeOwnerIdentities.add('user:${user.username.toLowerCase()}');
      }
    }
    for (final group in rule.groups) {
      if (group.fullPath.isNotEmpty) {
        codeOwnerIdentities.add('team:${group.fullPath.toLowerCase()}');
      }
    }
  }

  final users = <String, PrUserReviewer>{};
  for (final reviewer in reviewers) {
    final user = reviewer.user;
    if (user == null || user.username.isEmpty) {
      continue;
    }
    final key = user.username.toLowerCase();
    users[key] = PrUserReviewer(
      user: prUserFromGitLab(user),
      isCodeOwner: codeOwnerIdentities.contains('user:$key'),
      state: prReviewSubmissionStateFromGitLab(reviewer.state),
    );
  }
  for (final user in approvals.approvedBy) {
    if (user.username.isEmpty) {
      continue;
    }
    final key = user.username.toLowerCase();
    users[key] = PrUserReviewer(
      user: prUserFromGitLab(user),
      isCodeOwner:
          users[key]?.isCodeOwner ?? codeOwnerIdentities.contains('user:$key'),
      state: PrReviewSubmissionState.approved,
    );
  }

  final teams = <String, PrTeamReviewer>{};
  for (final rule in approvalState.rules) {
    for (final group in rule.groups) {
      if (group.fullPath.isEmpty) {
        continue;
      }
      final key = group.fullPath.toLowerCase();
      final existing = teams[key];
      final approved =
          rule.approved || existing?.state == PrReviewSubmissionState.approved;
      teams[key] = PrTeamReviewer(
        name: group.name.isNotEmpty ? group.name : group.fullPath,
        slug: group.fullPath,
        avatarUrl: group.avatarUrl,
        isCodeOwner: (existing?.isCodeOwner ?? false) || rule.isCodeOwner,
        state: approved
            ? PrReviewSubmissionState.approved
            : PrReviewSubmissionState.pending,
      );
    }
  }

  return PrReviewerState(
    reviewers: <PrReviewer>[...users.values, ...teams.values],
    codeOwnerIdentities: codeOwnerIdentities,
  );
}

/// Maps one diff-anchored note onto the domain [PrCodeReviewComment].
///
/// [position] is passed separately because a reply inside a diff thread may
/// omit it — the thread's anchor still applies. `RIGHT` is chosen whenever the
/// position carries a `new_line`, `LEFT` otherwise, which is the same
/// convention GitHub sends explicitly.
PrCodeReviewComment prCodeReviewCommentFromGitLab(
  GitLabNote note, {
  required GitLabNotePosition position,
  int? inReplyToId,
}) {
  final newLine = position.newLine;
  final oldLine = position.oldLine;
  final line = newLine ?? oldLine;
  final start = position.lineRange?.start;
  final startLine = start == null ? null : (start.newLine ?? start.oldLine);
  return PrCodeReviewComment(
    id: note.id,
    body: note.body,
    user: prUserFromGitLab(note.author),
    path: position.path,
    position: line,
    createdAt: note.createdAt,
    side: newLine != null ? 'RIGHT' : 'LEFT',
    inReplyToId: inReplyToId,
    startLine: (startLine != null && startLine != line) ? startLine : null,
    line: line,
    originalLine: oldLine,
  );
}

/// Flattens GitLab discussions into the domain's inline review comments.
///
/// A discussion is inline when any of its notes carries a position; every
/// subsequent note in that thread is a reply and points back at the thread's
/// first note through `inReplyToId`. System notes ("changed the description")
/// are activity, not comments, and are dropped. Image comments
/// (`position_type: image`) are skipped: they have no line to anchor to in a
/// text diff.
List<PrCodeReviewComment> prCodeReviewCommentsFromGitLab(
  Iterable<GitLabDiscussion> discussions,
) {
  final comments = <PrCodeReviewComment>[];
  for (final discussion in discussions) {
    GitLabNotePosition? anchor;
    for (final note in discussion.notes) {
      final position = note.position;
      if (position != null && position.positionType == 'text') {
        anchor = position;
        break;
      }
    }
    if (anchor == null) {
      continue;
    }
    int? rootId;
    for (final note in discussion.notes) {
      if (note.system) {
        continue;
      }
      comments.add(
        prCodeReviewCommentFromGitLab(
          note,
          position: note.position ?? anchor,
          inReplyToId: rootId,
        ),
      );
      rootId ??= note.id;
    }
  }
  return comments;
}

/// Maps one note onto the domain [IssueComment].
IssueComment issueCommentFromGitLab(GitLabNote note) => IssueComment(
  id: note.id,
  body: note.body,
  user: prUserFromGitLab(note.author),
  createdAt: note.createdAt,
);

/// Selects the top-level conversation comments out of a merge request's notes.
///
/// A note without a diff position is a conversation comment; system notes are
/// GitLab's own activity entries and never comments.
List<IssueComment> issueCommentsFromGitLab(Iterable<GitLabNote> notes) =>
    <IssueComment>[
      for (final note in notes)
        if (!note.system && note.position == null && note.body.isNotEmpty)
          issueCommentFromGitLab(note),
    ];

// ── Posting positions ──────────────────────────────────────────────────────

/// Builds GitLab's `line_code`, the `<sha1(path)>_<old_line>_<new_line>`
/// identifier a multi-line position range is keyed by.
///
/// An unknown side reads as `0`, which is what GitLab itself writes for a line
/// that exists on only one side of the diff.
String gitLabLineCode(String path, int? oldLine, int? newLine) =>
    '${sha1.convert(utf8.encode(path))}_${oldLine ?? 0}_${newLine ?? 0}';

/// Translates the port's `(path, line, side)` anchor into GitLab's position
/// object.
///
/// Both `old_path` and `new_path` are sent as [path]: GitLab validates a text
/// position against both, and the port carries only one path. For a file that
/// was renamed in the same merge request the pre-image path differs, so a
/// comment anchored on a renamed file's old side is the one case this cannot
/// express.
///
/// [startLine] widens the anchor into a `line_range`. GitLab keys the range
/// ends by `line_code`, which is derived from the path and the two line
/// numbers; the side that does not exist for a given end contributes `0`.
GitLabNotePosition gitLabPositionForAnchor({
  required GitLabDiffRefs refs,
  required String path,
  required int line,
  required String side,
  int? startLine,
  String? startSide,
}) {
  final onRight = side.toUpperCase() != 'LEFT';
  final endOldLine = onRight ? null : line;
  final endNewLine = onRight ? line : null;

  GitLabLineRange? range;
  if (startLine != null && startLine != line) {
    final startOnRight = (startSide ?? side).toUpperCase() != 'LEFT';
    final startOldLine = startOnRight ? null : startLine;
    final startNewLine = startOnRight ? startLine : null;
    range = GitLabLineRange(
      start: GitLabLineRangeEnd(
        lineCode: gitLabLineCode(path, startOldLine, startNewLine),
        type: startOnRight ? 'new' : 'old',
        oldLine: startOldLine,
        newLine: startNewLine,
      ),
      end: GitLabLineRangeEnd(
        lineCode: gitLabLineCode(path, endOldLine, endNewLine),
        type: onRight ? 'new' : 'old',
        oldLine: endOldLine,
        newLine: endNewLine,
      ),
    );
  }

  return GitLabNotePosition(
    baseSha: refs.baseSha,
    startSha: refs.startSha,
    headSha: refs.headSha,
    oldPath: path,
    newPath: path,
    oldLine: endOldLine,
    newLine: endNewLine,
    lineRange: range,
  );
}

// ── CI ─────────────────────────────────────────────────────────────────────

/// Maps a GitLab job status onto the domain [CheckRunStatus].
///
/// GitLab's `scheduled` has no counterpart in the domain enum and reads as
/// [CheckRunStatus.queued] — a delayed job has genuinely not started.
CheckRunStatus checkRunStatusFromGitLabJob(String status) => switch (status) {
  'running' => CheckRunStatus.inProgress,
  'success' ||
  'failed' ||
  'canceled' ||
  'cancelled' ||
  'skipped' ||
  'manual' => CheckRunStatus.completed,
  _ => CheckRunStatus.queued,
};

/// Maps a GitLab job status onto the domain [CheckRunConclusion], or null
/// while the job has not settled.
///
/// GitLab's `manual` — a job waiting for someone to press play — maps to
/// [CheckRunConclusion.actionRequired], which is the same pairing GitHub
/// Actions uses for a run that needs a human.
CheckRunConclusion? checkRunConclusionFromGitLabJob(String status) =>
    switch (status) {
      'success' => CheckRunConclusion.success,
      'failed' => CheckRunConclusion.failure,
      'canceled' || 'cancelled' => CheckRunConclusion.cancelled,
      'skipped' => CheckRunConclusion.skipped,
      'manual' => CheckRunConclusion.actionRequired,
      _ => null,
    };

/// The display name of [pipeline] — its own `name` when the project sets one,
/// else a stable `Pipeline #<id>`.
String gitLabPipelineDisplayName(GitLabPipeline? pipeline) {
  if (pipeline == null) {
    return 'Pipeline';
  }
  return pipeline.name.isNotEmpty ? pipeline.name : 'Pipeline #${pipeline.id}';
}

/// Maps a GitLab job onto the domain [CheckRun].
///
/// The pipeline stands in for GitHub's workflow run *and* check suite — both
/// ids point at it, so the UI's "group by run" join works unchanged.
/// `output` carries GitLab's failure reason when there is one, which is the
/// only per-job text short of downloading the trace.
CheckRun checkRunFromGitLab(GitLabJob job, {GitLabPipeline? pipeline}) {
  final pipelineId = pipeline?.id ?? job.pipelineId;
  return CheckRun(
    name: job.name,
    status: checkRunStatusFromGitLabJob(job.status),
    conclusion: checkRunConclusionFromGitLabJob(job.status),
    htmlUrl: job.webUrl,
    startedAt: job.startedAt,
    completedAt: job.finishedAt,
    output: job.failureReason,
    workflowName: gitLabPipelineDisplayName(pipeline),
    checkSuiteId: pipelineId == 0 ? null : pipelineId,
    jobId: job.id == 0 ? null : job.id,
    workflowRunId: pipelineId == 0 ? null : pipelineId,
  );
}

/// Maps a GitLab commit status onto the domain [CommitStatus].
///
/// `skipped` reads as [CommitStatusState.success]: it is not blocking and
/// there is no "did not run" member. `canceled` reads as
/// [CommitStatusState.error] — the context stopped without a verdict.
CommitStatus commitStatusFromGitLab(GitLabCommitStatus status) => CommitStatus(
  context: status.name,
  state: switch (status.status) {
    'success' || 'skipped' => CommitStatusState.success,
    'failed' => CommitStatusState.failure,
    'canceled' || 'cancelled' => CommitStatusState.error,
    _ => CommitStatusState.pending,
  },
  targetUrl: status.targetUrl,
  description: status.description,
  updatedAt: status.finishedAt ?? status.startedAt ?? status.createdAt,
);

/// Whether [status] came from an external integration rather than from a
/// GitLab CI job.
///
/// GitLab folds its own jobs into the commit-statuses feed, so returning it
/// wholesale would duplicate every check run. An external status is the only
/// kind the domain's [CommitStatus] is for — the deploy-preview link case —
/// and it is recognised by pointing somewhere that is not a GitLab job page.
bool isExternalGitLabCommitStatus(GitLabCommitStatus status) =>
    status.targetUrl.isNotEmpty && !status.targetUrl.contains('/-/jobs/');

/// Maps a GitLab job plus its trace onto the domain [JobRunDetail].
///
/// `steps` is always empty: a GitLab job is atomic — it has no step breakdown
/// to expose, only a script and its trace — so the detail view renders logs
/// alone rather than a fabricated single step.
JobRunDetail jobRunDetailFromGitLab(
  GitLabJob job, {
  String? logs,
  bool logsTruncated = false,
}) => JobRunDetail(
  jobId: job.id,
  status: checkRunStatusFromGitLabJob(job.status),
  conclusion: checkRunConclusionFromGitLabJob(job.status),
  htmlUrl: job.webUrl,
  logs: logs,
  logsTruncated: logsTruncated,
);

/// Builds the job graph of one pipeline.
///
/// GitLab's REST job payload does not carry `needs` (only GraphQL does), so
/// when it is absent the edges are derived from stage ordering: every job in a
/// stage depends on every job of the stage before it. Stage order is taken
/// from job-id order, which is the order GitLab creates them in. Retried jobs
/// repeat a name; the first occurrence wins so the graph has one node per job.
WorkflowGraph workflowGraphFromGitLabJobs(
  Iterable<GitLabJob> jobs, {
  required String name,
}) {
  final ordered = jobs.toList()..sort((a, b) => a.id.compareTo(b.id));
  final stageOrder = <String>[];
  final byStage = <String, List<GitLabJob>>{};
  final seenNames = <String>{};
  for (final job in ordered) {
    if (job.name.isEmpty || !seenNames.add(job.name)) {
      continue;
    }
    final stage = job.stage.isEmpty ? 'default' : job.stage;
    final bucket = byStage[stage];
    if (bucket == null) {
      stageOrder.add(stage);
      byStage[stage] = <GitLabJob>[job];
    } else {
      bucket.add(job);
    }
  }

  final nodes = <WorkflowJobNode>[];
  for (var index = 0; index < stageOrder.length; index++) {
    final upstream = index == 0
        ? const <GitLabJob>[]
        : byStage[stageOrder[index - 1]] ?? const <GitLabJob>[];
    for (final job in byStage[stageOrder[index]] ?? const <GitLabJob>[]) {
      nodes.add(
        WorkflowJobNode(
          id: job.name,
          name: job.name,
          needs: job.needs.isNotEmpty
              ? job.needs
              : <String>[for (final parent in upstream) parent.name],
        ),
      );
    }
  }
  return WorkflowGraph(name: name, jobs: nodes);
}

// ── Reactions ──────────────────────────────────────────────────────────────

/// The domain's reaction keys (GitHub's vocabulary) mapped to GitLab's emoji
/// shortcodes. Anything absent passes through unchanged, so a shortcode the
/// two forges already agree on needs no entry.
const Map<String, String> _gitLabAwardEmojiByContent = <String, String>{
  '+1': 'thumbsup',
  '-1': 'thumbsdown',
  'laugh': 'laughing',
  'hooray': 'tada',
};

/// The GitLab emoji shortcode for a domain reaction key (`+1` → `thumbsup`).
String gitLabAwardEmojiName(String content) =>
    _gitLabAwardEmojiByContent[content] ?? content;

/// The domain reaction key for a GitLab emoji shortcode
/// (`thumbsup` → `+1`), so the two directions of the reaction round-trip.
/// Unknown shortcodes pass through verbatim rather than being dropped.
String reactionContentFromGitLabAwardEmoji(String name) {
  for (final entry in _gitLabAwardEmojiByContent.entries) {
    if (entry.value == name) {
      return entry.key;
    }
  }
  return name;
}

/// Maps GitLab award emoji onto the port's raw `(emoji, who)` pairs.
List<ForgeReaction> forgeReactionsFromGitLab(
  Iterable<GitLabAwardEmoji> awards,
) => <ForgeReaction>[
  for (final award in awards)
    if (award.name.isNotEmpty)
      ForgeReaction(
        content: reactionContentFromGitLabAwardEmoji(award.name),
        login: award.user?.username ?? '',
      ),
];
