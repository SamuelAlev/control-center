import 'package:cc_domain/features/pr_review/domain/services/finding_cohort_router.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/compute_area_risk_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/review_hub/review_hub_risk_chip.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/features/pr_review/providers/review_hub_insight_providers.dart';
import 'package:control_center/features/pr_review/providers/review_hub_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The hub's left navigation: the PR-level overview entry plus one entry per
/// deterministic area (cohort), badged with the findings the router routed
/// into it and its deterministic risk. Selecting an area opens its deep dive.
class ReviewHubAreaNav extends ConsumerWidget {
  /// Creates a [ReviewHubAreaNav].
  const ReviewHubAreaNav({super.key, required this.routing, this.target});

  /// The routed areas (cohorts + findings + repo-wide bucket).
  final FindingCohortRouting<ReviewFinding> routing;

  /// The hub target, needed to resolve each area's risk. Without it the nav
  /// still renders — just without risk badges.
  final ReviewHubTarget? target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(reviewHubSelectedAreaProvider);
    final byRisk = ref.watch(reviewHubOrderByRiskProvider);
    final risks = target == null
        ? const <String, AreaRisk>{}
        : ref.watch(reviewHubAreaRiskProvider(target!));

    // Impact order is the default because it is what the cohort ranking
    // already means; risk depends on findings, which do not exist until a
    // review has actually run.
    final areas = [...routing.areas];
    if (byRisk && risks.isNotEmpty) {
      areas.sort((a, b) {
        final ra = risks[a.cohort.cohortKey]?.score ?? 0;
        final rb = risks[b.cohort.cohortKey]?.score ?? 0;
        final byScore = rb.compareTo(ra);
        return byScore != 0
            ? byScore
            : a.cohort.orderIndex.compareTo(b.cohort.orderIndex);
      });
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      children: [
        _NavEntry(
          icon: AppIcons.layoutGrid,
          label: l10n.reviewHubOverview,
          selected: selected == null,
          onTap: () =>
              ref.read(reviewHubSelectedAreaProvider.notifier).state = null,
        ),
        if (routing.areas.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.reviewHubAreas,
                    style: TextStyle(
                      color: ds.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (risks.isNotEmpty)
                  CcTappable(
                    onPressed: () =>
                        ref.read(reviewHubOrderByRiskProvider.notifier).state =
                            !byRisk,
                    borderRadius: BorderRadius.circular(6),
                    builder: (context, states) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        l10n.reviewHubOrderByRisk,
                        style: TextStyle(
                          color: byRisk ? ds.accent : ds.textTertiary,
                          fontSize: 10,
                          fontWeight: byRisk
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (final area in areas)
            _AreaEntry(
              area: area,
              risk: risks[area.cohort.cohortKey],
              selected: selected == area.cohort.cohortKey,
              onTap: () =>
                  ref.read(reviewHubSelectedAreaProvider.notifier).state =
                      area.cohort.cohortKey,
            ),
        ],
        if (routing.repositoryWide.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            child: Text(
              l10n.reviewHubRepoWideCount(routing.repositoryWide.length),
              style: TextStyle(color: ds.textTertiary, fontSize: 11),
            ),
          ),
      ],
    );
  }
}

class _NavEntry extends StatelessWidget {
  const _NavEntry({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    return CcTappable(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(8),
      builder: (context, states) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? ds.accent : ds.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? ds.textPrimary : ds.textSecondary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaEntry extends StatelessWidget {
  const _AreaEntry({
    required this.area,
    required this.selected,
    required this.onTap,
    this.risk,
  });

  final CohortFindings<ReviewFinding> area;
  final bool selected;
  final VoidCallback onTap;
  final AreaRisk? risk;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    return CcTappable(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(8),
      builder: (context, states) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    area.cohort.title,
                    style: TextStyle(
                      color: selected ? ds.textPrimary : ds.textSecondary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${area.cohort.impactScore}',
                  style: TextStyle(color: ds.textTertiary, fontSize: 11),
                ),
              ],
            ),
            if (risk != null && !risk!.isEmpty) ...[
              const SizedBox(height: 4),
              ReviewHubRiskChip(risk: risk!),
            ],
            if (!area.isEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (area.p0Count > 0)
                    _CountPill(
                      label: 'P0 ${area.p0Count}',
                      color: ds.danger,
                      bg: ds.dangerSoft,
                    ),
                  if (area.p1Count > 0)
                    _CountPill(
                      label: 'P1 ${area.p1Count}',
                      color: ds.warn,
                      bg: ds.warnSoft,
                    ),
                  if (area.p0Count == 0 && area.p1Count == 0)
                    _CountPill(
                      label: AppLocalizations.of(
                        context,
                      ).reviewHubAreaFindingsCount(area.findings.length),
                      color: ds.textSecondary,
                      bg: ds.bgSecondary,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    required this.color,
    required this.bg,
  });

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
