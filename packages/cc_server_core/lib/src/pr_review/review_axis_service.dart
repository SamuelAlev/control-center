import 'package:cc_domain/core/domain/ports/git_command_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_infra/cc_infra.dart';

/// Orchestrates the deterministic review axes (PRD 18 §7) and records their
/// results honestly.
///
/// Deterministic axes (API-contract, visual) are pure computation — no tokens.
/// Each records a [ReviewAxisResult]; a gated axis that could not clear holds
/// the overall verdict (absence of evidence never greens a gate). Token axes
/// (correctness/security/test-gap) run as reviewer-agent fan-out elsewhere;
/// their results are recorded as they finalize.
class ReviewAxisService {
  /// Creates a [ReviewAxisService].
  ReviewAxisService({
    required ApiContractDiffService contractService,
    required VisualDiffService visualService,
    required ReviewAxisResultRepository axisResults,
  }) : _contract = contractService,
       _visual = visualService,
       _axisResults = axisResults;

  final ApiContractDiffService _contract;
  final VisualDiffService _visual;
  final ReviewAxisResultRepository _axisResults;

  /// Runs the API-contract axis: diffs changed specs, records the axis result.
  /// Returns null when no spec files changed (the axis is not applicable).
  Future<ReviewAxisResult?> runContractAxis({
    required String workspaceId,
    required String repoId,
    required String prExternalId,
    required String baseSha,
    required String headSha,
    required List<String> changedFiles,
    required ContentReader readContent,
  }) async {
    if (_contract.matchingSpecs(changedFiles).isEmpty) {
      return null;
    }
    final diffs = await _contract.compute(
      workspaceId: workspaceId,
      repoId: repoId,
      prExternalId: prExternalId,
      baseSha: baseSha,
      headSha: headSha,
      changedFiles: changedFiles,
      readContent: readContent,
    );
    final result = contractAxisResult(diffs);
    await _axisResults.upsert(workspaceId, prExternalId, result);
    return result;
  }

  /// Runs the visual axis: renders + diffs changed components, records the axis
  /// result (honest `unavailable` when no Flutter SDK / no Widgetbook).
  Future<ReviewAxisResult> runVisualAxis({
    required String workspaceId,
    required String repoId,
    required String prExternalId,
    required String repoPath,
    required GitCommandPort git,
    required String baseSha,
    required String headSha,
  }) async {
    final outcome = await _visual.compute(
      workspaceId: workspaceId,
      repoId: repoId,
      prExternalId: prExternalId,
      repoPath: repoPath,
      git: git,
      baseSha: baseSha,
      headSha: headSha,
    );
    final result = visualAxisResult(outcome);
    await _axisResults.upsert(workspaceId, prExternalId, result);
    return result;
  }

  /// Derives the API-contract axis result from its diffs. Gated: a rejected or
  /// unresolved breaking change fails the gate; breaking-but-approved warns;
  /// no breaking passes. Derived contracts never gate.
  static ReviewAxisResult contractAxisResult(List<ApiContractDiff> diffs) {
    final gateBlocking = diffs.any((d) => d.blocksGate);
    final hasBreaking = diffs.any((d) => d.hasBreaking);
    final count = diffs.fold<int>(0, (sum, d) => sum + d.changes.length);
    final ReviewAxisVerdict verdict;
    final String note;
    if (gateBlocking) {
      verdict = ReviewAxisVerdict.fail;
      note = 'Breaking contract change awaiting decision';
    } else if (hasBreaking) {
      verdict = ReviewAxisVerdict.warn;
      note = 'Breaking changes approved';
    } else {
      verdict = ReviewAxisVerdict.pass;
      note = '';
    }
    return ReviewAxisResult(
      axis: ReviewAxis.apiContract,
      verdict: verdict,
      findingsCount: count,
      gated: true,
      confidence: 1,
      note: note,
    );
  }

  /// Derives the test-gap axis from the cohorts' deterministic coverage.
  ///
  /// This is the honest half of an axis that is otherwise a reviewer agent's
  /// opinion: "no test file references any symbol this area changed" is a
  /// checkable fact. It stays **advisory** (`gated: false`) because the code
  /// graph only sees static references — a test that exercises the code
  /// through a factory or a DI container is real coverage the graph cannot
  /// see, and gating a merge on a false negative would be worse than useless.
  ///
  /// Reports `unavailable` — never `pass` — when no cohort could determine
  /// coverage (an unindexed repo, or a diff that touched no resolvable
  /// symbol). An unindexed repo with a thorough suite and one with no tests at
  /// all look identical from here, so claiming either is a lie.
  static ReviewAxisResult testGapAxisFromCohorts(List<ReviewCohort> cohorts) {
    final known = [
      for (final c in cohorts)
        if (c.insights.testCoverageKnown) c,
    ];
    if (known.isEmpty) {
      return const ReviewAxisResult(
        axis: ReviewAxis.testGap,
        verdict: ReviewAxisVerdict.unavailable,
        findingsCount: 0,
        gated: false,
        confidence: 1,
        note: 'repo not indexed — coverage could not be determined',
      );
    }
    final uncovered = [
      for (final c in known)
        if (c.insights.coveringTests.isEmpty) c.title,
    ];
    if (uncovered.isEmpty) {
      return ReviewAxisResult(
        axis: ReviewAxis.testGap,
        verdict: ReviewAxisVerdict.pass,
        findingsCount: 0,
        gated: false,
        confidence: 1,
        note: 'every area has a referencing test (${known.length} area(s))',
      );
    }
    final named = uncovered.take(3).join(', ');
    final rest = uncovered.length > 3 ? ' +${uncovered.length - 3} more' : '';
    return ReviewAxisResult(
      axis: ReviewAxis.testGap,
      verdict: ReviewAxisVerdict.warn,
      findingsCount: uncovered.length,
      gated: false,
      confidence: 1,
      note: 'no referencing test found for: $named$rest',
    );
  }

  /// Derives the visual axis result from the harness outcome. Unavailable when
  /// the host/repo can't render (honest, never a silent pass); otherwise gated:
  /// any unapproved change fails until the operator approves the intended
  /// change; all approved/unchanged passes.
  static ReviewAxisResult visualAxisResult(VisualDiffOutcome outcome) {
    if (!outcome.available) {
      return ReviewAxisResult(
        axis: ReviewAxis.visual,
        verdict: ReviewAxisVerdict.unavailable,
        findingsCount: 0,
        gated: true,
        confidence: 1,
        note: 'unavailable — ${outcome.reason}',
      );
    }
    final unapproved = outcome.snapshots.where((s) => s.blocksGate).length;
    if (unapproved > 0) {
      return ReviewAxisResult(
        axis: ReviewAxis.visual,
        verdict: ReviewAxisVerdict.fail,
        findingsCount: unapproved,
        gated: true,
        confidence: 1,
        note: '$unapproved change(s) awaiting approval',
      );
    }
    return ReviewAxisResult(
      axis: ReviewAxis.visual,
      verdict: ReviewAxisVerdict.pass,
      findingsCount: outcome.snapshots.length,
      gated: true,
      confidence: 1,
      note: '',
    );
  }
}
