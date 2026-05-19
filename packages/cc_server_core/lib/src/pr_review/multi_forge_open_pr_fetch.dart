import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/pr_review/open_pr_polling_service.dart';

/// Builds a [ForgePrClient] for one repo coordinate on one forge.
typedef ForgePrClientForRepo = ForgePrClient Function(Repo repo);

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

  final ForgePrClientForRepo _clientFor;

  /// No conditional-request support outside GitHub, so every pass reports the
  /// list as changed.
  ///
  /// Reporting "unchanged" would be a guess, and a wrong guess here silently
  /// freezes a repo's queue until something else invalidates it. The cost of
  /// being honest is one extra list call per poll.
  @override
  Future<({bool changed, String? etag})> probeRepo(Repo repo, String? etag) =>
      Future.value((changed: true, etag: null));

  @override
  Future<OpenPrFetchResult> fetchGroups(List<Repo> repos) async {
    final groups = <OpenPrGroup>[];
    final resolved = <String>{};

    await Future.wait(
      repos.map((repo) async {
        try {
          final page = await _clientFor(repo).listOpenPullRequests();
          // Recorded before the empty check: a repo with a genuinely empty
          // queue is still an answer, and the poller relies on that difference
          // to tell "no open PRs" from "the forge did not respond".
          resolved.add(repo.id);
          if (page.prs.isNotEmpty) {
            groups.add((repo: repo, prs: page.prs, hasMore: page.hasMore));
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
    List<Repo> repos,
  ) => Future.value(const {});

  @override
  Future<bool?> wasMerged(Repo repo, int prNumber) async {
    try {
      return await _clientFor(repo).wasMerged(prNumber);
    } on Object {
      return null;
    }
  }

  // The three author-facing lookups below are GitHub-only for now. A non-GitHub
  // forge answers "not confirmed" / "unattributed" rather than a wrong value:
  // merge readiness then falls back to the derived heuristic, an approval
  // notification goes out without a name, and a failed-checks notification
  // without the check name. All three degrade the copy, never the correctness.
  @override
  Future<PrMergeableState> mergeState(Repo repo, int prNumber) =>
      Future.value(PrMergeableState.unknown);

  @override
  Future<String?> latestApprover(Repo repo, int prNumber) =>
      Future.value(null);

  @override
  Future<({String name, String? url})?> firstFailingCheck(
    Repo repo,
    int prNumber,
  ) => Future.value(null);
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
    String? etag,
  ) async {
    final delegate = _delegateFor(repo);
    if (delegate == null) {
      return (changed: false, etag: null);
    }
    return delegate.probeRepo(repo, etag);
  }

  @override
  Future<OpenPrFetchResult> fetchGroups(List<Repo> repos) async {
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
          final result = await delegate.fetchGroups(entry.value);
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
    List<Repo> repos,
  ) async {
    final grouped = _byForge(repos);
    final merged = <String, Map<int, PrStatusOverlay>>{};

    await Future.wait(
      grouped.entries.map((entry) async {
        final delegate = delegates[entry.key];
        if (delegate == null) {
          return;
        }
        try {
          merged.addAll(await delegate.fetchChecks(entry.value));
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
  Future<bool?> wasMerged(Repo repo, int prNumber) async {
    final delegate = _delegateFor(repo);
    if (delegate == null) {
      return null;
    }
    return delegate.wasMerged(repo, prNumber);
  }

  @override
  Future<PrMergeableState> mergeState(Repo repo, int prNumber) async {
    final delegate = _delegateFor(repo);
    if (delegate == null) {
      return PrMergeableState.unknown;
    }
    return delegate.mergeState(repo, prNumber);
  }

  @override
  Future<String?> latestApprover(Repo repo, int prNumber) async =>
      _delegateFor(repo)?.latestApprover(repo, prNumber);

  @override
  Future<({String name, String? url})?> firstFailingCheck(
    Repo repo,
    int prNumber,
  ) async => _delegateFor(repo)?.firstFailingCheck(repo, prNumber);
}

/// Merged-history search across every forge in a workspace.
///
/// The inbox's "merging and recently merged" section used to be one GitHub
/// search. With mixed forges there is no single search endpoint, so each repo
/// is asked for the operator's merged pull requests under *that forge's*
/// identity — the same human is a different login on each — and the results are
/// merged.
class MultiForgeMergedHistory {
  /// Creates a [MultiForgeMergedHistory].
  ///
  /// Both resolvers take the acting user so the answer is THAT person's:
  /// their per-forge viewer login, fetched on their own credential. With no
  /// user both fall to the server chain — the pre-multiplayer behavior, only
  /// right for a surface with no caller.
  const MultiForgeMergedHistory({
    required ForgePrClient Function(Repo repo, {String? actingUserId})
    clientFor,
    required Future<String> Function(ForgeHost forge, {String? userId})
    viewerLoginFor,
  }) : _clientFor = clientFor,
       _viewerLoginFor = viewerLoginFor;

  final ForgePrClient Function(Repo repo, {String? actingUserId}) _clientFor;
  final Future<String> Function(ForgeHost forge, {String? userId})
  _viewerLoginFor;

  /// [userId]'s recently merged pull requests across [repos], grouped by
  /// repo. Repos whose forge cannot answer — including a forge that user has
  /// not connected — are simply absent.
  Future<List<OpenPrGroup>> mergedByViewer(
    List<Repo> repos, {
    String? userId,
  }) async {
    final groups = <OpenPrGroup>[];

    await Future.wait(
      repos.map((repo) async {
        try {
          final login = await _viewerLoginFor(repo.forge, userId: userId);
          if (login.isEmpty) {
            return;
          }
          final prs = await _clientFor(
            repo,
            actingUserId: userId,
          ).listMergedByAuthor(login);
          if (prs.isNotEmpty) {
            groups.add((repo: repo, prs: prs, hasMore: false));
          }
        } on Object catch (e) {
          CcHostLog.warning(
            'merged_history: ${repo.forge.displayName} search failed for '
            '${repo.fullName}: $e',
          );
        }
      }),
    );

    return groups;
  }
}

/// Sorts merged pull requests newest-first across forges.
///
/// Ordering is by the forge-reported merge time, which is the only field the
/// three agree on. Anything missing one sorts last rather than first, so a
/// forge that omits the timestamp cannot dominate the top of the list.
int compareByMergedAtDesc(PullRequest a, PullRequest b) {
  final at = a.mergedAt;
  final bt = b.mergedAt;
  if (at == null && bt == null) {
    return 0;
  }
  if (at == null) {
    return 1;
  }
  if (bt == null) {
    return -1;
  }
  return bt.compareTo(at);
}
