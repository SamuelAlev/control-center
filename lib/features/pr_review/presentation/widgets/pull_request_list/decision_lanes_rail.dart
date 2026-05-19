import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/decision_lane.dart';
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The decision-lane rail: five tappable cards that filter the PR queue by what
/// each PR needs from the operator. The active lane is filled with a soft wash
/// of its colour and a stronger border; each card surfaces a live count so the
/// rail doubles as an at-a-glance triage summary. This is the primary
/// organizing layer of the list.
class DecisionLanesRail extends ConsumerWidget {
  /// Creates a [DecisionLanesRail].
  const DecisionLanesRail({super.key, required this.counts});

  /// Live per-lane PR counts across the (filter-respecting) open population.
  final Map<DecisionLane, int> counts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(decisionLaneFilterProvider);
    final notifier = ref.read(decisionLaneFilterProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 5
            : width >= 620
            ? 3
            : 2;
        const gap = AppSpacing.md;
        final cardWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final lane in kDecisionLanesInOrder)
              SizedBox(
                width: cardWidth,
                child: _LaneCard(
                  lane: lane,
                  count: counts[lane] ?? 0,
                  active: active == lane,
                  onTap: () => notifier.toggle(lane),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LaneCard extends StatelessWidget {
  const _LaneCard({
    required this.lane,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final DecisionLane lane;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final style = decisionLaneStyle(lane, tokens, l10n);
    final theme = Theme.of(context);

    final border = active ? tokens.lineStrong : tokens.borderSecondary;

    return Semantics(
      button: true,
      selected: active,
      label: '${style.label}: $count. ${style.hint}',
      child: CcTappable(
        onPressed: onTap,
        mouseCursor: SystemMouseCursors.click,
        builder: (context, states) {
          final hovered = states.contains(WidgetState.hovered);
          final shadow = active || hovered ? AppShadows.soft : null;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: active ? style.softColor : tokens.panel,
              borderRadius: AppRadii.brLg,
              border: Border.all(color: border),
              boxShadow: shadow,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _LaneDot(color: style.color, ring: style.ringOnly),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          style.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tokens.muted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$count',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: count == 0 ? tokens.idle : tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    style.hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LaneDot extends StatelessWidget {
  const _LaneDot({required this.color, required this.ring});

  final Color color;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: ring ? Colors.transparent : color,
        shape: BoxShape.circle,
        border: ring ? Border.all(color: color, width: 1.5) : null,
      ),
    );
  }
}
