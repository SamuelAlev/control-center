import 'package:cc_domain/cc_domain.dart'
    show NetworkException, ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_server_core/src/pr_review/open_pr_fetch_port.dart';

/// Production [OpenPrFetchPort] over the workspace's automation
/// [GitHubApiClient]s. The group fetch mirrors what `pr.listOpenForWorkspace`
/// serves: the GraphQL list query plus a best-effort checks overlay.
///
/// The client is resolved **per (workspace, repository)**
/// (`GitHubClients.forRepo`): every request, GraphQL included, rides a
/// one-repository installation-lane token for exactly that repository, never
/// a person's own token, so a workspace never reads with another's
/// credentials and no query can reach past the repo it is about. Repos are
/// asked [_concurrency] at a time, and one repo's failure is isolated to it
/// (it resolves nothing and keeps its previous snapshot entries) rather than
/// emptying the sweep.
class GitHubOpenPrFetchAdapter implements OpenPrFetchPort {
  /// Creates a [GitHubOpenPrFetchAdapter] resolving a client per repository.
  ///
  /// [_isOwnerSuspended] reports whether the workspace's App installation on
  /// an owner is suspended; a failed probe there is remapped to
  /// [kGitHubInstallationSuspendedCode] so the poller parks immediately with
  /// the resume notice instead of treating it as a generic 404.
  GitHubOpenPrFetchAdapter(this._clientForRepo, {this._isOwnerSuspended});

  /// Repositories read at the same time in one fetch or checks pass.
  static const int _concurrency = 6;

  final GitHubApiClient Function(String workspaceId, String owner, String repo)
  _clientForRepo;
  final Future<bool> Function(String workspaceId, String owner)?
  _isOwnerSuspended;

  GitHubApiClient _client(Repo repo, {String? workspaceId}) =>
      _clientForRepo(workspaceId ?? '', repo.remoteOwner, repo.remoteName);

  static List<({String owner, String name})> _spec(Repo repo) => [
    (owner: repo.remoteOwner, name: repo.remoteName),
  ];

  /// Runs [each] over [repos], [_concurrency] at a time.
  static Future<void> _bounded(
    List<Repo> repos,
    Future<void> Function(Repo repo) each,
  ) async {
    for (var i = 0; i < repos.length; i += _concurrency) {
      await Future.wait(repos.skip(i).take(_concurrency).map(each));
    }
  }

  Future<bool> _ownerSuspended(String owner, {String? workspaceId}) async =>
      workspaceId != null &&
      workspaceId.isNotEmpty &&
      (await _isOwnerSuspended?.call(workspaceId, owner) ?? false);

  @override
  Future<({bool changed, String? etag})> probeRepo(
    Repo repo,
    String? etag, {
    String? workspaceId,
  }) async {
    try {
      final probe = await _client(
        repo,
        workspaceId: workspaceId,
      ).pr.probeOpenPullRequests(repo.remoteOwner, repo.remoteName, etag: etag);
      return (changed: probe.changed, etag: probe.etag);
    } on Object {
      if (await _ownerSuspended(repo.remoteOwner, workspaceId: workspaceId)) {
        throw NetworkException(
          'GitHub App installation for ${repo.remoteOwner} is suspended',
          code: kGitHubInstallationSuspendedCode,
        );
      }
      rethrow;
    }
  }

  @override
  Future<OpenPrFetchResult> fetchGroups(
    List<Repo> repos, {
    String? workspaceId,
  }) async {
    final groups = <OpenPrGroup>[];
    final resolved = <String>{};

    await _bounded(repos, (repo) async {
      final client = _client(repo, workspaceId: workspaceId);
      final specs = _spec(repo);
      final GitHubPrBatchResult batch;
      try {
        batch = await client.graphql.fetchOpenPullRequestsBatch(specs);
      } on Object catch (e) {
        // Contribute nothing for this repo: it stays unresolved, so the
        // poller keeps its previous entries. Every other repo still lands.
        CcHostLog.warning(
          'open_pr_poll: GitHub fetch failed for ${repo.fullName}: $e',
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
        // `_carryEnrichmentForward`).
        CcHostLog.warning(
          'open_pr_poll: checks overlay failed for ${repo.fullName} — '
          'keeping the previous checks/review state: $e',
        );
      }
      final repoResult = batch.byIndex[0];
      if (repoResult == null) {
        return;
      }
      // Present in the batch = GitHub answered for this repo. Recorded
      // BEFORE the empty-group skip below, so a repo with a genuinely empty
      // queue still counts as resolved.
      resolved.add(repo.id);
      final repoChecks = checks[0];
      final prs = <PullRequest>[];
      for (final node in repoResult.nodes) {
        final number = (node['number'] as num?)?.toInt() ?? 0;
        final title = node['title'] as String? ?? '';
        if (number <= 0 || title.isEmpty) {
          continue;
        }
        var pr = pullRequestFromGraphQlNode(node, repoFullName: repo.fullName);
        final overlay = repoChecks?[pr.number];
        if (overlay != null) {
          pr = pr.copyWith(
            checksStatus: prChecksStatusFromRollup(overlay.checksRollup),
            reviewDecision: PrReviewDecision.fromString(overlay.reviewDecision),
          );
        }
        prs.add(pr);
      }
      if (prs.isEmpty) {
        return;
      }
      groups.add((
        repo: repo,
        prs: prs,
        hasMore: repoResult.hasMore,
        totalCount: repoResult.totalCount,
      ));
    });

    return (groups: groups, resolvedRepoIds: resolved);
  }

  @override
  Future<Map<String, Map<int, PrStatusOverlay>>> fetchChecks(
    List<Repo> repos, {
    String? workspaceId,
  }) async {
    final merged = <String, Map<int, PrStatusOverlay>>{};

    await _bounded(repos, (repo) async {
      final Map<int, Map<int, GitHubPrStatusOverlay>> byIndex;
      try {
        byIndex = await _client(
          repo,
          workspaceId: workspaceId,
        ).graphql.fetchOpenPullRequestsChecks(_spec(repo));
      } on Object catch (e) {
        CcHostLog.warning(
          'open_pr_poll: GitHub checks pass failed for ${repo.fullName}: $e',
        );
        return;
      }
      final overlays = byIndex[0];
      if (overlays == null) {
        return;
      }
      merged[repo.id] = {
        for (final e in overlays.entries)
          e.key: (
            checksRollup: e.value.checksRollup,
            reviewDecision: e.value.reviewDecision,
          ),
      };
    });

    return merged;
  }

  /// The per-repo forge client the single-PR lookups share with every other
  /// forge, so GitHub's answers follow the same port contract.
  /// It only reads: an approval through it is refused before it is sent.
  GitHubForgePrClient _forgeClient(Repo repo, {String? workspaceId}) =>
      GitHubForgePrClient(
        client: _client(repo, workspaceId: workspaceId),
        owner: repo.remoteOwner,
        repo: repo.remoteName,
        approvalGuard: (_, _) async => throw const ValidationException(
          'The open pull request poller never approves.',
        ),
      );

  @override
  Future<bool?> wasMerged(Repo repo, int prNumber, {String? workspaceId}) =>
      _forgeClient(repo, workspaceId: workspaceId).wasMerged(prNumber);

  @override
  Future<List<PullRequest>?> fetchBranchHistory(
    Repo repo,
    String branch, {
    String? workspaceId,
  }) async {
    try {
      return await _forgeClient(
        repo,
        workspaceId: workspaceId,
      ).listPullRequestsForBranch(branch);
    } on Object catch (e) {
      CcHostLog.warning(
        'open_pr_poll: branch history failed for ${repo.fullName}: $e',
      );
      return null;
    }
  }

  @override
  Future<PrMergeableState> mergeState(
    Repo repo,
    int prNumber, {
    String? workspaceId,
  }) async {
    try {
      return await _forgeClient(
        repo,
        workspaceId: workspaceId,
      ).mergeState(prNumber);
    } on Object catch (e) {
      // Not confirmed. The caller leaves the snapshot alone, so the edge is
      // re-attempted next sweep rather than announced on a failed read.
      CcHostLog.warning(
        'open_pr_poll: mergeability lookup failed for '
        '${repo.fullName}#$prNumber: $e',
      );
      return PrMergeableState.unknown;
    }
  }

  @override
  Future<String?> latestApprover(
    Repo repo,
    int prNumber, {
    String? workspaceId,
  }) async {
    try {
      return await _forgeClient(
        repo,
        workspaceId: workspaceId,
      ).latestApprover(prNumber);
    } on Object catch (e) {
      CcHostLog.warning(
        'open_pr_poll: approver lookup failed for '
        '${repo.fullName}#$prNumber: $e',
      );
      return null;
    }
  }

  @override
  Future<({String name, String? url})?> firstFailingCheck(
    Repo repo,
    int prNumber, {
    String? workspaceId,
  }) async {
    try {
      return await _forgeClient(
        repo,
        workspaceId: workspaceId,
      ).firstFailingCheck(prNumber);
    } on Object catch (e) {
      CcHostLog.warning(
        'open_pr_poll: check-run lookup failed for '
        '${repo.fullName}#$prNumber: $e',
      );
      return null;
    }
  }
}
