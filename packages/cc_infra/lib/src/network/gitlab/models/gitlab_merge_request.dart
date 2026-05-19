import 'package:cc_infra/src/network/gitlab/models/gitlab_pipeline.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_user.dart';
import 'package:cc_infra/src/network/models/date_parser.dart';

/// The three SHAs GitLab anchors a diff position against.
///
/// Posting an inline comment is impossible without all three: `base_sha` and
/// `head_sha` bound the diff, `start_sha` is the merge-base the diff was
/// computed from. They travel together and are never derived client-side.
class GitLabDiffRefs {
  /// Creates a [GitLabDiffRefs].
  const GitLabDiffRefs({
    required this.baseSha,
    required this.headSha,
    required this.startSha,
  });

  /// Reads a [GitLabDiffRefs] off a decoded JSON object.
  factory GitLabDiffRefs.fromJson(Map<String, dynamic> json) => GitLabDiffRefs(
    baseSha: json['base_sha'] as String? ?? '',
    headSha: json['head_sha'] as String? ?? '',
    startSha: json['start_sha'] as String? ?? '',
  );

  /// Reads a [GitLabDiffRefs] from [raw] when it is a JSON object, else null.
  static GitLabDiffRefs? maybeFromJson(Object? raw) =>
      raw is Map<String, dynamic> ? GitLabDiffRefs.fromJson(raw) : null;

  /// Tip of the target branch the diff is computed against.
  final String baseSha;

  /// Tip of the source branch — the commit the diff shows.
  final String headSha;

  /// Merge-base of source and target at the time the diff was computed.
  final String startSha;

  /// Whether all three SHAs are present, i.e. whether a position can be built.
  bool get isComplete =>
      baseSha.isNotEmpty && headSha.isNotEmpty && startSha.isNotEmpty;
}

/// A GitLab merge request, as returned by `GET /projects/:id/merge_requests`
/// and `.../merge_requests/:iid`.
///
/// Two ids matter and they are not interchangeable: [iid] is the per-project
/// number every URL and every user speaks (`!42`), while [id] is the
/// instance-wide identifier the domain carries as `externalId`.
class GitLabMergeRequest {
  /// Creates a [GitLabMergeRequest].
  const GitLabMergeRequest({
    required this.id,
    required this.iid,
    required this.title,
    required this.state,
    this.projectId = 0,
    this.description = '',
    this.draft = false,
    this.webUrl = '',
    this.author,
    this.assignees = const <GitLabUser>[],
    this.reviewers = const <GitLabUser>[],
    this.createdAt,
    this.updatedAt,
    this.mergedAt,
    this.closedAt,
    this.sourceBranch = '',
    this.targetBranch = '',
    this.sha = '',
    this.mergeCommitSha = '',
    this.squashCommitSha = '',
    this.diffRefs,
    this.mergeStatus = '',
    this.detailedMergeStatus = '',
    this.mergeError = '',
    this.hasConflicts = false,
    this.userNotesCount = 0,
    this.changesCount = '',
    this.squash = false,
    this.rebaseInProgress = false,
    this.headPipeline,
  });

  /// Reads a [GitLabMergeRequest] off a decoded JSON object.
  factory GitLabMergeRequest.fromJson(Map<String, dynamic> json) {
    // Older payloads carry a single `assignee`; newer ones an `assignees`
    // array. Prefer the array and fall back so both shapes read the same.
    final assignees = GitLabUser.listFromJson(json['assignees']);
    final singleAssignee = GitLabUser.maybeFromJson(json['assignee']);
    return GitLabMergeRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      iid: (json['iid'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      state: json['state'] as String? ?? '',
      projectId: (json['project_id'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      // `work_in_progress` is the pre-14.0 spelling of `draft`.
      draft:
          json['draft'] as bool? ?? json['work_in_progress'] as bool? ?? false,
      webUrl: json['web_url'] as String? ?? '',
      author: GitLabUser.maybeFromJson(json['author']),
      assignees: assignees.isNotEmpty
          ? assignees
          : (singleAssignee == null
                ? const <GitLabUser>[]
                : <GitLabUser>[singleAssignee]),
      reviewers: GitLabUser.listFromJson(json['reviewers']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      mergedAt: parseDate(json['merged_at']),
      closedAt: parseDate(json['closed_at']),
      sourceBranch: json['source_branch'] as String? ?? '',
      targetBranch: json['target_branch'] as String? ?? '',
      sha: json['sha'] as String? ?? '',
      mergeCommitSha: json['merge_commit_sha'] as String? ?? '',
      squashCommitSha: json['squash_commit_sha'] as String? ?? '',
      diffRefs: GitLabDiffRefs.maybeFromJson(json['diff_refs']),
      mergeStatus: json['merge_status'] as String? ?? '',
      detailedMergeStatus: json['detailed_merge_status'] as String? ?? '',
      mergeError: json['merge_error'] as String? ?? '',
      hasConflicts: json['has_conflicts'] as bool? ?? false,
      userNotesCount: (json['user_notes_count'] as num?)?.toInt() ?? 0,
      changesCount: json['changes_count']?.toString() ?? '',
      squash: json['squash'] as bool? ?? false,
      rebaseInProgress: json['rebase_in_progress'] as bool? ?? false,
      // The single-MR payload carries the full `head_pipeline`; the list
      // payload carries a lighter `pipeline` with the same status field. Read
      // either so a listed MR still reports its CI state.
      headPipeline:
          GitLabPipeline.maybeFromJson(json['head_pipeline']) ??
          GitLabPipeline.maybeFromJson(json['pipeline']),
    );
  }

  /// Instance-wide merge-request id. Opaque to callers; carried as the
  /// domain's `externalId`.
  final int id;

  /// Per-project merge-request number (`!42`). This is the domain's `number`
  /// and the value every merge-request URL is built from.
  final int iid;

  /// Title. Carries a `Draft: ` prefix while the MR is a draft — on GitLab the
  /// prefix *is* the draft state, so it is never edited away casually.
  final String title;

  /// State (`opened`, `closed`, `merged`, `locked`).
  final String state;

  /// Owning project id.
  final int projectId;

  /// Description body (raw markdown).
  final String description;

  /// Whether the MR is a draft.
  final bool draft;

  /// Link to the MR page.
  final String webUrl;

  /// Author, when supplied.
  final GitLabUser? author;

  /// Assigned users.
  final List<GitLabUser> assignees;

  /// Assigned reviewers. Carries no per-reviewer verdict — that lives on the
  /// separate `/reviewers` endpoint.
  final List<GitLabUser> reviewers;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last-update timestamp.
  final DateTime? updatedAt;

  /// Merge timestamp; non-null means merged.
  final DateTime? mergedAt;

  /// Close timestamp.
  final DateTime? closedAt;

  /// Source branch name.
  final String sourceBranch;

  /// Target branch name.
  final String targetBranch;

  /// Head commit SHA of the source branch.
  final String sha;

  /// The merge commit produced by an accepted MR. Empty until merged, and for
  /// a fast-forward or squash merge.
  final String mergeCommitSha;

  /// The squash commit produced by an accepted squash merge.
  final String squashCommitSha;

  /// The three SHAs a diff position is anchored against.
  final GitLabDiffRefs? diffRefs;

  /// Legacy mergeability summary (`can_be_merged`, `cannot_be_merged`,
  /// `unchecked`, `checking`, `cannot_be_merged_recheck`).
  final String mergeStatus;

  /// Fine-grained mergeability (GitLab 15.6+): `mergeable`, `not_approved`,
  /// `draft_status`, `ci_must_pass`, `conflict`, `discussions_not_resolved`,
  /// `requested_changes`, … Preferred over [mergeStatus] when present.
  final String detailedMergeStatus;

  /// Why the last merge attempt failed. Empty when there was none.
  final String mergeError;

  /// Whether the MR currently conflicts with its target branch.
  final bool hasConflicts;

  /// Number of non-system notes, i.e. the conversation comment count.
  final int userNotesCount;

  /// Changed-file count as GitLab reports it — a *string*, and one that may
  /// carry a `+` suffix (`"1000+"`) when the diff overflowed.
  final String changesCount;

  /// Whether the MR is set to squash on merge.
  final bool squash;

  /// Whether a rebase requested through `PUT .../rebase` is still running.
  /// Only populated when the MR was fetched with `include_rebase_in_progress`.
  final bool rebaseInProgress;

  /// The pipeline running against the head commit, when there is one.
  final GitLabPipeline? headPipeline;
}
