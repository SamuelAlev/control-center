import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/services/cache_stats.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/commit_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/job_run_detail.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_stack.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/reaction_group.dart';
import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_domain/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/daos/review_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_server_core/src/pr_review/pr_cache_codec.dart';
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
  static const prTimelineEvents = 'prTimelineEvents';
  static const prCheckRuns = 'prCheckRuns';
  static const prCommitStatuses = 'prCommitStatuses';

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
    prTimelineEvents,
    prCheckRuns,
    prCommitStatuses,
    prReviewerState,
  ];
}

// GitHub caps the files endpoint at 3 000 entries; above this threshold we
// fall back to the local-git source.
const _githubFilesApiLimit = 3000;

/// Cross-pass state for a long-lived SWR stream: the fingerprint of the last
/// emission (so a re-validation that changes nothing emits nothing) and
/// whether the stream was cancelled mid-pass (so the outer signal loop stops
/// instead of idling on a dead subscription).
class _SwrState {
  String? lastEncoded;
  bool cancelled = false;
}

/// Cached pr review repository.
///
/// One instance serves exactly one `(workspace, owner, repo)` triple. The
/// workspace is fixed by the [WorkspaceDatabase] handed in at construction —
/// the SWR cache and the review drafts both live in that workspace's own
/// database file and there is no setter that could repoint it afterwards.
///
/// **Forge-agnostic.** Everything here — the SWR disk cache, review drafts,
/// the large-PR fallback to a local git clone, reaction enrichment — works the
/// same whichever forge answered, because it talks to a [ForgePrClient] and
/// stores domain entities through [PrCacheCodec]. A GitLab merge request and a
/// Bitbucket pull request are cached, revalidated and served by this one class.
/// Where a forge lacks a capability its adapter throws [ForgeUnsupportedError];
/// this class does not branch on the forge itself.
class CachedPrReviewRepository implements PrReviewRepository {
  /// Creates a new `CachedPrReviewRepository` over one workspace's database.
  CachedPrReviewRepository({
    required WorkspaceDatabase db,
    required ForgePrClient forgeClient,
    required String owner,
    required String repo,
    required PrDiffSource apiDiffSource,
    required PrDiffSource localDiffSource,
    String? localCheckoutPath,
    DomainEventBus? eventBus,
    PrChangeSignals? changeSignals,
  }) : _db = db,
       _client = forgeClient,
       _owner = owner,
       _repo = repo,
       _apiDiffSource = apiDiffSource,
       _localDiffSource = localDiffSource,
       _localCheckoutPath = localCheckoutPath,
       _eventBus = eventBus,
       _signals = changeSignals;

  final WorkspaceDatabase _db;

  CacheDao get _cache => _db.cacheDao;

  ReviewDao get _draft => _db.reviewDao;

  /// The workspace this repository is bound to, read off the database file it
  /// writes so the two can never disagree.
  String get _workspaceId => _db.workspaceId;

  final ForgePrClient _client;
  final String _owner;
  final String _repo;
  final PrDiffSource _apiDiffSource;
  final PrDiffSource _localDiffSource;
  final String? _localCheckoutPath;
  final DomainEventBus? _eventBus;

  /// Live-update bus: when present, every `watch*` stream stays open after its
  /// initial SWR pass and re-validates whenever a [PrChangeSignal] for its PR
  /// arrives (from the open-PR poller, the notifications poller, or a local
  /// mutation). When null (tests, token-less hosts) the streams keep the
  /// legacy one-shot cache-then-fetch behavior.
  final PrChangeSignals? _signals;

  String get _repoFullName => '$_owner/$_repo';

  /// Cache key for PR-scoped kinds. Carries the repo so two linked repos with
  /// the same PR number can never collide inside one workspace's cache (the
  /// caches table is keyed `(workspaceId, kind, key)` with no repo dimension).
  String _prKey(int prNumber) => '$_repoFullName#$prNumber';

  /// Cache key for SHA-scoped kinds (check runs, commit files), repo-prefixed
  /// for the same collision-safety reason as [_prKey].
  String _shaKey(String sha) => '$_repoFullName|$sha';

  /// Publishes a change signal for [prNumber] so every open watch stream for
  /// it (this or any other subscriber's) re-runs its SWR pass.
  void _notifyPrChanged(int prNumber) {
    _signals?.notify(
      workspaceId: _workspaceId,
      repoFullName: _repoFullName,
      prNumber: prNumber,
    );
  }

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
    int? reactToPr,
    bool reactToChecks = false,
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
        reactToPr: reactToPr,
        reactToChecks: reactToChecks,
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
    int? reactToPr,
    bool reactToChecks = false,
  }) async* {
    final state = _SwrState();
    yield* _swrPass(
      cancelToken,
      state,
      kind: kind,
      key: key,
      decode: decode,
      fetch: fetch,
      encode: encode,
      skipRevalidate: skipRevalidate,
      isFirstPass: true,
    );
    if (state.cancelled || cancelToken.isCancelled) {
      return;
    }

    // Reactive phase: stay subscribed and re-validate on every change signal
    // for this PR. Without a signals bus (or for kinds that don't react) the
    // stream completes after the first pass — the legacy SWR behavior.
    final signals = _signals;
    if (signals == null || reactToPr == null) {
      return;
    }
    final iterator = StreamIterator(
      signals.watch(
        workspaceId: _workspaceId,
        repoFullName: _repoFullName,
        prNumber: reactToPr,
      ),
    );
    try {
      while (true) {
        final signal = await _nextSignal(iterator, cancelToken);
        if (signal == null) {
          return;
        }
        if (signal.checksOnly && !reactToChecks) {
          continue;
        }
        yield* _swrPass(
          cancelToken,
          state,
          kind: kind,
          key: key,
          decode: decode,
          fetch: fetch,
          encode: encode,
          skipRevalidate: skipRevalidate,
          isFirstPass: false,
        );
        if (state.cancelled || cancelToken.isCancelled) {
          return;
        }
      }
    } finally {
      unawaited(iterator.cancel());
    }
  }

  /// Waits for the next change signal, returning null when the signal stream
  /// closes OR the subscriber cancels.
  ///
  /// The race against [CancelToken.whenCancel] is load-bearing: an `async*`
  /// generator only honors cancellation at a `yield`, so a bare
  /// `iterator.moveNext()` on a quiet signal stream would suspend the
  /// generator indefinitely and deadlock [_cancellable]'s `onCancel` (which
  /// awaits the generator's teardown).
  static Future<PrChangeSignal?> _nextSignal(
    StreamIterator<PrChangeSignal> iterator,
    CancelToken cancelToken,
  ) async {
    final hasNext = await Future.any<bool>([
      iterator.moveNext(),
      cancelToken.whenCancel.then((_) => false),
    ]);
    if (!hasNext || cancelToken.isCancelled) {
      return null;
    }
    return iterator.current;
  }

  /// One stale-while-revalidate pass over `(kind, key)`:
  ///
  ///  1. yield the cached value if it differs from the last emission (a signal
  ///     may follow another writer's fresh cache write — serve it with no
  ///     network call);
  ///  2. honor [skipRevalidate] (the cheap freshness probe);
  ///  3. fetch, persist and yield when the payload actually changed.
  ///
  /// [state] carries the dedupe fingerprint across passes so a re-validation
  /// that finds nothing new emits nothing. Errors follow the original SWR
  /// contract: cancellations end the stream quietly, a first-pass fetch
  /// failure with no cache rethrows and any later failure is swallowed so a
  /// transient GitHub hiccup can't kill a long-lived subscription.
  Stream<T> _swrPass<T>(
    CancelToken cancelToken,
    _SwrState state, {
    required String kind,
    required String key,
    required FutureOr<T> Function(String cached) decode,
    required Future<T> Function(CancelToken? cancelToken) fetch,
    required FutureOr<String> Function(T fresh) encode,
    Future<bool> Function(T cached, CancelToken cancelToken)? skipRevalidate,
    required bool isFirstPass,
  }) async* {
    final cached = await _cache.read(_workspaceId, kind, key);
    final hadCache = cached != null;
    // SWR: a "hit" here means the pass could serve something immediately, not
    // that it skipped the network — revalidation still runs. That is the
    // number worth watching for this cache: it is what decides whether a PR
    // page paints instantly or waits on the forge.
    if (hadCache) {
      _swrStats.hit();
    } else {
      _swrStats.miss();
    }
    T? cachedModel;
    if (cached != null) {
      try {
        final decoded = await decode(cached);
        // Encode once and reuse: emission dedupe and the post-fetch comparison
        // share the normalized form (and, via the isolate helpers, heavy
        // payloads serialize off the main thread).
        final encoded = await encode(decoded);
        cachedModel = decoded;
        if (encoded != state.lastEncoded) {
          yield decoded;
          state.lastEncoded = encoded;
        }
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
          state.cancelled = true;
          return;
        }
      }
    }

    try {
      final fresh = await _singleFlightFetch<T>(kind, key, fetch, cancelToken);
      final freshEncoded = await encode(fresh);
      await _putBounded(kind, key, freshEncoded);
      if (freshEncoded != state.lastEncoded) {
        yield fresh;
        state.lastEncoded = freshEncoded;
      }
    } on Object catch (error) {
      // A cancellation means the subscriber unsubscribed; never resurface it as
      // a stream error (it would be unhandled and abort the process), even when
      // there is no cache to fall back on. Only a genuine first-pass fetch
      // failure with no cached value is worth surfacing.
      if (_isCancellation(error)) {
        state.cancelled = true;
        return;
      }
      if (isFirstPass && !hadCache) {
        rethrow;
      }
    }
  }

  /// Per-entry ceiling for a cached PR payload.
  ///
  /// The `caches` table has no size cap between the daily retention sweeps and
  /// a PR diff "can run to megabytes per row" (its own comment), so one
  /// session browsing large PRs could add hundreds of MB to a workspace file
  /// before anything reclaimed it. 8 MB is generous next to a normal PR and
  /// still bounds the pathological one.
  static const int _maxCachedEntryChars = 8 * 1024 * 1024;

  /// Writes [encoded] unless it exceeds [_maxCachedEntryChars].
  ///
  /// A refused entry is LOGGED, not silent: skipping the store means that PR
  /// re-fetches on every visit, which is a real behaviour change and should be
  /// visible to whoever wonders why one PR is always slow.
  Future<void> _putBounded(String kind, String key, String encoded) async {
    if (encoded.length > _maxCachedEntryChars) {
      CcInfraLog.warning(
        'PR cache: refusing to store $kind/$key '
        '(${encoded.length ~/ (1024 * 1024)}MB exceeds the '
        '${_maxCachedEntryChars ~/ (1024 * 1024)}MB per-entry cap) — this '
        'payload will be re-fetched on every visit',
      );
      _swrStats.evicted();
      return;
    }
    await _cache.put(_workspaceId, kind, key, encoded);
  }

  /// Hit/miss counters for the PR stale-while-revalidate layer.
  static final CacheStats _swrStats = CacheStatsRegistry.instance.of('pr_swr');

  /// In-flight upstream fetches, keyed by `(kind, key, T)`.
  ///
  /// A PR page opens ~6 watch streams at once (detail, diff, files, reviews,
  /// comments, timeline) and a change signal fans out to all of them; any two
  /// subscribers on the same kind+key would otherwise each issue their own
  /// forge request for identical bytes. `MediaCache._inflight` is the in-repo
  /// template for this.
  final Map<String, _InflightFetch> _inflightFetches = {};

  /// Runs [fetch] once per `(kind, key)`, sharing the result with concurrent
  /// callers.
  ///
  /// A waiter whose leader was CANCELLED (the leading subscriber unsubscribed
  /// mid-flight) re-issues the fetch itself rather than inheriting a
  /// cancellation it never asked for — the same waiter-re-initiation the media
  /// cache documents.
  Future<T> _singleFlightFetch<T>(
    String kind,
    String key,
    Future<T> Function(CancelToken? cancelToken) fetch,
    CancelToken cancelToken,
  ) async {
    final id = '$kind|$key|$T';
    final existing = _inflightFetches[id];
    if (existing != null) {
      try {
        return await existing.future as T;
      } on Object catch (error) {
        if (!_isCancellation(error)) {
          rethrow;
        }
        // Fall through and lead the next attempt ourselves.
      }
    }
    final entry = _InflightFetch(fetch(cancelToken));
    _inflightFetches[id] = entry;
    try {
      return await entry.future as T;
    } finally {
      // Only the leader clears its OWN entry — a waiter that re-led after a
      // cancellation may have replaced it.
      if (identical(_inflightFetches[id], entry)) {
        _inflightFetches.remove(id);
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

  /// Watches the full pull request detail, served from cache with SWR
  /// revalidation, then kept live via change signals.
  @override
  Stream<PullRequest?> watchPullRequest(int prNumber) {
    return _swr<PullRequest?>(
      kind: _Kind.prDetail,
      key: _prKey(prNumber),
      reactToPr: prNumber,
      decode: (raw) async =>
          PrCacheCodec.pullRequestFromCache(await _decodeJsonMap(raw)),
      fetch: (token) async {
        final pr = await _client.getPullRequest(prNumber, cancelToken: token);
        if (pr == null) {
          return null;
        }
        if (!_client.capabilities.reactions) {
          return pr;
        }
        try {
          return pr.copyWith(
            reactions: await _reactionGroupsWithUser(
              pr.reactions,
              target: ForgeReactionTarget.pullRequest,
              targetId: '$prNumber',
              prNumber: prNumber,
              cancelToken: token,
            ),
          );
        } catch (e) {
          CcInfraLog.error(
            'PR Reactions: enrichment failed for #$prNumber: $e',
            e,
          );
          return pr;
        }
      },
      encode: (fresh) async => fresh == null
          ? 'null'
          : await _encodeJson(PrCacheCodec.pullRequestToCache(fresh)),
    );
  }

  /// The viewer's account name on this forge, resolved once and reused.
  ///
  /// Reaction enrichment needs it on every comment, and it is per-forge: the
  /// same operator is a different login on GitHub than on GitLab, so it is
  /// asked of the client that answered rather than read from a global setting.
  Future<String?> _currentLogin(Object? token) async {
    if (_cachedLogin != null) {
      return _cachedLogin;
    }
    try {
      final user = await _client.getAuthenticatedUser(cancelToken: token);
      return _cachedLogin = user?.login;
    } catch (_) {
      return null;
    }
  }

  String? _cachedLogin;

  /// Marks which of [base]'s reactions belong to the viewer, and attaches the
  /// full reactor list for the hover card.
  ///
  /// Returns [base] unchanged on any failure: a missing "you reacted" highlight
  /// is a cosmetic loss, while a thrown error here would take down the whole
  /// comment stream.
  Future<List<ReactionGroup>> _reactionGroupsWithUser(
    List<ReactionGroup> base, {
    required ForgeReactionTarget target,
    required String targetId,
    required int prNumber,
    Object? cancelToken,
  }) async {
    if (base.isEmpty || !_client.capabilities.reactions) {
      return base;
    }
    final currentUserLogin = await _currentLogin(cancelToken);
    if (currentUserLogin == null) {
      return base;
    }
    try {
      final all = await _client.listReactions(
        target: target,
        targetId: targetId,
        prNumber: prNumber,
        cancelToken: cancelToken,
      );
      final myContents = <String>{};
      final byContent = <String, List<String>>{};
      for (final r in all) {
        if (r.login.isNotEmpty) {
          (byContent[r.content] ??= []).add(r.login);
        }
        if (r.login == currentUserLogin) {
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

  /// Reads and decodes the cached PR-detail blob ONCE.
  ///
  /// `_cachedHeadSha` / `_cachedBaseSha` / `_cachedChangedFiles` each used to
  /// do their own `_cache.read` plus a full `jsonDecode` of the whole detail
  /// payload; the files pass calls all three, so one pass decoded the same
  /// blob up to three times to pull three scalars out of it.
  Future<Map<String, dynamic>?> _cachedPrDetailMap(int prNumber) async {
    final raw = await _cache.read(
      _workspaceId,
      _Kind.prDetail,
      _prKey(prNumber),
    );
    if (raw == null) {
      return null;
    }
    return _decodeJsonMap(raw);
  }

  Future<String?> _cachedHeadSha(int prNumber) async =>
      (await _cachedPrDetailMap(prNumber))?['head_sha'] as String?;

  /// Reads the changed-file count from the cached PR detail, or 0 if absent.
  /// Used as a routing fallback so a live `getPullRequest` failure can't
  /// misroute a large PR away from the local-git source.
  Future<int> _cachedChangedFiles(int prNumber) async {
    final value = (await _cachedPrDetailMap(prNumber))?['changed_files'];
    return value is num ? value.toInt() : 0;
  }

  /// Watches the unified diff for a PR, revalidating only when head or base SHA changes.
  @override
  Stream<String> watchDiff(int prNumber) {
    return _swr<String>(
      kind: _Kind.prDiff,
      key: _prKey(prNumber),
      reactToPr: prNumber,
      decode: (raw) => raw,
      fetch: (token) =>
          _client.getPullRequestDiff(prNumber, cancelToken: token),
      encode: (fresh) => fresh,
      skipRevalidate: (_, cancelToken) async {
        // One read+decode of the cached detail for both SHAs.
        final detail = await _cachedPrDetailMap(prNumber);
        final cachedHead = detail?['head_sha'] as String?;
        if (cachedHead == null || cachedHead.isEmpty) {
          return false;
        }
        // A cache entry written before base SHA was tracked can't prove the
        // base branch hasn't moved — revalidate so it's rewritten with a base
        // SHA we can trust next time.
        final cachedBase = detail?['base_sha'] as String?;
        if (cachedBase == null || cachedBase.isEmpty) {
          return false;
        }

        final currentPr = await _client.getPullRequest(
          prNumber,
          cancelToken: cancelToken,
        );
        // Forges render a three-dot diff (merge-base(base, head)…head): the
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
    final signals = _signals;
    final signalIterator = signals == null
        ? null
        : StreamIterator(
            signals.watch(
              workspaceId: _workspaceId,
              repoFullName: _repoFullName,
              prNumber: prNumber,
            ),
          );
    try {
      var isFirstPass = true;
      while (true) {
        yield* _filesLoadPass(
          prNumber,
          cancelToken,
          serveCachedFirst: isFirstPass,
        );
        if (cancelToken.isCancelled || signalIterator == null) {
          return;
        }
        isFirstPass = false;
        // Wait for the next relevant change signal; a checks-only tick can't
        // move the file set, so it never re-runs the (live-PR-probing) pass.
        var relevant = false;
        while (!relevant) {
          final signal = await _nextSignal(signalIterator, cancelToken);
          if (signal == null) {
            return;
          }
          relevant = !signal.checksOnly;
        }
      }
    } finally {
      unawaited(signalIterator?.cancel());
    }
  }

  Stream<PrFilesLoad> _filesLoadPass(
    int prNumber,
    CancelToken cancelToken, {
    required bool serveCachedFirst,
  }) async* {
    // Fetch the live PR first — we need changedFiles to decide the source and
    // to know whether to serve the file cache. One call covers both the SWR
    // check and the changedFiles routing decision.
    PullRequest? currentPr;
    try {
      currentPr = await _client.getPullRequest(
        prNumber,
        cancelToken: cancelToken,
      );
    } catch (e) {
      CcInfraLog.error(
        'PR Files: getPullRequest failed while routing #$prNumber: $e',
        e,
      );
    }

    // Determine the changed-file count robustly. A transient failure of the
    // call above must NOT silently fall back to 0 — that would route a large
    // (>3000-file) PR to the API source, which is capped at 3000 files and
    // never clones, leaving the diff incomplete and pr_clones empty. Fall back
    // to the cached PR detail (populated by watchPullRequest) so the routing
    // decision survives a hiccup.
    var changedFiles = currentPr?.changedFiles ?? 0;
    if (changedFiles == 0) {
      changedFiles = await _cachedChangedFiles(prNumber);
    }
    final useLocalGit = changedFiles > _githubFilesApiLimit;
    CcInfraLog.info(
      'PR Files: routing #$prNumber: changedFiles=$changedFiles useLocalGit=$useLocalGit',
    );

    // Read the cached file list.
    final cached = await _cache.read(
      _workspaceId,
      _Kind.prFiles,
      _prKey(prNumber),
    );
    List<PrFile>? cachedModel;
    if (cached != null) {
      try {
        cachedModel = (await _decodeJsonList(
          cached,
        )).map(PrCacheCodec.fileFromCache).toList(growable: false);
      } catch (_) {}
    }

    if (!useLocalGit) {
      // For API-backed (small) PRs: yield the cached list immediately so the
      // UI renders while we check freshness. Only on the first pass — a
      // signal-driven revalidation would re-emit data the subscriber already
      // holds.
      if (serveCachedFirst && cachedModel != null && cachedModel.isNotEmpty) {
        yield PrFilesLoad(files: cachedModel);
      }

      // SWR fast path: the file list is still current only when BOTH the head
      // and the base SHA are unchanged. GitHub's three-dot diff (and thus the
      // changed-file set) shifts when the base branch moves even if the head
      // is untouched, so head-SHA alone is not enough. A pre-base-sha cache
      // entry (cachedBase null/empty) falls through and re-fetches.
      //
      // A cache entry still holding a withheld patch also falls through, so an
      // entry written before the raw-diff backfill existed (or one whose
      // backfill could not complete) gets another attempt instead of serving
      // an empty body for as long as the PR head sits still.
      if (cachedModel != null &&
          cachedModel.isNotEmpty &&
          !cachedModel.any(_isPatchWithheld)) {
        // One read+decode for both SHAs.
        final detail = await _cachedPrDetailMap(prNumber);
        final cachedSha = detail?['head_sha'] as String?;
        final cachedBase = detail?['base_sha'] as String?;
        if (cachedSha != null &&
            cachedSha.isNotEmpty &&
            cachedBase != null &&
            cachedBase.isNotEmpty &&
            currentPr?.headSha == cachedSha &&
            currentPr?.baseSha == cachedBase) {
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
      baseRef: currentPr?.baseRef ?? 'main',
      headRef: currentPr?.headRef ?? '',
      headSha: currentPr?.headSha ?? '',
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

    // Enrich with the forge's per-file viewed state, where the forge keeps
    // one. Skipped for the local-git source (it has no forge coordinate) and
    // for forges without the capability, whose viewed state is local-only.
    if (!useLocalGit &&
        lastFiles.isNotEmpty &&
        _client.capabilities.viewedStateSync) {
      Map<String, PrFileViewedState> viewedStates = const {};
      try {
        viewedStates = await _client.getFileViewedStates(
          prNumber,
          cancelToken: cancelToken,
        );
      } catch (e) {
        CcInfraLog.error(
          'PR Files: fetching viewerViewedState failed for #$prNumber: $e',
          e,
        );
      }

      if (viewedStates.isNotEmpty) {
        lastFiles = List<PrFile>.unmodifiable([
          for (final f in lastFiles)
            f.copyWith(
              viewerViewedState:
                  viewedStates[f.filename] ?? PrFileViewedState.unviewed,
            ),
        ]);
        yield PrFilesLoad(files: lastFiles, isComplete: true);
      }
    }

    // A forge drops a file's `patch` once that file's diff outgrows its
    // per-file response cap (GitHub withholds it somewhere north of ~100 KB),
    // so the file arrives with real +/- counts and an empty body — the viewer
    // then renders an expanded accordion with nothing inside it. The PR's raw
    // unified diff carries no such per-file cap, so fetch it once and splice
    // the withheld sections back in. Done last so the file tree and every
    // normal patch have already reached the UI; the oversized bodies fill in
    // a beat later. Pure renames carry no patch legitimately and are skipped,
    // which is also what keeps the extra request off the common path.
    if (!useLocalGit && lastFiles.any(_isPatchWithheld)) {
      final backfilled = await _backfillWithheldPatches(
        prNumber,
        lastFiles,
        cancelToken,
      );
      if (backfilled != null) {
        lastFiles = backfilled;
        yield PrFilesLoad(files: lastFiles, isComplete: true);
      }
    }

    if (lastFiles.isNotEmpty) {
      final encoded = await _encodeJson(
        lastFiles.map(PrCacheCodec.fileToCache).toList(growable: false),
        large: true,
      );
      await _putBounded(_Kind.prFiles, _prKey(prNumber), encoded);
    }
  }

  /// Whether the forge reported changed lines for [f] but sent no patch — the
  /// shape a file takes when its diff exceeded the forge's per-file cap. A
  /// pure rename (no changed lines) has no patch to withhold.
  static bool _isPatchWithheld(PrFile f) =>
      f.patch.isEmpty && (f.additions + f.deletions) > 0;

  /// Refills the patches the forge withheld from [files], reading them out of
  /// the PR's raw unified diff.
  ///
  /// Returns null when nothing could be filled — the forge cannot serve a raw
  /// diff, the call failed, or the raw diff was itself truncated — so the
  /// caller keeps the list it already has instead of re-emitting it unchanged.
  Future<List<PrFile>?> _backfillWithheldPatches(
    int prNumber,
    List<PrFile> files,
    CancelToken cancelToken,
  ) async {
    String fullDiff;
    try {
      fullDiff = await _client.getPullRequestDiff(
        prNumber,
        cancelToken: cancelToken,
      );
    } on Object catch (e) {
      if (!_isCancellation(e)) {
        CcInfraLog.error(
          'PR Files: raw-diff backfill failed for #$prNumber: $e',
          e,
        );
      }
      return null;
    }
    if (fullDiff.isEmpty) {
      return null;
    }

    // One pass over the raw diff rather than a scan per withheld file — the
    // diff is large by definition here, so N scans would be O(N × diffLength).
    final sections = extractAllFilePatches(fullDiff);
    var filled = 0;
    final out = <PrFile>[];
    for (final f in files) {
      final patch = _isPatchWithheld(f) ? sections[f.filename] : null;
      if (patch == null || patch.isEmpty) {
        out.add(f);
        continue;
      }
      filled++;
      out.add(f.copyWith(patch: patch));
    }
    if (filled == 0) {
      return null;
    }
    CcInfraLog.info(
      'PR Files: backfilled $filled withheld patch(es) for #$prNumber from '
      'the raw diff',
    );
    return List<PrFile>.unmodifiable(out);
  }

  /// Watches the raw content of a file at a given ref, served from cache with
  /// SWR. Deliberately non-reactive: content at a resolved ref is effectively
  /// immutable, so change signals would only re-fetch identical bytes.
  @override
  Stream<String> watchFileContent(String path, String ref) {
    return _swr<String>(
      kind: _Kind.prFileContent,
      key: '$_repoFullName|$path|$ref',
      decode: (raw) => raw,
      fetch: (token) => _client.getFileContent(path, ref, cancelToken: token),
      encode: (fresh) => fresh,
    );
  }

  /// Watches the list of commits for a PR, served from cache with SWR revalidation.
  @override
  Stream<List<PrCommit>> watchCommits(int prNumber) {
    return _swr<List<PrCommit>>(
      kind: _Kind.prCommits,
      key: _prKey(prNumber),
      reactToPr: prNumber,
      decode: (raw) async => (await _decodeJsonList(
        raw,
      )).map(PrCacheCodec.commitFromCache).toList(growable: false),
      fetch: (token) => _client.listCommits(prNumber, cancelToken: token),
      encode: (fresh) => _encodeJson(
        fresh.map(PrCacheCodec.commitToCache).toList(growable: false),
      ),
    );
  }

  /// Watches the list of changed files for a specific commit SHA.
  @override
  Stream<List<PrFile>> watchCommitFiles(String sha) {
    if (sha.isEmpty) {
      return Stream.value(const <PrFile>[]);
    }
    // Non-reactive: a commit's file set is immutable per SHA.
    return _swr<List<PrFile>>(
      kind: _Kind.prCommitFiles,
      key: _shaKey(sha),
      decode: (raw) async => (await _decodeJsonList(
        raw,
      )).map(PrCacheCodec.fileFromCache).toList(growable: false),
      fetch: (token) => _client.listCommitFiles(sha, cancelToken: token),
      encode: (fresh) => _encodeJson(
        fresh.map(PrCacheCodec.fileToCache).toList(growable: false),
        large: true,
      ),
    );
  }

  /// Watches the list of review submissions for a PR.
  @override
  Stream<List<PrReviewSubmission>> watchReviews(int prNumber) {
    return _swr<List<PrReviewSubmission>>(
      kind: _Kind.prReviews,
      key: _prKey(prNumber),
      reactToPr: prNumber,
      decode: (raw) async => (await _decodeJsonList(
        raw,
      )).map(PrCacheCodec.reviewFromCache).toList(growable: false),
      fetch: (token) => _client.listReviews(prNumber, cancelToken: token),
      encode: (fresh) => _encodeJson(
        fresh.map(PrCacheCodec.reviewToCache).toList(growable: false),
      ),
    );
  }

  /// Watches the conversation-timeline events (review requests / removals)
  /// for a PR.
  @override
  Stream<List<PrTimelineEvent>> watchTimelineEvents(int prNumber) {
    return _swr<List<PrTimelineEvent>>(
      kind: _Kind.prTimelineEvents,
      key: _prKey(prNumber),
      reactToPr: prNumber,
      decode: (raw) async => (await _decodeJsonList(
        raw,
      )).map(PrCacheCodec.timelineEventFromCache).toList(growable: false),
      fetch: (token) =>
          _client.listTimelineEvents(prNumber, cancelToken: token),
      encode: (fresh) => _encodeJson(
        fresh.map(PrCacheCodec.timelineEventToCache).toList(growable: false),
      ),
    );
  }

  /// Watches review comments for a PR, enriching reactions with per-user state.
  @override
  Stream<List<PrCodeReviewComment>> watchReviewComments(int prNumber) {
    return _swr<List<PrCodeReviewComment>>(
      kind: _Kind.prReviewComments,
      key: _prKey(prNumber),
      reactToPr: prNumber,
      decode: (raw) async => (await _decodeJsonList(
        raw,
      )).map(PrCacheCodec.reviewCommentFromCache).toList(growable: false),
      fetch: (token) async {
        final comments = await _client.listReviewComments(
          prNumber,
          cancelToken: token,
        );
        return _enrichCommentReactions(
          comments,
          prNumber: prNumber,
          cancelToken: token,
        );
      },
      encode: (fresh) => _encodeJson(
        fresh.map(PrCacheCodec.reviewCommentToCache).toList(growable: false),
        large: true,
      ),
    );
  }

  Future<List<PrCodeReviewComment>> _enrichCommentReactions(
    List<PrCodeReviewComment> comments, {
    required int prNumber,
    Object? cancelToken,
  }) async {
    if (!_client.capabilities.reactions) {
      return comments;
    }
    // Concurrent, bounded. One forge round trip per reacted comment run
    // SEQUENTIALLY meant a PR with 30 reacted comments paid 30 serial round
    // trips on every SWR revalidation pass; the concurrency cap keeps that
    // from turning into a burst the forge rate-limits.
    return _mapBounded(comments, (c) async {
      if (c.reactions.isEmpty) {
        return c;
      }
      try {
        return c.copyWith(
          reactions: await _reactionGroupsWithUser(
            c.reactions,
            target: ForgeReactionTarget.reviewComment,
            targetId: '${c.id}',
            prNumber: prNumber,
            cancelToken: cancelToken,
          ),
        );
      } catch (e) {
        CcInfraLog.error(
          'Comment Reactions: enrichment failed for #${c.id}: $e',
          e,
        );
        return c;
      }
    });
  }

  /// How many reaction round trips may be in flight at once.
  static const int _reactionEnrichConcurrency = 6;

  /// Maps [items] through [f] with at most [_reactionEnrichConcurrency] in
  /// flight, preserving input order.
  static Future<List<T>> _mapBounded<T>(
    List<T> items,
    Future<T> Function(T item) f,
  ) async {
    final out = List<T?>.filled(items.length, null);
    var next = 0;
    Future<void> worker() async {
      while (true) {
        final i = next++;
        if (i >= items.length) {
          return;
        }
        out[i] = await f(items[i]);
      }
    }

    final lanes = items.length < _reactionEnrichConcurrency
        ? items.length
        : _reactionEnrichConcurrency;
    await Future.wait([for (var i = 0; i < lanes; i++) worker()]);
    return [for (final item in out) item as T];
  }

  /// Watches issue comments for a PR, enriching reactions with per-user state.
  @override
  Stream<List<IssueComment>> watchIssueComments(int prNumber) {
    return _swr<List<IssueComment>>(
      kind: _Kind.prIssueComments,
      key: _prKey(prNumber),
      reactToPr: prNumber,
      decode: (raw) async => (await _decodeJsonList(
        raw,
      )).map(PrCacheCodec.issueCommentFromCache).toList(growable: false),
      fetch: (token) async {
        final comments = await _client.listIssueComments(
          prNumber,
          cancelToken: token,
        );
        return _enrichIssueCommentReactions(
          comments,
          prNumber: prNumber,
          cancelToken: token,
        );
      },
      encode: (fresh) => _encodeJson(
        fresh.map(PrCacheCodec.issueCommentToCache).toList(growable: false),
        large: true,
      ),
    );
  }

  Future<List<IssueComment>> _enrichIssueCommentReactions(
    List<IssueComment> comments, {
    required int prNumber,
    Object? cancelToken,
  }) async {
    if (!_client.capabilities.reactions) {
      return comments;
    }
    return _mapBounded(comments, (c) async {
      if (c.reactions.isEmpty) {
        return c;
      }
      try {
        return c.copyWith(
          reactions: await _reactionGroupsWithUser(
            c.reactions,
            target: ForgeReactionTarget.issueComment,
            targetId: '${c.id}',
            prNumber: prNumber,
            cancelToken: cancelToken,
          ),
        );
      } catch (e) {
        CcInfraLog.error(
          'IssueComment Reactions: enrichment for #${c.id}: $e',
          e,
        );
        return c;
      }
    });
  }

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
    // The check-runs cache is keyed by head SHA, which itself moves when the
    // PR gets a new push — so the reactive loop lives out here where the SHA
    // can be re-resolved per pass, instead of inside the (fixed-key) SWR
    // helper. Reacts to checks-only signals too: that's the poll that exists
    // for this stream.
    final signals = _signals;
    final signalIterator = signals == null
        ? null
        : StreamIterator(
            signals.watch(
              workspaceId: _workspaceId,
              repoFullName: _repoFullName,
              prNumber: prNumber,
            ),
          );
    final state = _SwrState();
    try {
      var isFirstPass = true;
      while (true) {
        final sha = await _resolveHeadSha(
          prNumber,
          cancelToken,
          rethrowOnFailure: isFirstPass,
        );
        if (cancelToken.isCancelled) {
          return;
        }
        if (sha == null || sha.isEmpty) {
          if (isFirstPass) {
            yield const <CheckRun>[];
          }
        } else {
          yield* _checkRunsPass(cancelToken, state, sha, isFirstPass);
          if (state.cancelled || cancelToken.isCancelled) {
            return;
          }
        }
        if (signalIterator == null) {
          return;
        }
        isFirstPass = false;
        if (await _nextSignal(signalIterator, cancelToken) == null) {
          return;
        }
      }
    } finally {
      unawaited(signalIterator?.cancel());
    }
  }

  /// Resolves the PR's head SHA: from the cached PR detail when available,
  /// falling back to a live fetch. Cancellations return null quietly; other
  /// live-fetch failures rethrow only when [rethrowOnFailure] (the first pass
  /// keeps the original error contract; a reactive pass must not kill the
  /// long-lived stream over a transient hiccup).
  Future<String?> _resolveHeadSha(
    int prNumber,
    CancelToken cancelToken, {
    required bool rethrowOnFailure,
  }) async {
    final sha = await _cachedHeadSha(prNumber);
    if (sha != null && sha.isNotEmpty) {
      return sha;
    }
    try {
      return (await _client.getPullRequest(
        prNumber,
        cancelToken: cancelToken,
      ))?.headSha;
    } on Object catch (error) {
      // Same crash class as the diff path: navigating away while check runs
      // load cancels this in-flight request. Swallow the cancellation so it
      // can't escape as a fatal unhandled error.
      if (_isCancellation(error)) {
        return null;
      }
      if (rethrowOnFailure) {
        rethrow;
      }
      return null;
    }
  }

  Stream<List<CheckRun>> _checkRunsPass(
    CancelToken cancelToken,
    _SwrState state,
    String sha,
    bool isFirstPass,
  ) {
    return _swrPass<List<CheckRun>>(
      cancelToken,
      state,
      kind: _Kind.prCheckRuns,
      key: _shaKey(sha),
      isFirstPass: isFirstPass,
      decode: (raw) async => (await _decodeJsonList(
        raw,
      )).map(PrCacheCodec.checkRunFromCache).toList(growable: false),
      // Collapsing superseded runs and joining each check to its workflow and
      // job is forge-specific plumbing, so it lives in the adapter. What
      // arrives here is already the visible set.
      fetch: (token) => _client.listCheckRuns(sha, cancelToken: token),
      encode: (fresh) => _encodeJson(
        fresh.map(PrCacheCodec.checkRunToCache).toList(growable: false),
      ),
    );
  }

  @override
  Future<JobRunDetail?> getJobRunDetail(int jobId) {
    if (!_client.capabilities.ciJobDetail) {
      return Future.value();
    }
    return _client.getJobRunDetail(jobId);
  }

  @override
  Future<WorkflowGraph?> getWorkflowGraph(int workflowRunId) {
    if (!_client.capabilities.ciJobDetail) {
      return Future.value();
    }
    return _client.getWorkflowGraph(workflowRunId);
  }

  @override
  Stream<List<CommitStatus>> watchCommitStatuses(int prNumber) {
    return _cancellable(
      (cancelToken) => _watchCommitStatuses(prNumber, cancelToken),
    );
  }

  Stream<List<CommitStatus>> _watchCommitStatuses(
    int prNumber,
    CancelToken cancelToken,
  ) async* {
    // Same SHA-keyed, signal-driven loop as the check-runs stream: statuses
    // hang off the head SHA, which moves on a new push.
    final signals = _signals;
    final signalIterator = signals == null
        ? null
        : StreamIterator(
            signals.watch(
              workspaceId: _workspaceId,
              repoFullName: _repoFullName,
              prNumber: prNumber,
            ),
          );
    final state = _SwrState();
    try {
      var isFirstPass = true;
      while (true) {
        final sha = await _resolveHeadSha(
          prNumber,
          cancelToken,
          rethrowOnFailure: isFirstPass,
        );
        if (cancelToken.isCancelled) {
          return;
        }
        if (sha == null || sha.isEmpty) {
          if (isFirstPass) {
            yield const <CommitStatus>[];
          }
        } else {
          yield* _commitStatusesPass(cancelToken, state, sha, isFirstPass);
          if (state.cancelled || cancelToken.isCancelled) {
            return;
          }
        }
        if (signalIterator == null) {
          return;
        }
        isFirstPass = false;
        if (await _nextSignal(signalIterator, cancelToken) == null) {
          return;
        }
      }
    } finally {
      unawaited(signalIterator?.cancel());
    }
  }

  Stream<List<CommitStatus>> _commitStatusesPass(
    CancelToken cancelToken,
    _SwrState state,
    String sha,
    bool isFirstPass,
  ) {
    return _swrPass<List<CommitStatus>>(
      cancelToken,
      state,
      kind: _Kind.prCommitStatuses,
      key: _shaKey(sha),
      isFirstPass: isFirstPass,
      decode: (raw) async => (await _decodeJsonList(
        raw,
      )).map(PrCacheCodec.commitStatusFromCache).toList(growable: false),
      fetch: (token) => _client.listCommitStatuses(sha, cancelToken: token),
      encode: (fresh) => _encodeJson(
        fresh.map(PrCacheCodec.commitStatusToCache).toList(growable: false),
      ),
    );
  }

  /// Invalidates all cached data for a PR and signals open watch streams (for
  /// every subscriber, on every connected client) to re-fetch.
  @override
  Future<void> invalidatePullRequest(int prNumber) async {
    final key = _prKey(prNumber);
    for (final kind in _Kind.prScoped) {
      await _cache.deleteEntry(_workspaceId, kind, key);
    }
    _notifyPrChanged(prNumber);
  }

  /// Invalidates the diff and files cache for a PR and signals open watch
  /// streams to re-fetch.
  @override
  Future<void> invalidateDiff(int prNumber) async {
    final key = _prKey(prNumber);
    await _cache.deleteEntry(_workspaceId, _Kind.prDiff, key);
    await _cache.deleteEntry(_workspaceId, _Kind.prFiles, key);
    _notifyPrChanged(prNumber);
  }

  /// Marks or unmarks a file as viewed in a PR.
  @override
  Future<void> markFileAsViewed({
    required int prNumber,
    required String externalId,
    required String path,
    required bool viewed,
  }) async {
    // Forges without a viewed-state API still get the local patch below, so
    // the toggle keeps working — it just does not follow the operator to
    // another device.
    if (_client.capabilities.viewedStateSync) {
      await _client.setFileViewedState(
        prNumber: prNumber,
        prExternalId: externalId,
        path: path,
        viewed: viewed,
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
    final raw = await _cache.read(
      _workspaceId,
      _Kind.prFiles,
      _prKey(prNumber),
    );
    if (raw == null) {
      return;
    }
    final list = await _decodeJsonList(raw);
    final wire = viewed
        ? PrFileViewedState.viewed.name
        : PrFileViewedState.unviewed.name;
    var dirty = false;
    final updated = <Map<String, dynamic>>[];
    for (final entry in list) {
      if (entry['filename'] == path) {
        if (entry['viewed_state'] != wire) {
          dirty = true;
        }
        updated.add({...entry, 'viewed_state': wire});
      } else {
        updated.add(entry);
      }
    }
    if (dirty) {
      await _cache.put(
        _workspaceId,
        _Kind.prFiles,
        _prKey(prNumber),
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
    final result = await _client.postReviewComment(
      prNumber: prNumber,
      commitSha: commitSha,
      path: path,
      line: line,
      side: side,
      startLine: startLine,
      startSide: startSide,
      body: body,
    );
    return {'id': result?.id ?? 0};
  }

  /// Replies to an existing review comment on a PR.
  @override
  Future<void> replyToReviewComment({
    required int prNumber,
    required int parentCommentId,
    required String body,
  }) async {
    await _client.replyToReviewComment(
      prNumber: prNumber,
      parentCommentId: '$parentCommentId',
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
    return _client.uploadContent(
      path: path,
      base64Content: base64Content,
      message: message,
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
    await _toggleReaction(
      target: ForgeReactionTarget.reviewComment,
      targetId: '$commentId',
      prNumber: prNumber,
      content: content,
      add: add,
      invalidates: const [_Kind.prReviewComments],
    );
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
    await _toggleReaction(
      target: ForgeReactionTarget.issueComment,
      targetId: '$commentId',
      prNumber: prNumber,
      content: content,
      add: add,
      invalidates: const [_Kind.prIssueComments],
    );
  }

  /// Toggles a reaction on a pull request.
  @override
  Future<void> togglePullRequestReaction({
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) async {
    await _toggleReaction(
      target: ForgeReactionTarget.pullRequest,
      targetId: '$prNumber',
      prNumber: prNumber,
      content: content,
      add: add,
      invalidates: const [_Kind.prDetail],
    );
  }

  /// The one reaction write path: the three public toggles differ only in what
  /// they target and which cache kind goes stale.
  ///
  /// A no-op on forges without reactions rather than a throw — the affordance
  /// is already hidden there, so reaching this is a bug in the caller, not
  /// something worth failing the user's click over.
  Future<void> _toggleReaction({
    required ForgeReactionTarget target,
    required String targetId,
    required int prNumber,
    required String content,
    required bool add,
    required List<String> invalidates,
  }) async {
    if (!_client.capabilities.reactions) {
      return;
    }
    await _client.toggleReaction(
      target: target,
      targetId: targetId,
      prNumber: prNumber,
      content: content,
      add: add,
    );
    await _invalidatePrKinds(prNumber, invalidates);
  }

  /// Invalidates [kinds] for [prNumber] and signals open watch streams once —
  /// a mutation's targeted cache-bust, so every subscriber (this client and
  /// any other connected one) refreshes without pressing anything.
  Future<void> _invalidatePrKinds(int prNumber, List<String> kinds) async {
    for (final kind in kinds) {
      await _cache.deleteEntry(_workspaceId, kind, _prKey(prNumber));
    }
    _notifyPrChanged(prNumber);
  }

  /// Submits a review (approve, request changes, or comment).
  @override
  Future<void> submitReview({
    required int prNumber,
    required String event,
    String? body,
  }) async {
    await _client.submitReview(
      prNumber: prNumber,
      verdict: switch (event) {
        'APPROVE' => ForgeReviewVerdict.approve,
        'REQUEST_CHANGES' => ForgeReviewVerdict.requestChanges,
        _ => ForgeReviewVerdict.comment,
      },
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
    // Ignored server-side: the dispatcher's write ledger already deduped this
    // call by key before the handler ran (PRD 19 §3), so a replay never reaches
    // GitHub here.
    String? idempotencyKey,
  }) async {
    final result = await _client.mergePullRequest(
      prNumber: prNumber,
      method: ForgeMergeMethod.fromWire(mergeMethod),
      commitTitle: commitTitle,
      commitMessage: commitMessage,
    );
    await invalidatePullRequest(prNumber);
    _emitStatusChanged('merged', prNumber);
    return result.toJson();
  }

  /// Closes a pull request.
  @override
  Future<void> closePullRequest({required int prNumber}) async {
    await _client.closePullRequest(prNumber);
    await invalidatePullRequest(prNumber);
    _emitStatusChanged('closed', prNumber);
  }

  // ── PR stacks ── thin delegations to the forge. Stacks are deliberately NOT
  // cached: they change on every restack/merge and the list is cheap (a single
  // endpoint), so staleness would buy nothing. Only GitHub has them; elsewhere
  // the capability is false and the UI never offers the affordance.

  /// Lists the repo's pull request stacks, optionally filtered to the stack
  /// containing [prNumber]. Empty on forges without stacks.
  @override
  Future<List<PrStack>> listStacks({int? prNumber}) {
    if (!_client.capabilities.stacks) {
      return Future.value(const <PrStack>[]);
    }
    return _client.listStacks(prNumber: prNumber);
  }

  /// Creates a stack from [prNumbers], ordered bottom to top.
  @override
  Future<PrStack> createStack({required List<int> prNumbers}) async {
    final stack = await _client.createStack(prNumbers: prNumbers);
    for (final entry in stack.pullRequests) {
      await invalidatePullRequest(entry.number);
    }
    return stack;
  }

  /// Appends [prNumbers] onto the top of the stack [stackNumber].
  @override
  Future<PrStack?> addToStack({
    required int stackNumber,
    required List<int> prNumbers,
  }) async {
    final stack = await _client.addToStack(
      stackNumber: stackNumber,
      prNumbers: prNumbers,
    );
    for (final entry in stack?.pullRequests ?? const <PrStackEntry>[]) {
      await invalidatePullRequest(entry.number);
    }
    return stack;
  }

  /// Removes the unmerged PRs from the stack [stackNumber]; null when the
  /// stack dissolved.
  @override
  Future<PrStack?> unstack({required int stackNumber}) async {
    final stack = await _client.unstack(stackNumber: stackNumber);
    if (stack == null) {
      return null;
    }
    for (final entry in stack.pullRequests) {
      await invalidatePullRequest(entry.number);
    }
    return stack;
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
    await _client.updatePullRequest(
      prNumber: prNumber,
      title: title,
      body: body,
    );
    // Targeted: only the PR detail changed — don't nuke the (expensive) diff/
    // files/commits caches the way the full invalidatePullRequest would.
    await _invalidatePrKinds(prNumber, const [_Kind.prDetail]);
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
    await _client.addAssignees(prNumber: prNumber, logins: logins);
    await _invalidatePrKinds(prNumber, const [_Kind.prDetail]);
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
    await _client.removeAssignees(prNumber: prNumber, logins: logins);
    await _invalidatePrKinds(prNumber, const [_Kind.prDetail]);
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
    await _client.requestReviewers(
      prNumber: prNumber,
      userLogins: userLogins,
      teamSlugs: _client.capabilities.teamReviewers ? teamSlugs : const [],
    );
    await _invalidatePrKinds(prNumber, const [
      _Kind.prReviewerState,
      _Kind.prDetail,
    ]);
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
    await _client.removeRequestedReviewers(
      prNumber: prNumber,
      userLogins: userLogins,
      teamSlugs: _client.capabilities.teamReviewers ? teamSlugs : const [],
    );
    await _invalidatePrKinds(prNumber, const [
      _Kind.prReviewerState,
      _Kind.prDetail,
    ]);
  }

  /// Watches the enriched reviewer state for a PR.
  @override
  Stream<List<PrReviewer>> watchReviewers(int prNumber) {
    return _swr<List<PrReviewer>>(
      kind: _Kind.prReviewerState,
      key: _prKey(prNumber),
      reactToPr: prNumber,
      decode: (raw) async => (await _decodeJsonList(
        raw,
      )).map(PrCacheCodec.reviewerFromCache).toList(growable: false),
      fetch: (token) async {
        final state = await _client.getReviewerState(
          prNumber,
          cancelToken: token,
        );
        // The forge reports code ownership only while the review request is
        // still outstanding, so remember every identity ever seen owning this
        // PR and re-apply the union — otherwise the code-owner shield vanishes
        // the moment the owner actually reviews.
        final known = await _mergeCodeOwnerIds(
          prNumber,
          state.codeOwnerIdentities,
        );
        if (known.isEmpty) {
          return state.reviewers;
        }
        return [
          for (final r in state.reviewers)
            known.contains(r.identity) && !r.isCodeOwner ? r.asCodeOwner() : r,
        ];
      },
      encode: (fresh) => _encodeJson(
        fresh.map(PrCacheCodec.reviewerToCache).toList(growable: false),
      ),
    );
  }

  /// Unions `newIds` into the persisted per-PR code-owner identity set and
  /// returns the updated set. Lets a code-owner shield persist after the
  /// reviewer's request is consumed by a review (a forge drops the flag
  /// once the request is satisfied). Writes back only when the set grows.
  Future<Set<String>> _mergeCodeOwnerIds(
    int prNumber,
    Set<String> newIds,
  ) async {
    final raw = await _cache.read(
      _workspaceId,
      _Kind.prCodeOwnerIds,
      _prKey(prNumber),
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
        _prKey(prNumber),
        await _encodeJson(<String, dynamic>{'ids': merged.toList()}),
      );
    }
    return merged;
  }

  /// Lists users who can be assigned to PRs in this repository.
  @override
  Future<List<PrUser>> listAssignableUsers() async {
    final cached = await _readEnvelope(_Kind.assignableUsers, _repoFullName);
    if (cached != null) {
      return cached.map(_prUserFromEnvelope).toList(growable: false);
    }
    final users = await _client.listAssignableUsers();
    final items = <Map<String, dynamic>>[
      for (final u in users) _prUserToEnvelope(u),
    ];
    await _writeEnvelope(_Kind.assignableUsers, _repoFullName, items);
    return items.map(_prUserFromEnvelope).toList(growable: false);
  }

  /// Lists all eligible reviewer candidates (users and teams) for this
  /// repository, TTL-cached like the assignable-user list.
  @override
  Future<List<PrReviewerCandidate>> listRequestableReviewers() async {
    final cached = await _readEnvelope(_Kind.requestableTeams, _repoFullName);
    if (cached != null) {
      return cached.map(_candidateFromEnvelope).toList(growable: false);
    }
    final candidates = await _client.listRequestableReviewers();
    final items = <Map<String, dynamic>>[
      for (final c in candidates)
        {
          'kind': c.kind.name,
          'key': c.key,
          'label': c.label,
          if (c.avatarUrl != null) 'avatar_url': c.avatarUrl,
        },
    ];
    await _writeEnvelope(_Kind.requestableTeams, _repoFullName, items);
    return items.map(_candidateFromEnvelope).toList(growable: false);
  }

  static PrReviewerCandidate _candidateFromEnvelope(Map<String, dynamic> m) =>
      PrReviewerCandidate(
        kind: m['kind'] == 'team' ? ReviewerKind.team : ReviewerKind.user,
        key: m['key'] as String? ?? '',
        label: m['label'] as String? ?? '',
        avatarUrl: m['avatar_url'] as String?,
      );

  /// The forge's suggested reviewers for a PR. Fetched fresh: the suggestion
  /// set shifts with each push, so it is not TTL-cached like the repo-wide
  /// candidate lists. Empty on forges that make no suggestions.
  @override
  Future<List<PrUser>> listSuggestedReviewers(int prNumber) {
    if (!_client.capabilities.suggestedReviewers) {
      return Future.value(const <PrUser>[]);
    }
    return _client.listSuggestedReviewers(prNumber);
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

  Map<String, dynamic> _prUserToEnvelope(PrUser u) => <String, dynamic>{
    'login': u.login,
    'avatar_url': u.avatarUrl,
    'name': ?u.name,
  };

  PrUser _prUserFromEnvelope(Map<String, dynamic> m) {
    final rawName = (m['name'] as String?)?.trim();
    return PrUser(
      login: m['login'] as String? ?? '',
      avatarUrl: m['avatar_url'] as String? ?? '',
      name: (rawName == null || rawName.isEmpty) ? null : rawName,
    );
  }

  /// Publishes a [PullRequestStatusChanged] so pipeline triggers (e.g. the
  /// stale-repository cleanup / release-notes pipelines) can react to merges,
  /// closes and user approvals.
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
}

// EmptyPrReviewRepository is defined in pr_review_repository.dart (domain layer).

/// One in-flight upstream fetch. A holder rather than a bare `Future` so the
/// leader can compare identity in its `finally` without the analyzer reading
/// the map lookup as an unawaited future.
class _InflightFetch {
  _InflightFetch(this.future);

  final Future<Object?> future;
}
