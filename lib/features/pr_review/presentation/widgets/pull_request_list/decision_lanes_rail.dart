import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_shadows.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/presentation/utils/decision_lane.dart';
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

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

class _LaneCard extends StatefulWidget {
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
  State<_LaneCard> createState() => _LaneCardState();
}

class _LaneCardState extends State<_LaneCard> {
  bool _hovered = false;

  void _setHovered(bool v) {
    if (_hovered == v) {
      return;
    }
    setState(() => _hovered = v);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context);
    final style = decisionLaneStyle(widget.lane, tokens, l10n);
    final theme = Theme.of(context);

    final border = widget.active ? tokens.lineStrong : tokens.borderSecondary;
    final shadow = widget.active || _hovered ? AppShadows.soft : null;

    return Semantics(
      button: true,
      selected: widget.active,
      label: '${style.label}: ${widget.count}. ${style.hint}',
      child: FTappable.static(
        onPress: widget.onTap,
        focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => _setHovered(true),
          onExit: (_) => _setHovered(false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: widget.active ? style.softColor : tokens.panel,
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
                    '${widget.count}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: widget.count == 0
                          ? tokens.idle
                          : colors.foreground,
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
          ),
        ),
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
