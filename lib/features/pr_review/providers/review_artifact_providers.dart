import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/presentation/review_artifact/review_artifact_delta.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies a review artifact: the studio target plus the PR space the
/// findings stream from (null before the space exists).
typedef ReviewArtifactTarget = ({ReviewStudioTarget studio, String? spaceId});

/// The findings of a space, parsed and sorted (empty while loading). The
/// single findings source every part of the artifact reads.
///
/// Applies the confidence-band floor (PRD 18 §9) here rather than per surface,
/// so the header count and the accordion can never disagree about which
/// findings exist. The floor defaults to 0.0 — a no-op until the reader
/// raises it.
final reviewArtifactFindingsProvider = Provider.autoDispose
    .family<List<ReviewFinding>, String?>((ref, spaceId) {
      if (spaceId == null) {
        return const <ReviewFinding>[];
      }
      final messages = ref
          .watch(spaceWideMessagesProvider(spaceId))
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

/// The finalized review summary of a space: the unified verdict (findings
/// escalated by the studio axes), the structured walkthrough and the raw
/// markdown body. Null while no `review_summary` message exists.
class ReviewArtifact {
  /// Creates a [ReviewArtifact].
  const ReviewArtifact({
    required this.verdict,
    required this.markdown,
    this.headSha,
    this.walkthrough,
    this.delta,
    this.nitpickMessageIds = const {},
  });

  /// The verdict posted at finalize time.
  final ReviewVerdict verdict;

  /// The commit this review actually read.
  ///
  /// Read from the summary directly rather than through [walkthrough], which
  /// is absent on a clean review — a review with nothing to say authors no
  /// narrative, so sourcing the commit from one would leave exactly the
  /// reviews that pass unable to report that they had gone stale.
  final String? headSha;

  /// The structured walkthrough, when the summary carried one.
  final ReviewWalkthroughSummary? walkthrough;

  /// The full summary markdown body.
  final String markdown;

  /// What moved since the previous finalized pass; null on a first review.
  final ReviewDelta? delta;

  /// Findings the review level set aside into the nitpick group.
  ///
  /// Computed server-side at finalize, not re-derived here: the level that
  /// produced this review is the one that decided, and a client recomputing it
  /// against the CURRENT workspace setting would silently regroup an old
  /// review the moment somebody changed the dial.
  final Set<String> nitpickMessageIds;

  /// Value equality, and it is load-bearing rather than hygiene.
  ///
  /// This is derived state: the provider recomputes it whenever ANY message in
  /// the space changes, and a `Provider` notifies its listeners when the new
  /// value is `!=` the old one. Without `==` that is identity, so a brand-new
  /// instance of an unchanged summary notified every time — the verdict banner
  /// rebuilt on every chat message in the thread even though the verdict had
  /// not moved since the review finalized.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewArtifact &&
          runtimeType == other.runtimeType &&
          verdict == other.verdict &&
          headSha == other.headSha &&
          walkthrough == other.walkthrough &&
          markdown == other.markdown &&
          delta == other.delta &&
          const SetEquality<String>().equals(
            nitpickMessageIds,
            other.nitpickMessageIds,
          );

  @override
  int get hashCode => Object.hash(
    verdict,
    headSha,
    walkthrough,
    markdown,
    delta,
    const SetEquality<String>().hash(nitpickMessageIds),
  );
}

/// The finalized summary of a review space, parsed from its summary message
/// (null until the review was finalized or the space has no summary yet).
final reviewArtifactProvider = Provider.autoDispose
    .family<ReviewArtifact?, String?>((ref, spaceId) {
      if (spaceId == null) {
        return null;
      }
      final messages = ref
          .watch(spaceWideMessagesProvider(spaceId))
          .asData
          ?.value;
      if (messages == null) {
        return null;
      }
      final summaries =
          messages
              .where((m) => m.messageType == MessageType.reviewSummary)
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
      return ReviewArtifact(
        verdict: verdict,
        markdown: latest.content,
        headSha: switch (latest.metadata?['summaryHeadSha']) {
          final String s when s.isNotEmpty => s,
          _ => null,
        },
        walkthrough: ReviewWalkthroughSummary.fromMetadata(latest.metadata),
        delta: ReviewDelta.fromMetadata(latest.metadata),
        nitpickMessageIds: switch (latest.metadata?['nitpickMessageIds']) {
          final List raw => raw.whereType<String>().toSet(),
          _ => const <String>{},
        },
      );
    });
