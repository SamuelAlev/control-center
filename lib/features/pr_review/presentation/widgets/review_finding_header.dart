import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Height of a finding's header row.
///
/// Fixed, because the review tab pins this row over its own scrolling body as a
/// sliver header and a persistent header has to declare its extent up front.
const double kReviewFindingHeaderExtent = 44;

/// The widest the trailing `file.ts:120` marker may grow before it ellipsizes.
///
/// The summary is what the reader scans by, so the anchor is capped rather than
/// allowed to push it out; the full path is always in the tooltip and in the
/// expanded body's meta strip.
const double _anchorMaxWidth = 180;

/// One finding's header: what it is, how sure the reviewer is, what it says and
/// where it stands.
///
/// ONE implementation for both surfaces that show a finding — the review tab's
/// accordion and the in-chat `reviewNode` bubble. They had grown two copies of
/// this row that were already drifting apart (one tracked its kind label, the
/// other did not; one showed an author, the other did not), which is the reason
/// the same finding looked like two different objects depending on where you
/// met it.
///
/// The row leads with the classification, carries the finding's own headline in
/// the middle and ends with its state. That order matters: a column of rows
/// reading `BUG · P1 · 85% · some/path.ts:474` is nine identical rows, and the
/// only thing that tells them apart is the one thing it left out.
class ReviewFindingHeader extends StatelessWidget {
  /// Creates a [ReviewFindingHeader].
  const ReviewFindingHeader({
    super.key,
    required this.payload,
    required this.summary,
    required this.expanded,
    required this.onToggle,
    this.leading,
    this.trailing,
    this.background,
    this.divider = true,
  });

  /// The finding's parsed payload.
  final ReviewNodePayload payload;

  /// The finding's headline — see [reviewFindingSummary]. May be empty, in
  /// which case the anchor carries the row on its own.
  final String summary;

  /// Whether the finding's body is showing, which drives the chevron and the
  /// row's resting tint.
  final bool expanded;

  /// Folds or unfolds the finding.
  final VoidCallback onToggle;

  /// Optional leading slot, before the kind glyph (the review tab's selection
  /// checkbox).
  final Widget? leading;

  /// Optional trailing slot, before the chevron (the review tab's author
  /// avatar).
  final Widget? trailing;

  /// Resting fill. Defaults to the panel fill.
  ///
  /// Always resolved to an OPAQUE color: as a pinned sliver header this row has
  /// the finding's own body scrolling underneath it, and a translucent fill
  /// lets that body bleed through as ghost text.
  final Color? background;

  /// Whether a hairline rule closes the row's bottom edge.
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final decor = reviewItemDecor(context, payload.kind, payload.priority);
    final statusLabel = reviewStatusLabel(context, payload.status);
    final path = payload.anchor.filePath;
    final lineSuffix = payload.anchor.lineNumber != null
        ? ':${payload.anchor.lineNumber}'
        : '';
    final anchorLabel = path == null
        ? null
        : '${path.split('/').last}$lineSuffix';

    // Mono for every classification token and every number in the row: the
    // kind, the priority and the confidence line up in a column down a list of
    // findings, which is what makes the list scannable rather than ragged.
    final monoLabel = CcFonts.code(textStyle: CcTypography.label);
    final monoCaption = CcFonts.code(textStyle: CcTypography.caption);

    return Semantics(
      button: true,
      expanded: expanded,
      child: CcTappable(
        onPressed: onToggle,
        semanticLabel: [
          decor.label,
          payload.priority.name.toUpperCase(),
          if (summary.isNotEmpty) summary,
          if (path != null) '$path$lineSuffix',
          statusLabel,
        ].join(', '),
        builder: (context, states) {
          final base = background ?? tokens.bgPrimary;
          final resting = expanded
              ? Color.alphaBlend(
                  tokens.bgSecondary.withValues(alpha: 0.5),
                  base,
                )
              : base;
          // Pre-blended rather than layered as a translucent box, for the same
          // reason the resting fill is opaque.
          final hovered =
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed);
          return Container(
            height: kReviewFindingHeaderExtent,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: hovered
                  ? Color.alphaBlend(tokens.hover, resting)
                  : resting,
              border: divider
                  ? Border(bottom: BorderSide(color: tokens.borderSecondary))
                  : null,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Icon(decor.icon, size: 14, color: decor.accent),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  decor.label,
                  style: monoLabel.copyWith(color: decor.accent),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  payload.priority.name.toUpperCase(),
                  style: monoLabel.copyWith(
                    color: reviewPriorityColor(payload.priority, context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                CcTooltip(
                  // A bare "85%" beside a priority reads as a second severity
                  // score; the tooltip says which number this is.
                  message: l10n.confidenceLabel(
                    (payload.confidence * 100).round(),
                  ),
                  child: Text(
                    '${(payload.confidence * 100).round()}%',
                    style: monoCaption.copyWith(color: tokens.textTertiary),
                  ),
                ),
                // A regex hit and a model's judgement carry different kinds of
                // certainty; a reader who cannot tell them apart will either
                // over-trust the model or dismiss the rule.
                if (payload.isDeterministic) ...[
                  const SizedBox(width: AppSpacing.sm),
                  CcTooltip(
                    message: l10n.reviewHubStaticRuleTooltip(
                      payload.ruleId ?? '',
                    ),
                    child: CcBadge(
                      label: l10n.reviewHubStaticRule,
                      icon: AppIcons.regex,
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.bodySm.copyWith(
                      color: tokens.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
                if (anchorLabel != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  CcTooltip(
                    message: '$path$lineSuffix',
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _anchorMaxWidth,
                      ),
                      child: Text(
                        anchorLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: monoCaption.copyWith(color: tokens.textTertiary),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.sm),
                CcBadge(
                  label: statusLabel,
                  variant: reviewStatusVariant(payload.status),
                  icon: reviewStatusIcon(payload.status),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                  size: 14,
                  color: tokens.textTertiary,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
