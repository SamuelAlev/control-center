import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/features/pr_review/domain/services/finding_cohort_router.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/presentation/review_hub/review_hub_delta_strip.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Identifies a review hub surface: the studio target plus the PR channel the
/// findings stream from (null before the channel exists).
typedef ReviewHubTarget = ({ReviewStudioTarget studio, String? channelId});

/// The findings of a channel, parsed and sorted (empty while loading). The
/// single findings source every hub surface reads.
///
/// Applies the confidence-band floor (PRD 18 §9) here rather than per surface,
/// so the areas, the deep dives and the accordion can never disagree about
/// which findings exist. The floor defaults to 0.0 — a no-op until the reader
/// raises it.
final reviewHubFindingsProvider = Provider.autoDispose
    .family<List<ReviewFinding>, String?>((ref, channelId) {
      if (channelId == null) {
        return const <ReviewFinding>[];
      }
      final messages = ref
          .watch(channelMessagesProvider(channelId))
          .asData
          ?.value;
      if (messages == null) {
        return const <ReviewFinding>[];
      }
      final floor = ref.watch(reviewConfidenceFloorProvider);
      final findings = parseAndSortFindings(messages);
      if (floor <= 0) {
        return findings;
      }
      return [
        for (final f in findings)
          // A P0 is never hidden by a confidence band: the whole point of the
          // floor is to quiet low-confidence noise, not to suppress the
          // findings that block a merge.
          if (f.payload.confidence >= floor ||
              f.payload.priority == ReviewNodePriority.p0)
            f,
      ];
    });

/// Findings routed into the deterministic areas (cohorts): the join that makes
/// Findings and Studio ONE review. Routing rules live in the shared domain
/// [FindingCohortRouter] (stamped key → anchor file → repository-wide).
final reviewHubAreasProvider = Provider.autoDispose
    .family<FindingCohortRouting<ReviewFinding>, ReviewHubTarget>((ref, t) {
      final cohorts =
          ref.watch(reviewCohortsProvider(t.studio)).asData?.value ?? const [];
      final findings = ref.watch(reviewHubFindingsProvider(t.channelId));
      return const FindingCohortRouter().route(
        cohorts: cohorts,
        findings: findings,
        payloadOf: (f) => f.payload,
      );
    });

/// The finalized review summary of a channel: the unified verdict (findings
/// escalated by the studio axes), the structured walkthrough and the raw
/// markdown body. Null while no `review_summary` message exists.
class ReviewHubSummary {
  /// Creates a [ReviewHubSummary].
  const ReviewHubSummary({
    required this.verdict,
    required this.markdown,
    this.walkthrough,
    this.delta,
  });

  /// The verdict posted at finalize time.
  final ReviewVerdict verdict;

  /// The structured walkthrough, when the summary carried one.
  final ReviewWalkthroughSummary? walkthrough;

  /// The full summary markdown body.
  final String markdown;

  /// What moved since the previous finalized pass; null on a first review.
  final ReviewDelta? delta;

  /// Value equality, and it is load-bearing rather than hygiene.
  ///
  /// This is derived state: the provider recomputes it whenever ANY message in
  /// the channel changes, and a `Provider` notifies its listeners when the new
  /// value is `!=` the old one. Without `==` that is identity, so a brand-new
  /// instance of an unchanged summary notified every time — the verdict banner
  /// rebuilt on every chat message in the thread even though the verdict had
  /// not moved since the review finalized.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewHubSummary &&
          runtimeType == other.runtimeType &&
          verdict == other.verdict &&
          walkthrough == other.walkthrough &&
          markdown == other.markdown &&
          delta == other.delta;

  @override
  int get hashCode => Object.hash(verdict, walkthrough, markdown, delta);
}

/// The finalized summary of a review channel, parsed from its summary message
/// (null until the review was finalized or the channel has no summary yet).
final reviewHubSummaryProvider = Provider.autoDispose
    .family<ReviewHubSummary?, String?>((ref, channelId) {
      if (channelId == null) {
        return null;
      }
      final messages = ref
          .watch(channelMessagesProvider(channelId))
          .asData
          ?.value;
      if (messages == null) {
        return null;
      }
      final summaries =
          messages
              .where((m) => m.messageType == ChannelMessageType.reviewSummary)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (summaries.isEmpty) {
        return null;
      }
      final latest = summaries.first;
      final verdict = ReviewVerdict.fromMetadata(latest.metadata);
      if (verdict == null) {
        return null;
      }
      return ReviewHubSummary(
        verdict: verdict,
        markdown: latest.content,
        walkthrough: ReviewWalkthroughSummary.fromMetadata(latest.metadata),
        delta: ReviewDelta.fromMetadata(latest.metadata),
      );
    });

/// The merged impact subgraph for a cohort (the deep-dive view): raw
/// `{indexed, roots, nodes, edges}` payload from `review_studio.cohortImpact`.
final reviewHubCohortImpactProvider = FutureProvider.autoDispose
    .family<
      Map<String, dynamic>,
      ({ReviewStudioTarget target, String cohortKey})
    >(
      (ref, args) => ref
          .watch(reviewStudioRepositoryProvider)
          .cohortImpact(
            owner: args.target.owner,
            repo: args.target.repo,
            prNumber: args.target.prNumber,
            cohortKey: args.cohortKey,
          ),
    );

/// The selected area (cohort key) whose deep dive is showing; null = the
/// PR-level overview.
final reviewHubSelectedAreaProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
