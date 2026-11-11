import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_publisher_port.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_anchor_index.dart';
import 'package:cc_domain/features/pr_review/domain/services/mention_matcher.dart'
    show neutralizeMentions;
import 'package:cc_domain/features/pr_review/domain/usecases/build_github_review_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/compute_review_verdict_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/github_review_plan.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pending_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Resolves the forge client a review on [repoFullName] is published on, from
/// the workspace's own repo row: ITS forge picks the adapter, and
/// [actingUserId] picks whose name the review carries (null → the
/// workspace's automation identity). Null when the workspace links no forge
/// repo by that name.
typedef ReviewForgeClientResolver =
    Future<ForgePrClient?> Function(
      String? actingUserId, {
      required String workspaceId,
      required String repoFullName,
    });

/// How automation attributes what it posts when the post lands under a
/// person's account rather than a bot's (Connect's shared App mints
/// user-to-server tokens of the workspace's accountable human). Without it a
/// reader cannot tell Control Center's findings from the person's own words,
/// and the PR conversation bridge would not recognise replies in those
/// threads as addressed to it. Answers null when automation posts as a bot
/// account, which is attribution enough.
typedef AutomatedReviewAttribution =
    Future<String Function(String body)?> Function({
      required String workspaceId,
      required String owner,
      String? actingUserId,
    });

/// Publishes a workspace's structured review findings to the repo's forge as
/// one pull-request review: inline line-anchored comments plus a verdict
/// summary, through [ForgePrClient.submitReview].
///
/// This is the user-gated publish step that `finalize_review` deliberately
/// defers. It reuses the same consensus rule and verdict computation, then
/// maps the findings into a [GitHubReviewPlan] via [BuildGitHubReviewUseCase]
/// (GitHub's vocabulary, which the port's verdicts mirror) and submits it.
/// A "changes requested" verdict on a forge without
/// [ForgeCapability.requestChanges] lands as a comment review. If the forge
/// rejects an inline anchor that is not part of the diff (422), the findings
/// are folded into the body so nothing is dropped.
class ReviewPublisherService implements ReviewPublisherPort {
  /// Creates a [ReviewPublisherService].
  ///
  /// [forgeClientFor] resolves the client to submit on, given the acting
  /// user, the workspace and the review's repo. Resolved per publish rather
  /// than held: the review a person presses "publish" on has to arrive under
  /// THEIR account, and the one an agent auto-publishes under the workspace's
  /// background identity — one captured client cannot be both, and the repo
  /// decides which forge it is.
  ReviewPublisherService({
    required ReviewForgeClientResolver forgeClientFor,
    required this._messaging,
    required this._reviewSpaces,
    this._automatedAttribution,
    BuildGitHubReviewUseCase? buildReview,
    ComputeReviewVerdictUseCase? computeVerdict,
  }) : _clientFor = forgeClientFor,
       _buildReview = buildReview ?? const BuildGitHubReviewUseCase(),
       _computeVerdict = computeVerdict ?? const ComputeReviewVerdictUseCase();

  final ReviewForgeClientResolver _clientFor;
  final AutomatedReviewAttribution? _automatedAttribution;
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
    final client = await _clientFor(
      actingUserId,
      workspaceId: workspaceId,
      repoFullName: association.repoFullName,
    );
    if (client == null) {
      throw StateError(
        'No forge repo ${association.repoFullName} is linked to this '
        'workspace.',
      );
    }

    // Space-wide: findings are filed in each reviewer's own stream, so
    // publishing must gather from every conversation in the room or it posts a
    // subset of the review to the forge.
    final messages = await _messaging.getSpaceMessages(workspaceId, spaceId);
    final drafts = _selectFindings(messages, selection);
    // The finalized summary's verdict is the authoritative one (findings
    // escalated by the studio axes at finalize time); fall back to computing
    // from the selected drafts when no summary was posted yet.
    final summary = _latestSummary(messages);
    final verdict =
        ReviewVerdict.fromMetadata(summary?.metadata) ??
        _computeVerdict.execute(drafts.map((d) => d.payload).toList());
    final built = _buildReview.execute(
      findings: drafts,
      verdict: verdict,
      walkthrough: summary == null
          ? null
          : ReviewWalkthroughSummary.fromMetadata(summary.metadata),
      // Automation never approves: only a person pressing publish may ship
      // an APPROVE, and the forge itself refuses one on their own PR.
      approveOnShip: approveOnShip && actingUserId != null,
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
      anchors: await _anchorIndex(client, association.prNumber),
    );
    final plan = _withinCapabilities(built, client.capabilities);

    // A person pressing publish posts their own review, unattributed.
    // Automation posts as the App's bot on every GitHub lane; it names the
    // person it acts for only when the attribution hook finds one.
    final attribute = actingUserId == null && client.forge == ForgeHost.github
        ? await _automatedAttribution?.call(
            workspaceId: workspaceId,
            owner: client.owner,
          )
        : null;
    final submitted = await _submit(
      client: client,
      prNumber: association.prNumber,
      plan: plan,
      // The bot's words (automation) never page anyone; a person's own
      // review says what they publish.
      attribute: actingUserId != null
          ? _unattributed
          : (body) => (attribute ?? _unattributed)(neutralizeMentions(body)),
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
  Future<DiffAnchorIndex> _anchorIndex(
    ForgePrClient client,
    int prNumber,
  ) async {
    try {
      final files = (await client.listFiles(prNumber)).files;
      if (files.isEmpty) {
        return DiffAnchorIndex.permissive;
      }
      return DiffAnchorIndex.fromPatches({
        for (final f in files) f.filename: f.patch,
      });
    } on Object catch (e) {
      CcInfraLog.warning(
        'review publish: could not read the PR diff to verify anchors '
        '(${client.owner}/${client.repo}#$prNumber): $e — publishing every '
        'finding inline',
      );
      return DiffAnchorIndex.permissive;
    }
  }

  /// [plan] as [capabilities] can express it: a "changes requested" verdict
  /// on a forge without one becomes a comment review with the same body.
  static GitHubReviewPlan _withinCapabilities(
    GitHubReviewPlan plan,
    ForgeCapabilities capabilities,
  ) => plan.event == 'REQUEST_CHANGES' && !capabilities.requestChanges
      ? GitHubReviewPlan(
          event: 'COMMENT',
          body: plan.body,
          inlineComments: plan.inlineComments,
        )
      : plan;

  /// The finding ids the finalizer demoted into the nitpick group, from the
  /// latest `review_summary` metadata. Empty when the summary records no
  /// demotions: every finding then publishes inline.
  Set<String> _nitpickIds(Map<String, dynamic>? metadata) {
    final raw = metadata?['nitpickMessageIds'];
    return raw is List ? raw.whereType<String>().toSet() : const {};
  }

  static String _unattributed(String body) => body;

  static ForgeReviewVerdict _verdict(String event) => switch (event) {
    'APPROVE' => ForgeReviewVerdict.approve,
    'REQUEST_CHANGES' => ForgeReviewVerdict.requestChanges,
    _ => ForgeReviewVerdict.comment,
  };

  Future<({int? reviewId, bool usedFallback})> _submit({
    required ForgePrClient client,
    required int prNumber,
    required GitHubReviewPlan plan,
    required String Function(String body) attribute,
  }) async {
    if (plan.inlineComments.isEmpty) {
      final id = await client.submitReview(
        prNumber: prNumber,
        verdict: _verdict(plan.event),
        body: attribute(plan.body),
      );
      return (reviewId: id, usedFallback: false);
    }
    try {
      final id = await client.submitReview(
        prNumber: prNumber,
        verdict: _verdict(plan.event),
        body: attribute(plan.body),
        comments: [
          for (final c in plan.inlineComments)
            PendingReviewComment(
              path: c.path,
              line: c.line,
              body: attribute(c.body),
              side: c.side,
              startLine: c.startLine,
              startSide: c.startSide,
            ),
        ],
      );
      return (reviewId: id, usedFallback: false);
    } on NetworkException catch (e) {
      // A 422 means at least one inline anchor isn't part of the diff; the
      // forge rejects the whole review. Fold the findings into the body so they
      // are never silently dropped. Re-throw anything else (auth, network,
      // 5xx).
      if (e.statusCode != 422) {
        rethrow;
      }
      final flat = plan.flattenedToBody();
      final id = await client.submitReview(
        prNumber: prNumber,
        verdict: _verdict(flat.event),
        body: attribute(flat.body),
      );
      return (reviewId: id, usedFallback: true);
    }
  }
}
