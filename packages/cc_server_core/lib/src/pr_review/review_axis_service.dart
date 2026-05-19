import 'package:cc_domain/core/domain/ports/git_command_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
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
    required String prNodeId,
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
      prNodeId: prNodeId,
      baseSha: baseSha,
      headSha: headSha,
      changedFiles: changedFiles,
      readContent: readContent,
    );
    final result = contractAxisResult(diffs);
    await _axisResults.upsert(workspaceId, prNodeId, result);
    return result;
  }

  /// Runs the visual axis: renders + diffs changed components, records the axis
  /// result (honest `unavailable` when no Flutter SDK / no Widgetbook).
  Future<ReviewAxisResult> runVisualAxis({
    required String workspaceId,
    required String repoId,
    required String prNodeId,
    required String repoPath,
    required GitCommandPort git,
    required String baseSha,
    required String headSha,
  }) async {
    final outcome = await _visual.compute(
      workspaceId: workspaceId,
      repoId: repoId,
      prNodeId: prNodeId,
      repoPath: repoPath,
      git: git,
      baseSha: baseSha,
      headSha: headSha,
    );
    final result = visualAxisResult(outcome);
    await _axisResults.upsert(workspaceId, prNodeId, result);
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
