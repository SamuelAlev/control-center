import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/forge/forge_pr_client_resolver.dart';
import 'package:cc_server_core/src/pr_review/open_pr_polling_service.dart';

/// An [OpenPrFetchPort] for any forge, driven per repo through its
/// [ForgePrClient].
///
/// GitHub keeps its own adapter because its GraphQL API can answer for many
/// repos in a single round trip. Everywhere else there is no batch endpoint, so
/// this asks each repo in parallel — which is also why one repo's failure is
/// contained here rather than failing the whole group.
class ForgeClientOpenPrFetchAdapter implements OpenPrFetchPort {
  /// Creates a [ForgeClientOpenPrFetchAdapter].
  const ForgeClientOpenPrFetchAdapter(this._clientFor);

  final ForgePrClientResolver _clientFor;

  /// No conditional-request support outside GitHub, so the probe is one
  /// small read instead: the open list's first page of size one, ordered by
  /// update, plus the open count ([ForgeOpenPrChangeProbeClient]). Its
  /// fingerprint stands in for the ETag, and the full list is re-read only
  /// when it moves.
  ///
  /// A forge client without the probe reports "changed" every pass: guessing
  /// "unchanged" would silently freeze a repo's queue. A failed probe
  /// propagates, so the poller can classify an access denial.
  @override
  Future<({bool changed, String? etag})> probeRepo(
    Repo repo,
    String? etag, {
    required String workspaceId,
  }) async {
    final client = _clientFor(repo, workspaceId: workspaceId);
    if (client is! ForgeOpenPrChangeProbeClient) {
      return (changed: true, etag: null);
    }
    final fingerprint = await (client as ForgeOpenPrChangeProbeClient)
        .openPullRequestsFingerprint();
    return (changed: fingerprint != etag, etag: fingerprint);
  }

  @override
  Future<OpenPrFetchResult> fetchGroups(
    List<Repo> repos, {
    required String workspaceId,
  }) async {
    final groups = <OpenPrGroup>[];
    final resolved = <String>{};

    await Future.wait(
      repos.map((repo) async {
        try {
          final page = await _clientFor(
            repo,
            workspaceId: workspaceId,
          ).listOpenPullRequests();
          // Recorded before the empty check: a repo with a genuinely empty
          // queue is still an answer, and the poller relies on that difference
          // to tell "no open PRs" from "the forge did not respond".
          resolved.add(repo.id);
          if (page.prs.isNotEmpty) {
            groups.add((
              repo: repo,
              prs: page.prs,
              hasMore: page.hasMore,
              totalCount: page.hasMore ? null : page.prs.length,
            ));
          }
        } on Object catch (e) {
          CcHostLog.warning(
            'open_pr_poll: ${repo.forge.displayName} list failed for '
            '${repo.fullName}: $e',
          );
        }
      }),
    );

    return (groups: groups, resolvedRepoIds: resolved);
  }

  /// The checks overlay arrives with the list on these forges, so the
  /// status-only pass has nothing extra to fetch.
  @override
  Future<Map<String, Map<int, PrStatusOverlay>>> fetchChecks(
    List<Repo> repos, {
    required String workspaceId,
  }) => Future.value(const {});

  @override
  Future<bool?> wasMerged(
    Repo repo,
    int prNumber, {
    required String workspaceId,
  }) =>
      _clientFor(repo, workspaceId: workspaceId).wasMerged(prNumber);

  @override
  Future<List<PullRequest>?> fetchBranchHistory(
    Repo repo,
    String branch, {
    required String workspaceId,
  }) async {
    final client = _clientFor(repo, workspaceId: workspaceId);
    // Gated on the declared capability, not a type test: a forge that claims
    // branch history but forgets the interface fails loudly here instead of
    // silently answering "unavailable" forever.
    if (!client.capabilities.has(ForgeCapability.branchHistory)) {
      return null;
    }
    try {
      return await (client as ForgeBranchPrHistoryClient)
          .listPullRequestsForBranch(branch);
    } on Object catch (e) {
      CcHostLog.warning(
        'open_pr_poll: ${repo.forge.displayName} branch history failed for '
        '${repo.fullName}: $e',
      );
      return null;
    }
  }

  /// The forge's merge-signal reads, or null when it declares none. A forge
  /// without them answers "not confirmed" / "unattributed" rather than a wrong
  /// value: merge readiness then falls back to the derived heuristic, an
  /// approval notification goes out without a name, and a failed-checks
  /// notification without the check name — the copy degrades, never the
  /// correctness.
  ForgeMergeSignalsClient? _signalsFor(Repo repo, String workspaceId) {
    final client = _clientFor(repo, workspaceId: workspaceId);
    return client.capabilities.has(ForgeCapability.mergeSignals)
        ? client as ForgeMergeSignalsClient
        : null;
  }

  Future<T> _signal<T>(
    Repo repo,
    String what,
    T fallback,
    Future<T> Function(ForgeMergeSignalsClient c) read, {
    required String workspaceId,
  }) async {
    final client = _signalsFor(repo, workspaceId);
    if (client == null) {
      return fallback;
    }
    try {
      return await read(client);
    } on Object catch (e) {
      CcHostLog.warning(
        'open_pr_poll: ${repo.forge.displayName} $what lookup failed for '
        '${repo.fullName}: $e',
      );
      return fallback;
    }
  }

  @override
  Future<PrMergeableState> mergeState(
    Repo repo,
    int prNumber, {
    required String workspaceId,
  }) => _signal(
    repo,
    'mergeability',
    PrMergeableState.unknown,
    (c) => c.mergeState(prNumber),
    workspaceId: workspaceId,
  );

  @override
  Future<String?> latestApprover(
    Repo repo,
    int prNumber, {
    required String workspaceId,
  }) => _signal(
    repo,
    'approver',
    null,
    (c) => c.latestApprover(prNumber),
    workspaceId: workspaceId,
  );

  @override
  Future<({String name, String? url})?> firstFailingCheck(
    Repo repo,
    int prNumber, {
    required String workspaceId,
  }) => _signal(
    repo,
    'check-run',
    null,
    (c) => c.firstFailingCheck(prNumber),
    workspaceId: workspaceId,
  );
}

/// The [OpenPrFetchPort] the workspace poller actually runs on: a fan-out over
/// every forge represented in the workspace.
///
/// This is what makes a mixed workspace work. Repos are grouped by
/// [Repo.forge], each group goes to that forge's own adapter, and the results
/// are merged into one snapshot — so the inbox interleaves GitHub pull requests
/// and Bitbucket pull requests without either side knowing about the other.
///
/// **Failures are isolated per forge.** A forge that is down, rate-limited or
/// unauthenticated contributes no groups and, crucially, no resolved repo ids —
/// the poller then keeps that forge's previous entries and leaves every other
/// forge's fresh data untouched. One broken connection must never empty the
/// whole inbox.
class MultiForgeOpenPrFetchAdapter implements OpenPrFetchPort {
  /// Creates a [MultiForgeOpenPrFetchAdapter] over per-forge [delegates].
  const MultiForgeOpenPrFetchAdapter(this.delegates);

  /// One adapter per forge the server can talk to. A repo whose forge is absent
  /// is skipped entirely.
  final Map<ForgeHost, OpenPrFetchPort> delegates;

  OpenPrFetchPort? _delegateFor(Repo repo) => delegates[repo.forge];

  static Map<ForgeHost, List<Repo>> _byForge(List<Repo> repos) {
    final grouped = <ForgeHost, List<Repo>>{};
    for (final repo in repos) {
      (grouped[repo.forge] ??= []).add(repo);
    }
    return grouped;
  }

  @override
  Future<({bool changed, String? etag})> probeRepo(
    Repo repo,
    String? etag, {
    required String workspaceId,
  }) async {
    final delegate = _delegateFor(repo);
    if (delegate == null) {
      return (changed: false, etag: null);
    }
    return delegate.probeRepo(repo, etag, workspaceId: workspaceId);
  }

  @override
  Future<OpenPrFetchResult> fetchGroups(
    List<Repo> repos, {
    required String workspaceId,
  }) async {
    final grouped = _byForge(repos);
    final groups = <OpenPrGroup>[];
    final resolved = <String>{};

    await Future.wait(
      grouped.entries.map((entry) async {
        final delegate = delegates[entry.key];
        if (delegate == null) {
          return;
        }
        try {
          final result = await delegate.fetchGroups(
            entry.value,
            workspaceId: workspaceId,
          );
          groups.addAll(result.groups);
          resolved.addAll(result.resolvedRepoIds);
        } on Object catch (e) {
          // Contribute nothing: the poller keeps this forge's previous entries
          // and every other forge's results still land.
          CcHostLog.warning(
            'open_pr_poll: ${entry.key.displayName} fetch failed for '
            '${entry.value.length} repo(s): $e',
          );
        }
      }),
    );

    return (groups: groups, resolvedRepoIds: resolved);
  }

  @override
  Future<Map<String, Map<int, PrStatusOverlay>>> fetchChecks(
    List<Repo> repos, {
    required String workspaceId,
  }) async {
    final grouped = _byForge(repos);
    final merged = <String, Map<int, PrStatusOverlay>>{};

    await Future.wait(
      grouped.entries.map((entry) async {
        final delegate = delegates[entry.key];
        if (delegate == null) {
          return;
        }
        try {
          merged.addAll(
            await delegate.fetchChecks(entry.value, workspaceId: workspaceId),
          );
        } on Object catch (e) {
          CcHostLog.warning(
            'open_pr_poll: ${entry.key.displayName} checks pass failed: $e',
          );
        }
      }),
    );

    return merged;
  }

  @override
  Future<bool?> wasMerged(
    Repo repo,
    int prNumber, {
    required String workspaceId,
  }) async {
    final delegate = _delegateFor(repo);
    if (delegate == null) {
      return null;
    }
    return delegate.wasMerged(repo, prNumber, workspaceId: workspaceId);
  }

  @override
  Future<List<PullRequest>?> fetchBranchHistory(
    Repo repo,
    String branch, {
    required String workspaceId,
  }) async {
    final delegate = _delegateFor(repo);
    if (delegate == null) {
      return null;
    }
    return delegate.fetchBranchHistory(repo, branch, workspaceId: workspaceId);
  }

  @override
  Future<PrMergeableState> mergeState(
    Repo repo,
    int prNumber, {
    required String workspaceId,
  }) async {
    final delegate = _delegateFor(repo);
    if (delegate == null) {
      return PrMergeableState.unknown;
    }
    return delegate.mergeState(repo, prNumber, workspaceId: workspaceId);
  }

  @override
  Future<String?> latestApprover(
    Repo repo,
    int prNumber, {
    required String workspaceId,
  }) async => _delegateFor(
    repo,
  )?.latestApprover(repo, prNumber, workspaceId: workspaceId);

  @override
  Future<({String name, String? url})?> firstFailingCheck(
    Repo repo,
    int prNumber, {
    required String workspaceId,
  }) async => _delegateFor(
    repo,
  )?.firstFailingCheck(repo, prNumber, workspaceId: workspaceId);
}

/// One forge-wide merged-PR search: the pull requests [login] got merged
/// since [mergedSince] across [repos] (all on one forge), on [userId]'s own
/// credential in [workspaceId], each paired with the repo it belongs to.
typedef MergedPrSearch =
    Future<List<({Repo repo, PullRequest pr})>> Function({
      required String login,
      required List<Repo> repos,
      required DateTime mergedSince,
      required String userId,
      required String workspaceId,
    });

/// Merged-history search across every forge in a workspace.
///
/// The inbox's "merging and recently merged" section. Each forge is asked
/// for the caller's merged pull requests under *that forge's* identity — the
/// same human is a different login on each — on the caller's own
/// credential, as few times as the forge allows:
///
/// * GitHub: one `is:pr is:merged author:<login> merged:>=<date> repo:a …`
///   search per [githubChunk] repos, [githubConcurrency] at a time.
/// * GitLab: one `/merge_requests?scope=all&state=merged` request, filtered
///   to the linked projects.
/// * Bitbucket: there is no cross-repository search, so per repo,
///   [bitbucketConcurrency] at a time.
class MultiForgeMergedHistory {
  /// Creates a [MultiForgeMergedHistory].
  const MultiForgeMergedHistory({
    required this._clientFor,
    required this._viewerLoginFor,
    required this._githubSearch,
    required this._gitlabSearch,
    this._now,
  });

  /// How far back the history reaches.
  static const Duration window = Duration(days: 30);

  /// Repos per GitHub search (the query's `repo:` qualifiers).
  static const int githubChunk = 5;

  /// GitHub searches in flight at once (the search API has its own, small,
  /// rate limit).
  static const int githubConcurrency = 2;

  /// Bitbucket repos asked at once.
  static const int bitbucketConcurrency = 4;

  final ForgePrClientResolver _clientFor;
  final Future<String> Function(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  })
  _viewerLoginFor;
  final MergedPrSearch _githubSearch;
  final MergedPrSearch _gitlabSearch;
  final DateTime Function()? _now;

  /// [userId]'s recently merged pull requests across [repos], grouped by
  /// repo. Repos whose forge cannot answer — including a forge that user has
  /// not connected — are simply absent.
  ///
  /// [workspaceId] is the workspace [repos] belong to; without one (or
  /// without a user) this answers nothing, since its credentials come from
  /// them.
  Future<List<OpenPrGroup>> mergedByViewer(
    List<Repo> repos, {
    String? userId,
    String? workspaceId,
  }) async {
    if (workspaceId == null ||
        workspaceId.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      return const [];
    }
    final since = (_now?.call() ?? DateTime.now()).toUtc().subtract(window);
    final byForge = <ForgeHost, List<Repo>>{};
    for (final repo in repos) {
      (byForge[repo.forge] ??= []).add(repo);
    }
    final byRepoId = <String, ({Repo repo, List<PullRequest> prs})>{};
    void add(Repo repo, PullRequest pr) {
      (byRepoId[repo.id] ??= (repo: repo, prs: <PullRequest>[])).prs.add(pr);
    }

    Future<String> loginOn(ForgeHost forge) async {
      try {
        return await _viewerLoginFor(
          forge,
          userId: userId,
          workspaceId: workspaceId,
        );
      } on Object catch (e) {
        CcHostLog.warning(
          'merged_history: ${forge.displayName} login unavailable: $e',
        );
        return '';
      }
    }

    await Future.wait([
      for (final MapEntry(key: forge, value: forgeRepos) in byForge.entries)
        () async {
          final login = await loginOn(forge);
          if (login.isEmpty) {
            return;
          }
          switch (forge) {
            case ForgeHost.github:
              final chunks = [
                for (var i = 0; i < forgeRepos.length; i += githubChunk)
                  forgeRepos.skip(i).take(githubChunk).toList(),
              ];
              await _bounded(chunks, githubConcurrency, (chunk) async {
                for (final hit in await _search(
                  _githubSearch,
                  forge,
                  login: login,
                  repos: chunk,
                  since: since,
                  userId: userId,
                  workspaceId: workspaceId,
                )) {
                  add(hit.repo, hit.pr);
                }
              });
            case ForgeHost.gitlab:
              for (final hit in await _search(
                _gitlabSearch,
                forge,
                login: login,
                repos: forgeRepos,
                since: since,
                userId: userId,
                workspaceId: workspaceId,
              )) {
                add(hit.repo, hit.pr);
              }
            case ForgeHost.bitbucket:
              await _bounded(forgeRepos, bitbucketConcurrency, (repo) async {
                try {
                  final prs = await _clientFor(
                    repo,
                    actingUserId: userId,
                    workspaceId: workspaceId,
                  ).listMergedByAuthor(login);
                  for (final pr in prs) {
                    final mergedAt = pr.mergedAt;
                    if (mergedAt == null || !mergedAt.isBefore(since)) {
                      add(repo, pr);
                    }
                  }
                } on Object catch (e) {
                  CcHostLog.warning(
                    'merged_history: Bitbucket search failed for '
                    '${repo.fullName}: $e',
                  );
                }
              });
            case ForgeHost.local:
              return;
          }
        }(),
    ]);

    return [
      for (final entry in byRepoId.values)
        (repo: entry.repo, prs: entry.prs, hasMore: false, totalCount: null),
    ];
  }

  static Future<List<({Repo repo, PullRequest pr})>> _search(
    MergedPrSearch search,
    ForgeHost forge, {
    required String login,
    required List<Repo> repos,
    required DateTime since,
    required String userId,
    required String workspaceId,
  }) async {
    try {
      return await search(
        login: login,
        repos: repos,
        mergedSince: since,
        userId: userId,
        workspaceId: workspaceId,
      );
    } on Object catch (e) {
      CcHostLog.warning(
        'merged_history: ${forge.displayName} search failed for '
        '${repos.length} repo(s): $e',
      );
      return const [];
    }
  }

  static Future<void> _bounded<T>(
    List<T> items,
    int width,
    Future<void> Function(T item) each,
  ) async {
    for (var i = 0; i < items.length; i += width) {
      await Future.wait(items.skip(i).take(width).map(each));
    }
  }
}
