import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/services/finding_cohort_router.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/compute_area_risk_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_dependency_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/visual_diff.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/review_hub_providers.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// The deterministic signals that belong to ONE review area, joined from the
/// streams the hub already watches.
///
/// A sibling of the routed findings rather than part of them: the router's job
/// is "which findings belong to this area", and these answer "what else is true
/// about it". Keeping them apart means the routing rule stays the single thing
/// it is, and a new signal lands here without touching it.
class ReviewAreaSignals {
  /// Creates a [ReviewAreaSignals].
  const ReviewAreaSignals({
    required this.area,
    this.contractDiffs = const [],
    this.visualDiffs = const [],
    this.dependencyDiffs = const [],
    this.locChanged = 0,
  });

  /// The routed area this describes.
  final CohortFindings<ReviewFinding> area;

  /// API-contract diffs whose spec file lives in this area.
  final List<ApiContractDiff> contractDiffs;

  /// Visual diffs whose component maps into this area.
  final List<VisualDiffSnapshot> visualDiffs;

  /// Dependency lockfile diffs in this area.
  final List<PrDependencyDiff> dependencyDiffs;

  /// Added + removed lines across the area's files.
  final int locChanged;

  /// Whether the area changes an API contract.
  bool get hasContractChange => contractDiffs.isNotEmpty;

  /// Whether the area breaks an API contract.
  bool get hasBreakingContract => contractDiffs.any((d) => d.hasBreaking);

  /// Whether the area changes a rendered component.
  bool get hasVisualDiff => visualDiffs.isNotEmpty;

  /// Whether the area moves any dependency.
  bool get hasDependencyChange => dependencyDiffs.any((d) => !d.isEmpty);

  /// Largest visual change percentage among the area's components.
  double get visualChangedPercentMax {
    var max = 0.0;
    for (final snapshot in visualDiffs) {
      for (final variant in snapshot.variants) {
        if (variant.changedRegionPercent > max) {
          max = variant.changedRegionPercent;
        }
      }
    }
    return max;
  }

  /// Added + removed + upgraded dependency count across the area's lockfiles.
  int get dependencyChurn => dependencyDiffs.fold(0, (sum, d) => sum + d.churn);

  /// Breaking contract changes in this area.
  int get contractBreakingCount => contractDiffs.fold(
    0,
    (sum, d) => sum + d.changes.where((c) => c.isBreaking).length,
  );
}

/// The deterministic signals for every area of a PR, keyed by cohort key.
final reviewHubAreaSignalsProvider = Provider.autoDispose
    .family<Map<String, ReviewAreaSignals>, ReviewHubTarget>((ref, t) {
      final routing = ref.watch(reviewHubAreasProvider(t));
      final contracts =
          ref.watch(reviewContractDiffsProvider(t.studio)).asData?.value ??
          const <ApiContractDiff>[];
      final visuals =
          ref.watch(reviewVisualDiffsProvider(t.studio)).asData?.value ??
          const <VisualDiffSnapshot>[];
      final dependencies =
          ref.watch(reviewHubDependencyDiffsProvider(t.studio)).asData?.value ??
          const <PrDependencyDiff>[];
      final files =
          ref.watch(prFilesProvider(t.studio.prNumber)).asData?.value ??
          const <PrFile>[];

      final locByFile = {
        for (final f in files) f.filename: f.additions + f.deletions,
      };

      return {
        for (final area in routing.areas)
          area.cohort.cohortKey: _signalsFor(
            area: area,
            contracts: contracts,
            visuals: visuals,
            dependencies: dependencies,
            locByFile: locByFile,
          ),
      };
    });

ReviewAreaSignals _signalsFor({
  required CohortFindings<ReviewFinding> area,
  required List<ApiContractDiff> contracts,
  required List<VisualDiffSnapshot> visuals,
  required List<PrDependencyDiff> dependencies,
  required Map<String, int> locByFile,
}) {
  final paths = area.cohort.filePaths.toSet();
  var loc = 0;
  for (final path in paths) {
    loc += locByFile[path] ?? 0;
  }
  return ReviewAreaSignals(
    area: area,
    contractDiffs: [
      for (final d in contracts)
        if (paths.contains(d.specPath)) d,
    ],
    // A visual snapshot is keyed by component, not by file. Match on the
    // component key naming a file in the area — a component whose key we
    // cannot place stays on the PR-level view rather than being attributed to
    // an arbitrary area.
    visualDiffs: [
      for (final v in visuals)
        if (paths.any(
          (p) => v.componentKey.contains(p) || p.contains(v.componentKey),
        ))
          v,
    ],
    dependencyDiffs: [
      for (final d in dependencies)
        if (paths.contains(d.filePath)) d,
    ],
    locChanged: loc,
  );
}

/// Live dependency lockfile diffs for a PR.
final reviewHubDependencyDiffsProvider = StreamProvider.autoDispose
    .family<List<PrDependencyDiff>, ReviewStudioTarget>(
      (ref, t) => ref
          .watch(reviewStudioRepositoryProvider)
          .watchDependencyDiffs(t.owner, t.repo, t.prNumber),
    );

/// Structured failure signals from the PR's failing CI jobs.
final reviewHubCiSignalsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ReviewStudioTarget>(
      (ref, t) => ref
          .watch(reviewStudioRepositoryProvider)
          .ciSignals(owner: t.owner, repo: t.repo, prNumber: t.prNumber),
    );

/// Aggregated review-effectiveness counters for the workspace.
final reviewHubStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.watch(reviewStudioRepositoryProvider).reviewStats(),
);

/// The deterministic risk score of every area, keyed by cohort key.
final reviewHubAreaRiskProvider = Provider.autoDispose
    .family<Map<String, AreaRisk>, ReviewHubTarget>((ref, t) {
      const useCase = ComputeAreaRiskUseCase();
      final signals = ref.watch(reviewHubAreaSignalsProvider(t));
      return {
        for (final entry in signals.entries)
          entry.key: useCase.execute(_inputFor(entry.value)),
      };
    });

AreaRiskInput _inputFor(ReviewAreaSignals s) {
  final cohort = s.area.cohort;
  return AreaRiskInput(
    locChanged: s.locChanged,
    fileCount: cohort.filePaths.length,
    impactScore: cohort.impactScore,
    p0Count: s.area.p0Count,
    p1Count: s.area.p1Count,
    filePaths: cohort.filePaths,
    contractBreakingCount: s.contractBreakingCount,
    visualChangedPercentMax: s.visualChangedPercentMax,
    dependencyChurn: s.dependencyChurn,
    // Null when the graph could not tell — which must not be read as zero.
    coveringTestCount: cohort.insights.coveringTestCount,
  );
}

/// Whether the area nav orders by deterministic risk instead of impact.
///
/// Impact stays the default: it is what the cohort ranking already means, and
/// risk depends on findings that do not exist until a review has run.
final reviewHubOrderByRiskProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
