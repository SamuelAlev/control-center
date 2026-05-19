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
import 'package:cc_domain/features/pr_review/domain/entities/reaction_group.dart';

/// Symmetric JSON codecs for the PR-review SWR disk cache.
///
/// The cache used to store GitHub's *wire* JSON and re-derive domain entities
/// from it on read, which meant a cached PR could only ever have come from
/// GitHub. These codecs are forge-neutral and, unlike the old pair, genuinely
/// symmetric: `xToCache` and `xFromCache` name the same keys, so what is
/// written is exactly what is read back and a GitLab merge request caches the
/// same way a GitHub pull request does.
///
/// Keys are short but spelled out rather than positional — a cache row outlives
/// a release, and a renamed field should read as a missing value (safely
/// defaulted) instead of silently taking a neighbour's data.
///
/// Every `fromCache` tolerates a missing or wrongly-typed key: a cache is a
/// performance aid, so a partially-unreadable row degrades to defaults and gets
/// overwritten by the next revalidation. It must never throw and take a stream
/// down.
class PrCacheCodec {
  const PrCacheCodec._();

  // ── primitives ───────────────────────────────────────────────────────────

  static String? _str(dynamic v) => v is String ? v : null;

  static int _int(dynamic v, [int fallback = 0]) =>
      v is num ? v.toInt() : fallback;

  static int? _intOrNull(dynamic v) => v is num ? v.toInt() : null;

  static bool _bool(dynamic v, [bool fallback = false]) =>
      v is bool ? v : fallback;

  static DateTime? _date(dynamic v) =>
      v is String ? DateTime.tryParse(v) : null;

  static List<Map<String, dynamic>> _maps(dynamic v) => v is List
      ? v.whereType<Map<String, dynamic>>().toList(growable: false)
      : const [];

  static List<String> _strings(dynamic v) =>
      v is List ? v.whereType<String>().toList(growable: false) : const [];

  /// Resolves an enum by name, falling back when the stored name is unknown —
  /// which is what happens when a cache row predates a new enum member.
  static T _enumByName<T extends Enum>(
    List<T> values,
    dynamic name,
    T fallback,
  ) {
    if (name is! String) {
      return fallback;
    }
    for (final v in values) {
      if (v.name == name) {
        return v;
      }
    }
    return fallback;
  }

  // ── PrUser ───────────────────────────────────────────────────────────────

  /// Serializes a user.
  static Map<String, dynamic> userToCache(PrUser u) => {
    'login': u.login,
    'avatar_url': u.avatarUrl,
    if (u.name != null) 'name': u.name,
  };

  /// Reads a user, or null when the key was absent.
  ///
  /// A present-but-blank user decodes to a blank [PrUser] rather than null, so
  /// the codec is a true round trip. Collapsing it to null instead would make
  /// `encode(decode(x))` differ from `x` for any PR whose author the forge
  /// withheld — and the SWR cache dedupes emissions by comparing exactly those
  /// two strings, so every cached read of such a PR would emit twice.
  static PrUser? userFromCache(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    return PrUser(
      login: _str(raw['login']) ?? '',
      avatarUrl: _str(raw['avatar_url']) ?? '',
      name: _str(raw['name']),
    );
  }

  static List<PrUser> _usersFromCache(dynamic raw) => [
    for (final m in _maps(raw)) ?userFromCache(m),
  ];

  // ── ReactionGroup ────────────────────────────────────────────────────────

  /// Serializes reaction groups.
  static List<Map<String, dynamic>> reactionsToCache(
    List<ReactionGroup> groups,
  ) => [
    for (final g in groups)
      {
        'content': g.content,
        'emoji': g.emoji,
        'count': g.count,
        'user_reacted': g.userReacted,
        'usernames': g.usernames,
      },
  ];

  /// Reads reaction groups.
  static List<ReactionGroup> reactionsFromCache(dynamic raw) => [
    for (final m in _maps(raw))
      ReactionGroup(
        content: _str(m['content']) ?? '',
        emoji: _str(m['emoji']) ?? '',
        count: _int(m['count']),
        userReacted: _bool(m['user_reacted']),
        usernames: _strings(m['usernames']),
      ),
  ];

  // ── PullRequest ──────────────────────────────────────────────────────────

  /// Serializes a pull request.
  static Map<String, dynamic> pullRequestToCache(PullRequest pr) => {
    'id': pr.id,
    'number': pr.number,
    'title': pr.title,
    'body': pr.body,
    'state': pr.state.name,
    'is_draft': pr.isDraft,
    if (pr.author != null) 'author': userToCache(pr.author!),
    'created_at': pr.createdAt?.toIso8601String(),
    'updated_at': pr.updatedAt?.toIso8601String(),
    'merged_at': pr.mergedAt?.toIso8601String(),
    'repo_full_name': pr.repoFullName,
    'html_url': pr.htmlUrl,
    'external_id': pr.externalId,
    'head_sha': pr.headSha,
    'head_ref': pr.headRef,
    'base_ref': pr.baseRef,
    'base_sha': pr.baseSha,
    'requested_reviewers': [
      for (final u in pr.requestedReviewers) userToCache(u),
    ],
    'requested_team_slugs': pr.requestedTeamSlugs,
    'assignees': [for (final u in pr.assignees) userToCache(u)],
    'reviewed_by_me': pr.reviewedByMe,
    'reactions': reactionsToCache(pr.reactions),
    // A cached `body_html` can carry image JWTs that expire after ~5 minutes.
    // The renderer degrades to an attachment card on image error and the next
    // SWR pass refreshes it, so caching it is still worth it.
    if (pr.bodyHtml != null) 'body_html': pr.bodyHtml,
    'changed_files': pr.changedFiles,
    'commits_count': pr.commitsCount,
    'additions': pr.additions,
    'deletions': pr.deletions,
    'comments_count': pr.commentsCount,
    'checks_status': pr.checksStatus.name,
    'mergeable_state': pr.mergeableState.name,
    'review_decision': pr.reviewDecision.name,
  };

  /// Reads a pull request, or null when the map is absent.
  static PullRequest? pullRequestFromCache(Map<String, dynamic>? m) {
    if (m == null) {
      return null;
    }
    return PullRequest(
      id: _int(m['id']),
      number: _int(m['number']),
      title: _str(m['title']) ?? '',
      body: _str(m['body']) ?? '',
      state: _enumByName(PrState.values, m['state'], PrState.open),
      isDraft: _bool(m['is_draft']),
      author: userFromCache(m['author']),
      createdAt: _date(m['created_at']),
      updatedAt: _date(m['updated_at']),
      repoFullName: _str(m['repo_full_name']) ?? '',
      htmlUrl: _str(m['html_url']) ?? '',
      externalId: _str(m['external_id']) ?? '',
      headSha: _str(m['head_sha']) ?? '',
      headRef: _str(m['head_ref']) ?? '',
      baseRef: _str(m['base_ref']) ?? '',
      baseSha: _str(m['base_sha']) ?? '',
      requestedReviewers: _usersFromCache(m['requested_reviewers']),
      requestedTeamSlugs: _strings(m['requested_team_slugs']),
      assignees: _usersFromCache(m['assignees']),
      mergedAt: _date(m['merged_at']),
      reviewedByMe: _bool(m['reviewed_by_me']),
      reactions: reactionsFromCache(m['reactions']),
      bodyHtml: _str(m['body_html']),
      changedFiles: _int(m['changed_files']),
      commitsCount: _int(m['commits_count']),
      additions: _int(m['additions']),
      deletions: _int(m['deletions']),
      commentsCount: _int(m['comments_count']),
      checksStatus: _enumByName(
        PrChecksStatus.values,
        m['checks_status'],
        PrChecksStatus.none,
      ),
      mergeableState: _enumByName(
        PrMergeableState.values,
        m['mergeable_state'],
        PrMergeableState.unknown,
      ),
      reviewDecision: _enumByName(
        PrReviewDecision.values,
        m['review_decision'],
        PrReviewDecision.none,
      ),
    );
  }

  // ── PrFile ───────────────────────────────────────────────────────────────

  /// Serializes a changed file.
  static Map<String, dynamic> fileToCache(PrFile f) => {
    'filename': f.filename,
    'status': f.status.name,
    'additions': f.additions,
    'deletions': f.deletions,
    'patch': f.patch,
    if (f.previousFilename != null) 'previous_filename': f.previousFilename,
    'viewed_state': f.viewerViewedState.name,
  };

  /// Reads a changed file.
  static PrFile fileFromCache(Map<String, dynamic> m) => PrFile(
    filename: _str(m['filename']) ?? '',
    status: _enumByName(
      PrFileStatus.values,
      m['status'],
      PrFileStatus.modified,
    ),
    additions: _int(m['additions']),
    deletions: _int(m['deletions']),
    patch: _str(m['patch']) ?? '',
    previousFilename: _str(m['previous_filename']),
    viewerViewedState: _enumByName(
      PrFileViewedState.values,
      m['viewed_state'],
      PrFileViewedState.unviewed,
    ),
  );

  // ── PrCommit ─────────────────────────────────────────────────────────────

  /// Serializes a commit.
  static Map<String, dynamic> commitToCache(PrCommit c) => {
    'sha': c.sha,
    'message': c.message,
    if (c.author != null) 'author': userToCache(c.author!),
    'date': c.date?.toIso8601String(),
  };

  /// Reads a commit.
  static PrCommit commitFromCache(Map<String, dynamic> m) => PrCommit(
    sha: _str(m['sha']) ?? '',
    message: _str(m['message']) ?? '',
    author: userFromCache(m['author']),
    date: _date(m['date']),
  );

  // ── PrReviewSubmission ───────────────────────────────────────────────────

  /// Serializes a submitted review.
  static Map<String, dynamic> reviewToCache(PrReviewSubmission r) => {
    'id': r.id,
    'state': r.state.name,
    if (r.author != null) 'author': userToCache(r.author!),
    'body': r.body,
    'submitted_at': r.submittedAt?.toIso8601String(),
    'reactions': reactionsToCache(r.reactions),
  };

  /// Reads a submitted review.
  static PrReviewSubmission reviewFromCache(Map<String, dynamic> m) =>
      PrReviewSubmission(
        id: _int(m['id']),
        state: _enumByName(
          PrReviewSubmissionState.values,
          m['state'],
          PrReviewSubmissionState.commented,
        ),
        author: userFromCache(m['author']),
        body: _str(m['body']) ?? '',
        submittedAt: _date(m['submitted_at']),
        reactions: reactionsFromCache(m['reactions']),
      );

  // ── PrCodeReviewComment ──────────────────────────────────────────────────

  /// Serializes an inline review comment.
  static Map<String, dynamic> reviewCommentToCache(PrCodeReviewComment c) => {
    'id': c.id,
    if (c.reviewId != null) 'review_id': c.reviewId,
    'body': c.body,
    if (c.user != null) 'user': userToCache(c.user!),
    'path': c.path,
    'position': c.position,
    'created_at': c.createdAt?.toIso8601String(),
    'side': c.side,
    if (c.inReplyToId != null) 'in_reply_to_id': c.inReplyToId,
    if (c.startLine != null) 'start_line': c.startLine,
    'diff_hunk': c.diffHunk,
    if (c.line != null) 'line': c.line,
    if (c.originalLine != null) 'original_line': c.originalLine,
    if (c.threadId != null) 'thread_id': c.threadId,
    if (c.isResolved) 'is_resolved': true,
    'reactions': reactionsToCache(c.reactions),
  };

  /// Reads an inline review comment.
  static PrCodeReviewComment reviewCommentFromCache(Map<String, dynamic> m) =>
      PrCodeReviewComment(
        id: _int(m['id']),
        reviewId: _intOrNull(m['review_id']),
        body: _str(m['body']) ?? '',
        user: userFromCache(m['user']),
        path: _str(m['path']) ?? '',
        position: _intOrNull(m['position']),
        createdAt: _date(m['created_at']),
        side: _str(m['side']) ?? 'RIGHT',
        inReplyToId: _intOrNull(m['in_reply_to_id']),
        startLine: _intOrNull(m['start_line']),
        diffHunk: _str(m['diff_hunk']) ?? '',
        line: _intOrNull(m['line']),
        originalLine: _intOrNull(m['original_line']),
        threadId: _str(m['thread_id']),
        isResolved: m['is_resolved'] == true,
        reactions: reactionsFromCache(m['reactions']),
      );

  // ── IssueComment ─────────────────────────────────────────────────────────

  /// Serializes a conversation comment.
  static Map<String, dynamic> issueCommentToCache(IssueComment c) => {
    'id': c.id,
    'body': c.body,
    if (c.user != null) 'user': userToCache(c.user!),
    'created_at': c.createdAt?.toIso8601String(),
    'reactions': reactionsToCache(c.reactions),
  };

  /// Reads a conversation comment.
  static IssueComment issueCommentFromCache(Map<String, dynamic> m) =>
      IssueComment(
        id: _int(m['id']),
        body: _str(m['body']) ?? '',
        user: userFromCache(m['user']),
        createdAt: _date(m['created_at']),
        reactions: reactionsFromCache(m['reactions']),
      );

  // ── PrTimelineEvent ──────────────────────────────────────────────────────

  /// Serializes a timeline event.
  static Map<String, dynamic> timelineEventToCache(PrTimelineEvent e) => {
    'kind': e.kind.name,
    if (e.actor != null) 'actor': userToCache(e.actor!),
    'reviewer_name': e.reviewerName,
    'reviewer_is_team': e.reviewerIsTeam,
    'reviewer_avatar_url': e.reviewerAvatarUrl,
    'created_at': e.createdAt?.toIso8601String(),
  };

  /// Reads a timeline event.
  static PrTimelineEvent timelineEventFromCache(Map<String, dynamic> m) =>
      PrTimelineEvent(
        kind: _enumByName(
          PrTimelineEventKind.values,
          m['kind'],
          PrTimelineEventKind.values.first,
        ),
        actor: userFromCache(m['actor']),
        reviewerName: _str(m['reviewer_name']) ?? '',
        reviewerIsTeam: _bool(m['reviewer_is_team']),
        reviewerAvatarUrl: _str(m['reviewer_avatar_url']) ?? '',
        createdAt: _date(m['created_at']),
      );

  // ── CheckRun ─────────────────────────────────────────────────────────────

  /// Serializes a CI check.
  static Map<String, dynamic> checkRunToCache(CheckRun c) => {
    'name': c.name,
    'status': c.status.name,
    if (c.conclusion != null) 'conclusion': c.conclusion!.name,
    'html_url': c.htmlUrl,
    'started_at': c.startedAt?.toIso8601String(),
    'completed_at': c.completedAt?.toIso8601String(),
    'output': c.output,
    if (c.workflowName != null) 'workflow_name': c.workflowName,
    if (c.checkSuiteId != null) 'check_suite_id': c.checkSuiteId,
    if (c.jobId != null) 'job_id': c.jobId,
    if (c.workflowRunId != null) 'workflow_run_id': c.workflowRunId,
  };

  /// Reads a CI check.
  static CheckRun checkRunFromCache(Map<String, dynamic> m) => CheckRun(
    name: _str(m['name']) ?? '',
    status: _enumByName(
      CheckRunStatus.values,
      m['status'],
      CheckRunStatus.completed,
    ),
    conclusion: m['conclusion'] == null
        ? null
        : _enumByName(
            CheckRunConclusion.values,
            m['conclusion'],
            CheckRunConclusion.neutral,
          ),
    htmlUrl: _str(m['html_url']) ?? '',
    startedAt: _date(m['started_at']),
    completedAt: _date(m['completed_at']),
    output: _str(m['output']) ?? '',
    workflowName: _str(m['workflow_name']),
    checkSuiteId: _intOrNull(m['check_suite_id']),
    jobId: _intOrNull(m['job_id']),
    workflowRunId: _intOrNull(m['workflow_run_id']),
  );

  // ── CommitStatus ─────────────────────────────────────────────────────────

  /// Serializes a commit status.
  static Map<String, dynamic> commitStatusToCache(CommitStatus s) => {
    'context': s.context,
    'state': s.state.name,
    'target_url': s.targetUrl,
    'description': s.description,
    'updated_at': s.updatedAt?.toIso8601String(),
  };

  /// Reads a commit status.
  static CommitStatus commitStatusFromCache(Map<String, dynamic> m) =>
      CommitStatus(
        context: _str(m['context']) ?? '',
        state: _enumByName(
          CommitStatusState.values,
          m['state'],
          CommitStatusState.pending,
        ),
        targetUrl: _str(m['target_url']) ?? '',
        description: _str(m['description']) ?? '',
        updatedAt: _date(m['updated_at']),
      );

  // ── PrReviewer ───────────────────────────────────────────────────────────

  /// Serializes a reviewer (user or team).
  static Map<String, dynamic> reviewerToCache(PrReviewer r) => switch (r) {
    PrUserReviewer(:final user) => {
      'kind': 'user',
      'user': userToCache(user),
      'is_code_owner': r.isCodeOwner,
      'state': r.state.name,
    },
    PrTeamReviewer(
      :final name,
      :final slug,
      :final avatarUrl,
      :final reviewedBy,
    ) =>
      {
        'kind': 'team',
        'name': name,
        'slug': slug,
        'avatar_url': avatarUrl,
        if (reviewedBy != null) 'reviewed_by': userToCache(reviewedBy),
        'is_code_owner': r.isCodeOwner,
        'state': r.state.name,
      },
  };

  /// Reads a reviewer.
  static PrReviewer reviewerFromCache(Map<String, dynamic> m) {
    final state = _enumByName(
      PrReviewSubmissionState.values,
      m['state'],
      PrReviewSubmissionState.pending,
    );
    final isCodeOwner = _bool(m['is_code_owner']);
    if (_str(m['kind']) == 'team') {
      return PrTeamReviewer(
        name: _str(m['name']) ?? '',
        slug: _str(m['slug']) ?? '',
        avatarUrl: _str(m['avatar_url']) ?? '',
        reviewedBy: userFromCache(m['reviewed_by']),
        isCodeOwner: isCodeOwner,
        state: state,
      );
    }
    return PrUserReviewer(
      user: userFromCache(m['user']) ?? const PrUser(login: '', avatarUrl: ''),
      isCodeOwner: isCodeOwner,
      state: state,
    );
  }
}
