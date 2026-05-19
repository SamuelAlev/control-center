import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
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
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:cc_infra/src/network/models/github_check_run.dart';
import 'package:cc_infra/src/network/models/github_commit.dart';
import 'package:cc_infra/src/network/models/github_issue_comment.dart';
import 'package:cc_infra/src/network/models/github_pull_request.dart';
import 'package:cc_infra/src/network/models/github_pull_request_file.dart';
import 'package:cc_infra/src/network/models/github_reaction.dart';
import 'package:cc_infra/src/network/models/github_review.dart';
import 'package:cc_infra/src/network/models/github_review_comment.dart';
import 'package:cc_infra/src/network/models/github_workflow_run.dart';
import 'package:cc_infra/src/network/pr_review_mapper.dart';
import 'package:cc_infra/src/util/isolate_json.dart';
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/daos/review_dao.dart';
import 'package:dio/dio.dart';

class _Kind {
  static const prDetail = 'prDetail';
  static const prDiff = 'prDiff';
  static const prFiles = 'prFiles';
  static const prFileContent = 'prFileContent';
  static const prCommits = 'prCommits';
  static const prCommitFiles = 'prCommitFiles';
  static const prReviews = 'prReviews';
  static const prReviewComments = 'prReviewComments';
  static const prIssueComments = 'prIssueComments';
  static const prCheckRuns = 'prCheckRuns';

  /// Enriched reviewer rows (users + teams + code-owner flags + on-behalf
  /// merge) resolved from the GraphQL review-state query, keyed by PR number.
  static const prReviewerState = 'prReviewerState';

  /// Monotonic per-PR set of reviewer identities ever seen flagged
  /// `asCodeOwner`. Deliberately NOT in `prScoped`: it accumulates so the
  /// shield survives the pending→reviewed transition (GitHub drops the flag).
  static const prCodeOwnerIds = 'prCodeOwnerIds';

  /// Repo-scoped picker candidate caches (TTL-enveloped), keyed by repo.
  static const assignableUsers = 'assignableUsers';
  static const requestableTeams = 'requestableTeams';

  static const prScoped = <String>[
    prDetail,
    prDiff,
    prFiles,
    prCommits,
    prReviews,
    prReviewComments,
    prIssueComments,
    prCheckRuns,
    prReviewerState,
  ];
}

// GitHub caps the files endpoint at 3 000 entries; above this threshold we
// fall back to the local-git source.
const _githubFilesApiLimit = 3000;

/// Cached pr review repository.
class CachedPrReviewRepository implements PrReviewRepository {
  /// Creates a new `CachedPrReviewRepository`.
  CachedPrReviewRepository({
    required CacheDao cacheDao,
    required ReviewDao draftDao,
    required GitHubApiClient gitHubClient,
    required String workspaceId,
    required String owner,
    required String repo,
    required PrDiffSource apiDiffSource,
    required PrDiffSource localDiffSource,
    String? localCheckoutPath,
    DomainEventBus? eventBus,
  }) : _cache = cacheDao,
       _draft = draftDao,
       _client = gitHubClient,
       _workspaceId = workspaceId,
       _owner = owner,
       _repo = repo,
       _apiDiffSource = apiDiffSource,
       _localDiffSource = localDiffSource,
       _localCheckoutPath = localCheckoutPath,
       _eventBus = eventBus;

  final CacheDao _cache;
  final ReviewDao _draft;
  final GitHubApiClient _client;
  final String _workspaceId;
  final String _owner;
  final String _repo;
  final PrDiffSource _apiDiffSource;
  final PrDiffSource _localDiffSource;
  final String? _localCheckoutPath;
  final DomainEventBus? _eventBus;

  String get _repoFullName => '$_owner/$_repo';

  /// Wraps a token-driven stream so that cancelling the subscription — e.g. a
  /// Riverpod `autoDispose` provider tearing down when the user navigates away
  /// from a PR — immediately cancels the [CancelToken], aborting any in-flight
  /// GitHub request.
  ///
  /// An `async*` `finally` can't achieve this: while the generator is suspended
  /// at an `await`, its `finally` only runs once that await completes — so the
  /// request would finish (defeating the point) before being "cancelled". A
  /// [StreamController]'s `onCancel` fires as soon as the consumer unsubscribes,
  /// so the token is cancelled right away and dio aborts the request.
  Stream<T> _cancellable<T>(Stream<T> Function(CancelToken cancelToken) build) {
    final cancelToken = CancelToken();
    final controller = StreamController<T>();
    StreamSubscription<T>? sub;
    controller
      ..onListen = () {
        sub = build(cancelToken).listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      }
      ..onCancel = () async {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel();
        }
        await sub?.cancel();
      };
    return controller.stream;
  }

  /// Whether [error] is a dio request cancellation — the benign signal that a
  /// subscriber unsubscribed (e.g. an `autoDispose` provider tearing down when
  /// the user navigates away from, or presses back on, a PR), which fires the
  /// [CancelToken] via [_cancellable]'s `onCancel`.
  ///
  /// A cancellation must NEVER propagate as a stream error. The subscription is
  /// already gone, so it would surface as an unhandled error in the server's
  /// root isolate — which is fatal — and the abrupt VM teardown then races the
  /// drift background isolate's sqlite finalizers into a `sqlite3_finalize`
  /// segfault. Every `await` on a [CancelToken]-driven call inside these
  /// generators is guarded with this check and a quiet `return`.
  static bool _isCancellation(Object error) =>
      error is DioException && error.type == DioExceptionType.cancel;

  Stream<T> _swr<T>({
    required String kind,
    required String key,
    required FutureOr<T> Function(String cached) decode,
    required Future<T> Function(CancelToken? cancelToken) fetch,
    required FutureOr<String> Function(T fresh) encode,
    Future<bool> Function(T cached, CancelToken cancelToken)? skipRevalidate,
  }) {
    return _cancellable(
      (cancelToken) => _swrInner(
        cancelToken,
        kind: kind,
        key: key,
        decode: decode,
        fetch: fetch,
        encode: encode,
        skipRevalidate: skipRevalidate,
      ),
    );
  }

  Stream<T> _swrInner<T>(
    CancelToken cancelToken, {
    required String kind,
    required String key,
    required FutureOr<T> Function(String cached) decode,
    required Future<T> Function(CancelToken? cancelToken) fetch,
    required FutureOr<String> Function(T fresh) encode,
    Future<bool> Function(T cached, CancelToken cancelToken)? skipRevalidate,
  }) async* {
    final cached = await _cache.read(_workspaceId, kind, key);
    final hadCache = cached != null;
    T? cachedModel;
    if (hadCache) {
      try {
        final decoded = await decode(cached);
        yield decoded;
        cachedModel = decoded;
      } catch (_) {}
    }

    if (cachedModel != null && skipRevalidate != null) {
      try {
        if (await skipRevalidate(cachedModel, cancelToken)) {
          return;
        }
      } on Object catch (error) {
        // The freshness probe makes its own network call (e.g. the diff path
        // fetches the PR to compare head/base SHAs). If the subscriber went
        // away mid-probe that surfaces as a cancellation — stop quietly rather
        // than let it escape this already-cancelled generator as a fatal
        // unhandled error. A non-cancel probe failure (transient hiccup) just
        // falls through to a full revalidation below.
        if (_isCancellation(error)) {
          return;
        }
      }
    }

    try {
      final fresh = await fetch(cancelToken);
      // Encode once and reuse: the write and the change-detection comparison
      // share it, so a heavy payload is serialized a single time (and, via the
      // isolate helpers, off the UI thread).
      final freshEncoded = await encode(fresh);
      await _cache.put(_workspaceId, kind, key, freshEncoded);
      if (cachedModel == null || freshEncoded != await encode(cachedModel)) {
        yield fresh;
      }
    } on Object catch (error) {
      // A cancellation means the subscriber unsubscribed; never resurface it as
      // a stream error (it would be unhandled and abort the process), even when
      // there is no cache to fall back on. Only a genuine fetch failure with no
      // cached value is worth surfacing.
      if (_isCancellation(error)) {
        return;
      }
      if (!hadCache) {
        rethrow;
      }
    }
  }

  // JSON (de)serialization for the on-disk cache runs through the isolate
  // helpers so a large blob (a PR file list with patches, a long comment
  // thread) is parsed/serialized off the UI thread. Small blobs stay inline —
  // the helpers are threshold-guarded. Pass `large: true` when encoding a
  // collection that can grow big; single-object writes stay on the main isolate
  // where the isolate hand-off would cost more than the encode.
  Future<String> _encodeJson(Object? value, {bool large = false}) =>
      encodeJsonInIsolate(value, large: large);

  Future<List<Map<String, dynamic>>> _decodeJsonList(String raw) =>
      decodeJsonListInIsolate(raw);

  Future<Map<String, dynamic>?> _decodeJsonMap(String raw) =>
      decodeJsonMapInIsolate(raw);

  /// Watches the full pull request detail, served from cache with SWR revalidation.
  @override
  Stream<PullRequest?> watchPullRequest(int prNumber) {
    return _swr<PullRequest?>(
      kind: _Kind.prDetail,
      key: '$prNumber',
      decode: (raw) async {
        final map = await _decodeJsonMap(raw);
        if (map == null) {
          return null;
        }

        final gh = GitHubPullRequest.fromJson(map);
        final pr = pullRequestFromGitHub(gh, repoFullName: _repoFullName);
        final cachedReactions = map['reactions'];
        if (cachedReactions is Map<String, dynamic> &&
            cachedReactions.containsKey('__groups')) {
          return PullRequest(
            id: pr.id,
            number: pr.number,
            title: pr.title,
            body: pr.body,
            state: pr.state,
            isDraft: pr.isDraft,
            author: pr.author,
            createdAt: pr.createdAt,
            updatedAt: pr.updatedAt,
            repoFullName: pr.repoFullName,
            htmlUrl: pr.htmlUrl,
            nodeId: pr.nodeId,
            headSha: pr.headSha,
            baseRef: pr.baseRef,
            baseSha: pr.baseSha,
            headRef: pr.headRef,
            requestedReviewers: pr.requestedReviewers,
            assignees: pr.assignees,
            mergedAt: pr.mergedAt,
            reviewedByMe: pr.reviewedByMe,
            reactions: _reactionGroupsFromCacheJson(cachedReactions),
            bodyHtml: pr.bodyHtml,
            changedFiles: pr.changedFiles,
            commitsCount: pr.commitsCount,
            mergeableState: pr.mergeableState,
          );
        }
        return pr;
      },
      fetch: (token) async {
        final gh = await _client.pr.getPullRequest(
          _owner,
          _repo,
          prNumber,
          cancelToken: token,
        );
        if (gh == null) {
          return null;
        }
        var pr = pullRequestFromGitHub(gh, repoFullName: _repoFullName);
        try {
          final issueReactions = await _client.pr.getIssueReactionSummary(
            _owner,
            _repo,
            prNumber,
            cancelToken: token,
          );
          final login = await _currentLogin(token);
          final groups = _reactionGroupsWithUser(
            reactionGroupsFromSummary(issueReactions),
            issueNumber: prNumber,
            currentUserLogin: login,
          );
          pr = PullRequest(
            id: pr.id,
            number: pr.number,
            title: pr.title,
            body: pr.body,
            state: pr.state,
            isDraft: pr.isDraft,
            author: pr.author,
            createdAt: pr.createdAt,
            updatedAt: pr.updatedAt,
            repoFullName: pr.repoFullName,
            htmlUrl: pr.htmlUrl,
            nodeId: pr.nodeId,
            headSha: pr.headSha,
            baseRef: pr.baseRef,
            baseSha: pr.baseSha,
            headRef: pr.headRef,
            requestedReviewers: pr.requestedReviewers,
            assignees: pr.assignees,
            mergedAt: pr.mergedAt,
            reviewedByMe: pr.reviewedByMe,
            reactions: await groups,
            bodyHtml: pr.bodyHtml,
            changedFiles: pr.changedFiles,
            commitsCount: pr.commitsCount,
            mergeableState: pr.mergeableState,
          );
        } catch (e) {
          CcInfraLog.error('PR Reactions: enrichment failed for #$prNumber: $e', e);
        }
        return pr;
      },
      encode: (fresh) async => fresh == null
          ? 'null'
          : await _encodeJson(_pullRequestToCacheJson(fresh)),
    );
  }

  Future<String?> _currentLogin(CancelToken? token) async {
    try {
      final user = await _client.content.getAuthenticatedUser(
        cancelToken: token,
      );
      return user?.login;
    } catch (_) {
      return null;
    }
  }

  Future<List<ReactionGroup>> _reactionGroupsWithUser(
    List<ReactionGroup> base, {
    int? issueNumber,
    int? reviewCommentId,
    int? issueCommentId,
    String? currentUserLogin,
  }) async {
    if (currentUserLogin == null || base.isEmpty) {
      return base;
    }
    try {
      final List<GitHubReaction> all;
      if (reviewCommentId != null) {
        all = await _client.pr.listReviewCommentReactions(
          _owner,
          _repo,
          commentId: reviewCommentId,
        );
      } else if (issueCommentId != null) {
        all = await _client.pr.listIssueCommentReactions(
          _owner,
          _repo,
          commentId: issueCommentId,
        );
      } else if (issueNumber != null) {
        all = await _client.pr.listIssueReactions(
          _owner,
          _repo,
          issueNumber: issueNumber,
        );
      } else {
        return base;
      }
      final myContents = <String>{};
      final byContent = <String, List<String>>{};
      for (final r in all) {
        final login = r.user?.login;
        if (login != null) {
          (byContent[r.content] ??= []).add(login);
        }
        if (login == currentUserLogin) {
          myContents.add(r.content);
        }
      }
      return [
        for (final g in base)
          g.copyWith(
            userReacted: myContents.contains(g.content),
            usernames: byContent[g.content] ?? const [],
          ),
      ];
    } catch (e) {
      CcInfraLog.error('ReactionGroupsWithUser: failed: $e', e);
      return base;
    }
  }

  Map<String, dynamic> _pullRequestToCacheJson(PullRequest pr) {
    final authorJson = pr.author != null
        ? <String, dynamic>{
            'login': pr.author!.login,
            'avatar_url': pr.author!.avatarUrl,
          }
        : <String, dynamic>{'login': '', 'avatar_url': ''};
    return <String, dynamic>{
      'number': pr.number,
      'title': pr.title,
      'body': pr.body,
      'state': pr.state.name,
      'draft': pr.isDraft,
      'user': authorJson,
      'html_url': pr.htmlUrl,
      'node_id': pr.nodeId,
      'created_at': pr.createdAt?.toIso8601String(),
      'updated_at': pr.updatedAt?.toIso8601String(),
      'merged_at': pr.mergedAt?.toIso8601String(),
      'head': <String, dynamic>{'sha': pr.headSha, 'ref': pr.headRef},
      'base': <String, dynamic>{'ref': pr.baseRef, 'sha': pr.baseSha},
      'requested_reviewers': pr.requestedReviewers
          .map(
            (u) => <String, dynamic>{
              'login': u.login,
              'avatar_url': u.avatarUrl,
            },
          )
          .toList(growable: false),
      'assignees': pr.assignees
          .map(
            (u) => <String, dynamic>{
              'login': u.login,
              'avatar_url': u.avatarUrl,
            },
          )
          .toList(growable: false),
      'reactions': _reactionGroupsToCacheJson(pr.reactions),
      // Cached body_html may contain JWTs that have expired (5 min lifetime).
      // The renderer falls back to the attachment card on image error and
      // SWR refresh kicks off a re-fetch with a fresh body_html.
      if (pr.bodyHtml != null) 'body_html': pr.bodyHtml,
      if (pr.changedFiles > 0) 'changed_files': pr.changedFiles,
      if (pr.commitsCount > 0) 'commits': pr.commitsCount,
    };
  }

  Future<String?> _cachedHeadSha(int prNumber) async {
    final cachedPrJson = await _cache.read(
      _workspaceId,
      _Kind.prDetail,
      '$prNumber',
    );
    if (cachedPrJson == null) {
      return null;
    }

    final map = await _decodeJsonMap(cachedPrJson);
    if (map == null) {
      return null;
    }

    final head = map['head'] as Map<String, dynamic>?;
    return head?['sha'] as String?;
  }

  Future<String?> _cachedBaseSha(int prNumber) async {
    final cachedPrJson = await _cache.read(
      _workspaceId,
      _Kind.prDetail,
      '$prNumber',
    );
    if (cachedPrJson == null) {
      return null;
    }

    final map = await _decodeJsonMap(cachedPrJson);
    if (map == null) {
      return null;
    }

    final base = map['base'] as Map<String, dynamic>?;
    return base?['sha'] as String?;
  }

  /// Reads the changed-file count from the cached PR detail, or 0 if absent.
  /// Used as a routing fallback so a live `getPullRequest` failure can't
  /// misroute a large PR away from the local-git source.
  Future<int> _cachedChangedFiles(int prNumber) async {
    final raw = await _cache.read(_workspaceId, _Kind.prDetail, '$prNumber');
    if (raw == null) {
      return 0;
    }
    final map = await _decodeJsonMap(raw);
    final value = map?['changed_files'];
    return value is num ? value.toInt() : 0;
  }

  /// Watches the unified diff for a PR, revalidating only when head or base SHA changes.
  @override
  Stream<String> watchDiff(int prNumber) {
    return _swr<String>(
      kind: _Kind.prDiff,
      key: '$prNumber',
      decode: (raw) => raw,
      fetch: (token) => _client.pr.getPullRequestDiff(
        _owner,
        _repo,
        prNumber,
        cancelToken: token,
      ),
      encode: (fresh) => fresh,
      skipRevalidate: (_, cancelToken) async {
        final cachedHead = await _cachedHeadSha(prNumber);
        if (cachedHead == null || cachedHead.isEmpty) {
          return false;
        }
        // A cache entry written before base SHA was tracked can't prove the
        // base branch hasn't moved — revalidate so it's rewritten with a base
        // SHA we can trust next time.
        final cachedBase = await _cachedBaseSha(prNumber);
        if (cachedBase == null || cachedBase.isEmpty) {
          return false;
        }

        final currentPr = await _client.pr.getPullRequest(
          _owner,
          _repo,
          prNumber,
          cancelToken: cancelToken,
        );
        // GitHub renders a three-dot diff (merge-base(base, head)…head): the
        // diff changes when EITHER the head advances or the base branch moves.
        // Only skip the refetch when both are unchanged.
        return currentPr?.headSha == cachedHead &&
            currentPr?.baseSha == cachedBase;
      },
    );
  }

  /// Watches the list of changed files for a PR.
  @override
  Stream<List<PrFile>> watchFiles(int prNumber) async* {
    await for (final load in watchFilesLoad(prNumber)) {
      if (load.files.isNotEmpty) {
        yield load.files;
      }
    }
  }

  /// Like [watchFiles] but also carries clone-progress information.
  /// Used by `prFilesLoadProvider` so the UI can render the progress card.
  Stream<PrFilesLoad> watchFilesLoad(int prNumber) {
    return _cancellable(
      (cancelToken) => _watchFilesLoad(prNumber, cancelToken),
    );
  }

  Stream<PrFilesLoad> _watchFilesLoad(
    int prNumber,
    CancelToken cancelToken,
  ) async* {
    // Fetch the live PR first — we need changedFiles to decide the source and
    // to know whether to serve the file cache. One call covers both the SWR
    // check and the changedFiles routing decision.
    GitHubPullRequest? currentGhPr;
    try {
      currentGhPr = await _client.pr.getPullRequest(
        _owner,
        _repo,
        prNumber,
        cancelToken: cancelToken,
      );
    } catch (e) {
      CcInfraLog.error('PR Files: getPullRequest failed while routing #$prNumber: $e',
        e,
      );
    }

    // Determine the changed-file count robustly. A transient failure of the
    // call above must NOT silently fall back to 0 — that would route a large
    // (>3000-file) PR to the API source, which is capped at 3000 files and
    // never clones, leaving the diff incomplete and pr_clones empty. Fall back
    // to the cached PR detail (populated by watchPullRequest) so the routing
    // decision survives a hiccup.
    var changedFiles = currentGhPr?.changedFiles ?? 0;
    if (changedFiles == 0) {
      changedFiles = await _cachedChangedFiles(prNumber);
    }
    final useLocalGit = changedFiles > _githubFilesApiLimit;
    CcInfraLog.info('PR Files: routing #$prNumber: changedFiles=$changedFiles useLocalGit=$useLocalGit',
    );

    // Read the cached file list.
    final cached = await _cache.read(_workspaceId, _Kind.prFiles, '$prNumber');
    List<PrFile>? cachedModel;
    if (cached != null) {
      try {
        cachedModel = (await _decodeJsonList(
          cached,
        )).map(_prFileFromCacheJson).toList(growable: false);
      } catch (_) {}
    }

    if (!useLocalGit) {
      // For API-backed (small) PRs: yield the cached list immediately so the
      // UI renders while we check freshness.
      if (cachedModel != null && cachedModel.isNotEmpty) {
        yield PrFilesLoad(files: cachedModel);
      }

      // SWR fast path: the file list is still current only when BOTH the head
      // and the base SHA are unchanged. GitHub's three-dot diff (and thus the
      // changed-file set) shifts when the base branch moves even if the head
      // is untouched, so head-SHA alone is not enough. A pre-base-sha cache
      // entry (cachedBase null/empty) falls through and re-fetches.
      if (cachedModel != null && cachedModel.isNotEmpty) {
        final cachedSha = await _cachedHeadSha(prNumber);
        final cachedBase = await _cachedBaseSha(prNumber);
        if (cachedSha != null &&
            cachedSha.isNotEmpty &&
            cachedBase != null &&
            cachedBase.isNotEmpty &&
            currentGhPr?.headSha == cachedSha &&
            currentGhPr?.baseSha == cachedBase) {
          return;
        }
      }
    }
    // For large PRs (useLocalGit == true) we intentionally skip the cache
    // yield — the cached list contains at most 3 000 files and is incomplete.
    // The UI will show the clone-progress card instead.

    final req = PrSourceRequest(
      prNumber: prNumber,
      owner: _owner,
      repo: _repo,
      baseRef: currentGhPr?.baseRef ?? 'main',
      headRef: currentGhPr?.headRef ?? '',
      headSha: currentGhPr?.headSha ?? '',
      changedFiles: changedFiles,
      workspaceId: _workspaceId,
      localCheckoutPath: _localCheckoutPath,
    );

    final source = useLocalGit ? _localDiffSource : _apiDiffSource;
    List<PrFile> lastFiles = const [];

    try {
      await for (final load in source.watchFiles(req)) {
        lastFiles = load.files;
        yield load;
      }
    } on Object catch (error) {
      // The subscriber went away mid-clone/-fetch — stop without emitting a
      // spurious error load to a stream nobody is listening to.
      if (_isCancellation(error)) {
        return;
      }
      if (cachedModel == null || cachedModel.isEmpty) {
        yield PrFilesLoad(files: lastFiles, error: error, isComplete: true);
        return;
      }
      return;
    }

    // For the GitHub API source, enrich with viewerViewedState via GraphQL.
    if (!useLocalGit && lastFiles.isNotEmpty) {
      Map<String, String> viewedStates = const {};
      try {
        viewedStates = await _client.graphql.getFileViewedStates(
          owner: _owner,
          repo: _repo,
          number: prNumber,
          cancelToken: cancelToken,
        );
      } catch (e) {
        CcInfraLog.error('PR Files: fetching viewerViewedState failed for #$prNumber: $e',
          e,
        );
      }

      if (viewedStates.isNotEmpty) {
        lastFiles = List<PrFile>.unmodifiable([
          for (final f in lastFiles)
            f.copyWith(
              viewerViewedState: PrFileViewedStateExtension.fromWireName(
                viewedStates[f.filename],
              ),
            ),
        ]);
        yield PrFilesLoad(files: lastFiles, isComplete: true);
      }
    }

    if (lastFiles.isNotEmpty) {
      final encoded = await _encodeJson(
        lastFiles.map(_prFileToCacheJson).toList(growable: false),
        large: true,
      );
      await _cache.put(_workspaceId, _Kind.prFiles, '$prNumber', encoded);
    }
  }

  Map<String, dynamic> _prFileToCacheJson(PrFile f) => <String, dynamic>{
    'filename': f.filename,
    'status': f.status.name,
    'additions': f.additions,
    'deletions': f.deletions,
    'patch': f.patch,
    'previous_filename': f.previousFilename,
    'viewer_viewed_state': f.viewerViewedState.wireName,
  };

  PrFile _prFileFromCacheJson(Map<String, dynamic> m) {
    final base = prFileFromGitHub(GitHubPullRequestFile.fromJson(m));
    final wire = m['viewer_viewed_state'];
    if (wire is String) {
      return base.copyWith(
        viewerViewedState: PrFileViewedStateExtension.fromWireName(wire),
      );
    }
    return base;
  }

  /// Watches the raw content of a file at a given ref, served from cache with SWR.
  @override
  Stream<String> watchFileContent(String path, String ref) {
    return _swr<String>(
      kind: _Kind.prFileContent,
      key: '$path|$ref',
      decode: (raw) => raw,
      fetch: (token) => _client.content.getFileContent(
        _owner,
        _repo,
        path,
        ref,
        cancelToken: token,
      ),
      encode: (fresh) => fresh,
    );
  }

  /// Watches the list of commits for a PR, served from cache with SWR revalidation.
  @override
  Stream<List<PrCommit>> watchCommits(int prNumber) {
    return _swr<List<PrCommit>>(
      kind: _Kind.prCommits,
      key: '$prNumber',
      decode: (raw) async => (await _decodeJsonList(raw))
          .map(GitHubCommit.fromJson)
          .map(prCommitFromGitHub)
          .toList(growable: false),
      fetch: (token) => _client.pr
          .listAllPullRequestCommits(
            _owner,
            _repo,
            prNumber,
            cancelToken: token,
          )
          .then((l) => l.map(prCommitFromGitHub).toList(growable: false)),
      encode: (fresh) =>
          _encodeJson(fresh.map(_prCommitToCacheJson).toList(growable: false)),
    );
  }

  Map<String, dynamic> _prCommitToCacheJson(PrCommit c) => <String, dynamic>{
    'sha': c.sha,
    'commit': <String, dynamic>{
      'message': c.message,
      'author': <String, dynamic>{
        'name': c.author?.login ?? '',
        'email': '',
        'date': c.date?.toIso8601String(),
      },
    },
    'author': c.author != null
        ? <String, dynamic>{
            'login': c.author!.login,
            'avatar_url': c.author!.avatarUrl,
          }
        : null,
  };

  /// Watches the list of changed files for a specific commit SHA.
  @override
  Stream<List<PrFile>> watchCommitFiles(String sha) {
    if (sha.isEmpty) {
      return Stream.value(const <PrFile>[]);
    }
    return _swr<List<PrFile>>(
      kind: _Kind.prCommitFiles,
      key: sha,
      decode: (raw) async => (await _decodeJsonList(raw))
          .map(GitHubPullRequestFile.fromJson)
          .map(prFileFromGitHub)
          .toList(growable: false),
      fetch: (token) => _client.pr
          .getCommitFiles(_owner, _repo, sha, cancelToken: token)
          .then((l) => l.map(prFileFromGitHub).toList(growable: false)),
      encode: (fresh) => _encodeJson(
        fresh.map(_prFileToCacheJson).toList(growable: false),
        large: true,
      ),
    );
  }

  /// Watches the list of review submissions for a PR.
  @override
  Stream<List<PrReviewSubmission>> watchReviews(int prNumber) {
    return _swr<List<PrReviewSubmission>>(
      kind: _Kind.prReviews,
      key: '$prNumber',
      decode: (raw) async => (await _decodeJsonList(raw))
          .map(GitHubReview.fromJson)
          .map(prReviewSubmissionFromGitHub)
          .toList(growable: false),
      fetch: (token) => _client.pr
          .listPullRequestReviews(_owner, _repo, prNumber, cancelToken: token)
          .then(
            (l) => l.map(prReviewSubmissionFromGitHub).toList(growable: false),
          ),
      encode: (fresh) => _encodeJson(
        fresh.map(_prReviewSubmissionToCacheJson).toList(growable: false),
      ),
    );
  }

  Map<String, dynamic> _prReviewSubmissionToCacheJson(PrReviewSubmission r) =>
      <String, dynamic>{
        'id': 0,
        'state': r.state.name.toUpperCase(),
        'body': r.body,
        'submitted_at': null,
        'user': r.author != null
            ? <String, dynamic>{
                'login': r.author!.login,
                'avatar_url': r.author!.avatarUrl,
              }
            : null,
      };

  /// Watches review comments for a PR, enriching reactions with per-user state.
  @override
  Stream<List<PrCodeReviewComment>> watchReviewComments(int prNumber) {
    return _swr<List<PrCodeReviewComment>>(
      kind: _Kind.prReviewComments,
      key: '$prNumber',
      decode: (raw) async => (await _decodeJsonList(
        raw,
      )).map(_reviewCommentFromCacheJson).toList(growable: false),
      fetch: (token) async {
        final ghComments = await _client.pr.listPullRequestReviewComments(
          _owner,
          _repo,
          prNumber,
          cancelToken: token,
        );
        final login = await _currentLogin(token);
        var comments = ghComments
            .map(prCodeReviewCommentFromGitHub)
            .toList(growable: false);
        if (login != null) {
          comments = await _enrichCommentReactions(comments, login);
        }
        return comments;
      },
      encode: (fresh) => _encodeJson(
        fresh.map(_prCodeReviewCommentToCacheJson).toList(growable: false),
        large: true,
      ),
    );
  }

  Future<List<PrCodeReviewComment>> _enrichCommentReactions(
    List<PrCodeReviewComment> comments,
    String login,
  ) async {
    final results = <PrCodeReviewComment>[];
    for (final c in comments) {
      if (c.reactions.isEmpty) {
        results.add(c);
        continue;
      }
      try {
        final groups = await _reactionGroupsWithUser(
          c.reactions,
          reviewCommentId: c.id,
          currentUserLogin: login,
        );
        results.add(
          PrCodeReviewComment(
            id: c.id,
            body: c.body,
            user: c.user,
            path: c.path,
            position: c.position,
            createdAt: c.createdAt,
            side: c.side,
            inReplyToId: c.inReplyToId,
            startLine: c.startLine,
            diffHunk: c.diffHunk,
            line: c.line,
            originalLine: c.originalLine,
            reactions: groups,
          ),
        );
      } catch (e) {
        CcInfraLog.error('Comment Reactions: enrichment failed for #${c.id}: $e', e);
        results.add(c);
      }
    }
    return results;
  }

  PrCodeReviewComment _reviewCommentFromCacheJson(Map<String, dynamic> m) {
    final gh = GitHubReviewComment.fromJson(m);
    final c = prCodeReviewCommentFromGitHub(gh);
    final cached = m['reactions'];
    if (cached is Map<String, dynamic> && cached.containsKey('__groups')) {
      return PrCodeReviewComment(
        id: c.id,
        body: c.body,
        user: c.user,
        path: c.path,
        position: c.position,
        createdAt: c.createdAt,
        side: c.side,
        inReplyToId: c.inReplyToId,
        startLine: c.startLine,
        diffHunk: c.diffHunk,
        line: c.line,
        originalLine: c.originalLine,
        reactions: _reactionGroupsFromCacheJson(cached),
      );
    }
    return c;
  }

  IssueComment _issueCommentFromCacheJson(Map<String, dynamic> m) {
    final gh = GitHubIssueComment.fromJson(m);
    final c = issueCommentFromGitHub(gh);
    final cached = m['reactions'];
    if (cached is Map<String, dynamic> && cached.containsKey('__groups')) {
      return IssueComment(
        id: c.id,
        body: c.body,
        user: c.user,
        createdAt: c.createdAt,
        reactions: _reactionGroupsFromCacheJson(cached),
      );
    }
    return c;
  }

  Map<String, dynamic> _prCodeReviewCommentToCacheJson(PrCodeReviewComment c) =>
      <String, dynamic>{
        'id': c.id,
        'body': c.body,
        'path': c.path,
        'diff_hunk': c.diffHunk,
        'line': c.line,
        'original_line': c.originalLine,
        'side': c.side,
        'in_reply_to_id': c.inReplyToId,
        'start_line': c.startLine,
        'user': c.user != null
            ? <String, dynamic>{
                'login': c.user!.login,
                'avatar_url': c.user!.avatarUrl,
              }
            : null,
        'created_at': c.createdAt?.toIso8601String(),
        'reactions': _reactionGroupsToCacheJson(c.reactions),
      };

  /// Watches issue comments for a PR, enriching reactions with per-user state.
  @override
  Stream<List<IssueComment>> watchIssueComments(int prNumber) {
    return _swr<List<IssueComment>>(
      kind: _Kind.prIssueComments,
      key: '$prNumber',
      decode: (raw) async => (await _decodeJsonList(
        raw,
      )).map(_issueCommentFromCacheJson).toList(growable: false),
      fetch: (token) async {
        final ghComments = await _client.pr.listIssueComments(
          _owner,
          _repo,
          prNumber,
          cancelToken: token,
        );
        final login = await _currentLogin(token);
        var comments = ghComments
            .map(issueCommentFromGitHub)
            .toList(growable: false);
        if (login != null) {
          comments = await _enrichIssueCommentReactions(comments, login);
        }
        return comments;
      },
      encode: (fresh) => _encodeJson(
        fresh.map(_issueCommentToCacheJson).toList(growable: false),
        large: true,
      ),
    );
  }

  Future<List<IssueComment>> _enrichIssueCommentReactions(
    List<IssueComment> comments,
    String login,
  ) async {
    final results = <IssueComment>[];
    for (final c in comments) {
      if (c.reactions.isEmpty) {
        results.add(c);
        continue;
      }
      try {
        final groups = await _reactionGroupsWithUser(
          c.reactions,
          issueCommentId: c.id,
          currentUserLogin: login,
        );
        results.add(
          IssueComment(
            id: c.id,
            body: c.body,
            user: c.user,
            createdAt: c.createdAt,
            reactions: groups,
          ),
        );
      } catch (e) {
        CcInfraLog.error('IssueComment Reactions: enrichment for #${c.id}: $e', e);
        results.add(c);
      }
    }
    return results;
  }

  Map<String, dynamic> _issueCommentToCacheJson(IssueComment c) =>
      <String, dynamic>{
        'id': c.id,
        'body': c.body,
        'user': c.user != null
            ? <String, dynamic>{
                'login': c.user!.login,
                'avatar_url': c.user!.avatarUrl,
              }
            : null,
        'created_at': c.createdAt?.toIso8601String(),
        'reactions': _reactionGroupsToCacheJson(c.reactions),
      };

  /// Watches check runs for a PR, joining workflow names from the Actions API.
  @override
  Stream<List<CheckRun>> watchCheckRuns(int prNumber) {
    return _cancellable(
      (cancelToken) => _watchCheckRuns(prNumber, cancelToken),
    );
  }

  Stream<List<CheckRun>> _watchCheckRuns(
    int prNumber,
    CancelToken cancelToken,
  ) async* {
    final cachedPrJson = await _cache.read(
      _workspaceId,
      _Kind.prDetail,
      '$prNumber',
    );
    String? sha;
    if (cachedPrJson != null) {
      final map = await _decodeJsonMap(cachedPrJson);
      if (map != null) {
        final head = map['head'] as Map<String, dynamic>?;
        sha = head?['sha'] as String?;
      }
    }
    if (sha == null || sha.isEmpty) {
      try {
        sha = (await _client.pr.getPullRequest(
          _owner,
          _repo,
          prNumber,
          cancelToken: cancelToken,
        ))?.headSha;
      } on Object catch (error) {
        // Same crash class as the diff path: navigating away while check runs
        // load cancels this in-flight request. Swallow the cancellation so it
        // can't escape as a fatal unhandled error.
        if (_isCancellation(error)) {
          return;
        }
        rethrow;
      }
    }
    if (sha == null || sha.isEmpty) {
      yield const <CheckRun>[];
      return;
    }

    yield* _swrInner<List<CheckRun>>(
      cancelToken,
      kind: _Kind.prCheckRuns,
      key: sha,
      decode: (raw) async {
        final decoded = await _decodeJsonList(raw);
        return decoded
            .map((m) {
              final wf = m['__workflow_name'] as String?;
              final base = checkRunFromGitHub(GitHubCheckRun.fromJson(m));
              return wf == null || wf.isEmpty
                  ? base
                  : base.copyWith(workflowName: wf);
            })
            .toList(growable: false);
      },
      fetch: (token) async {
        // Fetch check runs and workflow runs concurrently — the
        // check-runs API only knows about the individual job (e.g.
        // "Unit test (1)") and not its parent workflow, so we join the
        // results by `check_suite_id` to recover the workflow name from
        // the actions/runs API.
        final results = await Future.wait([
          _client.pr.listCheckRuns(_owner, _repo, sha!, cancelToken: token),
          _client.pr.listWorkflowRuns(_owner, _repo, sha, cancelToken: token),
        ]);
        final checkRuns = results[0] as List<GitHubCheckRun>;
        final workflowRuns = results[1] as List<GitHubWorkflowRun>;
        final workflowBySuite = <int, String>{
          for (final w in workflowRuns)
            if (w.checkSuiteId != 0) w.checkSuiteId: _displayNameFor(w),
        };
        return checkRuns
            .map((c) {
              final base = checkRunFromGitHub(c);
              final suite = c.checkSuiteId;
              if (suite == null) {
                return base;
              }
              final wf = workflowBySuite[suite];
              if (wf == null || wf.isEmpty) {
                return base;
              }
              return base.copyWith(workflowName: wf);
            })
            .toList(growable: false);
      },
      encode: (fresh) =>
          _encodeJson(fresh.map(_checkRunToCacheJson).toList(growable: false)),
    );
  }

  /// Display name for a workflow run: prefer the explicit `name:` from the
  /// YAML, fall back to the workflow file basename (e.g. `tests-pr.yaml`)
  /// when the run was triggered before the workflow was named.
  static String _displayNameFor(GitHubWorkflowRun w) {
    if (w.name.isNotEmpty) {
      return w.name;
    }
    if (w.path.isEmpty) {
      return '';
    }
    final slash = w.path.lastIndexOf('/');
    return slash < 0 ? w.path : w.path.substring(slash + 1);
  }

  Map<String, dynamic> _checkRunToCacheJson(CheckRun c) => <String, dynamic>{
    'id': 0,
    'name': c.name,
    'status': c.status.name,
    'conclusion': c.conclusion?.name,
    'html_url': c.htmlUrl,
    'completed_at': c.completedAt?.toIso8601String(),
    'output': <String, dynamic>{'summary': c.output, 'title': ''},
    'app': <String, dynamic>{'name': ''},
    if (c.checkSuiteId != null)
      'check_suite': <String, dynamic>{'id': c.checkSuiteId},
    // Embedded in the cache JSON so workflow grouping survives offline
    // restores without an extra workflow_runs round-trip.
    if (c.workflowName != null) '__workflow_name': c.workflowName,
  };

  /// Invalidates all cached data for a PR.
  @override
  Future<void> invalidatePullRequest(int prNumber) async {
    final key = '$prNumber';
    for (final kind in _Kind.prScoped) {
      await _cache.deleteEntry(_workspaceId, kind, key);
    }
  }

  /// Invalidates the diff and files cache for a PR.
  @override
  Future<void> invalidateDiff(int prNumber) async {
    final key = '$prNumber';
    await _cache.deleteEntry(_workspaceId, _Kind.prDiff, key);
    await _cache.deleteEntry(_workspaceId, _Kind.prFiles, key);
  }

  /// Marks or unmarks a file as viewed in a PR.
  @override
  Future<void> markFileAsViewed({
    required int prNumber,
    required String nodeId,
    required String path,
    required bool viewed,
  }) async {
    if (viewed) {
      await _client.graphql.markFileAsViewed(pullRequestId: nodeId, path: path);
    } else {
      await _client.graphql.unmarkFileAsViewed(
        pullRequestId: nodeId,
        path: path,
      );
    }
    await _patchCachedFileViewedState(
      prNumber: prNumber,
      path: path,
      viewed: viewed,
    );
  }

  /// Flips the viewed flag inside the cached prFiles entry so a reload
  /// shows the latest state without waiting for the next revalidation
  /// roundtrip.
  Future<void> _patchCachedFileViewedState({
    required int prNumber,
    required String path,
    required bool viewed,
  }) async {
    final raw = await _cache.read(_workspaceId, _Kind.prFiles, '$prNumber');
    if (raw == null) {
      return;
    }
    final list = await _decodeJsonList(raw);
    final wire = viewed
        ? PrFileViewedState.viewed.wireName
        : PrFileViewedState.unviewed.wireName;
    var dirty = false;
    final updated = <Map<String, dynamic>>[];
    for (final entry in list) {
      if (entry['filename'] == path) {
        if (entry['viewer_viewed_state'] != wire) {
          dirty = true;
        }
        updated.add({...entry, 'viewer_viewed_state': wire});
      } else {
        updated.add(entry);
      }
    }
    if (dirty) {
      await _cache.put(
        _workspaceId,
        _Kind.prFiles,
        '$prNumber',
        await _encodeJson(updated, large: true),
      );
    }
  }

  /// Posts a new review comment on a PR.
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
    final result = await _client.pr.postReviewComment(
      _owner,
      _repo,
      prNumber: prNumber,
      commitSha: commitSha,
      path: path,
      line: line,
      side: side,
      startLine: startLine,
      startSide: startSide,
      body: body,
    );
    return {'id': result.id};
  }

  /// Replies to an existing review comment on a PR.
  @override
  Future<void> replyToReviewComment({
    required int prNumber,
    required int parentCommentId,
    required String body,
  }) async {
    await _client.pr.replyToReviewComment(
      _owner,
      _repo,
      prNumber: prNumber,
      parentCommentId: parentCommentId,
      body: body,
    );
  }

  /// Saves a draft review message for a PR.
  @override
  Future<void> upsertDraft(int prNumber, String text) async {
    await _draft.upsertDraft(_owner, _repo, prNumber, text);
  }

  /// Retrieves a saved draft review message for a PR.
  @override
  Future<String?> getDraft(int prNumber) async {
    return _draft.getDraft(_owner, _repo, prNumber);
  }

  /// Clears a saved draft review message for a PR.
  @override
  Future<void> clearDraft(int prNumber) async {
    await _draft.clearDraft(_owner, _repo, prNumber);
  }

  /// Uploads base64-encoded content to a file in the repository.
  @override
  Future<String> uploadContent(
    String path,
    String base64Content,
    String message,
  ) async {
    return _client.content.createFileContent(
      _owner,
      _repo,
      path,
      base64Content,
      message,
    );
  }

  /// Toggles a reaction on a review comment.
  @override
  Future<void> toggleReviewCommentReaction({
    required int commentId,
    required String content,
    required bool add,
    required int prNumber,
    String? currentUserLogin,
  }) async {
    if (add) {
      await _client.pr.createReviewCommentReaction(
        _owner,
        _repo,
        commentId: commentId,
        content: content,
      );
    } else {
      final reactions = await _client.pr.listReviewCommentReactions(
        _owner,
        _repo,
        commentId: commentId,
      );
      final mine = reactions.where(
        (r) => r.user?.login == currentUserLogin && r.content == content,
      );
      for (final r in mine) {
        await _client.pr.deleteReviewCommentReaction(
          _owner,
          _repo,
          commentId: commentId,
          reactionId: r.id,
        );
      }
    }
    await _invalidateKind(_Kind.prReviewComments, '$prNumber');
  }

  /// Toggles a reaction on an issue comment.
  @override
  Future<void> toggleIssueCommentReaction({
    required int commentId,
    required String content,
    required bool add,
    required int prNumber,
    String? currentUserLogin,
  }) async {
    if (add) {
      await _client.pr.createIssueCommentReaction(
        _owner,
        _repo,
        commentId: commentId,
        content: content,
      );
    } else {
      final reactions = await _client.pr.listIssueCommentReactions(
        _owner,
        _repo,
        commentId: commentId,
      );
      final mine = reactions.where(
        (r) => r.user?.login == currentUserLogin && r.content == content,
      );
      for (final r in mine) {
        await _client.pr.deleteIssueCommentReaction(
          _owner,
          _repo,
          commentId: commentId,
          reactionId: r.id,
        );
      }
    }
    await _invalidateKind(_Kind.prIssueComments, '$prNumber');
  }

  /// Toggles a reaction on a pull request.
  @override
  Future<void> togglePullRequestReaction({
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) async {
    if (add) {
      await _client.pr.createIssueReaction(
        _owner,
        _repo,
        issueNumber: prNumber,
        content: content,
      );
    } else {
      final reactions = await _client.pr.listIssueReactions(
        _owner,
        _repo,
        issueNumber: prNumber,
      );
      final mine = reactions.where(
        (r) => r.user?.login == currentUserLogin && r.content == content,
      );
      for (final r in mine) {
        await _client.pr.deleteIssueReaction(
          _owner,
          _repo,
          issueNumber: prNumber,
          reactionId: r.id,
        );
      }
    }
    await _invalidateKind(_Kind.prDetail, '$prNumber');
  }

  Future<void> _invalidateKind(String kind, String key) async {
    await _cache.deleteEntry(_workspaceId, kind, key);
  }

  /// Submits a review (approve, request changes, or comment).
  @override
  Future<void> submitReview({
    required int prNumber,
    required String event,
    String? body,
  }) async {
    await _client.pr.submitReview(
      _owner,
      _repo,
      prNumber: prNumber,
      event: event,
      body: body,
    );
    await invalidatePullRequest(prNumber);
    // A user-submitted approval ends the reviewer's involvement with this PR,
    // so surface it as a status change that cleanup triggers can react to
    // (e.g. pruning the reviewer's "open in editor" worktree). Only the
    // local user reaches this repository path; agent-published reviews go
    // through ReviewPublisherService and intentionally do not emit here.
    if (event == 'APPROVE') {
      _emitStatusChanged('approved', prNumber);
    }
  }

  /// Merges a pull request using the specified merge method.
  @override
  Future<Map<String, dynamic>> mergePullRequest({
    required int prNumber,
    required String mergeMethod,
    String? commitTitle,
    String? commitMessage,
  }) async {
    final result = await _client.pr.mergePullRequest(
      _owner,
      _repo,
      prNumber: prNumber,
      mergeMethod: mergeMethod,
      commitTitle: commitTitle,
      commitMessage: commitMessage,
    );
    await invalidatePullRequest(prNumber);
    _emitStatusChanged('merged', prNumber);
    return result;
  }

  /// Closes a pull request.
  @override
  Future<void> closePullRequest({required int prNumber}) async {
    await _client.pr.closePullRequest(_owner, _repo, prNumber: prNumber);
    await invalidatePullRequest(prNumber);
    _emitStatusChanged('closed', prNumber);
  }

  /// Updates the title or body of a pull request.
  @override
  Future<void> updatePullRequest({
    required int prNumber,
    String? title,
    String? body,
  }) async {
    if (title == null && body == null) {
      return;
    }
    await _client.pr.updatePullRequest(
      _owner,
      _repo,
      prNumber: prNumber,
      title: title,
      body: body,
    );
    // Targeted: only the PR detail changed — don't nuke the (expensive) diff/
    // files/commits caches the way the full invalidatePullRequest would.
    await _invalidateKind(_Kind.prDetail, '$prNumber');
  }

  /// Adds assignees to a pull request.
  @override
  Future<void> addAssignees({
    required int prNumber,
    required List<String> logins,
  }) async {
    if (logins.isEmpty) {
      return;
    }
    // GitHub caps assignees at 10 per call — chunk larger requests.
    for (final chunk in _chunk(logins, 10)) {
      await _client.pr.addAssignees(
        _owner,
        _repo,
        prNumber: prNumber,
        logins: chunk,
      );
    }
    await _invalidateKind(_Kind.prDetail, '$prNumber');
  }

  /// Removes assignees from a pull request.
  @override
  Future<void> removeAssignees({
    required int prNumber,
    required List<String> logins,
  }) async {
    if (logins.isEmpty) {
      return;
    }
    for (final chunk in _chunk(logins, 10)) {
      await _client.pr.removeAssignees(
        _owner,
        _repo,
        prNumber: prNumber,
        logins: chunk,
      );
    }
    await _invalidateKind(_Kind.prDetail, '$prNumber');
  }

  /// Requests reviewers for a pull request.
  @override
  Future<void> requestReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
  }) async {
    if (userLogins.isEmpty && teamSlugs.isEmpty) {
      return;
    }
    await _client.pr.requestReviewers(
      _owner,
      _repo,
      prNumber: prNumber,
      reviewers: userLogins,
      teamReviewers: teamSlugs,
    );
    await _invalidateKind(_Kind.prReviewerState, '$prNumber');
    await _invalidateKind(_Kind.prDetail, '$prNumber');
  }

  /// Removes requested reviewers from a pull request.
  @override
  Future<void> removeRequestedReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
  }) async {
    if (userLogins.isEmpty && teamSlugs.isEmpty) {
      return;
    }
    await _client.pr.removeRequestedReviewers(
      _owner,
      _repo,
      prNumber: prNumber,
      reviewers: userLogins,
      teamReviewers: teamSlugs,
    );
    await _invalidateKind(_Kind.prReviewerState, '$prNumber');
    await _invalidateKind(_Kind.prDetail, '$prNumber');
  }

  static Iterable<List<T>> _chunk<T>(List<T> items, int size) sync* {
    for (var i = 0; i < items.length; i += size) {
      final end = (i + size) > items.length ? items.length : i + size;
      yield items.sublist(i, end);
    }
  }

  /// Watches the enriched reviewer state for a PR.
  @override
  Stream<List<PrReviewer>> watchReviewers(int prNumber) {
    return _swr<List<PrReviewer>>(
      kind: _Kind.prReviewerState,
      key: '$prNumber',
      decode: (raw) async => (await _decodeJsonList(
        raw,
      )).map(_prReviewerFromCacheJson).toList(growable: false),
      fetch: (token) async {
        final state = await _client.graphql.getPullRequestReviewState(
          owner: _owner,
          repo: _repo,
          number: prNumber,
          cancelToken: token,
        );
        final known = await _mergeCodeOwnerIds(
          prNumber,
          codeOwnerIdentitiesFromReviewState(state),
        );
        return prReviewersFromReviewState(state, knownCodeOwnerIds: known);
      },
      encode: (fresh) => _encodeJson(
        fresh.map(_prReviewerToCacheJson).toList(growable: false),
      ),
    );
  }

  /// Unions `newIds` into the persisted per-PR code-owner identity set and
  /// returns the updated set. Lets a code-owner shield persist after the
  /// reviewer's request is consumed by a review (GitHub drops `asCodeOwner`
  /// once the request is satisfied). Writes back only when the set grows.
  Future<Set<String>> _mergeCodeOwnerIds(
    int prNumber,
    Set<String> newIds,
  ) async {
    final raw = await _cache.read(
      _workspaceId,
      _Kind.prCodeOwnerIds,
      '$prNumber',
    );
    final existing = <String>{};
    if (raw != null) {
      final map = await _decodeJsonMap(raw);
      final ids = map?['ids'];
      if (ids is List) {
        existing.addAll(ids.whereType<String>());
      }
    }
    final merged = <String>{...existing, ...newIds};
    if (merged.length != existing.length) {
      await _cache.put(
        _workspaceId,
        _Kind.prCodeOwnerIds,
        '$prNumber',
        await _encodeJson(<String, dynamic>{'ids': merged.toList()}),
      );
    }
    return merged;
  }

  Map<String, dynamic> _prReviewerToCacheJson(PrReviewer r) {
    switch (r) {
      case PrUserReviewer():
        return <String, dynamic>{
          'kind': 'user',
          'is_code_owner': r.isCodeOwner,
          'state': r.state.name,
          'login': r.user.login,
          'avatar_url': r.user.avatarUrl,
        };
      case PrTeamReviewer():
        return <String, dynamic>{
          'kind': 'team',
          'is_code_owner': r.isCodeOwner,
          'state': r.state.name,
          'name': r.name,
          'slug': r.slug,
          if (r.reviewedBy != null)
            'reviewed_by': <String, dynamic>{
              'login': r.reviewedBy!.login,
              'avatar_url': r.reviewedBy!.avatarUrl,
            },
        };
    }
  }

  PrReviewer _prReviewerFromCacheJson(Map<String, dynamic> m) {
    final state = PrReviewSubmissionState.values.firstWhere(
      (s) => s.name == m['state'],
      orElse: () => PrReviewSubmissionState.pending,
    );
    final isCodeOwner = m['is_code_owner'] as bool? ?? false;
    if (m['kind'] == 'team') {
      final rb = m['reviewed_by'];
      return PrTeamReviewer(
        name: m['name'] as String? ?? '',
        slug: m['slug'] as String? ?? '',
        isCodeOwner: isCodeOwner,
        state: state,
        reviewedBy: rb is Map<String, dynamic>
            ? PrUser(
                login: rb['login'] as String? ?? '',
                avatarUrl: rb['avatar_url'] as String? ?? '',
              )
            : null,
      );
    }
    return PrUserReviewer(
      user: PrUser(
        login: m['login'] as String? ?? '',
        avatarUrl: m['avatar_url'] as String? ?? '',
      ),
      isCodeOwner: isCodeOwner,
      state: state,
    );
  }

  /// Lists users who can be assigned to PRs in this repository.
  @override
  Future<List<PrUser>> listAssignableUsers() async {
    final cached = await _readEnvelope(_Kind.assignableUsers, _repoFullName);
    if (cached != null) {
      return cached.map(_prUserFromEnvelope).toList(growable: false);
    }
    final users = await _client.pr.listAssignableUsers(_owner, _repo);
    final items = <Map<String, dynamic>>[
      for (final u in users) {'login': u.login, 'avatar_url': u.avatarUrl},
    ];
    await _writeEnvelope(_Kind.assignableUsers, _repoFullName, items);
    return items.map(_prUserFromEnvelope).toList(growable: false);
  }

  /// Lists all eligible reviewer candidates (users and teams) for this repository.
  @override
  Future<List<PrReviewerCandidate>> listRequestableReviewers() async {
    final users = await listAssignableUsers();
    final teams = await _listRequestableTeams();
    return <PrReviewerCandidate>[
      for (final u in users) PrReviewerCandidate.user(u),
      ...teams,
    ];
  }

  Future<List<PrReviewerCandidate>> _listRequestableTeams() async {
    final cached = await _readEnvelope(_Kind.requestableTeams, _repoFullName);
    if (cached != null) {
      return cached
          .map(
            (m) => PrReviewerCandidate(
              kind: ReviewerKind.team,
              key: m['slug'] as String? ?? '',
              label: m['name'] as String? ?? '',
            ),
          )
          .toList(growable: false);
    }
    final teams = await _client.pr.listRequestableTeams(_owner, _repo);
    final items = <Map<String, dynamic>>[
      for (final t in teams) {'name': t.name, 'slug': t.slug},
    ];
    await _writeEnvelope(_Kind.requestableTeams, _repoFullName, items);
    return items
        .map(
          (m) => PrReviewerCandidate(
            kind: ReviewerKind.team,
            key: m['slug'] as String? ?? '',
            label: m['name'] as String? ?? '',
          ),
        )
        .toList(growable: false);
  }

  /// Soft TTL for picker candidate lists: tolerate a stale list rather than
  /// hit the network every time a picker opens.
  static const _pickerTtl = Duration(minutes: 10);

  /// Reads a `{fetchedAt, items}` envelope and returns its items if still
  /// within `_pickerTtl`, else null (caller refetches). CacheDao is TTL-less,
  /// so freshness is enforced here.
  Future<List<Map<String, dynamic>>?> _readEnvelope(
    String kind,
    String key,
  ) async {
    final raw = await _cache.read(_workspaceId, kind, key);
    if (raw == null) {
      return null;
    }
    final map = await _decodeJsonMap(raw);
    if (map == null) {
      return null;
    }
    final fetchedAt = DateTime.tryParse(map['fetchedAt'] as String? ?? '');
    if (fetchedAt == null ||
        DateTime.now().difference(fetchedAt) > _pickerTtl) {
      return null;
    }
    final items = map['items'];
    if (items is! List) {
      return null;
    }
    return items.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Future<void> _writeEnvelope(
    String kind,
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    await _cache.put(
      _workspaceId,
      kind,
      key,
      await _encodeJson(<String, dynamic>{
        'fetchedAt': DateTime.now().toIso8601String(),
        'items': items,
      }, large: true),
    );
  }

  PrUser _prUserFromEnvelope(Map<String, dynamic> m) => PrUser(
    login: m['login'] as String? ?? '',
    avatarUrl: m['avatar_url'] as String? ?? '',
  );

  /// Publishes a [PullRequestStatusChanged] so pipeline triggers (e.g. the
  /// stale-repository cleanup / release-notes pipelines) can react to merges,
  /// closes, and user approvals.
  void _emitStatusChanged(String status, int prNumber) {
    _eventBus?.publish(
      PullRequestStatusChanged(
        status: status,
        workspaceId: _workspaceId,
        repoFullName: _repoFullName,
        prNumber: prNumber,
        occurredAt: DateTime.now(),
      ),
    );
  }

  Map<String, dynamic>? _reactionGroupsToCacheJson(List<dynamic> groups) {
    if (groups.isEmpty) {
      return null;
    }
    final list = <Map<String, dynamic>>[];
    for (final g in groups) {
      final group = g as ReactionGroup;
      list.add(<String, dynamic>{
        'content': group.content,
        'count': group.count,
        'userReacted': group.userReacted,
        'usernames': group.usernames,
      });
    }
    return {'__groups': list};
  }

  List<ReactionGroup> _reactionGroupsFromCacheJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return const [];
    }
    final groups = raw['__groups'];
    if (groups is! List) {
      return reactionGroupsFromSummary(
        raw.containsKey('total_count')
            ? GitHubReactionSummary.fromJson(raw)
            : null,
      );
    }
    return [
      for (final g in groups.whereType<Map<String, dynamic>>())
        ReactionGroup(
          content: g['content'] as String? ?? '',
          emoji: ReactionGroup.emojiForContent(g['content'] as String? ?? ''),
          count: g['count'] as int? ?? 0,
          userReacted: g['userReacted'] as bool? ?? false,
          usernames:
              (g['usernames'] as List?)?.whereType<String>().toList(
                growable: false,
              ) ??
              const [],
        ),
    ];
  }
}

// EmptyPrReviewRepository is defined in pr_review_repository.dart (domain layer).
