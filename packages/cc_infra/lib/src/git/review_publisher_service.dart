import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_publisher_port.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_anchor_index.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/build_github_review_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/compute_review_verdict_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/github_review_plan.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
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
  ///
  /// [githubPrClientFor] resolves the client to submit on, given the acting
  /// user. Resolved per publish rather than held: the review a person presses
  /// "publish" on has to arrive under THEIR account, and the one an agent
  /// auto-publishes under the server's — one captured client cannot be both.
  ReviewPublisherService({
    required GitHubPrClient Function(String? actingUserId) githubPrClientFor,
    required MessagingRepository messaging,
    required ReviewSpaceRepository reviewSpaces,
    BuildGitHubReviewUseCase? buildReview,
    ComputeReviewVerdictUseCase? computeVerdict,
  }) : _githubFor = githubPrClientFor,
       _messaging = messaging,
       _reviewSpaces = reviewSpaces,
       _buildReview = buildReview ?? const BuildGitHubReviewUseCase(),
       _computeVerdict = computeVerdict ?? const ComputeReviewVerdictUseCase();

  final GitHubPrClient Function(String? actingUserId) _githubFor;
  final MessagingRepository _messaging;
  final ReviewSpaceRepository _reviewSpaces;
  final BuildGitHubReviewUseCase _buildReview;
  final ComputeReviewVerdictUseCase _computeVerdict;

  /// Publishes the review for [spaceId]. [workspaceId] is required and
  /// enforced: a space owned by another workspace is rejected loudly with a
  /// [WorkspaceMismatchException] rather than leaking across the boundary.
  ///
  /// Marks the association `completed` on a successful submit.
  @override
  Future<PublishReviewResult> publish({
    required String workspaceId,
    required String spaceId,
    ReviewPublishSelection selection = ReviewPublishSelection.consensus,
    bool approveOnShip = false,
    String? actingUserId,
  }) async {
    final association = await _reviewSpaces
        .watchBySpace(workspaceId, spaceId)
        .first;
    if (association == null) {
      throw ArgumentError('Channel $spaceId is not linked to a PR review.');
    }
    if (association.workspaceId != workspaceId) {
      throw WorkspaceMismatchException(
        'Review channel $spaceId belongs to a different workspace.',
      );
    }
    final parts = association.repoFullName.split('/');
    if (parts.length != 2) {
      throw ArgumentError('Invalid repoFullName: ${association.repoFullName}');
    }
    final owner = parts[0];
    final repo = parts[1];

    // Space-wide: findings are filed in each reviewer's own stream, so
    // publishing must gather from every conversation in the room or it posts a
    // subset of the review to GitHub.
    final messages = await _messaging.getSpaceMessages(workspaceId, spaceId);
    final drafts = _selectFindings(messages, selection);
    // The finalized summary's verdict is the authoritative one (findings
    // escalated by the studio axes at finalize time); fall back to computing
    // from the selected drafts when no summary was posted yet.
    final summary = _latestSummary(messages);
    final verdict =
        ReviewVerdict.fromMetadata(summary?.metadata) ??
        _computeVerdict.execute(drafts.map((d) => d.payload).toList());
    final plan = _buildReview.execute(
      findings: drafts,
      verdict: verdict,
      walkthrough: summary == null
          ? null
          : ReviewWalkthroughSummary.fromMetadata(summary.metadata),
      approveOnShip: approveOnShip,
      // What the finalizer demoted at this review's level. Read from the
      // summary rather than recomputed here, so the published review collapses
      // exactly what the app collapsed — recomputing would let the two drift
      // apart the moment the workspace's level changed between finalize and
      // publish.
      nitpickMessageIds: _nitpickIds(summary?.metadata),
      // The PR's diff AS IT STANDS NOW. Publishing can happen long after the
      // review ran, and the author may have rewritten the very lines a finding
      // points at — a comment on code that has already moved on is the most
      // trust-destroying thing a reviewer can leave.
      anchors: await _anchorIndex(
        github: _githubFor(actingUserId),
        owner: owner,
        repo: repo,
        prNumber: association.prNumber,
      ),
    );

    final submitted = await _submit(
      github: _githubFor(actingUserId),
      owner: owner,
      repo: repo,
      prNumber: association.prNumber,
      plan: plan,
    );

    if (association.status != ReviewSpaceStatus.completed) {
      await _reviewSpaces.updateStatus(
        workspaceId,
        association.id,
        ReviewSpaceStatus.completed,
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

  /// The space's most recent `review_summary` message, or null.
  Message? _latestSummary(List<Message> messages) {
    final summaries =
        messages
            .where((m) => m.messageType == MessageType.reviewSummary)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return summaries.isEmpty ? null : summaries.first;
  }

  List<ReviewFindingDraft> _selectFindings(
    List<Message> messages,
    ReviewPublishSelection selection,
  ) {
    final drafts = <ReviewFindingDraft>[];
    for (final m in messages) {
      if (m.messageType != MessageType.reviewNode) {
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
        final peers = payload.confirmedBy
            .where((id) => id != m.senderId)
            .toList();
        if (peers.isEmpty) {
          continue;
        }
      }
      drafts.add(
        ReviewFindingDraft(
          payload: payload,
          content: m.content,
          messageId: m.id,
        ),
      );
    }
    return drafts;
  }

  /// The lines the PR's current diff touches, per changed file.
  ///
  /// Falls back to [DiffAnchorIndex.permissive] on any failure, deliberately:
  /// an empty index would treat every finding as out-of-diff and silently
  /// publish a review with no inline comments, turning one failed API call
  /// into a review that looks like it found nothing.
  Future<DiffAnchorIndex> _anchorIndex({
    required GitHubPrClient github,
    required String owner,
    required String repo,
    required int prNumber,
  }) async {
    try {
      final files = await github.listPullRequestFiles(owner, repo, prNumber);
      if (files.isEmpty) {
        return DiffAnchorIndex.permissive;
      }
      return DiffAnchorIndex.fromPatches({
        for (final f in files) f.filename: f.patch,
      });
    } on Object catch (e) {
      CcInfraLog.warning(
        'review publish: could not read the PR diff to verify anchors '
        '($owner/$repo#$prNumber): $e — publishing every finding inline',
      );
      return DiffAnchorIndex.permissive;
    }
  }

  /// The finding ids the finalizer demoted into the nitpick group, from the
  /// latest `review_summary` metadata. Empty when the review predates levels
  /// or nothing was demoted — in both cases every finding publishes inline,
  /// which is what happened before.
  Set<String> _nitpickIds(Map<String, dynamic>? metadata) {
    final raw = metadata?['nitpickMessageIds'];
    return raw is List ? raw.whereType<String>().toSet() : const {};
  }

  Future<({int reviewId, bool usedFallback})> _submit({
    required GitHubPrClient github,
    required String owner,
    required String repo,
    required int prNumber,
    required GitHubReviewPlan plan,
  }) async {
    if (plan.inlineComments.isEmpty) {
      final review = await github.submitReview(
        owner,
        repo,
        prNumber: prNumber,
        event: plan.event,
        body: plan.body,
      );
      return (reviewId: review.id, usedFallback: false);
    }
    try {
      final review = await github.submitReview(
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
      final review = await github.submitReview(
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
