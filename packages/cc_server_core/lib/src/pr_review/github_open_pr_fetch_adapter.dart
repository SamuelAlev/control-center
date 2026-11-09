import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_server_core/src/pr_review/open_pr_fetch_port.dart';

/// Production [OpenPrFetchPort] over the workspace's automation
/// [GitHubApiClient]s. The group fetch mirrors what `pr.listOpenForWorkspace`
/// serves: the batched GraphQL list query plus a best-effort checks overlay.
///
/// The client is resolved **per (workspace, repo owner)**: each REST request
/// carries a token for its one repository and GraphQL rides the workspace's
/// accountable human, so a workspace never reads with another's credentials.
/// Batch calls are grouped by owner, and one owner's failure is isolated to
/// its own repos (they resolve nothing and keep their previous snapshot
/// entries) rather than emptying the sweep.
class GitHubOpenPrFetchAdapter implements OpenPrFetchPort {
  /// Creates a [GitHubOpenPrFetchAdapter] resolving a client per repo owner.
  ///
  /// [_ownerSuspended] reports whether the workspace's App installation on
  /// an owner is suspended; a failed probe there is remapped to
  /// [kGitHubInstallationSuspendedCode] so the poller parks immediately with
  /// the resume notice instead of treating it as a generic 404.
  GitHubOpenPrFetchAdapter(this._clientForOwner, {this._isOwnerSuspended});

  final GitHubApiClient Function(String workspaceId, String owner)
  _clientForOwner;
  final Future<bool> Function(String workspaceId, String owner)?
  _isOwnerSuspended;

  GitHubApiClient _client(Repo repo, {String? workspaceId}) =>
      _clientForOwner(workspaceId ?? '', repo.remoteOwner);

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

    await Future.wait(
      _byOwner(repos).values.map((ownerRepos) async {
        final client = _client(ownerRepos.first, workspaceId: workspaceId);
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
    List<Repo> repos, {
    String? workspaceId,
  }) async {
    final merged = <String, Map<int, PrStatusOverlay>>{};

    await Future.wait(
      _byOwner(repos).values.map((ownerRepos) async {
        final Map<int, Map<int, GitHubPrStatusOverlay>> byIndex;
        try {
          byIndex = await _client(
            ownerRepos.first,
            workspaceId: workspaceId,
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

  /// The per-repo forge client the single-PR lookups share with every other
  /// forge, so GitHub's answers follow the same port contract.
  GitHubForgePrClient _forgeClient(Repo repo, {String? workspaceId}) =>
      GitHubForgePrClient(
        client: _client(repo, workspaceId: workspaceId),
        owner: repo.remoteOwner,
        repo: repo.remoteName,
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
