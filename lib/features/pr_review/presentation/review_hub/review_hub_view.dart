import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/services/finding_cohort_router.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/presentation/review_hub/review_hub_area_nav.dart';
import 'package:control_center/features/pr_review/presentation/review_hub/review_hub_deep_dive.dart';
import 'package:control_center/features/pr_review/presentation/review_hub/review_hub_overview.dart';
import 'package:control_center/features/pr_review/presentation/review_studio/review_studio_axes.dart';
import 'package:control_center/features/pr_review/presentation/review_studio/review_studio_cohorts.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/ask_ai_review_button.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_context_rail.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/review_hub_providers.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The merged review surface (one tab, one review): the AI findings flow and
/// the deterministic studio joined by areas — findings routed into cohorts,
/// a CodeRabbit-style AI summary on top and a per-area deep dive (walkthrough,
/// scoped findings, impact graph, contract diffs).
class ReviewHubView extends ConsumerStatefulWidget {
  /// Creates a [ReviewHubView].
  const ReviewHubView({super.key, required this.pr});

  /// The pull request under review.
  final PullRequest pr;

  @override
  ConsumerState<ReviewHubView> createState() => _ReviewHubViewState();
}

class _ReviewHubViewState extends ConsumerState<ReviewHubView> {
  ReviewStudioTarget get _target {
    final parts = widget.pr.repoFullName.split('/');
    return ReviewStudioTarget(
      owner: parts.isNotEmpty ? parts.first : '',
      repo: parts.length > 1 ? parts.sublist(1).join('/') : '',
      prNumber: widget.pr.number,
    );
  }

  @override
  void initState() {
    super.initState();
    // Compute cohorts + deterministic axes on open (idempotent server-side),
    // so the areas exist before/independently of an AI review run.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(reviewStudioComputeProvider(_target));
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncAssoc = ref.watch(
      reviewChannelForPrProvider(widget.pr.externalId),
    );
    return asyncAssoc.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => Center(
        child: Text(AppLocalizations.of(context).failedWithError('$e')),
      ),
      data: (assoc) {
        if (assoc == null) {
          return _IntroCta(pr: widget.pr);
        }
        return _HubBody(pr: widget.pr, association: assoc, target: _target);
      },
    );
  }
}

class _IntroCta extends StatelessWidget {
  const _IntroCta({required this.pr});

  final PullRequest pr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.sparkles, size: 48, color: tokens.textTertiary),
            const SizedBox(height: 16),
            Text(
              l10n.aiReview,
              style: CcTypography.title.copyWith(color: tokens.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reviewHubIntroBody,
              textAlign: TextAlign.center,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(height: 24),
            AskAiReviewButton(pr: pr),
          ],
        ),
      ),
    );
  }
}

class _HubBody extends ConsumerWidget {
  const _HubBody({
    required this.pr,
    required this.association,
    required this.target,
  });

  final PullRequest pr;
  final ReviewChannelAssociation association;
  final ReviewStudioTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem!;
    final hubTarget = (studio: target, channelId: association.channelId);
    final routing = ref.watch(reviewHubAreasProvider(hubTarget));
    final selectedArea = ref.watch(reviewHubSelectedAreaProvider);

    return Column(
      children: [
        _HubHeader(pr: pr, association: association, target: target),
        const CcDivider(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final center = _centerPane(
                context,
                routing: routing,
                selectedArea: selectedArea,
              );
              if (constraints.maxWidth < 900) {
                return center;
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 240,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: ds.borderPrimary),
                        ),
                      ),
                      child: ReviewHubAreaNav(
                        routing: routing,
                        target: hubTarget,
                      ),
                    ),
                  ),
                  Expanded(child: center),
                  SizedBox(
                    width: 280,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: ds.borderPrimary),
                        ),
                      ),
                      child: selectedArea == null
                          ? PrContextRail(prNumber: pr.number)
                          : CohortContextRail(
                              cohorts: [
                                for (final a in routing.areas) a.cohort,
                              ],
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _centerPane(
    BuildContext context, {
    required FindingCohortRouting<ReviewFinding> routing,
    required String? selectedArea,
  }) {
    if (selectedArea == null) {
      return ReviewHubOverview(
        pr: pr,
        association: association,
        target: target,
      );
    }
    final area = routing.areas
        .where((a) => a.cohort.cohortKey == selectedArea)
        .firstOrNull;
    if (area == null) {
      return ReviewHubOverview(
        pr: pr,
        association: association,
        target: target,
      );
    }
    return ReviewHubDeepDive(pr: pr, association: association, area: area);
  }
}

/// The merged header: one verdict (the finalized summary when it exists, the
/// axis-aggregated provisional otherwise), the axis dashboard, and the review
/// actions (status, publish, auto-publish opt-in, recompute, ask AI).
class _HubHeader extends ConsumerStatefulWidget {
  const _HubHeader({
    required this.pr,
    required this.association,
    required this.target,
  });

  final PullRequest pr;
  final ReviewChannelAssociation association;
  final ReviewStudioTarget target;

  @override
  ConsumerState<_HubHeader> createState() => _HubHeaderState();
}

class _HubHeaderState extends ConsumerState<_HubHeader> {
  bool _publishing = false;

  ReviewVerdict get _verdict {
    final summary = ref.watch(
      reviewHubSummaryProvider(widget.association.channelId),
    );
    if (summary != null) {
      return summary.verdict;
    }
    return ref.watch(reviewStudioVerdictProvider(widget.target));
  }

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context);
    final toast = CcToastScope.maybeOf(context);
    setState(() => _publishing = true);
    try {
      await ref.read(rpcClientProvider).call('pr_review.publishReview', {
        'workspace_id': widget.association.workspaceId,
        'channel_id': widget.association.channelId,
        'selection': 'consensus',
      });
      if (!mounted) {
        return;
      }
      ref.invalidate(
        reviewChannelForPrProvider(widget.association.prExternalId),
      );
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

  Future<void> _toggleAutoPublish(bool value) async {
    final workspace = ref.read(activeWorkspaceProvider);
    if (workspace == null) {
      return;
    }
    try {
      await ref
          .read(workspaceRepositoryProvider)
          .upsert(workspace.copyWith(autoPublishReview: value));
    } catch (e) {
      if (!mounted) {
        return;
      }
      CcToastScope.maybeOf(context)?.show(
        AppLocalizations.of(context).failedWithError('$e'),
        variant: CcToastVariant.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem!;
    final axes =
        ref.watch(reviewAxisResultsProvider(widget.target)).asData?.value ??
        const <ReviewAxisResult>[];
    final summary = ref.watch(
      reviewHubSummaryProvider(widget.association.channelId),
    );
    final provisional = summary == null;
    final workspace = ref.watch(activeWorkspaceProvider);
    final showPublish =
        widget.association.status == ReviewChannelStatus.awaitingApproval;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ReviewVerdictHeader(
                  verdict: _verdict,
                  provisional: provisional,
                ),
              ),
              const SizedBox(width: 12),
              if (showPublish)
                CcButton(
                  size: CcButtonSize.sm,
                  onPressed: _publishing ? null : _publish,
                  icon: AppIcons.send,
                  child: Text(_publishing ? l10n.saving : l10n.publishToGithub),
                ),
              const SizedBox(width: 8),
              CcTooltip(
                message: l10n.reviewHubAutoPublishTooltip,
                child: CcSwitch(
                  value: workspace?.autoPublishReview ?? false,
                  onChanged: _toggleAutoPublish,
                ),
              ),
              const SizedBox(width: 8),
              CcTooltip(
                message: l10n.reviewHubAutoPublish,
                child: Icon(
                  AppIcons.send,
                  size: 14,
                  color: (workspace?.autoPublishReview ?? false)
                      ? ds.accent
                      : ds.textTertiary,
                ),
              ),
              const SizedBox(width: 8),
              if (widget.association.status != ReviewChannelStatus.inProgress)
                AskAiReviewButton(pr: widget.pr),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: MultiAxisDashboard(axes: axes),
          ),
        ],
      ),
    );
  }
}
