import 'dart:math' show min;

import 'package:cc_domain/cc_domain.dart'
    show NetworkException, ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart'
    show ClosedPrOutcome;
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

  /// Runs [each] over [repos] using a work-queue of at most [_concurrency]
  /// workers (no wave barriers).
  static Future<void> _bounded(
    List<Repo> repos,
    Future<void> Function(Repo repo) each,
  ) async {
    if (repos.isEmpty) {
      return;
    }
    var next = 0;
    final workers = min(_concurrency, repos.length);
    await Future.wait([
      for (var w = 0; w < workers; w++)
        () async {
          while (true) {
            final i = next++;
            if (i >= repos.length) {
              break;
            }
            await each(repos[i]);
          }
        }(),
    ]);
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
      final pipelinedChecks = <Future<Map<int, GitHubPrStatusOverlay>?>>[];
      var missingNodeId = false;
      Object? checksError;

      final GitHubPrBatchResult batch;
      try {
        batch = await client.graphql.fetchOpenPullRequestsBatch(
          specs,
          onPage: (_, pageNodes) {
            final ids = <String>[];
            for (final node in pageNodes) {
              final number = (node['number'] as num?)?.toInt() ?? 0;
              final title = node['title'] as String? ?? '';
              if (number <= 0 || title.isEmpty) {
                continue;
              }
              final id = node['id'] as String?;
              if (id == null || id.isEmpty) {
                missingNodeId = true;
              } else {
                ids.add(id);
              }
            }
            if (ids.isNotEmpty) {
              pipelinedChecks.add(
                client.graphql.fetchPullRequestStatusByIds(ids).then(
                  (overlays) => overlays,
                  onError: (Object e, StackTrace _) {
                    checksError ??= e;
                    return null;
                  },
                ),
              );
            }
          },
        );
      } on Object catch (e) {
        // Contribute nothing for this repo: it stays unresolved, so the
        // poller keeps its previous entries. Every other repo still lands.
        CcHostLog.warning(
          'open_pr_poll: GitHub fetch failed for ${repo.fullName}: $e',
        );
        return;
      }
      final repoResult = batch.byIndex[0];
      if (repoResult == null) {
        return;
      }
      // Present in the batch = GitHub answered for this repo. Recorded
      // BEFORE the empty-group skip below, so a repo with a genuinely empty
      // queue still counts as resolved (and skips checks requests completely).
      resolved.add(repo.id);
      if (repoResult.nodes.isEmpty) {
        return;
      }

      var repoChecks = <int, GitHubPrStatusOverlay>{};
      if (!missingNodeId && pipelinedChecks.isNotEmpty) {
        final pages = await Future.wait(pipelinedChecks);
        for (final page in pages) {
          if (page != null) {
            repoChecks.addAll(page);
          }
        }
        if (checksError != null) {
          CcHostLog.warning(
            'open_pr_poll: checks overlay failed for ${repo.fullName} — '
            'keeping the previous checks/review state: $checksError',
          );
        }
      } else {
        try {
          final checks = await client.graphql.fetchOpenPullRequestsChecks(
            specs,
          );
          repoChecks = checks[0] ?? const {};
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
      }

      final prs = <PullRequest>[];
      for (final node in repoResult.nodes) {
        final number = (node['number'] as num?)?.toInt() ?? 0;
        final title = node['title'] as String? ?? '';
        if (number <= 0 || title.isEmpty) {
          continue;
        }
        var pr = pullRequestFromGraphQlNode(node, repoFullName: repo.fullName);
        final overlay = repoChecks[pr.number];
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
    Map<String, List<String>>? prNodeIdsByRepoId,
  }) async {
    final merged = <String, Map<int, PrStatusOverlay>>{};

    await _bounded(repos, (repo) async {
      final knownIds = prNodeIdsByRepoId?[repo.id];
      if (knownIds != null && knownIds.isEmpty) {
        merged[repo.id] = const {};
        return;
      }
      final Map<int, GitHubPrStatusOverlay> overlays;
      try {
        final graphql = _client(repo, workspaceId: workspaceId).graphql;
        if (knownIds != null) {
          overlays = await graphql.fetchPullRequestStatusByIds(knownIds);
        } else {
          final byIndex = await graphql.fetchOpenPullRequestsChecks(
            _spec(repo),
          );
          final found = byIndex[0];
          if (found == null) {
            return;
          }
          overlays = found;
        }
      } on Object catch (e) {
        CcHostLog.warning(
          'open_pr_poll: GitHub checks pass failed for ${repo.fullName}: $e',
        );
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

  @override
  Future<Map<int, PullRequest>?> fetchPullRequests(
    Repo repo,
    List<int> prNumbers, {
    String? workspaceId,
  }) async {
    if (prNumbers.isEmpty) {
      return const {};
    }
    try {
      final nodes = await _client(
        repo,
        workspaceId: workspaceId,
      ).graphql.fetchPullRequestsByNumbers(
        owner: repo.remoteOwner,
        repo: repo.remoteName,
        numbers: prNumbers,
      );
      return {
        for (final entry in nodes.entries)
          if ((entry.value['title'] as String? ?? '').isNotEmpty)
            entry.key: pullRequestFromGraphQlNode(
              entry.value,
              repoFullName: repo.fullName,
            ),
      };
    } on Object catch (e) {
      CcHostLog.warning(
        'open_pr_poll: surgical PR fetch failed for ${repo.fullName} '
        '($prNumbers): $e',
      );
      return null;
    }
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
  Future<ClosedPrOutcome?> closedOutcome(
    Repo repo,
    int prNumber, {
    String? workspaceId,
  }) => _forgeClient(repo, workspaceId: workspaceId).closedOutcome(prNumber);

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
