import 'dart:convert';

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
import 'package:cc_infra/src/network/gitlab/models/gitlab_tree_entry.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_user.dart';
import 'package:dio/dio.dart';

/// The largest page size GitLab's REST v4 list endpoints accept.
const int kGitLabMaxPerPage = 100;

/// How many pages [GitLabApiClient] will follow before giving up.
///
/// At [kGitLabMaxPerPage] that is 1000 items — past the point where a PR
/// review surface stays useful, and a hard stop against a pathological repo
/// pinning the server on one request. Callers that hit the ceiling get what
/// was fetched, exactly like the GitHub adapter's file-page ceiling.
const int kGitLabMaxPages = 10;

/// Thin, transport-only client for GitLab's REST v4 API.
///
/// Two rules hold this class together:
///
/// 1. **Every path is relative.** The instance base URL (`https://gitlab.com/
///    api/v4`, or a self-hosted equivalent) lives on the injected [Dio], never
///    in a path string here — that is what lets the same adapter serve
///    gitlab.com and a private instance. Authentication is likewise the
///    injected client's business: no header is built here.
/// 2. **It returns wire models and nothing else.** No domain type crosses this
///    boundary and no `DioException` is caught to be reshaped — errors travel
///    up untouched so the layer above maps them once. The only exceptions are
///    the handful of documented "absent means empty" reads (a 404 on a
///    Premium-only or version-gated endpoint), which are a fact about the
///    instance rather than a failure.
class GitLabApiClient {
  /// Creates a [GitLabApiClient] over [dio], which must already carry the
  /// instance base URL and the auth header.
  GitLabApiClient(Dio dio) : _dio = dio;

  final Dio _dio;

  /// Percent-encodes a `namespace/project` path into the single path segment
  /// GitLab addresses projects by.
  ///
  /// GitLab accepts either the numeric project id or the URL-encoded path, and
  /// this adapter only ever knows the path. Nesting is preserved by encoding
  /// every separator, so `group/subgroup/project` becomes
  /// `group%2Fsubgroup%2Fproject` and addresses the right project rather than
  /// three bogus path segments.
  ///
  /// Throws an [ArgumentError] when [pathWithNamespace] is blank — a request
  /// built against an empty project id would silently hit a collection
  /// endpoint.
  static String encodeProjectPath(String pathWithNamespace) {
    final trimmed = pathWithNamespace.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        pathWithNamespace,
        'pathWithNamespace',
        'must be a non-empty namespace/project path',
      );
    }
    return Uri.encodeComponent(trimmed);
  }

  /// Percent-encodes a repository file path into one path segment, for the
  /// `repository/files/:file_path` family.
  static String encodeFilePath(String filePath) =>
      Uri.encodeComponent(filePath.replaceAll(RegExp(r'^/+'), ''));

  // ── Project ──────────────────────────────────────────────────────────────

  /// Fetches project [projectId], or null when it does not exist.
  Future<GitLabProject?> getProject(
    String projectId, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<dynamic>(
      '/projects/$projectId',
      cancelToken: cancelToken,
    );
    final data = _asMap(response.data);
    return data == null ? null : GitLabProject.fromJson(data);
  }

  /// Lists everyone with access to [projectId], inherited memberships
  /// included. Paginated.
  Future<List<GitLabMember>> listProjectMembers(
    String projectId, {
    CancelToken? cancelToken,
  }) => _getPaged(
    '/projects/$projectId/members/all',
    GitLabMember.fromJson,
    cancelToken: cancelToken,
  );

  /// Lists everyone in group [groupPath] (URL-encoded full path), inherited
  /// memberships included. Paginated.
  ///
  /// Used to expand a "team reviewer" into the individual reviewers GitLab
  /// actually accepts on a merge request.
  Future<List<GitLabMember>> listGroupMembers(
    String groupPath, {
    CancelToken? cancelToken,
  }) => _getPaged(
    '/groups/${Uri.encodeComponent(groupPath)}/members/all',
    GitLabMember.fromJson,
    cancelToken: cancelToken,
  );

  // ── Users ────────────────────────────────────────────────────────────────

  /// The user the token belongs to, or null when the token is not accepted.
  Future<GitLabUser?> getCurrentUser({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/user',
        cancelToken: cancelToken,
      );
      final data = _asMap(response.data);
      return data == null ? null : GitLabUser.fromJson(data);
    } on DioException catch (e) {
      // An unauthenticated client is a state the port models as `null`, not an
      // error: `getAuthenticatedUser` is documented to answer null exactly
      // here. Everything else propagates.
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        return null;
      }
      rethrow;
    }
  }

  /// Resolves a `@handle` to a user, or null when no account matches.
  Future<GitLabUser?> findUserByUsername(
    String username, {
    CancelToken? cancelToken,
  }) async {
    final handle = username.trim().replaceAll(RegExp(r'^@'), '');
    if (handle.isEmpty) {
      return null;
    }
    final response = await _dio.get<dynamic>(
      '/users',
      queryParameters: <String, dynamic>{'username': handle},
      cancelToken: cancelToken,
    );
    final users = _decodeList(response.data, GitLabUser.fromJson);
    for (final user in users) {
      if (user.username.toLowerCase() == handle.toLowerCase()) {
        return user;
      }
    }
    return users.isEmpty ? null : users.first;
  }

  // ── Merge requests ───────────────────────────────────────────────────────

  /// Fetches merge request [iid] of [projectId], or null when it does not
  /// exist.
  ///
  /// Set [includeRebaseInProgress] while polling a rebase — GitLab only
  /// populates `rebase_in_progress` when asked to.
  Future<GitLabMergeRequest?> getMergeRequest(
    String projectId,
    int iid, {
    bool includeRebaseInProgress = false,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/projects/$projectId/merge_requests/$iid',
        queryParameters: <String, dynamic>{
          if (includeRebaseInProgress) 'include_rebase_in_progress': true,
        },
        cancelToken: cancelToken,
      );
      final data = _asMap(response.data);
      return data == null ? null : GitLabMergeRequest.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// One page of merge requests for [projectId].
  ///
  /// Returns `hasMore` alongside the page so a caller can offer "load more"
  /// without a second probe: GitLab reports the next page number in the
  /// `X-Next-Page` header, and a full page is treated as "probably more" for
  /// the keyset-paginated endpoints that omit it.
  ///
  /// [state] is GitLab's spelling (`opened`, `closed`, `merged`, `all`).
  Future<({List<GitLabMergeRequest> items, bool hasMore})> listMergeRequests(
    String projectId, {
    required String state,
    String? authorUsername,
    int perPage = kGitLabMaxPerPage,
    int page = 1,
    String orderBy = 'updated_at',
    String sort = 'desc',
    CancelToken? cancelToken,
  }) async {
    final size = perPage.clamp(1, kGitLabMaxPerPage);
    final response = await _dio.get<dynamic>(
      '/projects/$projectId/merge_requests',
      queryParameters: <String, dynamic>{
        'state': state,
        'order_by': orderBy,
        'sort': sort,
        'per_page': size,
        'page': page,
        if (authorUsername != null && authorUsername.isNotEmpty)
          'author_username': authorUsername,
      },
      cancelToken: cancelToken,
    );
    final items = _decodeList(response.data, GitLabMergeRequest.fromJson);
    final next = response.headers.value('x-next-page');
    final hasMore = (next != null && next.isNotEmpty) || items.length >= size;
    return (items: items, hasMore: hasMore);
  }

  /// The per-file diffs of merge request [iid].
  ///
  /// Prefers the paginated `/diffs` endpoint (GitLab 15.7+) and falls back to
  /// the older single-shot `/changes` payload when the instance does not serve
  /// it. [limit] stops paging once that many files have been collected.
  Future<List<GitLabDiff>> listMergeRequestDiffs(
    String projectId,
    int iid, {
    int? limit,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _getPaged(
        '/projects/$projectId/merge_requests/$iid/diffs',
        GitLabDiff.fromJson,
        limit: limit,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      // A 404 here is ambiguous — either the endpoint predates the instance's
      // version or the MR is gone. The `/changes` retry settles it: a missing
      // MR 404s there too and that error is the one that propagates.
      if (e.response?.statusCode != 404) {
        rethrow;
      }
    }
    final response = await _dio.get<dynamic>(
      '/projects/$projectId/merge_requests/$iid/changes',
      cancelToken: cancelToken,
    );
    final data = _asMap(response.data);
    final changes = _decodeList(data?['changes'], GitLabDiff.fromJson);
    if (limit != null && changes.length > limit) {
      return changes.sublist(0, limit);
    }
    return changes;
  }

  /// The commits of merge request [iid], newest first (GitLab's order).
  Future<List<GitLabCommit>> listMergeRequestCommits(
    String projectId,
    int iid, {
    CancelToken? cancelToken,
  }) => _getPaged(
    '/projects/$projectId/merge_requests/$iid/commits',
    GitLabCommit.fromJson,
    cancelToken: cancelToken,
  );

  /// The pipelines that ran for merge request [iid], newest first.
  Future<List<GitLabPipeline>> listMergeRequestPipelines(
    String projectId,
    int iid, {
    CancelToken? cancelToken,
  }) => _getPaged(
    '/projects/$projectId/merge_requests/$iid/pipelines',
    GitLabPipeline.fromJson,
    cancelToken: cancelToken,
  );

  /// Creates a merge request and returns it.
  ///
  /// [title] must already carry the `Draft: ` prefix when a draft is wanted —
  /// on GitLab the prefix *is* the draft flag and there is no separate field.
  Future<GitLabMergeRequest> createMergeRequest(
    String projectId, {
    required String title,
    required String sourceBranch,
    required String targetBranch,
    String? description,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<dynamic>(
      '/projects/$projectId/merge_requests',
      data: <String, dynamic>{
        'title': title,
        'source_branch': sourceBranch,
        'target_branch': targetBranch,
        'description': ?description,
      },
      cancelToken: cancelToken,
    );
    final data = _asMap(response.data);
    if (data == null) {
      throw const FormatException(
        'Unexpected payload from merge-request creation',
      );
    }
    return GitLabMergeRequest.fromJson(data);
  }

  /// Updates merge request [iid]. Only non-null fields are sent.
  ///
  /// [stateEvent] is GitLab's lifecycle verb (`close` / `reopen`).
  Future<GitLabMergeRequest?> updateMergeRequest(
    String projectId,
    int iid, {
    String? title,
    String? description,
    String? stateEvent,
    List<int>? assigneeIds,
    List<int>? reviewerIds,
    CancelToken? cancelToken,
  }) async {
    // An empty list is meaningful for the `*_ids` fields — it clears them — so
    // they are sent whenever non-null, never merely when non-empty.
    final payload = <String, dynamic>{
      'title': ?title,
      'description': ?description,
      'state_event': ?stateEvent,
      'assignee_ids': ?assigneeIds,
      'reviewer_ids': ?reviewerIds,
    };
    if (payload.isEmpty) {
      return null;
    }
    final response = await _dio.put<dynamic>(
      '/projects/$projectId/merge_requests/$iid',
      data: payload,
      cancelToken: cancelToken,
    );
    final data = _asMap(response.data);
    return data == null ? null : GitLabMergeRequest.fromJson(data);
  }

  /// Accepts (merges) merge request [iid].
  ///
  /// `merge_when_pipeline_succeeds` is deliberately never set: the port's
  /// contract is "merge now, tell me what happened", and deferring the merge
  /// would report a success that has not occurred.
  Future<GitLabMergeRequest?> acceptMergeRequest(
    String projectId,
    int iid, {
    required bool squash,
    String? mergeCommitMessage,
    String? squashCommitMessage,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.put<dynamic>(
      '/projects/$projectId/merge_requests/$iid/merge',
      data: <String, dynamic>{
        'squash': squash,
        if (!squash &&
            mergeCommitMessage != null &&
            mergeCommitMessage.isNotEmpty)
          'merge_commit_message': mergeCommitMessage,
        if (squash &&
            squashCommitMessage != null &&
            squashCommitMessage.isNotEmpty)
          'squash_commit_message': squashCommitMessage,
      },
      cancelToken: cancelToken,
    );
    final data = _asMap(response.data);
    return data == null ? null : GitLabMergeRequest.fromJson(data);
  }

  /// Asks GitLab to rebase merge request [iid] onto its target branch.
  ///
  /// Returns immediately: the rebase runs in the background and the caller
  /// polls [getMergeRequest] with `includeRebaseInProgress` to learn when it
  /// settled.
  Future<void> rebaseMergeRequest(
    String projectId,
    int iid, {
    bool skipCi = false,
    CancelToken? cancelToken,
  }) async {
    await _dio.put<dynamic>(
      '/projects/$projectId/merge_requests/$iid/rebase',
      queryParameters: <String, dynamic>{if (skipCi) 'skip_ci': true},
      cancelToken: cancelToken,
    );
  }

  // ── Approvals and reviewers ──────────────────────────────────────────────

  /// The approval summary of merge request [iid].
  Future<GitLabApprovals> getMergeRequestApprovals(
    String projectId,
    int iid, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<dynamic>(
      '/projects/$projectId/merge_requests/$iid/approvals',
      cancelToken: cancelToken,
    );
    final data = _asMap(response.data);
    return data == null
        ? GitLabApprovals.empty
        : GitLabApprovals.fromJson(data);
  }

  /// The approval *rules* of merge request [iid] — the source of code-owner
  /// and group reviewers.
  ///
  /// Approval rules are a paid-tier feature. On an instance that does not
  /// serve them the endpoint answers 404/403, which is a fact about the
  /// instance rather than a failure, so it degrades to
  /// [GitLabApprovalState.empty]: no rules, no code owners, no group
  /// reviewers. Every other status propagates.
  Future<GitLabApprovalState> getMergeRequestApprovalState(
    String projectId,
    int iid, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/projects/$projectId/merge_requests/$iid/approval_state',
        cancelToken: cancelToken,
      );
      final data = _asMap(response.data);
      return data == null
          ? GitLabApprovalState.empty
          : GitLabApprovalState.fromJson(data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 403 || status == 404) {
        return GitLabApprovalState.empty;
      }
      rethrow;
    }
  }

  /// Approves merge request [iid] on behalf of the token's user.
  Future<void> approveMergeRequest(
    String projectId,
    int iid, {
    CancelToken? cancelToken,
  }) async {
    await _dio.post<dynamic>(
      '/projects/$projectId/merge_requests/$iid/approve',
      cancelToken: cancelToken,
    );
  }

  /// Withdraws the token user's approval of merge request [iid].
  ///
  /// A 404 means "there was nothing to withdraw", which is the same end state
  /// as a successful call, so it is not surfaced as an error.
  Future<void> unapproveMergeRequest(
    String projectId,
    int iid, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/projects/$projectId/merge_requests/$iid/unapprove',
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return;
      }
      rethrow;
    }
  }

  /// The assigned reviewers of merge request [iid] together with their
  /// per-reviewer state.
  Future<List<GitLabMergeRequestReviewer>> listMergeRequestReviewers(
    String projectId,
    int iid, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<dynamic>(
      '/projects/$projectId/merge_requests/$iid/reviewers',
      cancelToken: cancelToken,
    );
    return _decodeList(response.data, GitLabMergeRequestReviewer.fromJson);
  }

  // ── Notes and discussions ────────────────────────────────────────────────

  /// Every discussion (comment thread) on merge request [iid]. Paginated.
  Future<List<GitLabDiscussion>> listMergeRequestDiscussions(
    String projectId,
    int iid, {
    CancelToken? cancelToken,
  }) => _getPaged(
    '/projects/$projectId/merge_requests/$iid/discussions',
    GitLabDiscussion.fromJson,
    cancelToken: cancelToken,
  );

  /// Every note on merge request [iid], oldest first. Paginated.
  Future<List<GitLabNote>> listMergeRequestNotes(
    String projectId,
    int iid, {
    CancelToken? cancelToken,
  }) => _getPaged(
    '/projects/$projectId/merge_requests/$iid/notes',
    GitLabNote.fromJson,
    query: const <String, dynamic>{'sort': 'asc', 'order_by': 'created_at'},
    cancelToken: cancelToken,
  );

  /// Posts a top-level note on merge request [iid].
  Future<GitLabNote?> createMergeRequestNote(
    String projectId,
    int iid, {
    required String body,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<dynamic>(
      '/projects/$projectId/merge_requests/$iid/notes',
      data: <String, dynamic>{'body': body},
      cancelToken: cancelToken,
    );
    final data = _asMap(response.data);
    return data == null ? null : GitLabNote.fromJson(data);
  }

  /// Opens a new discussion on merge request [iid].
  ///
  /// Supplying [position] makes it an inline (diff-anchored) thread; omitting
  /// it makes it a plain conversation thread.
  Future<GitLabDiscussion?> createDiscussion(
    String projectId,
    int iid, {
    required String body,
    GitLabNotePosition? position,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<dynamic>(
      '/projects/$projectId/merge_requests/$iid/discussions',
      data: <String, dynamic>{
        'body': body,
        if (position != null) 'position': position.toJson(),
      },
      cancelToken: cancelToken,
    );
    final data = _asMap(response.data);
    return data == null ? null : GitLabDiscussion.fromJson(data);
  }

  /// Appends a note to discussion [discussionId] of merge request [iid].
  Future<GitLabNote?> createDiscussionNote(
    String projectId,
    int iid, {
    required String discussionId,
    required String body,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<dynamic>(
      '/projects/$projectId/merge_requests/$iid/discussions/'
      '${Uri.encodeComponent(discussionId)}/notes',
      data: <String, dynamic>{'body': body},
      cancelToken: cancelToken,
    );
    final data = _asMap(response.data);
    return data == null ? null : GitLabNote.fromJson(data);
  }

  // ── Draft notes (pending review batching) ────────────────────────────────

  /// The ids of the token user's unpublished draft notes on merge request
  /// [iid].
  ///
  /// Only the ids are surfaced: draft notes have their own wire shape (`note`
  /// instead of `body`, no author object) and the adapter needs nothing from
  /// them but "are there any". A 404 means the instance predates the endpoint,
  /// which is indistinguishable in effect from having no drafts.
  Future<List<int>> listDraftNoteIds(
    String projectId,
    int iid, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/projects/$projectId/merge_requests/$iid/draft_notes',
        queryParameters: const <String, dynamic>{'per_page': kGitLabMaxPerPage},
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is! List) {
        return const <int>[];
      }
      return <int>[
        for (final entry in data.whereType<Map<String, dynamic>>())
          if ((entry['id'] as num?)?.toInt() case final int id when id > 0) id,
      ];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const <int>[];
      }
      rethrow;
    }
  }

  /// Publishes every draft note the token user has on merge request [iid], in
  /// one batch — the operation the `pendingReviewBatching` capability names.
  Future<void> publishDraftNotes(
    String projectId,
    int iid, {
    CancelToken? cancelToken,
  }) async {
    await _dio.post<dynamic>(
      '/projects/$projectId/merge_requests/$iid/draft_notes/bulk_publish',
      cancelToken: cancelToken,
    );
  }

  // ── Award emoji (reactions) ──────────────────────────────────────────────

  /// The award emoji on merge request [iid] itself.
  Future<List<GitLabAwardEmoji>> listMergeRequestAwardEmoji(
    String projectId,
    int iid, {
    CancelToken? cancelToken,
  }) => _getPaged(
    '/projects/$projectId/merge_requests/$iid/award_emoji',
    GitLabAwardEmoji.fromJson,
    cancelToken: cancelToken,
  );

  /// The award emoji on note [noteId] of merge request [iid].
  Future<List<GitLabAwardEmoji>> listNoteAwardEmoji(
    String projectId,
    int iid,
    int noteId, {
    CancelToken? cancelToken,
  }) => _getPaged(
    '/projects/$projectId/merge_requests/$iid/notes/$noteId/award_emoji',
    GitLabAwardEmoji.fromJson,
    cancelToken: cancelToken,
  );

  /// Awards [name] (a GitLab emoji shortcode) to merge request [iid].
  Future<GitLabAwardEmoji?> createMergeRequestAwardEmoji(
    String projectId,
    int iid, {
    required String name,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<dynamic>(
      '/projects/$projectId/merge_requests/$iid/award_emoji',
      queryParameters: <String, dynamic>{'name': name},
      cancelToken: cancelToken,
    );
    final data = _asMap(response.data);
    return data == null ? null : GitLabAwardEmoji.fromJson(data);
  }

  /// Awards [name] to note [noteId] of merge request [iid].
  Future<GitLabAwardEmoji?> createNoteAwardEmoji(
    String projectId,
    int iid,
    int noteId, {
    required String name,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<dynamic>(
      '/projects/$projectId/merge_requests/$iid/notes/$noteId/award_emoji',
      queryParameters: <String, dynamic>{'name': name},
      cancelToken: cancelToken,
    );
    final data = _asMap(response.data);
    return data == null ? null : GitLabAwardEmoji.fromJson(data);
  }

  /// Removes award [awardId] from merge request [iid].
  Future<void> deleteMergeRequestAwardEmoji(
    String projectId,
    int iid,
    int awardId, {
    CancelToken? cancelToken,
  }) async {
    await _dio.delete<dynamic>(
      '/projects/$projectId/merge_requests/$iid/award_emoji/$awardId',
      cancelToken: cancelToken,
    );
  }

  /// Removes award [awardId] from note [noteId] of merge request [iid].
  Future<void> deleteNoteAwardEmoji(
    String projectId,
    int iid,
    int noteId,
    int awardId, {
    CancelToken? cancelToken,
  }) async {
    await _dio.delete<dynamic>(
      '/projects/$projectId/merge_requests/$iid/notes/$noteId/'
      'award_emoji/$awardId',
      cancelToken: cancelToken,
    );
  }

  // ── CI ───────────────────────────────────────────────────────────────────

  /// The pipelines that ran against commit [sha], newest first.
  ///
  /// The port asks for checks by SHA rather than by merge request, so this —
  /// not `/merge_requests/:iid/pipelines` — is the endpoint that answers it.
  Future<List<GitLabPipeline>> listPipelinesForSha(
    String projectId,
    String sha, {
    CancelToken? cancelToken,
  }) => _getPaged(
    '/projects/$projectId/pipelines',
    GitLabPipeline.fromJson,
    query: <String, dynamic>{'sha': sha, 'order_by': 'id', 'sort': 'desc'},
    maxPages: 1,
    cancelToken: cancelToken,
  );

  /// Fetches pipeline [pipelineId], or null when it does not exist.
  Future<GitLabPipeline?> getPipeline(
    String projectId,
    int pipelineId, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/projects/$projectId/pipelines/$pipelineId',
        cancelToken: cancelToken,
      );
      final data = _asMap(response.data);
      return data == null ? null : GitLabPipeline.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// The jobs of pipeline [pipelineId], in creation order. Paginated.
  Future<List<GitLabJob>> listPipelineJobs(
    String projectId,
    int pipelineId, {
    CancelToken? cancelToken,
  }) => _getPaged(
    '/projects/$projectId/pipelines/$pipelineId/jobs',
    GitLabJob.fromJson,
    cancelToken: cancelToken,
  );

  /// Fetches job [jobId], or null when it does not exist.
  Future<GitLabJob?> getJob(
    String projectId,
    int jobId, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/projects/$projectId/jobs/$jobId',
        cancelToken: cancelToken,
      );
      final data = _asMap(response.data);
      return data == null ? null : GitLabJob.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// The plain-text trace of job [jobId], keeping only the last [maxBytes].
  ///
  /// Null when GitLab has no trace to serve (the job never ran, or its
  /// artifacts expired), which the domain models as "logs not published yet"
  /// rather than as a failure.
  Future<({String text, bool truncated})?> getJobTrace(
    String projectId,
    int jobId, {
    int maxBytes = 512 * 1024,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/projects/$projectId/jobs/$jobId/trace',
        options: Options(responseType: ResponseType.plain),
        cancelToken: cancelToken,
      );
      final raw = response.data?.toString() ?? '';
      if (raw.isEmpty) {
        return null;
      }
      final bytes = utf8.encode(raw);
      if (bytes.length <= maxBytes) {
        return (text: raw.replaceAll('\r\n', '\n'), truncated: false);
      }
      final tail = utf8.decode(
        bytes.sublist(bytes.length - maxBytes),
        allowMalformed: true,
      );
      return (text: tail.replaceAll('\r\n', '\n'), truncated: true);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// The commit statuses reported against [sha]. Paginated.
  Future<List<GitLabCommitStatus>> listCommitStatuses(
    String projectId,
    String sha, {
    CancelToken? cancelToken,
  }) => _getPaged(
    '/projects/$projectId/repository/commits/${Uri.encodeComponent(sha)}'
    '/statuses',
    GitLabCommitStatus.fromJson,
    cancelToken: cancelToken,
  );

  // ── Repository ───────────────────────────────────────────────────────────

  /// The project's branches. Paginated.
  ///
  /// GitLab orders branches by name and offers no sort-by-activity, so a
  /// caller that wants "newest first" sorts what it gets — which is why this
  /// pages rather than truncating at the first page.
  Future<List<GitLabBranch>> listBranches(
    String projectId, {
    int? limit,
    CancelToken? cancelToken,
  }) => _getPaged(
    '/projects/$projectId/repository/branches',
    GitLabBranch.fromJson,
    limit: limit,
    cancelToken: cancelToken,
  );

  /// Compares [from] with [to], returning the commits and per-file diffs a
  /// merge request between them would carry.
  ///
  /// Null when the refs cannot be compared — a branch that does not exist, or
  /// a comparison GitLab declines. The port distinguishes that from "no
  /// changes", so it must not read as an empty comparison.
  Future<GitLabComparison?> compareRefs(
    String projectId, {
    required String from,
    required String to,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<dynamic>(
      '/projects/$projectId/repository/compare',
      queryParameters: <String, dynamic>{'from': from, 'to': to},
      cancelToken: cancelToken,
    );
    final data = _asMap(response.data);
    return data == null ? null : GitLabComparison.fromJson(data);
  }

  /// Lists the repository tree at [path].
  ///
  /// A missing directory answers 404, which is reported as an empty listing:
  /// "this project ships no merge-request templates" is a fact about the
  /// project, not a failure to read it.
  Future<List<GitLabTreeEntry>> listRepositoryTree(
    String projectId, {
    required String path,
    String? ref,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _getPaged(
        '/projects/$projectId/repository/tree',
        GitLabTreeEntry.fromJson,
        query: <String, dynamic>{'path': path, 'ref': ?ref},
        maxPages: 1,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const <GitLabTreeEntry>[];
      }
      rethrow;
    }
  }

  /// The per-file diffs of commit [sha]. Paginated.
  Future<List<GitLabDiff>> listCommitDiffs(
    String projectId,
    String sha, {
    CancelToken? cancelToken,
  }) => _getPaged(
    '/projects/$projectId/repository/commits/${Uri.encodeComponent(sha)}/diff',
    GitLabDiff.fromJson,
    cancelToken: cancelToken,
  );

  /// The raw bytes of [filePath] at [ref], decoded as text.
  Future<String> getRawFile(
    String projectId,
    String filePath,
    String ref, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<dynamic>(
      '/projects/$projectId/repository/files/${encodeFilePath(filePath)}/raw',
      queryParameters: <String, dynamic>{'ref': ref},
      options: Options(responseType: ResponseType.plain),
      cancelToken: cancelToken,
    );
    return response.data?.toString() ?? '';
  }

  /// Uploads [bytes] to project [projectId] and returns the project-relative
  /// URL GitLab stored it at (`/uploads/<hash>/<name>`), or null when the
  /// response carried none.
  ///
  /// GitLab uploads are not commits: there is no path and no commit message,
  /// the file lands in the project's upload store and is referenced from
  /// markdown.
  Future<String?> uploadFile(
    String projectId, {
    required List<int> bytes,
    required String filename,
    CancelToken? cancelToken,
  }) async {
    final form = FormData.fromMap(<String, dynamic>{
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dio.post<dynamic>(
      '/projects/$projectId/uploads',
      data: form,
      cancelToken: cancelToken,
    );
    final data = _asMap(response.data);
    final url = data?['url'] as String?;
    return (url == null || url.isEmpty) ? null : url;
  }

  // ── Internals ────────────────────────────────────────────────────────────

  /// Follows GitLab's offset pagination for [path], decoding each page with
  /// [fromJson].
  ///
  /// Stops on the first of: a short page, an absent or non-advancing
  /// `X-Next-Page` header, [limit] items collected, or [maxPages] pages read.
  /// The header is checked *and* the short-page test applies, because keyset
  /// pagination omits the header entirely on some endpoints.
  Future<List<T>> _getPaged<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic> query = const <String, dynamic>{},
    int perPage = kGitLabMaxPerPage,
    int maxPages = kGitLabMaxPages,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final items = <T>[];
    var page = 1;
    for (var fetched = 0; fetched < maxPages; fetched++) {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: <String, dynamic>{
          ...query,
          'per_page': perPage,
          'page': page,
        },
        cancelToken: cancelToken,
      );
      final batch = _decodeList(response.data, fromJson);
      items.addAll(batch);
      if (limit != null && items.length >= limit) {
        return items.sublist(0, limit);
      }
      if (batch.length < perPage) {
        break;
      }
      final next = int.tryParse(response.headers.value('x-next-page') ?? '');
      if (next == null || next <= page) {
        break;
      }
      page = next;
    }
    return items;
  }

  static Map<String, dynamic>? _asMap(Object? data) =>
      data is Map<String, dynamic> ? data : null;

  static List<T> _decodeList<T>(
    Object? data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! List) {
      return <T>[];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }
}
