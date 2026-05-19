import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/visual_diff.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Identifies a PR across the Review Studio provider family.
class ReviewStudioTarget {
  /// Creates a [ReviewStudioTarget].
  const ReviewStudioTarget({
    required this.owner,
    required this.repo,
    required this.prNumber,
  });

  /// Repository owner.
  final String owner;

  /// Repository name.
  final String repo;

  /// PR number.
  final int prNumber;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewStudioTarget &&
          owner == other.owner &&
          repo == other.repo &&
          prNumber == other.prNumber;

  @override
  int get hashCode => Object.hash(owner, repo, prNumber);
}

/// The Review Studio RPC repository (PRD 18) over the bound-workspace session.
final reviewStudioRepositoryProvider = Provider<RemoteReviewStudioRepository>(
  (ref) => RemoteReviewStudioRepository(ref.watch(rpcClientProvider)),
);

/// Live semantic cohorts for a PR, in reading order (§1).
final reviewCohortsProvider = StreamProvider.autoDispose
    .family<List<ReviewCohort>, ReviewStudioTarget>(
      (ref, t) => ref
          .watch(reviewStudioRepositoryProvider)
          .watchCohorts(t.owner, t.repo, t.prNumber),
    );

/// Live API-contract diffs for a PR (§5).
final reviewContractDiffsProvider = StreamProvider.autoDispose
    .family<List<ApiContractDiff>, ReviewStudioTarget>(
      (ref, t) => ref
          .watch(reviewStudioRepositoryProvider)
          .watchContractDiffs(t.owner, t.repo, t.prNumber),
    );

/// Live UI visual-diff snapshots for a PR (§4).
final reviewVisualDiffsProvider = StreamProvider.autoDispose
    .family<List<VisualDiffSnapshot>, ReviewStudioTarget>(
      (ref, t) => ref
          .watch(reviewStudioRepositoryProvider)
          .watchVisualDiffs(t.owner, t.repo, t.prNumber),
    );

/// Live per-axis results for a PR (§7).
final reviewAxisResultsProvider = StreamProvider.autoDispose
    .family<List<ReviewAxisResult>, ReviewStudioTarget>(
      (ref, t) => ref
          .watch(reviewStudioRepositoryProvider)
          .watchAxisResults(t.owner, t.repo, t.prNumber),
    );

/// The overall verdict, aggregated from the axis results honestly (§7/§9). A
/// gated axis that could not clear holds the verdict; a gated failure blocks.
final reviewStudioVerdictProvider = Provider.autoDispose
    .family<ReviewVerdict, ReviewStudioTarget>((ref, t) {
      final axes =
          ref.watch(reviewAxisResultsProvider(t)).asData?.value ?? const [];
      const base = ReviewVerdict(
        overall: ReviewVerdictOverall.ship,
        confidence: 1,
        explanation: '',
        counts: {},
      );
      return base.withAxisResults(axes);
    });

/// The blast radius for a changed file (§6): the reverse-dependency subgraph
/// (`{indexed, root, nodes, edges}`).
final reviewBlastRadiusProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({ReviewStudioTarget target, String file})>(
      (ref, args) => ref
          .watch(reviewStudioRepositoryProvider)
          .blastRadius(
            owner: args.target.owner,
            repo: args.target.repo,
            filePath: args.file,
          ),
    );

/// Triggers a server-side recompute of cohorts + deterministic axes for a PR.
/// Idempotent; call on studio open and on demand.
final reviewStudioComputeProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ReviewStudioTarget>(
      (ref, t) => ref
          .watch(reviewStudioRepositoryProvider)
          .compute(t.owner, t.repo, t.prNumber),
    );

/// The center pane of the studio (which surface is showing).
enum ReviewStudioPane {
  /// Guided walkthrough with cohorts + diagrams (§2/§3).
  walkthrough,

  /// Swagger-style API-contract diff (§5).
  contract,

  /// UI component visual diff (§4).
  visual,

  /// Beyond-the-diff blast-radius map (§6).
  blastRadius,
}

/// Which center pane the studio is showing.
final reviewStudioPaneProvider = StateProvider.autoDispose<ReviewStudioPane>(
  (ref) => ReviewStudioPane.walkthrough,
);

/// The selected cohort key (drives the context rail + walkthrough scroll).
final selectedCohortKeyProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// The selected changed file for the blast-radius view.
final selectedBlastFileProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// The active confidence-band floor for finding filtering (§9), 0..1.
final reviewConfidenceFloorProvider = StateProvider.autoDispose<double>(
  (ref) => 0.0,
);
