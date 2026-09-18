import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/confidence_meter.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_chip.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Domain node — the brand-accented anchor of each cluster. Brand is the only
/// color here; topics, facts and policies stay neutral so blue keeps meaning.
class DomainNode extends StatelessWidget {
  const DomainNode({
    super.key,
    required this.domainLabel,
    required this.factCount,
    required this.policyCount,
    required this.onTap,
  });

  final String domainLabel;
  final int factCount;
  final int policyCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: tokens.bgBrandPrimary,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: tokens.borderBrand),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.tag, size: 14, color: tokens.fgBrandPrimary),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    domainLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.body.copyWith(
                      color: tokens.textBrandPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppLocalizations.of(
                context,
              ).factsPoliciesCount(factCount, policyCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(
                color: tokens.textBrandSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Topic node — neutral grouping under a domain, and the graph's expand
/// control: its chevron is what reveals the facts stacked beneath it.
class TopicNode extends StatelessWidget {
  const TopicNode({
    super.key,
    required this.topic,
    required this.factCount,
    required this.expanded,
    required this.onToggle,
    required this.onTap,
  });

  final String topic;
  final int factCount;

  /// Whether this topic's facts are currently on the canvas.
  final bool expanded;

  /// Shows or hides this topic's facts.
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final label = expanded
        ? l10n.memoryGraphHideFacts
        : l10n.memoryGraphShowFacts;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          // An expanded topic heads a column of its own cards, so it takes the
          // ink border that says "this one is open" — shape, not colour, since
          // the whole grid is the same neutral.
          color: tokens.bgSecondary,
          borderRadius: AppRadii.brMd,
          border: Border.all(
            color: expanded ? tokens.borderPrimary : tokens.borderSecondary,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.hash, size: 12, color: tokens.fgQuaternary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    topic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.caption.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // The count row IS the toggle, so the target is the width of the
            // card rather than a 14px glyph, and opening a topic's facts stays
            // a different press from opening its detail sheet.
            CcTooltip(
              message: label,
              child: Semantics(
                button: true,
                label: label,
                child: GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 22,
                    child: Row(
                      children: [
                        Text(
                          factCount == 1
                              ? l10n.factCount(factCount)
                              : l10n.factCountPlural(factCount),
                          style: CcTypography.caption.copyWith(
                            color: tokens.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                          size: 14,
                          color: tokens.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fact node — neutral card; the only color is the confidence meter.
class FactNode extends StatelessWidget {
  const FactNode({
    super.key,
    required this.fact,
    required this.supersededCount,
    required this.onTap,
  });

  final MemoryFact fact;
  final int supersededCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: fact.isSuperseded ? 0.55 : 1.0,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: tokens.bgPrimary,
            borderRadius: AppRadii.brMd,
            border: Border.all(color: tokens.borderSecondary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: MemoryMetaChip(
                      label: fact.topic,
                      icon: AppIcons.lightbulb,
                    ),
                  ),
                  if (supersededCount > 0) ...[
                    const SizedBox(width: AppSpacing.xs),
                    MemoryMetaChip(label: 'v${supersededCount + 1}'),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                fact.content.split('\n').first,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.caption.copyWith(
                  color: tokens.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ConfidenceMeter(confidence: fact.confidence, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}
