// Repository interfaces for Review Studio (PRD 18). Implementations are
// Drift-backed on the server (`cc_persistence`) and RPC-backed on clients
// (`cc_data`). Every method is workspace-scoped (required `workspaceId`) per
// the isolation invariant; repo-scoped snapshots also carry `repoId`.

import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_dependency_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_diagram.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_run_snapshot.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/visual_diff.dart';

/// The synthetic PR key Review Studio used before migration 46 unified the
/// studio tables onto the real GitHub node id. Kept as the last-resort fallback
/// when the real node id can't be resolved (a PR GitHub can't find). New code
/// should resolve the real node id via a [ReviewPrExternalIdResolver].
String reviewPrNodeKey(String owner, String repo, int prNumber) =>
    '$owner/$repo#$prNumber';

/// Resolves a PR's canonical review key — its real GitHub node id (the same id
/// `review_channels` stores). Server-side (association-first, cached GitHub
/// fallback); injected into the studio ops + annotation tools.
typedef ReviewPrExternalIdResolver =
    Future<String> Function({
      required String workspaceId,
      required String owner,
      required String repo,
      required int prNumber,
    });

/// Persists and streams a PR's semantic cohorts (PRD 18 §1).
abstract class ReviewCohortRepository {
  /// The cohorts for [prExternalId] within [workspaceId], ordered by reading order.
  Future<List<ReviewCohort>> forPr(String workspaceId, String prExternalId);

  /// Streams the cohorts for [prExternalId], updated on recompute.
  Stream<List<ReviewCohort>> watchForPr(
    String workspaceId,
    String prExternalId,
  );

  /// Replaces the whole cohort set for [prExternalId] (a recompute on PR open /
  /// head-SHA change). Atomic: readers never see a half-written set.
  Future<void> replaceForPr(
    String workspaceId,
    String prExternalId,
    List<ReviewCohort> cohorts,
  );

  /// Sets a single cohort's summary markdown (per-cohort AI summary, §2).
  Future<void> updateSummary(
    String workspaceId,
    String cohortId,
    String summaryMarkdown,
  );

  /// Replaces a single cohort's walkthrough diagrams (graph-verified, §3).
  Future<void> updateDiagrams(
    String workspaceId,
    String cohortId,
    List<ReviewDiagram> diagrams,
  );
}

/// Persists and streams API-contract diffs (PRD 18 §5).
abstract class ApiContractDiffRepository {
  /// The contract diffs for [prExternalId] within [workspaceId].
  Future<List<ApiContractDiff>> forPr(String workspaceId, String prExternalId);

  /// Streams the contract diffs for [prExternalId].
  Stream<List<ApiContractDiff>> watchForPr(
    String workspaceId,
    String prExternalId,
  );

  /// Upserts one spec's diff (keyed by (prExternalId, specPath)).
  Future<void> upsert(String workspaceId, ApiContractDiff diff);

  /// Records a per-change approve/reject decision (the merge-gate feed, §5).
  Future<void> setChangeDecision(
    String workspaceId,
    String diffId,
    String changeId,
    ApiChangeDecision decision,
  );
}

/// Persists and streams UI visual-diff snapshots (PRD 18 §4).
abstract class VisualDiffRepository {
  /// The visual snapshots for [prExternalId] within [workspaceId].
  Future<List<VisualDiffSnapshot>> forPr(
    String workspaceId,
    String prExternalId,
  );

  /// Streams the visual snapshots for [prExternalId].
  Stream<List<VisualDiffSnapshot>> watchForPr(
    String workspaceId,
    String prExternalId,
  );

  /// Upserts one component snapshot (keyed by (prExternalId, componentKey)).
  Future<void> upsert(String workspaceId, VisualDiffSnapshot snapshot);

  /// Sets a snapshot's approval status (the "approve intended change" gate).
  Future<void> setStatus(
    String workspaceId,
    String snapshotId,
    VisualDiffStatus status,
  );
}

/// Persists and streams a PR's dependency lockfile diffs.
abstract class ReviewDependencyDiffRepository {
  /// The dependency diffs for [prExternalId] within [workspaceId].
  Future<List<PrDependencyDiff>> forPr(String workspaceId, String prExternalId);

  /// Streams the dependency diffs for [prExternalId].
  Stream<List<PrDependencyDiff>> watchForPr(
    String workspaceId,
    String prExternalId,
  );

  /// Replaces the whole diff set for [prExternalId]. Wholesale rather than
  /// per-file: a lockfile dropped from the PR must stop being reported, which
  /// an upsert-only path would never notice.
  Future<void> replaceForPr(
    String workspaceId,
    String prExternalId,
    List<PrDependencyDiff> diffs,
  );
}

/// Persists and reads finalized review passes (the delta-aware re-review
/// record).
abstract class ReviewRunSnapshotRepository {
  /// Records one finalized pass.
  Future<void> record(String workspaceId, ReviewRunSnapshot snapshot);

  /// The most recent pass for [prExternalId], or null on a first review.
  Future<ReviewRunSnapshot?> latestForPr(
    String workspaceId,
    String prExternalId,
  );

  /// Passes for [prExternalId], newest first.
  Future<List<ReviewRunSnapshot>> forPr(
    String workspaceId,
    String prExternalId, {
    int limit,
  });

  /// Aggregated counters across every pass in [workspaceId] — the review
  /// effectiveness ("made / addressed") figures.
  Future<ReviewRunStats> statsForWorkspace(String workspaceId);
}

/// Persists and streams per-axis review results (PRD 18 §7).
abstract class ReviewAxisResultRepository {
  /// The axis results for [prExternalId] within [workspaceId].
  Future<List<ReviewAxisResult>> forPr(String workspaceId, String prExternalId);

  /// Streams the axis results for [prExternalId].
  Stream<List<ReviewAxisResult>> watchForPr(
    String workspaceId,
    String prExternalId,
  );

  /// Upserts a single axis result (keyed by (prExternalId, axis)).
  Future<void> upsert(
    String workspaceId,
    String prExternalId,
    ReviewAxisResult result,
  );
}
