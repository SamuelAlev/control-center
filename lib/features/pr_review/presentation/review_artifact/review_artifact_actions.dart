import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/pr_review/presentation/widgets/ask_ai_review_button.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_accordion_list.dart';
import 'package:control_center/features/pr_review/providers/pr_review_run_providers.dart';
import 'package:control_center/features/pr_review/providers/review_artifact_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The actions that act on a whole published review: publish it to GitHub, or
/// hand its findings to an agent to fix and push.
///
/// A slim bar above the artifact rather than a dashboard header. The verdict,
/// the summary and the findings are IN the artifact — repeating them in chrome
/// above it is how the tab came to read as a dashboard with a document stuck
/// underneath.
class ReviewArtifactActions extends ConsumerStatefulWidget {
  /// Creates a [ReviewArtifactActions].
  const ReviewArtifactActions({
    super.key,
    required this.pr,
    required this.spaceId,
    required this.accordion,
    this.rerunning = false,
  });

  /// The pull request the review belongs to.
  final PullRequest pr;

  /// The review space the findings live in (null when it could not resolve).
  final String? spaceId;

  /// Whether a newer review is in flight over this artifact.
  final bool rerunning;

  /// Reaches into the findings list below, which owns the selection, the
  /// prompt and the dispatch — so "fix" has one implementation, not two.
  final ReviewAccordionController accordion;

  @override
  ConsumerState<ReviewArtifactActions> createState() =>
      _ReviewArtifactActionsState();
}

class _ReviewArtifactActionsState extends ConsumerState<ReviewArtifactActions> {
  bool _publishing = false;

  Future<void> _publish(ReviewSpaceAssociation assoc) async {
    final l10n = AppLocalizations.of(context);
    final toast = CcToastScope.maybeOf(context);
    setState(() => _publishing = true);
    try {
      await ref.read(rpcClientProvider).call('pr_review.publishReview', {
        'workspace_id': assoc.workspaceId,
        'space_id': assoc.spaceId,
        // Every open finding, not just peer-confirmed ones. `consensus`
        // requires a SECOND reviewer to have confirmed a finding, which they
        // rarely do — so it submitted a verdict with nothing under it and read
        // as a button that had done nothing.
        'selection': 'all_open',
        // Let the gravity of the findings pick the GitHub event: block →
        // REQUEST_CHANGES, hold → COMMENT, ship → APPROVE. The conservative
        // default existed so a review could not approve under the OPERATOR's
        // name; it now goes out under the app's, which is the identity that
        // actually formed the opinion.
        'approve_on_ship': true,
      });
      if (!mounted) {
        return;
      }
      ref.invalidate(reviewSpacesForWorkspaceProvider);
      toast?.show(l10n.published, variant: CcToastVariant.success);
    } catch (e) {
      if (!mounted) {
        return;
      }
      toast?.show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
    } finally {
      if (mounted) {
        setState(() => _publishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem!;
    final assoc = ref.watch(
      prReviewAssociationProvider((
        repoFullName: widget.pr.repoFullName,
        prNumber: widget.pr.number,
      )),
    );
    final findings = ref.watch(reviewArtifactFindingsProvider(widget.spaceId));
    final openFindings = findings
        .where((f) => f.payload.status != ReviewNodeStatus.dismissed)
        .length;
    final canPublish =
        assoc != null &&
        assoc.status == ReviewSpaceStatus.awaitingApproval &&
        openFindings > 0;

    // The verbs' labels and scope track the checkboxes, so the bar rebuilds
    // with the controller rather than a frame behind it.
    return AnimatedBuilder(
      animation: widget.accordion,
      builder: (context, _) {
        final selection = widget.accordion.selectedIds;
        final hasSelection = selection.isNotEmpty;
        // Default scope: every open P0–P2 finding. P3 nits are opt-in — they
        // join the scope only when someone ticks their checkbox.
        final scope = hasSelection
            ? selection.toList()
            : [
                for (final f in findings)
                  if ((f.payload.status == ReviewNodeStatus.open ||
                          f.payload.status ==
                              ReviewNodeStatus.consensusReady) &&
                      f.payload.priority != ReviewNodePriority.p3)
                    f.message.id,
              ];

        return Padding(
          padding: const EdgeInsets.all(12),
          // A Wrap, not a Row: the bar carries up to four verbs beside the
          // count, and the findings column is narrow when the rail is open —
          // a Row clipped the trailing actions off the edge.
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.rerunning)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CcSpinner(size: 12),
                    const SizedBox(width: 8),
                    Text(
                      l10n.prReviewRerunning,
                      style: TextStyle(color: ds.textTertiary, fontSize: 12),
                    ),
                  ],
                )
              else
                Text(
                  hasSelection
                      ? l10n.countSelected(scope.length)
                      : openFindings == 0
                      ? l10n.prReviewNoOpenFindings
                      : l10n.prReviewOpenFindings(openFindings),
                  style: TextStyle(color: ds.textTertiary, fontSize: 12),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Hand the findings to an agent that fixes them in the
                  // review space's worktree — which IS the PR branch at its
                  // head — and pushes.
                  if (scope.isNotEmpty && widget.spaceId != null)
                    CcButton(
                      size: CcButtonSize.sm,
                      variant: CcButtonVariant.secondary,
                      onPressed: () => widget.accordion.fixFindings(scope),
                      icon: AppIcons.wrench,
                      child: Text(
                        hasSelection
                            ? l10n.reviewArtifactFixSelected(scope.length)
                            : l10n.reviewArtifactFixAll(scope.length),
                      ),
                    ),
                  if (hasSelection) ...[
                    // A ticked subset goes out as plain inline comments, not
                    // a verdict review: publishing submits a verdict over the
                    // WHOLE review and closes it out, and three ticked
                    // findings are not the review's verdict.
                    CcButton(
                      size: CcButtonSize.sm,
                      onPressed: () => widget.accordion.commentFindings(scope),
                      icon: AppIcons.messageSquarePlus,
                      child: Text(
                        l10n.reviewArtifactCommentSelected(scope.length),
                      ),
                    ),
                    CcButton(
                      size: CcButtonSize.sm,
                      variant: CcButtonVariant.secondary,
                      onPressed: widget.accordion.clearSelection,
                      child: Text(l10n.clearSelection),
                    ),
                  ] else if (canPublish)
                    // ONE bulk forge action. "Comment on GitHub" used to sit
                    // beside this one and was the same thing done worse: a
                    // POST per finding, no verdict, and the review left open
                    // behind it. Publishing submits the identical inline
                    // comments in a single review, carries the verdict, and
                    // closes the review out.
                    CcButton(
                      size: CcButtonSize.sm,
                      onPressed: _publishing ? null : () => _publish(assoc),
                      icon: AppIcons.send,
                      child: Text(
                        _publishing ? l10n.saving : l10n.publishToGithub,
                      ),
                    ),
                  if (!widget.rerunning) AskAiReviewButton(pr: widget.pr),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
