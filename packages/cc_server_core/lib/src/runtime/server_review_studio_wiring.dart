part of '../cc_server_runtime.dart';

/// The `computeReviewStudio` closure: cohorts and deterministic axes for a
/// pull request (PRD 18). Resolves the linked repo, fetches the PR's changed
/// files and base/head SHAs, then runs the cohort grouper (code graph), the
/// contract axis (spec diff) and the visual axis (golden harness, degraded
/// honestly without a Flutter SDK).
Future<Map<String, dynamic>> Function({
  required String workspaceId,
  required String owner,
  required String repo,
  required int prNumber,
  required String userId,
})
_reviewStudioComputer({
  required Future<Repo> Function(String workspaceId, String owner, String repo)
  resolveLinkedReviewRepo,
  required GitHubApiClient Function(String workspaceId, String owner)
  githubClientForOwner,
  required Map<String, String> prExternalIdCache,
  required DaoIsolatedRepoRepository isolatedRepoRepository,
  required ReviewCohortService reviewCohortService,
  required DaoReviewAxisResultRepository reviewAxisResultRepository,
  required ReviewDependencyService reviewDependencyService,
  required ReviewAxisService reviewAxisService,
  required VisualDiffService visualDiffService,
  required PrWorktreeService prWorktree,
  required RepoPathGuard repoPathGuard,
}) =>
    ({
      required String workspaceId,
      required String owner,
      required String repo,
      required int prNumber,
      required String userId,
    }) async {
      final linked = await resolveLinkedReviewRepo(workspaceId, owner, repo);
      final github = githubClientForOwner(workspaceId, owner);
      final gh = await github.pr.getPullRequest(owner, repo, prNumber);
      if (gh == null) {
        throw const NotFoundException('Pull request not found');
      }
      final pr = pullRequestFromGitHub(gh, repoFullName: linked.fullName);
      final files = await github.pr.listPullRequestFiles(owner, repo, prNumber);
      final changedFiles = files.map((f) => f.filename).toList();
      // Canonical key = the real GitHub node id (migration 46). Prime the cache so
      // the read ops resolve it without a second fetch.
      final prExternalId = pr.externalId.isNotEmpty
          ? pr.externalId
          : reviewPrNodeKey(owner, repo, prNumber);
      prExternalIdCache['$owner/$repo#$prNumber'] = prExternalId;

      // The PR's own code-graph partition, when its worktree has been
      // materialized. Absent (or not yet indexed) it falls back to the base
      // partition inside the service and the result is stamped as such.
      String? checkoutId;
      try {
        final isolated = await isolatedRepoRepository.forUnitRepo(
          workspaceId,
          'pr:${linked.fullName}#$prNumber',
          linked.id,
        );
        checkoutId = isolated?.id;
      } catch (e) {
        CcHostLog.warning('review_studio: PR partition lookup failed: $e');
      }

      final cohorts = await reviewCohortService.compute(
        workspaceId: workspaceId,
        repoId: linked.id,
        prExternalId: prExternalId,
        headSha: pr.headSha,
        changedFiles: changedFiles,
        patchByFile: {
          for (final f in files)
            if (f.patch.isNotEmpty) f.filename: f.patch,
        },
        checkoutId: checkoutId,
      );

      final axes = <Map<String, dynamic>>[];
      // Test-gap axis (token-free). Deterministic grounding for what was
      // otherwise a purely token-driven axis: an area whose changed symbols have
      // no inbound reference from any test file is a real, checkable gap.
      final testGap = ReviewAxisService.testGapAxisFromCohorts(cohorts);
      await reviewAxisResultRepository.upsert(
        workspaceId,
        prExternalId,
        testGap,
      );
      axes.add(testGap.toJson());

      // Dependency diffs (token-free, offline). Reuses the same content reader
      // the contract axis uses — no extra forge surface.
      try {
        final dependencyDiffs = await reviewDependencyService.compute(
          workspaceId: workspaceId,
          prExternalId: prExternalId,
          baseSha: pr.baseSha,
          headSha: pr.headSha,
          changedFiles: changedFiles,
          readContent: ({required String path, required String ref}) =>
              github.content.getFileContent(owner, repo, path, ref),
        );
        if (dependencyDiffs.isNotEmpty) {
          CcHostLog.info(
            'review_studio: ${dependencyDiffs.length} lockfile diff(s)',
          );
        }
      } catch (e) {
        CcHostLog.warning('review_studio: dependency diff failed: $e');
      }
      // API-contract axis (token-free).
      final contract = await reviewAxisService.runContractAxis(
        workspaceId: workspaceId,
        repoId: linked.id,
        prExternalId: prExternalId,
        baseSha: pr.baseSha,
        headSha: pr.headSha,
        changedFiles: changedFiles,
        readContent: ({required String path, required String ref}) =>
            github.content.getFileContent(owner, repo, path, ref),
      );
      if (contract != null) {
        axes.add(contract.toJson());
      }
      // Visual axis (token-free). Cheap precheck first: no Flutter SDK → honest
      // "unavailable" without provisioning a worktree.
      if (!await visualDiffService.hostHasFlutter()) {
        final result = ReviewAxisService.visualAxisResult(
          VisualDiffOutcome.unavailable('no Flutter SDK on host'),
        );
        await reviewAxisResultRepository.upsert(
          workspaceId,
          prExternalId,
          result,
        );
        axes.add(result.toJson());
      } else {
        try {
          final worktree = await prWorktree.ensureWorktree(
            workspaceId: workspaceId,
            // The checkout it branches from must be one the server serves.
            repo: await repoPathGuard.admit(workspaceId, linked),
            prNumber: prNumber,
            prHeadRef: pr.headRef.isEmpty
                ? 'refs/pull/$prNumber/head'
                : pr.headRef,
          );
          final visual = await reviewAxisService.runVisualAxis(
            workspaceId: workspaceId,
            requestedByUserId: userId,
            repoId: linked.id,
            prExternalId: prExternalId,
            repoPath: worktree,
            git: const ProcessGitCommandAdapter(),
            baseSha: pr.baseSha,
            headSha: pr.headSha,
          );
          axes.add(visual.toJson());
        } catch (e) {
          CcHostLog.warning('review_studio: visual axis failed: $e');
          final result = ReviewAxisService.visualAxisResult(
            VisualDiffOutcome.unavailable('golden harness error'),
          );
          await reviewAxisResultRepository.upsert(
            workspaceId,
            prExternalId,
            result,
          );
          axes.add(result.toJson());
        }
      }

      return {'cohorts': cohorts.map((x) => x.toJson()).toList(), 'axes': axes};
    };
