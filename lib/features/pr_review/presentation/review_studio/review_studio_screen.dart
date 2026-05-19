import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/visual_diff.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/review_studio/review_studio_axes.dart';
import 'package:control_center/features/pr_review/presentation/review_studio/review_studio_blast.dart';
import 'package:control_center/features/pr_review/presentation/review_studio/review_studio_cohorts.dart';
import 'package:control_center/features/pr_review/presentation/review_studio/review_studio_contract.dart';
import 'package:control_center/features/pr_review/presentation/review_studio/review_studio_visual.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Review Studio (PRD 18): a semantic, multi-modal review surface for a PR.
///
/// A 3-panel layout — cohort nav (left) / walkthrough·contract·visual·blast
/// (center) / context rail (right) — with a prominent verdict header and a
/// multi-axis dashboard on top. Cohorts + deterministic axes are computed
/// server-side on open.
class ReviewStudioView extends ConsumerStatefulWidget {
  /// Creates a [ReviewStudioView].
  const ReviewStudioView({
    super.key,
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
  ConsumerState<ReviewStudioView> createState() => _ReviewStudioViewState();
}

class _ReviewStudioViewState extends ConsumerState<ReviewStudioView> {
  ReviewStudioTarget get _target => ReviewStudioTarget(
    owner: widget.owner,
    repo: widget.repo,
    prNumber: widget.prNumber,
  );

  @override
  void initState() {
    super.initState();
    // Compute cohorts + deterministic axes on open (idempotent server-side).
    // Guarded: the view can be dismissed before the frame lands, and `ref`
    // throws once the element is gone.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(reviewStudioComputeProvider(_target));
    });
  }

  void _recompute() => ref.invalidate(reviewStudioComputeProvider(_target));

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final cohorts =
        ref.watch(reviewCohortsProvider(_target)).asData?.value ?? const [];
    final axes =
        ref.watch(reviewAxisResultsProvider(_target)).asData?.value ?? const [];
    final verdict = ref.watch(reviewStudioVerdictProvider(_target));
    final pane = ref.watch(reviewStudioPaneProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: ReviewVerdictHeader(verdict: verdict)),
                  const SizedBox(width: 12),
                  CcButton(
                    variant: CcButtonVariant.line,
                    onPressed: _recompute,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.zap, size: 14, color: ds.textSecondary),
                        const SizedBox(width: 6),
                        Text(l10n.reviewStudioRecompute),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: MultiAxisDashboard(axes: axes),
              ),
              const SizedBox(height: 10),
              _PaneSwitcher(current: pane),
            ],
          ),
        ),
        const CcDivider(),
        Expanded(child: _body(context, ds, cohorts, axes, pane)),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    DesignSystemTokens ds,
    List<ReviewCohort> cohorts,
    List<ReviewAxisResult> axes,
    ReviewStudioPane pane,
  ) {
    final center = _centerPane(cohorts, axes, pane);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return center;
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 230,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: ds.borderPrimary)),
                ),
                child: CohortNav(cohorts: cohorts),
              ),
            ),
            Expanded(child: center),
            SizedBox(
              width: 280,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: ds.borderPrimary)),
                ),
                child: CohortContextRail(cohorts: cohorts),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _centerPane(
    List<ReviewCohort> cohorts,
    List<ReviewAxisResult> axes,
    ReviewStudioPane pane,
  ) {
    switch (pane) {
      case ReviewStudioPane.walkthrough:
        return ReviewWalkthrough(cohorts: cohorts);
      case ReviewStudioPane.contract:
        final diffs =
            ref.watch(reviewContractDiffsProvider(_target)).asData?.value ??
            const <ApiContractDiff>[];
        return ContractDiffPanel(
          diffs: diffs,
          onDecision: (diffId, changeId, decision) => ref
              .read(reviewStudioRepositoryProvider)
              .setContractDecision(
                diffId: diffId,
                changeId: changeId,
                decision: decision,
              ),
        );
      case ReviewStudioPane.visual:
        final snapshots =
            ref.watch(reviewVisualDiffsProvider(_target)).asData?.value ??
            const <VisualDiffSnapshot>[];
        final visualAxis = axes
            .where((a) => a.axis == ReviewAxis.visual)
            .firstOrNull;
        return VisualDiffPanel(
          snapshots: snapshots,
          visualAxis: visualAxis,
          onApprove: (snapshotId, status) => ref
              .read(reviewStudioRepositoryProvider)
              .approveVisual(snapshotId: snapshotId, status: status),
        );
      case ReviewStudioPane.blastRadius:
        final files = <String>{for (final c in cohorts) ...c.filePaths}.toList()
          ..sort();
        return BlastRadiusPanel(target: _target, changedFiles: files);
    }
  }
}

class _PaneSwitcher extends ConsumerWidget {
  const _PaneSwitcher({required this.current});

  final ReviewStudioPane current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = <(ReviewStudioPane, String, IconData)>[
      (
        ReviewStudioPane.walkthrough,
        l10n.reviewStudioWalkthrough,
        AppIcons.fileText,
      ),
      (ReviewStudioPane.contract, l10n.reviewStudioContract, AppIcons.code),
      (ReviewStudioPane.visual, l10n.reviewStudioVisual, AppIcons.eye),
      (
        ReviewStudioPane.blastRadius,
        l10n.reviewStudioBlastRadius,
        AppIcons.network,
      ),
    ];
    return Wrap(
      spacing: 6,
      children: [
        for (final (pane, label, icon) in items)
          _PaneButton(
            label: label,
            icon: icon,
            active: pane == current,
            onTap: () =>
                ref.read(reviewStudioPaneProvider.notifier).state = pane,
          ),
      ],
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
