import 'package:cc_domain/cc_domain.dart';
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
import 'package:cc_domain/features/pr_review/domain/providers/vcs_provider.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [PrReviewRepository] backed by the RPC client — the thin-client data path.
///
/// The PR-review surface is per-`(owner, repo)`, unlike the workspace-scoped
/// CRUD verticals: the host binds the workspace per session, but the GitHub
/// coordinates (`owner`/`repo`) travel in every op/watch's args because a
/// workspace reviews PRs across several repos. Implements the domain interface
/// over the host's `pr_review.*` ops + `pr_review.watch*` subscriptions, mapping
/// the PR wire DTOs back to domain entities. The host owns the SWR disk cache,
/// GitHub auth, and draft persistence; this client never touches a database and
/// never holds a token — it resolves the repository from the bound workspace's
/// linked repo server-side, so a foreign `(owner, repo)` is rejected there.
class RpcPrReviewRepository implements PrReviewRepository {
  /// Creates an [RpcPrReviewRepository] over the RPC client for `(owner, repo)`.
  ///
  /// [workspaceId] is informational on this side: the host binds the
  /// authoritative workspace per session and resolves the repository against
  /// the workspace's linked repos.
  RpcPrReviewRepository(
    this._client, {
    required this.workspaceId,
    required String owner,
    required String repo,
  }) : _owner = owner,
       _repo = repo;

  final RemoteRpcClient _client;

  /// The workspace this repository was resolved for (host-authoritative).
  final String workspaceId;
  final String _owner;
  final String _repo;

  Map<String, dynamic> _coords([Map<String, dynamic> extra = const {}]) => {
    'owner': _owner,
    'repo': _repo,
    ...extra,
  };

  // ---- DTO → entity mapping ----

  static PrUser? _userFromDto(PrUserDto? d) =>
      d == null ? null : PrUser(login: d.login, avatarUrl: d.avatarUrl);

  static ReactionGroup _reactionFromDto(ReactionGroupDto d) => ReactionGroup(
    content: d.content,
    emoji: ReactionGroup.emojiForContent(d.content),
    count: d.count,
    userReacted: d.userReacted,
    usernames: d.usernames,
  );

  static List<ReactionGroup> _reactionsFromDto(List<ReactionGroupDto> dtos) =>
      dtos.map(_reactionFromDto).toList();

  static PullRequest _pullRequestFromDto(PullRequestDto d) => PullRequest(
    id: d.id,
    number: d.number,
    title: d.title,
    body: d.body,
    state: PrStateExtension.fromString(d.state),
    isDraft: d.isDraft,
    author: _userFromDto(d.author),
    createdAt: d.createdAt == null ? null : DateTime.tryParse(d.createdAt!),
    updatedAt: d.updatedAt == null ? null : DateTime.tryParse(d.updatedAt!),
    repoFullName: d.repoFullName,
    htmlUrl: d.htmlUrl,
    nodeId: d.nodeId,
    headSha: d.headSha,
    baseRef: d.baseRef,
    baseSha: d.baseSha,
    headRef: d.headRef,
    requestedReviewers: d.requestedReviewers
        .map((u) => PrUser(login: u.login, avatarUrl: u.avatarUrl))
        .toList(),
    assignees: d.assignees
        .map((u) => PrUser(login: u.login, avatarUrl: u.avatarUrl))
        .toList(),
    mergedAt: d.mergedAt == null ? null : DateTime.tryParse(d.mergedAt!),
    reviewedByMe: d.reviewedByMe,
    reactions: _reactionsFromDto(d.reactions),
    bodyHtml: d.bodyHtml,
    changedFiles: d.changedFiles,
    commitsCount: d.commitsCount,
    additions: d.additions,
    deletions: d.deletions,
    commentsCount: d.commentsCount,
    checksStatus:
        PrChecksStatus.values.asNameMap()[d.checksStatus] ??
        PrChecksStatus.none,
    mergeableState:
        PrMergeableState.values.asNameMap()[d.mergeableState] ??
        PrMergeableState.unknown,
  );

  static PrFile _fileFromDto(PrFileDto d) => PrFile(
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

  static PrCommit _commitFromDto(PrCommitDto d) => PrCommit(
    sha: d.sha,
    message: d.message,
    author: _userFromDto(d.author),
    date: d.date == null ? null : DateTime.tryParse(d.date!),
  );

  static PrReviewSubmissionState _reviewStateFromName(String name) =>
      PrReviewSubmissionState.values.asNameMap()[name] ??
      PrReviewSubmissionState.commented;

  static PrReviewSubmission _reviewFromDto(PrReviewSubmissionDto d) =>
      PrReviewSubmission(
        state: _reviewStateFromName(d.state),
        author: _userFromDto(d.author),
        body: d.body,
      );

  static PrCodeReviewComment _reviewCommentFromDto(PrCodeReviewCommentDto d) =>
      PrCodeReviewComment(
        id: d.id,
        body: d.body,
        user: _userFromDto(d.user),
        path: d.path,
        position: d.position,
        createdAt: d.createdAt == null ? null : DateTime.tryParse(d.createdAt!),
        side: d.side,
        inReplyToId: d.inReplyToId,
        startLine: d.startLine,
        diffHunk: d.diffHunk,
        line: d.line,
        originalLine: d.originalLine,
        reactions: _reactionsFromDto(d.reactions),
      );

  static IssueComment _issueCommentFromDto(IssueCommentDto d) => IssueComment(
    id: d.id,
    body: d.body,
    user: _userFromDto(d.user),
    createdAt: d.createdAt == null ? null : DateTime.tryParse(d.createdAt!),
    reactions: _reactionsFromDto(d.reactions),
  );

  static CheckRun _checkRunFromDto(CheckRunDto d) => CheckRun(
    name: d.name,
    status: CheckRunStatusExtension.fromString(d.status),
    conclusion: d.conclusion == null
        ? null
        : CheckRunConclusionExtension.fromString(d.conclusion!),
    htmlUrl: d.htmlUrl,
    completedAt: d.completedAt == null
        ? null
        : DateTime.tryParse(d.completedAt!),
    output: d.output,
    workflowName: d.workflowName,
    checkSuiteId: d.checkSuiteId,
  );

  static PrReviewer _reviewerFromDto(PrReviewerDto d) {
    final state = _reviewStateFromName(d.state);
    if (d.kind == 'team') {
      return PrTeamReviewer(
        name: d.name,
        slug: d.slug,
        isCodeOwner: d.isCodeOwner,
        state: state,
        reviewedBy: _userFromDto(d.reviewedBy),
      );
    }
    return PrUserReviewer(
      user: _userFromDto(d.user) ?? const PrUser(login: '', avatarUrl: ''),
      isCodeOwner: d.isCodeOwner,
      state: state,
    );
  }

  static PrReviewerCandidate _candidateFromDto(PrReviewerCandidateDto d) =>
      PrReviewerCandidate(
        kind: d.kind == 'team' ? ReviewerKind.team : ReviewerKind.user,
        key: d.key,
        label: d.label,
        avatarUrl: d.avatarUrl,
      );

  // ---- Watches ----

  @override
  Stream<PullRequest?> watchPullRequest(int prNumber) => _client
      .subscribe('pr_review.watchPullRequest', _coords({'pr_number': prNumber}))
      .map((data) {
        final pr = data['pull_request'];
        return pr is Map
            ? _pullRequestFromDto(
                PullRequestDto.fromJson(pr.cast<String, dynamic>()),
              )
            : null;
      });

  @override
  Stream<String> watchDiff(int prNumber) => _client
      .subscribe('pr_review.watchDiff', _coords({'pr_number': prNumber}))
      .map((data) => data['diff'] as String? ?? '');

  @override
  Stream<List<PrFile>> watchFiles(int prNumber) => _client
      .subscribe('pr_review.watchFiles', _coords({'pr_number': prNumber}))
      .map(_filesFromData);

  @override
  Stream<String> watchFileContent(String path, String ref) => _client
      .subscribe('pr_review.watchFileContent', _coords({
        'path': path,
        'ref': ref,
      }))
      .map((data) => data['content'] as String? ?? '');

  @override
  Stream<List<PrCommit>> watchCommits(int prNumber) => _client
      .subscribe('pr_review.watchCommits', _coords({'pr_number': prNumber}))
      .map(
        (data) => ((data['commits'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (c) =>
                  _commitFromDto(PrCommitDto.fromJson(c.cast<String, dynamic>())),
            )
            .toList(),
      );

  @override
  Stream<List<PrFile>> watchCommitFiles(String sha) => _client
      .subscribe('pr_review.watchCommitFiles', _coords({'sha': sha}))
      .map(_filesFromData);

  @override
  Stream<List<PrReviewSubmission>> watchReviews(int prNumber) => _client
      .subscribe('pr_review.watchReviews', _coords({'pr_number': prNumber}))
      .map(
        (data) => ((data['reviews'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (r) => _reviewFromDto(
                PrReviewSubmissionDto.fromJson(r.cast<String, dynamic>()),
              ),
            )
            .toList(),
      );

  @override
  Stream<List<PrCodeReviewComment>> watchReviewComments(int prNumber) => _client
      .subscribe(
        'pr_review.watchReviewComments',
        _coords({'pr_number': prNumber}),
      )
      .map(
        (data) => ((data['comments'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (c) => _reviewCommentFromDto(
                PrCodeReviewCommentDto.fromJson(c.cast<String, dynamic>()),
              ),
            )
            .toList(),
      );

  @override
  Stream<List<IssueComment>> watchIssueComments(int prNumber) => _client
      .subscribe(
        'pr_review.watchIssueComments',
        _coords({'pr_number': prNumber}),
      )
      .map(
        (data) => ((data['comments'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (c) => _issueCommentFromDto(
                IssueCommentDto.fromJson(c.cast<String, dynamic>()),
              ),
            )
            .toList(),
      );

  @override
  Stream<List<CheckRun>> watchCheckRuns(int prNumber) => _client
      .subscribe('pr_review.watchCheckRuns', _coords({'pr_number': prNumber}))
      .map(
        (data) => ((data['check_runs'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (c) =>
                  _checkRunFromDto(CheckRunDto.fromJson(c.cast<String, dynamic>())),
            )
            .toList(),
      );

  @override
  Stream<List<PrReviewer>> watchReviewers(int prNumber) => _client
      .subscribe('pr_review.watchReviewers', _coords({'pr_number': prNumber}))
      .map(
        (data) => ((data['reviewers'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (r) =>
                  _reviewerFromDto(PrReviewerDto.fromJson(r.cast<String, dynamic>())),
            )
            .toList(),
      );

  // ---- Reads ----

  @override
  Future<String?> getDraft(int prNumber) async {
    final data = await _client.call(
      'pr_review.getDraft',
      _coords({'pr_number': prNumber}),
    );
    return data['draft'] as String?;
  }

  @override
  Future<List<PrUser>> listAssignableUsers() async {
    final data = await _client.call('pr_review.listAssignableUsers', _coords());
    return ((data['users'] as List?) ?? const [])
        .whereType<Map>()
        .map((u) => PrUserDto.fromJson(u.cast<String, dynamic>()))
        .map((u) => PrUser(login: u.login, avatarUrl: u.avatarUrl))
        .toList();
  }

  @override
  Future<List<PrReviewerCandidate>> listRequestableReviewers() async {
    final data = await _client.call(
      'pr_review.listRequestableReviewers',
      _coords(),
    );
    return ((data['candidates'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (c) => _candidateFromDto(
            PrReviewerCandidateDto.fromJson(c.cast<String, dynamic>()),
          ),
        )
        .toList();
  }

  // ---- Mutations ----

  @override
  Future<void> invalidatePullRequest(int prNumber) => _client.call(
    'pr_review.invalidatePullRequest',
    _coords({'pr_number': prNumber}),
  );

  @override
  Future<void> invalidateDiff(int prNumber) =>
      _client.call('pr_review.invalidateDiff', _coords({'pr_number': prNumber}));

  @override
  Future<void> markFileAsViewed({
    required int prNumber,
    required String nodeId,
    required String path,
    required bool viewed,
  }) => _client.call('pr_review.markFileAsViewed', _coords({
    'pr_number': prNumber,
    'node_id': nodeId,
    'path': path,
    'viewed': viewed,
  }));

  @override
  Future<Map<String, dynamic>> postReviewComment({
    required int prNumber,
    required String commitSha,
    required String path,
    required int line,
    required String side,
    required String body,
    int? startLine,
    String? startSide,
  }) async {
    final data = await _client.call('pr_review.postReviewComment', _coords({
      'pr_number': prNumber,
      'commit_sha': commitSha,
      'path': path,
      'line': line,
      'side': side,
      'body': body,
      'start_line': ?startLine,
      'start_side': ?startSide,
    }));
    final result = data['result'];
    return result is Map ? result.cast<String, dynamic>() : <String, dynamic>{};
  }

  @override
  Future<void> replyToReviewComment({
    required int prNumber,
    required int parentCommentId,
    required String body,
  }) => _client.call('pr_review.replyToReviewComment', _coords({
    'pr_number': prNumber,
    'parent_comment_id': parentCommentId,
    'body': body,
  }));

  @override
  Future<void> upsertDraft(int prNumber, String text) => _client.call(
    'pr_review.upsertDraft',
    _coords({'pr_number': prNumber, 'text': text}),
  );

  @override
  Future<void> clearDraft(int prNumber) =>
      _client.call('pr_review.clearDraft', _coords({'pr_number': prNumber}));

  @override
  Future<String> uploadContent(
    String path,
    String base64Content,
    String message,
  ) async {
    final data = await _client.call('pr_review.uploadContent', _coords({
      'path': path,
      'base64_content': base64Content,
      'message': message,
    }));
    return data['url'] as String? ?? '';
  }

  @override
  Future<void> toggleReviewCommentReaction({
    required int commentId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) => _client.call('pr_review.toggleReviewCommentReaction', _coords({
    'comment_id': commentId,
    'pr_number': prNumber,
    'content': content,
    'add': add,
    'current_user_login': ?currentUserLogin,
  }));

  @override
  Future<void> toggleIssueCommentReaction({
    required int commentId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) => _client.call('pr_review.toggleIssueCommentReaction', _coords({
    'comment_id': commentId,
    'pr_number': prNumber,
    'content': content,
    'add': add,
    'current_user_login': ?currentUserLogin,
  }));

  @override
  Future<void> togglePullRequestReaction({
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) => _client.call('pr_review.togglePullRequestReaction', _coords({
    'pr_number': prNumber,
    'content': content,
    'add': add,
    'current_user_login': ?currentUserLogin,
  }));

  @override
  Future<void> submitReview({
    required int prNumber,
    required String event,
    String? body,
  }) => _client.call('pr_review.submitReview', _coords({
    'pr_number': prNumber,
    'event': event,
    'body': ?body,
  }));

  @override
  Future<Map<String, dynamic>> mergePullRequest({
    required int prNumber,
    required String mergeMethod,
    String? commitTitle,
    String? commitMessage,
  }) async {
    final data = await _client.call('pr_review.mergePullRequest', _coords({
      'pr_number': prNumber,
      'merge_method': mergeMethod,
      'commit_title': ?commitTitle,
      'commit_message': ?commitMessage,
    }));
    final result = data['result'];
    return result is Map ? result.cast<String, dynamic>() : <String, dynamic>{};
  }

  @override
  Future<void> closePullRequest({required int prNumber}) => _client.call(
    'pr_review.closePullRequest',
    _coords({'pr_number': prNumber}),
  );

  @override
  Future<void> updatePullRequest({
    required int prNumber,
    String? title,
    String? body,
  }) => _client.call('pr_review.updatePullRequest', _coords({
    'pr_number': prNumber,
    'title': ?title,
    'body': ?body,
  }));

  @override
  Future<void> addAssignees({
    required int prNumber,
    required List<String> logins,
  }) => _client.call('pr_review.addAssignees', _coords({
    'pr_number': prNumber,
    'logins': logins,
  }));

  @override
  Future<void> removeAssignees({
    required int prNumber,
    required List<String> logins,
  }) => _client.call('pr_review.removeAssignees', _coords({
    'pr_number': prNumber,
    'logins': logins,
  }));

  @override
  Future<void> requestReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
  }) => _client.call('pr_review.requestReviewers', _coords({
    'pr_number': prNumber,
    'user_logins': userLogins,
    'team_slugs': teamSlugs,
  }));

  @override
  Future<void> removeRequestedReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
  }) => _client.call('pr_review.removeRequestedReviewers', _coords({
    'pr_number': prNumber,
    'user_logins': userLogins,
    'team_slugs': teamSlugs,
  }));

  // ---- Reference previews ----
  // Not part of [PrReviewRepository] — the `#`-reference chip providers call
  // these directly over the same client.

  /// Fetches the lightweight PR preview for [number] in this repo, or null.
  Future<PrPreviewDto?> prPreview(int number) async {
    final data = await _client.call(
      'pr_review.prPreview',
      _coords({'number': number}),
    );
    final preview = data['preview'];
    return preview is Map
        ? PrPreviewDto.fromJson(preview.cast<String, dynamic>())
        : null;
  }

  /// Fetches the lightweight commit preview for [sha] in this repo, or null.
  Future<CommitPreviewDto?> commitPreview(String sha) async {
    final data = await _client.call(
      'pr_review.commitPreview',
      _coords({'sha': sha}),
    );
    final preview = data['preview'];
    return preview is Map
        ? CommitPreviewDto.fromJson(preview.cast<String, dynamic>())
        : null;
  }

  List<PrFile> _filesFromData(Map<String, dynamic> data) =>
      ((data['files'] as List?) ?? const [])
          .whereType<Map>()
          .map((f) => _fileFromDto(PrFileDto.fromJson(f.cast<String, dynamic>())))
          .toList();
}

/// A [VcsProviderFactory] that resolves PR-review repositories over the RPC
/// client — the thin-client composition of the GitHub VCS host.
///
/// `create(ctx)` returns an [RpcPrReviewRepository] for `ctx.repo`'s GitHub
/// coordinates; the host resolves the cache-backed repository against the bound
/// workspace's linked repos and owns GitHub auth. Always reports
/// `VcsHost.github` — the only host Control Center serves over RPC today.
class RpcVcsProviderFactory implements VcsProviderFactory {
  /// Creates an [RpcVcsProviderFactory] over the RPC client.
  RpcVcsProviderFactory(this._client);

  final RemoteRpcClient _client;

  @override
  VcsHost get host => VcsHost.github;

  @override
  PrReviewRepository create(VcsProviderContext ctx) => RpcPrReviewRepository(
    _client,
    workspaceId: ctx.workspaceId,
    owner: ctx.repo.githubOwner,
    repo: ctx.repo.githubRepoName,
  );
}
