import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/commit_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_activity_entry.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_branch.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_comment.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_commit.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_commit_status.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_diffstat_entry.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_participant.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_pipeline.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_pull_request.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_user.dart';

/// The synthetic global identifier for a Bitbucket pull request:
/// `bb:<workspace>/<repo>#<id>`.
///
/// Bitbucket publishes no globally unique opaque id — its `id` is per-repo, so
/// PR 1 exists in every repository. `PullRequest.externalId` is contracted to
/// be globally unique and opaque to callers, so the adapter mints one from the
/// coordinate that *does* identify the pull request. It is stable (nothing in
/// it can change without the pull request becoming a different pull request)
/// and is never parsed back apart — callers treat it as a key.
String bitbucketPrExternalId(String owner, String repo, int id) =>
    'bb:$owner/$repo#$id';

/// Maps a Bitbucket account onto the domain's user.
///
/// `PrUser.login` takes `nickname` — the handle a human types and the closest
/// thing Bitbucket has to a login — and falls back to `account_id` when the
/// account withholds a nickname. Nothing in the domain treats `login` as
/// resolvable back to a Bitbucket write API: the reviewer writes resolve
/// handles to account uuids through the workspace membership instead.
PrUser prUserFromBitbucket(BitbucketUser? user) {
  if (user == null) {
    return const PrUser(login: '', avatarUrl: '');
  }
  return PrUser(
    login: user.handle,
    avatarUrl: user.avatarUrl,
    name: user.displayName.isEmpty ? null : user.displayName,
  );
}

/// Maps a Bitbucket pull request onto the domain entity.
///
/// Approximations, all forced by what Bitbucket does not publish:
///
/// * `id` and `number` are both the per-repo Bitbucket id; the globally unique
///   handle is the synthesized [bitbucketPrExternalId].
/// * `isDraft` is always false — Bitbucket Cloud has no draft pull requests.
/// * `mergedAt` falls back to `updated_on` for a `MERGED` pull request, since
///   Bitbucket publishes no merge timestamp. It is therefore the time of the
///   last change to a merged pull request, which is the merge itself unless
///   something touched it afterwards.
/// * `assignees` is always empty — Bitbucket has no assignee separate from the
///   reviewer roster.
/// * `reviewDecision` is rolled up from the participants: any outstanding
///   "changes requested" wins, else any approval, else none. Bitbucket exposes
///   no "review required" signal on the pull request, so a repository whose
///   merge checks demand a review still reads as `none` until someone votes.
/// * `additions`/`deletions`/`changedFiles`/`commitsCount`/`checksStatus`/
///   `mergeableState` are left at their defaults: none of them are on this
///   payload and each has its own endpoint.
PullRequest pullRequestFromBitbucket(
  BitbucketPullRequest pr, {
  required String owner,
  required String repo,
}) {
  final merged = pr.isMerged;
  return PullRequest(
    id: pr.id,
    number: pr.id,
    title: pr.title,
    body: pr.description,
    bodyHtml: pr.descriptionHtml,
    state: _prStateFromBitbucket(pr.state),
    isDraft: false,
    author: prUserFromBitbucket(pr.author),
    createdAt: pr.createdOn,
    updatedAt: pr.updatedOn,
    repoFullName: '$owner/$repo',
    htmlUrl: pr.htmlUrl,
    externalId: bitbucketPrExternalId(owner, repo, pr.id),
    headSha: pr.sourceCommitHash,
    baseRef: pr.destinationBranch,
    baseSha: pr.destinationCommitHash,
    headRef: pr.sourceBranch,
    requestedReviewers: pr.reviewers
        .map(prUserFromBitbucket)
        .toList(growable: false),
    assignees: const <PrUser>[],
    mergedAt: merged ? pr.updatedOn : null,
    commentsCount: pr.commentCount,
    reviewDecision: _reviewDecisionFromBitbucket(pr.participants),
  );
}

/// Maps a diffstat entry onto the domain's file.
///
/// [patch] must be supplied by the caller: Bitbucket's diffstat carries counts
/// and paths but no hunks, so the text comes from the sibling unified-diff
/// endpoint via [patchesByPathFromUnifiedDiff]. It defaults to empty, which is
/// what a binary file legitimately has.
PrFile prFileFromBitbucket(BitbucketDiffstatEntry entry, {String patch = ''}) {
  final renamed = entry.isRename;
  return PrFile(
    filename: entry.path,
    // `PrFileStatusExtension.fromString` already agrees with Bitbucket's
    // added/removed/modified/renamed spellings and defaults anything else
    // (`merge conflict`) to modified.
    status: renamed
        ? PrFileStatus.renamed
        : PrFileStatusExtension.fromString(entry.status),
    additions: entry.linesAdded,
    deletions: entry.linesRemoved,
    patch: patch,
    previousFilename: renamed ? entry.oldPath : null,
  );
}

/// Maps a Bitbucket commit onto the domain's commit.
///
/// When the commit's author email matches no Bitbucket account the entity gets
/// a user whose `login` is the raw git author name and whose avatar is empty —
/// a name with no profile behind it, which is exactly the truth.
PrCommit prCommitFromBitbucket(BitbucketCommit commit) => PrCommit(
  sha: commit.hash,
  message: commit.message,
  author: commit.author != null
      ? prUserFromBitbucket(commit.author)
      : PrUser(login: commit.rawAuthorName, avatarUrl: ''),
  date: commit.date,
);

/// Maps an inline Bitbucket comment onto the domain's code review comment.
///
/// Bitbucket anchors with `{from, to}`: `to` names a line on the post-image and
/// `from` a line on the pre-image, so `to` becomes side `RIGHT` and `from`
/// becomes side `LEFT`. A comment on an outdated or file-level anchor has
/// neither, and keeps side `RIGHT` with a null line.
///
/// `diffHunk`, `startLine` and `reviewId` stay empty/null: Bitbucket returns no
/// surrounding hunk, has no multi-line anchors and has no review resource for a
/// comment to belong to.
PrCodeReviewComment prCodeReviewCommentFromBitbucket(BitbucketComment comment) {
  final onNewSide = comment.inlineTo != null;
  final line = comment.inlineTo ?? comment.inlineFrom;
  return PrCodeReviewComment(
    id: comment.id,
    body: comment.rawContent,
    user: prUserFromBitbucket(comment.user),
    path: comment.inlinePath ?? '',
    position: line,
    createdAt: comment.createdOn,
    side: onNewSide ? 'RIGHT' : 'LEFT',
    inReplyToId: comment.parentId,
    line: line,
    originalLine: comment.inlineFrom,
  );
}

/// Maps a top-level Bitbucket comment onto the domain's conversation comment.
///
/// `reactions` stays empty: Bitbucket has no reaction API, which is why the
/// `reactions` capability is false rather than "supported but empty".
IssueComment issueCommentFromBitbucket(BitbucketComment comment) =>
    IssueComment(
      id: comment.id,
      body: comment.rawContent,
      user: prUserFromBitbucket(comment.user),
      createdAt: comment.createdOn,
    );

/// Maps a participant's verdict onto a review submission, or null when the
/// participant has not voted.
///
/// Bitbucket has no review resource: a verdict is a flag on the participation
/// row. So the submission gets `id: 0` (there is no review id to carry) and an
/// EMPTY body — the fact that Bitbucket cannot attach prose to a verdict is
/// why a review body posted through this adapter becomes a separate comment.
PrReviewSubmission? prReviewSubmissionFromBitbucket(
  BitbucketParticipant participant,
) {
  if (!participant.hasVerdict) {
    return null;
  }
  return PrReviewSubmission(
    state: participant.hasRequestedChanges
        ? PrReviewSubmissionState.changesRequested
        : PrReviewSubmissionState.approved,
    author: prUserFromBitbucket(participant.user),
    body: '',
    submittedAt: participant.participatedOn,
  );
}

/// Every submitted verdict on a pull request, in participant order.
List<PrReviewSubmission> prReviewSubmissionsFromBitbucket(
  BitbucketPullRequest pr,
) => <PrReviewSubmission>[
  for (final participant in pr.participants)
    ?prReviewSubmissionFromBitbucket(participant),
];

/// Reconciles a pull request's requested reviewers with its participants into
/// the domain's reviewer rows.
///
/// A requested reviewer who has not voted is `pending`; a participant's verdict
/// overrides that row. Participants who voted without being asked (Bitbucket's
/// `PARTICIPANT` role) are included too — their approval counts on Bitbucket,
/// so hiding them would misreport the pull request.
///
/// Every row is `isCodeOwner: false`: Bitbucket has no CODEOWNERS equivalent,
/// and the reviewer state's empty `codeOwnerIdentities` says "this forge
/// cannot tell you", not "nobody owns this code". Only user rows are produced
/// — Bitbucket cannot request a review from a group.
List<PrReviewer> prReviewersFromBitbucket(BitbucketPullRequest pr) {
  final rows = <String, PrUserReviewer>{};

  for (final requested in pr.reviewers) {
    final user = prUserFromBitbucket(requested);
    if (user.login.isEmpty) {
      continue;
    }
    rows[user.login.toLowerCase()] = PrUserReviewer(
      user: user,
      isCodeOwner: false,
      state: PrReviewSubmissionState.pending,
    );
  }

  for (final participant in pr.participants) {
    final user = prUserFromBitbucket(participant.user);
    if (user.login.isEmpty) {
      continue;
    }
    final key = user.login.toLowerCase();
    if (!participant.hasVerdict) {
      // A participant with no verdict only earns a row when they were asked;
      // someone who merely commented is not an awaited reviewer.
      if (participant.isReviewer && !rows.containsKey(key)) {
        rows[key] = PrUserReviewer(
          user: user,
          isCodeOwner: false,
          state: PrReviewSubmissionState.pending,
        );
      }
      continue;
    }
    rows[key] = PrUserReviewer(
      user: user,
      isCodeOwner: false,
      state: participant.hasRequestedChanges
          ? PrReviewSubmissionState.changesRequested
          : PrReviewSubmissionState.approved,
    );
  }

  return rows.values.toList(growable: false);
}

/// Maps Bitbucket's branch refs onto the compose-PR pickers' branch rows.
///
/// [defaultBranch] flags the repository's main branch; pass `''` when it is
/// unknown and no row is flagged.
///
/// The result is re-sorted newest-first with unknown dates LAST, independently
/// of the `-target.date` the request asked for. The port contracts that
/// ordering, and a branch whose tip carries no date must not lead a picker
/// just because the server happened to return it first.
///
/// The author label prefers the tip commit's linked Bitbucket account — its
/// nickname, so the string matches the handle `PrUser.login` shows elsewhere —
/// and falls back to its display name, then to the raw git author name for a
/// commit whose email matches no account.
List<ForgeBranch> forgeBranchesFromBitbucket(
  List<BitbucketBranch> branches, {
  String defaultBranch = '',
}) {
  final rows = <ForgeBranch>[
    for (final branch in branches)
      if (branch.name.isNotEmpty)
        ForgeBranch(
          name: branch.name,
          lastCommitAt: branch.target?.date,
          lastCommitAuthor: _branchAuthorLabel(branch.target),
          isDefault: defaultBranch.isNotEmpty && branch.name == defaultBranch,
        ),
  ]..sort((a, b) {
    final left = a.lastCommitAt;
    final right = b.lastCommitAt;
    if (left == null && right == null) {
      return 0;
    }
    if (left == null) {
      return 1;
    }
    if (right == null) {
      return -1;
    }
    return right.compareTo(left);
  });
  return rows;
}

String _branchAuthorLabel(BitbucketCommit? target) {
  if (target == null) {
    return '';
  }
  final user = target.author;
  if (user != null) {
    if (user.nickname.isNotEmpty) {
      return user.nickname;
    }
    if (user.displayName.isNotEmpty) {
      return user.displayName;
    }
  }
  return target.rawAuthorName;
}

/// Maps a Bitbucket build status onto the domain's check run.
///
/// Bitbucket's four states collapse onto the domain's status/conclusion pair:
/// `INPROGRESS` is in-progress with no conclusion, `SUCCESSFUL`/`FAILED` are
/// completed with the obvious verdict, and `STOPPED` is completed/cancelled.
/// `jobId`, `workflowRunId` and `checkSuiteId` stay null — there is nothing
/// behind a Bitbucket status to drill into, which is the `ciJobDetail`
/// capability being false.
CheckRun checkRunFromBitbucketStatus(BitbucketCommitStatus status) {
  final upper = status.state.toUpperCase();
  return CheckRun(
    name: _checkName(status.name, status.key),
    status: switch (upper) {
      'INPROGRESS' => CheckRunStatus.inProgress,
      'SUCCESSFUL' || 'FAILED' || 'STOPPED' => CheckRunStatus.completed,
      _ => CheckRunStatus.queued,
    },
    conclusion: switch (upper) {
      'SUCCESSFUL' => CheckRunConclusion.success,
      'FAILED' => CheckRunConclusion.failure,
      'STOPPED' => CheckRunConclusion.cancelled,
      _ => null,
    },
    htmlUrl: status.url,
    startedAt: status.createdOn,
    completedAt: status.isTerminal ? status.updatedOn : null,
    output: status.description,
  );
}

/// Maps a Bitbucket Pipelines run onto the domain's check run.
///
/// For callers that want the native pipeline view. A run also publishes a
/// build status, so mixing these into the list from
/// [checkRunFromBitbucketStatus] double-counts the same work.
CheckRun checkRunFromBitbucketPipeline(BitbucketPipeline pipeline) {
  final state = pipeline.stateName.toUpperCase();
  final result = pipeline.resultName.toUpperCase();
  return CheckRun(
    name: pipeline.displayName,
    status: switch (state) {
      'COMPLETED' => CheckRunStatus.completed,
      'IN_PROGRESS' || 'PAUSED' => CheckRunStatus.inProgress,
      _ => CheckRunStatus.queued,
    },
    conclusion: switch (result) {
      'SUCCESSFUL' => CheckRunConclusion.success,
      'FAILED' || 'ERROR' => CheckRunConclusion.failure,
      'STOPPED' => CheckRunConclusion.cancelled,
      _ => null,
    },
    startedAt: pipeline.createdOn,
    completedAt: pipeline.completedOn,
    output: pipeline.triggerName,
  );
}

/// Maps a Bitbucket build status onto the domain's commit status.
///
/// The same wire object feeds both this and [checkRunFromBitbucketStatus]:
/// Bitbucket has one status API, not GitHub's separate checks and statuses, so
/// a deploy-preview integration and a test run arrive through the same door.
CommitStatus commitStatusFromBitbucket(BitbucketCommitStatus status) {
  final upper = status.state.toUpperCase();
  return CommitStatus(
    context: status.key.isNotEmpty ? status.key : status.name,
    state: switch (upper) {
      'SUCCESSFUL' => CommitStatusState.success,
      'FAILED' => CommitStatusState.failure,
      'STOPPED' => CommitStatusState.error,
      _ => CommitStatusState.pending,
    },
    targetUrl: status.url,
    description: status.description,
    updatedAt: status.updatedOn,
  );
}

/// Derives review-request timeline events from a pull request's activity feed.
///
/// Bitbucket records no discrete "review requested" event. What it records is
/// an `update` entry carrying the reviewer roster as it stood afterwards, so
/// the events are recovered by replaying the feed oldest-first and diffing
/// consecutive rosters: a reviewer who appears was requested, one who
/// disappears had the request withdrawn. The roster on the first update is
/// treated as requested at that moment, which is what opening a pull request
/// with reviewers attached means.
///
/// This is therefore an approximation in two ways. Updates that did not report
/// a roster are skipped (Bitbucket omits the field rather than repeating it),
/// so a change made across such a gap is attributed to the next update that
/// does report one. And the actor is the update's author, which is the person
/// who edited the pull request — on Bitbucket that is the only attribution
/// available.
///
/// Approval, changes-requested and comment entries produce nothing: the domain
/// models only the two review-request kinds, and those signals ride the review
/// and comment streams instead.
List<PrTimelineEvent> prTimelineEventsFromBitbucket(
  List<BitbucketActivityEntry> activity,
) {
  final updates =
      activity
          .where(
            (e) =>
                e.kind == BitbucketActivityKind.update && e.reviewers != null,
          )
          .toList()
        ..sort((a, b) {
          final left = a.date;
          final right = b.date;
          if (left == null || right == null) {
            return 0;
          }
          return left.compareTo(right);
        });

  final events = <PrTimelineEvent>[];
  var previous = <String, BitbucketUser>{};
  var first = true;
  for (final update in updates) {
    final current = <String, BitbucketUser>{
      for (final user in update.reviewers ?? const <BitbucketUser>[])
        if (user.handle.isNotEmpty) user.handle.toLowerCase(): user,
    };
    final actor = update.actor == null
        ? null
        : prUserFromBitbucket(update.actor);

    for (final entry in current.entries) {
      if (first || !previous.containsKey(entry.key)) {
        events.add(
          PrTimelineEvent(
            kind: PrTimelineEventKind.reviewRequested,
            actor: actor,
            reviewerName: entry.value.handle,
            reviewerAvatarUrl: entry.value.avatarUrl,
            createdAt: update.date,
          ),
        );
      }
    }
    if (!first) {
      for (final entry in previous.entries) {
        if (!current.containsKey(entry.key)) {
          events.add(
            PrTimelineEvent(
              kind: PrTimelineEventKind.reviewRequestRemoved,
              actor: actor,
              reviewerName: entry.value.handle,
              reviewerAvatarUrl: entry.value.avatarUrl,
              createdAt: update.date,
            ),
          );
        }
      }
    }

    previous = current;
    first = false;
  }
  return events;
}

/// Splits a unified diff into per-file patches, keyed by the file's path.
///
/// This exists because Bitbucket's diffstat — unlike GitHub's files endpoint —
/// carries no hunks, so the only way to hand the diff viewer real patch text is
/// to fetch the whole unified diff once and cut it up. Each value is the
/// hunks-only slice, starting at the first `@@` line, matching what GitHub's
/// `patch` field contains; a segment with no hunks (a binary file, a
/// content-free rename) maps to an empty string.
///
/// Files are keyed by their post-image path (`+++ b/…`), falling back to a
/// `rename to` line, then the pre-image path for a deletion, then the `b/` half
/// of the `diff --git` header for a segment that carries none of those. That is
/// the same key `BitbucketDiffstatEntry.path` produces, which is what lets the
/// two responses be joined.
///
/// Paths that git had to quote (embedded tabs, newlines, non-UTF-8 bytes) are
/// left as git wrote them and simply will not match a diffstat entry, so such a
/// file renders without a patch rather than under a wrong name.
Map<String, String> patchesByPathFromUnifiedDiff(String diff) {
  final patches = <String, String>{};
  if (diff.isEmpty) {
    return patches;
  }
  final lines = diff.split('\n');
  var start = -1;
  for (var i = 0; i <= lines.length; i++) {
    final isHeader = i < lines.length && lines[i].startsWith(_gitDiffHeader);
    if (!isHeader && i != lines.length) {
      continue;
    }
    if (start >= 0) {
      _absorbDiffSegment(patches, lines.sublist(start, i));
    }
    start = i;
  }
  return patches;
}

const String _gitDiffHeader = 'diff --git ';
const String _renameToPrefix = 'rename to ';

void _absorbDiffSegment(Map<String, String> out, List<String> segment) {
  String? oldPath;
  String? newPath;
  String? renameTo;
  var hunkStart = -1;
  for (var i = 0; i < segment.length; i++) {
    final line = segment[i];
    // Every header line precedes the first hunk, so stopping here also keeps
    // hunk BODIES out of the scan — an added line reading `+++ foo` would
    // otherwise be mistaken for a path header.
    if (line.startsWith('@@')) {
      hunkStart = i;
      break;
    }
    if (line.startsWith('--- ')) {
      oldPath = _stripDiffPathPrefix(line.substring(4));
    } else if (line.startsWith('+++ ')) {
      newPath = _stripDiffPathPrefix(line.substring(4));
    } else if (line.startsWith(_renameToPrefix)) {
      renameTo = line.substring(_renameToPrefix.length).trim();
    }
  }

  final path =
      newPath ?? renameTo ?? oldPath ?? _pathFromGitDiffHeader(segment.first);
  if (path == null || path.isEmpty) {
    return;
  }
  out[path] = hunkStart < 0
      ? ''
      : segment.sublist(hunkStart).join('\n').trimRight();
}

String? _stripDiffPathPrefix(String raw) {
  var value = raw;
  // git appends a tab-separated timestamp on some diff dialects.
  final tab = value.indexOf('\t');
  if (tab >= 0) {
    value = value.substring(0, tab);
  }
  value = value.trim();
  if (value.isEmpty || value == '/dev/null') {
    return null;
  }
  if (value.startsWith('a/') || value.startsWith('b/')) {
    return value.substring(2);
  }
  return value;
}

String? _pathFromGitDiffHeader(String header) {
  if (!header.startsWith(_gitDiffHeader)) {
    return null;
  }
  final rest = header.substring(_gitDiffHeader.length).trim();
  final marker = rest.indexOf(' b/');
  if (marker < 0) {
    return null;
  }
  return rest.substring(marker + 3);
}

String _checkName(String name, String key) {
  if (name.isNotEmpty) {
    return name;
  }
  // `CheckRun` asserts a non-empty name; a status with neither name nor key is
  // malformed, so label it rather than crash the whole check list.
  return key.isNotEmpty ? key : 'Build';
}

PrState _prStateFromBitbucket(String state) => switch (state.toUpperCase()) {
  'MERGED' => PrState.merged,
  'DECLINED' || 'SUPERSEDED' => PrState.closed,
  _ => PrState.open,
};

PrReviewDecision _reviewDecisionFromBitbucket(
  List<BitbucketParticipant> participants,
) {
  var approved = false;
  for (final participant in participants) {
    if (participant.hasRequestedChanges) {
      return PrReviewDecision.changesRequested;
    }
    if (participant.approved) {
      approved = true;
    }
  }
  return approved ? PrReviewDecision.approved : PrReviewDecision.none;
}
