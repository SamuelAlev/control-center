import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/services/finding_cohort_router.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_dependency_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/review_hub/review_hub_ask_box.dart';
import 'package:control_center/features/pr_review/presentation/review_hub/review_hub_ci_panel.dart';
import 'package:control_center/features/pr_review/presentation/review_hub/review_hub_dependencies_panel.dart';
import 'package:control_center/features/pr_review/presentation/review_hub/review_hub_impact_panel.dart';
import 'package:control_center/features/pr_review/presentation/review_hub/review_hub_reading_order.dart';
import 'package:control_center/features/pr_review/presentation/review_hub/review_hub_risk_chip.dart';
import 'package:control_center/features/pr_review/presentation/review_studio/review_studio_contract.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_accordion_list.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/review_hub_insight_providers.dart';
import 'package:control_center/features/pr_review/providers/review_hub_providers.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One area's deep dive: the guided reading order, the findings routed into
/// the area, its merged impact subgraph, and every deterministic signal that
/// belongs to it (CI failures, API contract, dependencies).
///
/// The point of the surface is altitude. The PR list says which files moved;
/// this says what the change *is* in one part of the system, what depends on
/// it, what it might break, and what a reviewer should read first.
class ReviewHubDeepDive extends ConsumerStatefulWidget {
  /// Creates a [ReviewHubDeepDive].
  const ReviewHubDeepDive({
    super.key,
    required this.pr,
    required this.association,
    required this.area,
  });

  /// The pull request under review.
  final PullRequest pr;

  /// The PR channel association.
  final ReviewChannelAssociation association;

  /// The routed area to dive into.
  final CohortFindings<ReviewFinding> area;

  @override
  ConsumerState<ReviewHubDeepDive> createState() => _ReviewHubDeepDiveState();
}

enum _DivePane { readingOrder, findings, impact, ci, contract, dependencies }

class _ReviewHubDeepDiveState extends ConsumerState<ReviewHubDeepDive> {
  _DivePane _pane = _DivePane.readingOrder;
  final _accordion = ReviewAccordionController();
  bool _pinnedPane = false;

  @override
  void dispose() {
    _accordion.dispose();
    super.dispose();
  }

  ReviewStudioTarget get _target {
    final parts = widget.pr.repoFullName.split('/');
    return ReviewStudioTarget(
      owner: parts.isNotEmpty ? parts.first : '',
      repo: parts.length > 1 ? parts.sublist(1).join('/') : '',
      prNumber: widget.pr.number,
    );
  }

  ReviewHubTarget get _hubTarget =>
      (studio: _target, channelId: widget.association.channelId);

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final area = widget.area;
    final target = _target;

    final contractDiffs =
        ref.watch(reviewContractDiffsProvider(target)).asData?.value ??
        const <ApiContractDiff>[];
    final areaFiles = area.cohort.filePaths.toSet();
    final scopedContract = contractDiffs
        .where((d) => areaFiles.contains(d.specPath))
        .toList(growable: false);

    final signals = ref.watch(reviewHubAreaSignalsProvider(_hubTarget));
    final areaSignals = signals[area.cohort.cohortKey];
    final risk = ref.watch(
      reviewHubAreaRiskProvider(_hubTarget),
    )[area.cohort.cohortKey];
    final dependencies = areaSignals?.dependencyDiffs ?? const [];

    final panes = <(_DivePane, String, IconData)>[
      (_DivePane.readingOrder, l10n.reviewHubReadingOrder, AppIcons.listChecks),
      (_DivePane.findings, l10n.reviewFindings, AppIcons.bug),
      (_DivePane.impact, l10n.reviewHubImpact, AppIcons.network),
      (_DivePane.ci, l10n.reviewHubCiSignals, AppIcons.activity),
      if (scopedContract.isNotEmpty)
        (_DivePane.contract, l10n.reviewStudioContract, AppIcons.code),
      if (dependencies.isNotEmpty)
        (_DivePane.dependencies, l10n.reviewHubDependencies, AppIcons.box),
    ];
    // Findings lead once they exist — but only until the reader picks a pane
    // themselves, or switching areas would keep yanking them back.
    if (!_pinnedPane && _pane == _DivePane.readingOrder && !area.isEmpty) {
      _pane = _DivePane.findings;
    }
    if (!panes.any((p) => p.$1 == _pane)) {
      _pane = _DivePane.readingOrder;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      area.cohort.title,
                      style: TextStyle(
                        color: ds.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (risk != null && !risk.isEmpty) ...[
                    const SizedBox(width: 8),
                    ReviewHubRiskChip(risk: risk, compact: false),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    l10n.reviewHubAreaFindingsCount(area.findings.length),
                    style: TextStyle(color: ds.textTertiary, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _CoverageLine(cohort: area.cohort),
              const SizedBox(height: 8),
              ReviewHubChangedSymbols(insights: area.cohort.insights),
              const SizedBox(height: 8),
              ReviewHubAskBox(
                target: target,
                cohortKey: area.cohort.cohortKey,
                channelId: widget.association.channelId,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (pane, label, icon) in panes)
                _DiveTab(
                  label: label,
                  icon: icon,
                  active: _pane == pane,
                  onTap: () => setState(() {
                    _pane = pane;
                    _pinnedPane = true;
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const CcDivider(),
        Expanded(child: _paneBody(context, scopedContract, dependencies)),
      ],
    );
  }

  Widget _paneBody(
    BuildContext context,
    List<ApiContractDiff> contract,
    List<PrDependencyDiff> dependencies,
  ) {
    final l10n = AppLocalizations.of(context);
    final area = widget.area;
    final repo = ref.read(prReviewRepositoryProvider);
    final fetcher = widget.pr.headSha.isEmpty
        ? null
        : (String path) => repo
              .watchFileContent(path, widget.pr.headSha)
              .first
              .timeout(const Duration(seconds: 15));
    // Scope the accordion to exactly the findings the router routed here —
    // one routing rule (stamped key → anchor file) everywhere.
    final areaMessageIds = {for (final f in area.findings) f.message.id};
    final hasOpen = area.findings.any(
      (f) =>
          f.payload.status == ReviewNodeStatus.open ||
          f.payload.status == ReviewNodeStatus.consensusReady,
    );

    switch (_pane) {
      case _DivePane.readingOrder:
        return ReviewHubReadingOrder(cohort: area.cohort);
      case _DivePane.findings:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CcButton(
                    onPressed: _accordion.selectAllOpen,
                    size: CcButtonSize.sm,
                    variant: CcButtonVariant.secondary,
                    icon: AppIcons.wrench,
                    child: Text(l10n.reviewHubFixAllInArea),
                  ),
                ),
              ),
            Expanded(
              child: ReviewAccordionList(
                channelId: widget.association.channelId,
                fetchFileContent: fetcher,
                pr: widget.pr,
                controller: _accordion,
                findingsFilter: (f) => areaMessageIds.contains(f.message.id),
              ),
            ),
          ],
        );
      case _DivePane.impact:
        return ReviewHubImpactPanel(
          target: _target,
          cohortKey: area.cohort.cohortKey,
        );
      case _DivePane.ci:
        return ReviewHubCiPanel(
          target: _target,
          cohortKey: area.cohort.cohortKey,
        );
      case _DivePane.contract:
        return ContractDiffPanel(
          diffs: contract,
          onDecision: (diffId, changeId, decision) => ref
              .read(reviewStudioRepositoryProvider)
              .setContractDecision(
                diffId: diffId,
                changeId: changeId,
                decision: decision,
              ),
        );
      case _DivePane.dependencies:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: ReviewHubDependenciesPanel(diffs: dependencies),
        );
    }
  }
}

/// The area's deterministic test coverage, stated honestly.
///
/// Three distinct states, because collapsing them is the failure mode: "no
/// test references this" is a real risk signal, while "we could not tell" is
/// not, and rendering the second as the first would send a reviewer chasing a
/// gap that may not exist.
class _CoverageLine extends StatelessWidget {
  const _CoverageLine({required this.cohort});

  final ReviewCohort cohort;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final count = cohort.insights.coveringTestCount;

    final (icon, color, text) = switch (count) {
      null => (
        AppIcons.circleHelp,
        ds.textTertiary,
        l10n.reviewHubCoverageUnknown,
      ),
      0 => (AppIcons.alertTriangle, ds.warn, l10n.reviewHubNoCoveringTests),
      _ => (
        AppIcons.circleCheck,
        ds.textSecondary,
        l10n.reviewHubCoveringTests(count),
      ),
    };

    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DiveTab extends StatelessWidget {
  const _DiveTab({
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
