import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_server_core/src/pr_review/open_pr_fetch_port.dart';

/// Production [OpenPrFetchPort] over the server's gh-authenticated
/// [GitHubApiClient]. The group fetch mirrors what `pr.listOpenForWorkspace`
/// serves: the batched GraphQL list query plus a best-effort checks overlay.
///
/// The client is resolved **per repo owner**, not held once. The server's
/// no-caller GitHub credential is a token for whichever app installation
/// answered first, and GitHub answers such a token with 404 for every repo
/// under an owner the app is not installed on — so a workspace mixing owners
/// must ask about each owner's repos with a credential that covers *that*
/// owner. Batch calls are grouped by owner accordingly, and one owner's
/// failure is isolated to its own repos (they resolve nothing and keep their
/// previous snapshot entries) rather than emptying the sweep.
class GitHubOpenPrFetchAdapter implements OpenPrFetchPort {
  /// Creates a [GitHubOpenPrFetchAdapter] resolving a client per repo owner.
  ///
  /// [app] is the server's GitHub App identity. When an installation covering
  /// the repo's owner is suspended, a failed probe is remapped to
  /// [kGitHubInstallationSuspendedCode] so the poller parks immediately with
  /// the resume-or-token notice instead of treating it as a generic 404.
  GitHubOpenPrFetchAdapter(
    this._clientForOwner, {
    Future<GitHubAppClient?> Function()? app,
  }) : _app = app;

  final GitHubApiClient Function(String owner) _clientForOwner;
  final Future<GitHubAppClient?> Function()? _app;

  static List<({String owner, String name})> _specs(List<Repo> repos) => [
    for (final r in repos) (owner: r.remoteOwner, name: r.remoteName),
  ];

  /// Groups [repos] by owner (case-insensitively — GitHub logins are), keeping
  /// each group's original casing for the API calls.
  static Map<String, List<Repo>> _byOwner(List<Repo> repos) {
    final grouped = <String, List<Repo>>{};
    for (final repo in repos) {
      (grouped[repo.remoteOwner.toLowerCase()] ??= []).add(repo);
    }
    return grouped;
  }

  Future<bool> _ownerSuspended(String owner) async {
    final app = await _app?.call();
    return app != null && await app.isOwnerSuspended(owner);
  }

  @override
  Future<({bool changed, String? etag})> probeRepo(
    Repo repo,
    String? etag,
  ) async {
    try {
      final probe = await _clientForOwner(
        repo.remoteOwner,
      ).pr.probeOpenPullRequests(repo.remoteOwner, repo.remoteName, etag: etag);
      return (changed: probe.changed, etag: probe.etag);
    } on Object {
      if (await _ownerSuspended(repo.remoteOwner)) {
        throw NetworkException(
          'GitHub App installation for ${repo.remoteOwner} is suspended',
          code: kGitHubInstallationSuspendedCode,
        );
      }
      rethrow;
    }
  }

  @override
  Future<OpenPrFetchResult> fetchGroups(List<Repo> repos) async {
    final groups = <OpenPrGroup>[];
    final resolved = <String>{};

    await Future.wait(
      _byOwner(repos).values.map((ownerRepos) async {
        final client = _clientForOwner(ownerRepos.first.remoteOwner);
        final specs = _specs(ownerRepos);
        final GitHubPrBatchResult batch;
        try {
          batch = await client.graphql.fetchOpenPullRequestsBatch(specs);
        } on Object catch (e) {
          // Contribute nothing for this owner: its repos stay unresolved, so
          // the poller keeps their previous entries. Every other owner's
          // results still land.
          CcHostLog.warning(
            'open_pr_poll: GitHub fetch failed for '
            '${ownerRepos.first.remoteOwner} (${ownerRepos.length} repo(s)): '
            '$e',
          );
          return;
        }
        var checks = <int, Map<int, GitHubPrStatusOverlay>>{};
        try {
          checks = await client.graphql.fetchOpenPullRequestsChecks(specs);
        } on Object catch (e) {
          // Checks are best-effort for RENDERING — the rows still list. They
          // are not best-effort for NOTIFYING: an unread rollup decodes to the
          // same `none` as "this PR has no checks", so the poller carries the
          // previous value forward rather than persisting the gap (see
          // `_carryEnrichmentForward`). Logged because this failure used to be
          // completely silent while being the trigger for repeat
          // notifications.
          CcHostLog.warning(
            'open_pr_poll: checks overlay failed for '
            '${ownerRepos.first.remoteOwner} (${ownerRepos.length} repo(s)) — '
            'keeping the previous checks/review state: $e',
          );
        }
        for (var i = 0; i < ownerRepos.length; i++) {
          final repo = ownerRepos[i];
          final repoResult = batch.byIndex[i];
          if (repoResult == null) {
            continue;
          }
          // Present in the batch = GitHub answered for this repo. Recorded
          // BEFORE the empty-group skip below, so a repo with a genuinely
          // empty queue still counts as resolved.
          resolved.add(repo.id);
          final repoChecks = checks[i];
          final prs = <PullRequest>[];
          for (final node in repoResult.nodes) {
            final number = (node['number'] as num?)?.toInt() ?? 0;
            final title = node['title'] as String? ?? '';
            if (number <= 0 || title.isEmpty) {
              continue;
            }
            var pr = pullRequestFromGraphQlNode(
              node,
              repoFullName: repo.fullName,
            );
            final overlay = repoChecks?[pr.number];
            if (overlay != null) {
              pr = pr.copyWith(
                checksStatus: prChecksStatusFromRollup(overlay.checksRollup),
                reviewDecision: PrReviewDecision.fromString(
                  overlay.reviewDecision,
                ),
              );
            }
            prs.add(pr);
          }
          if (prs.isEmpty) {
            continue;
          }
          groups.add((repo: repo, prs: prs, hasMore: repoResult.hasMore));
        }
      }),
    );

    return (groups: groups, resolvedRepoIds: resolved);
  }

  @override
  Future<Map<String, Map<int, PrStatusOverlay>>> fetchChecks(
    List<Repo> repos,
  ) async {
    final merged = <String, Map<int, PrStatusOverlay>>{};

    await Future.wait(
      _byOwner(repos).values.map((ownerRepos) async {
        final Map<int, Map<int, GitHubPrStatusOverlay>> byIndex;
        try {
          byIndex = await _clientForOwner(
            ownerRepos.first.remoteOwner,
          ).graphql.fetchOpenPullRequestsChecks(_specs(ownerRepos));
        } on Object catch (e) {
          CcHostLog.warning(
            'open_pr_poll: GitHub checks pass failed for '
            '${ownerRepos.first.remoteOwner}: $e',
          );
          return;
        }
        for (var i = 0; i < ownerRepos.length; i++) {
          final overlays = byIndex[i];
          if (overlays == null) {
            continue;
          }
          merged[ownerRepos[i].id] = {
            for (final e in overlays.entries)
              e.key: (
                checksRollup: e.value.checksRollup,
                reviewDecision: e.value.reviewDecision,
              ),
          };
        }
      }),
    );

    return merged;
  }

  @override
  Future<bool?> wasMerged(Repo repo, int prNumber) async {
    try {
      final gh = await _clientForOwner(
        repo.remoteOwner,
      ).pr.getPullRequest(repo.remoteOwner, repo.remoteName, prNumber);
      if (gh == null) {
        return null;
      }
      return gh.mergedAt != null;
    } on Object {
      return null;
    }
  }

  @override
  Future<PrMergeableState> mergeState(Repo repo, int prNumber) async {
    try {
      final gh = await _clientForOwner(
        repo.remoteOwner,
      ).pr.getPullRequest(repo.remoteOwner, repo.remoteName, prNumber);
      if (gh == null || gh.mergeableState.isEmpty) {
        return PrMergeableState.unknown;
      }
      return PrMergeableState.fromString(gh.mergeableState);
    } on Object {
      // Not confirmed. The caller leaves the snapshot alone, so the edge is
      // re-attempted next sweep rather than announced on a failed read.
      return PrMergeableState.unknown;
    }
  }

  @override
  Future<String?> latestApprover(Repo repo, int prNumber) async {
    try {
      final reviews = await _clientForOwner(
        repo.remoteOwner,
      ).pr.listPullRequestReviews(repo.remoteOwner, repo.remoteName, prNumber);
      GitHubReview? newest;
      for (final review in reviews) {
        if (review.state != GitHubReviewState.approved) {
          continue;
        }
        final at = review.submittedAt;
        final best = newest?.submittedAt;
        if (newest == null ||
            (at != null && (best == null || at.isAfter(best)))) {
          newest = review;
        }
      }
      final login = newest?.user?.login;
      return (login == null || login.isEmpty) ? null : login;
    } on Object {
      return null;
    }
  }

  @override
  Future<({String name, String? url})?> firstFailingCheck(
    Repo repo,
    int prNumber,
  ) async {
    try {
      final gh = await _clientForOwner(
        repo.remoteOwner,
      ).pr.getPullRequest(repo.remoteOwner, repo.remoteName, prNumber);
      final sha = gh?.headSha;
      if (sha == null || sha.isEmpty) {
        return null;
      }
      final runs = await _clientForOwner(
        repo.remoteOwner,
      ).pr.listCheckRuns(repo.remoteOwner, repo.remoteName, sha);
      for (final run in runs) {
        if (run.isFailing) {
          return (name: run.name, url: run.htmlUrl);
        }
      }
      return null;
    } on Object {
      return null;
    }
  }
}
