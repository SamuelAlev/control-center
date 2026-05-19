import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/visual_diff.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/review_hub/review_hub_delta_strip.dart';
import 'package:control_center/features/pr_review/presentation/review_hub/review_hub_learnings_panel.dart';
import 'package:control_center/features/pr_review/presentation/review_hub/review_hub_summary_card.dart';
import 'package:control_center/features/pr_review/presentation/review_studio/review_studio_visual.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_accordion_list.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/review_hub_providers.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The PR-level overview: the AI summary card on top, then a strip switching
/// between the flat findings list (the CodeRabbit-style prioritized view) and
/// the PR-level visual diffs.
class ReviewHubOverview extends ConsumerStatefulWidget {
  /// Creates a [ReviewHubOverview].
  const ReviewHubOverview({
    super.key,
    required this.pr,
    required this.association,
    required this.target,
  });

  /// The pull request under review.
  final PullRequest pr;

  /// The PR channel association.
  final ReviewChannelAssociation association;

  /// The studio target (owner/repo/prNumber).
  final ReviewStudioTarget target;

  @override
  ConsumerState<ReviewHubOverview> createState() => _ReviewHubOverviewState();
}

enum _OverviewPane { findings, visual, learnings }

class _ReviewHubOverviewState extends ConsumerState<ReviewHubOverview> {
  _OverviewPane _pane = _OverviewPane.findings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(prReviewRepositoryProvider);
    final fetcher = widget.pr.headSha.isEmpty
        ? null
        : (String path) => repo
              .watchFileContent(path, widget.pr.headSha)
              .first
              .timeout(const Duration(seconds: 15));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The delta rides above the summary: "two of these are new" changes
        // how the whole card below is read.
        Builder(
          builder: (context) {
            final delta = ref
                .watch(reviewHubSummaryProvider(widget.association.channelId))
                ?.delta;
            if (delta == null || delta.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: ReviewHubDeltaStrip(delta: delta),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: ReviewHubSummaryCard(channelId: widget.association.channelId),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 6,
            children: [
              _PaneButton(
                label: l10n.reviewFindings,
                icon: AppIcons.listChecks,
                active: _pane == _OverviewPane.findings,
                onTap: () => setState(() => _pane = _OverviewPane.findings),
              ),
              _PaneButton(
                label: l10n.reviewStudioVisual,
                icon: AppIcons.eye,
                active: _pane == _OverviewPane.visual,
                onTap: () => setState(() => _pane = _OverviewPane.visual),
              ),
              _PaneButton(
                label: l10n.reviewHubLearnings,
                icon: AppIcons.brain,
                active: _pane == _OverviewPane.learnings,
                onTap: () => setState(() => _pane = _OverviewPane.learnings),
              ),
            ],
          ),
        ),
        const CcDivider(),
        Expanded(
          child: switch (_pane) {
            _OverviewPane.findings => ReviewAccordionList(
              channelId: widget.association.channelId,
              fetchFileContent: fetcher,
              pr: widget.pr,
            ),
            _OverviewPane.visual => _VisualPane(
              target: widget.target,
              onApprove: (snapshotId, status) => ref
                  .read(reviewStudioRepositoryProvider)
                  .approveVisual(snapshotId: snapshotId, status: status),
            ),
            _OverviewPane.learnings => const SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: ReviewHubLearningsPanel(),
            ),
          },
        ),
      ],
    );
  }
}

class _VisualPane extends ConsumerWidget {
  const _VisualPane({required this.target, required this.onApprove});

  final ReviewStudioTarget target;
  final void Function(String snapshotId, VisualDiffStatus status) onApprove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshots =
        ref.watch(reviewVisualDiffsProvider(target)).asData?.value ??
        const <VisualDiffSnapshot>[];
    final axes =
        ref.watch(reviewAxisResultsProvider(target)).asData?.value ??
        const <ReviewAxisResult>[];
    return VisualDiffPanel(
      snapshots: snapshots,
      visualAxis: axes.where((a) => a.axis == ReviewAxis.visual).firstOrNull,
      onApprove: onApprove,
    );
  }
}

class _PaneButton extends StatelessWidget {
  const _PaneButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    return CcTappable(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(8),
      builder: (context, states) => DecoratedBox(
        decoration: BoxDecoration(
          color: active ? ds.accentSoft : const Color(0x00000000),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: active ? ds.accent : ds.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? ds.accent : ds.textSecondary,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
