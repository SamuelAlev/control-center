import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_publisher_port.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/build_github_review_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/compute_review_verdict_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/github_review_plan.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';

/// Publishes a workspace's structured review findings to GitHub as a single
/// pull-request review: inline line-anchored comments plus a verdict summary.
///
/// This is the user-gated publish step that `finalize_review` deliberately
/// defers. It reuses the same consensus rule and verdict computation, then
/// maps the findings into a [GitHubReviewPlan] via [BuildGitHubReviewUseCase]
/// and submits it. If GitHub rejects an inline anchor that is not part of the
/// diff (422), the findings are folded into the body so nothing is dropped.
class ReviewPublisherService implements ReviewPublisherPort {
  /// Creates a [ReviewPublisherService].
  ReviewPublisherService({
    required GitHubPrClient githubPrClient,
    required MessagingRepository messaging,
    required ReviewChannelRepository reviewChannels,
    BuildGitHubReviewUseCase? buildReview,
    ComputeReviewVerdictUseCase? computeVerdict,
  })  : _github = githubPrClient,
        _messaging = messaging,
        _reviewChannels = reviewChannels,
        _buildReview = buildReview ?? const BuildGitHubReviewUseCase(),
        _computeVerdict = computeVerdict ?? const ComputeReviewVerdictUseCase();

  final GitHubPrClient _github;
  final MessagingRepository _messaging;
  final ReviewChannelRepository _reviewChannels;
  final BuildGitHubReviewUseCase _buildReview;
  final ComputeReviewVerdictUseCase _computeVerdict;

  /// Publishes the review for [channelId]. [workspaceId] is required and
  /// enforced: a channel owned by another workspace is rejected loudly with a
  /// [WorkspaceMismatchException] rather than leaking across the boundary.
  ///
  /// Marks the association `completed` on a successful submit.
  @override
  Future<PublishReviewResult> publish({
    required String workspaceId,
    required String channelId,
    ReviewPublishSelection selection = ReviewPublishSelection.consensus,
    bool approveOnShip = false,
  }) async {
    final association = await _reviewChannels.watchByChannel(channelId).first;
    if (association == null) {
      throw ArgumentError('Channel $channelId is not linked to a PR review.');
    }
    if (association.workspaceId != workspaceId) {
      throw WorkspaceMismatchException(
        'Review channel $channelId belongs to a different workspace.',
      );
    }
    final parts = association.repoFullName.split('/');
    if (parts.length != 2) {
      throw ArgumentError('Invalid repoFullName: ${association.repoFullName}');
    }
    final owner = parts[0];
    final repo = parts[1];

    final messages = await _messaging.getMessages(channelId);
    final drafts = _selectFindings(messages, selection);
    final verdict =
        _computeVerdict.execute(drafts.map((d) => d.payload).toList());
    final plan = _buildReview.execute(
      findings: drafts,
      verdict: verdict,
      approveOnShip: approveOnShip,
    );

    final submitted = await _submit(
      owner: owner,
      repo: repo,
      prNumber: association.prNumber,
      plan: plan,
    );

    if (association.status != ReviewChannelStatus.completed) {
      await _reviewChannels.updateStatus(
        association.id,
        ReviewChannelStatus.completed,
      );
    }

    return PublishReviewResult(
      reviewId: submitted.reviewId,
      event: plan.event,
      findingCount: drafts.length,
      inlineCount: submitted.usedFallback ? 0 : plan.inlineComments.length,
      usedFallback: submitted.usedFallback,
    );
  }

  List<ReviewFindingDraft> _selectFindings(
    List<ChannelMessage> messages,
    ReviewPublishSelection selection,
  ) {
    final drafts = <ReviewFindingDraft>[];
    for (final m in messages) {
      if (m.messageType != ChannelMessageType.reviewNode) {
        continue;
      }
      final payload = ReviewNodePayload.fromMetadata(m.metadata);
      if (payload == null) {
        continue;
      }
      if (payload.status == ReviewNodeStatus.dismissed ||
          payload.status == ReviewNodeStatus.resolved) {
        continue;
      }
      if (selection == ReviewPublishSelection.consensus) {
        // Author cannot self-confirm — mirror finalize_review's rule.
        final peers =
            payload.confirmedBy.where((id) => id != m.senderId).toList();
        if (peers.isEmpty) {
          continue;
        }
      }
      drafts.add(ReviewFindingDraft(payload: payload, content: m.content));
    }
    return drafts;
  }

  Future<({int reviewId, bool usedFallback})> _submit({
    required String owner,
    required String repo,
    required int prNumber,
    required GitHubReviewPlan plan,
  }) async {
    if (plan.inlineComments.isEmpty) {
      final review = await _github.submitReview(
        owner,
        repo,
        prNumber: prNumber,
        event: plan.event,
        body: plan.body,
      );
      return (reviewId: review.id, usedFallback: false);
    }
    try {
      final review = await _github.submitReview(
        owner,
        repo,
        prNumber: prNumber,
        event: plan.event,
        body: plan.body,
        comments: plan.inlineComments.map((c) => c.toJson()).toList(),
      );
      return (reviewId: review.id, usedFallback: false);
    } on NetworkException catch (e) {
      // A 422 means at least one inline anchor isn't part of the diff; GitHub
      // rejects the whole review. Fold the findings into the body so they are
      // never silently dropped. Re-throw anything else (auth, network, 5xx).
      if (e.statusCode != 422) {
        rethrow;
      }
      final flat = plan.flattenedToBody();
      final review = await _github.submitReview(
        owner,
        repo,
        prNumber: prNumber,
        event: flat.event,
        body: flat.body,
      );
      return (reviewId: review.id, usedFallback: true);
    }
  }
}
