import 'package:cc_ui/src/components/cc_sidebar.dart';
import 'package:cc_ui/src/components/cc_tooltip.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// The sidebar item extent: expanded rows are 32px tall, collapsed (rail)
/// items are 32×32 squares — a design-system invariant, not a call-site
/// choice.
const double kCcSidebarItemExtent = 32;

/// A navigation row for [CcSidebar].
///
/// Renders an [icon] and [label] as a flat row, always
/// [kCcSidebarItemExtent] (32px) tall. At rest the fill is transparent
/// so the sidebar background shows through; hovering washes it with `t.hover`.
/// The [selected] row reads as the current destination through a brand-tinted
/// `accentSoft` fill (the accent at reduced alpha) wrapped in a 1px `accent`
/// border, with accent-colored icon/label; unselected rows use `textSecondary`.
///
/// In [collapsed] (icon-only rail) mode the label is hidden and the item
/// renders as a fixed 32×32 square ([kCcSidebarItemExtent]) centered in the
/// rail — a design-system invariant. Any [badge] keeps its full content
/// (count included) straddling the square's top-right corner — never degraded
/// to a bare dot. The collapsed state is sourced from the nearest
/// [CcSidebarScope] when present, falling back to the local [collapsed] flag.
class CcSidebarItem extends StatelessWidget {
  /// Creates a [CcSidebarItem].
  const CcSidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.onPressed,
    this.badge,
    this.collapsed = false,
  });

  /// The leading nav icon (an [IconData] from the bundled icon font —
  /// declare app glyphs via `tool/gen_icon_seams.py`; see [CcIcons]).
  final IconData icon;

  /// The destination label.
  final String label;

  /// Whether this is the current selection.
  final bool selected;

  /// Tap handler. When null the row is non-interactive.
  final VoidCallback? onPressed;

  /// Optional trailing badge (e.g. a count). Collapses to a dot in rail mode.
  final Widget? badge;

  /// Icon-only rail mode fallback when there is no [CcSidebarScope] ancestor.
  final bool collapsed;

  Color _background(DesignSystemTokens t, Set<WidgetState> states) {
    if (selected) {
      return t.accentSoft;
    }
    if (states.contains(WidgetState.pressed)) {
      return t.hoverStrong;
    }
    if (states.contains(WidgetState.hovered)) {
      return t.hover;
    }
    // Alpha-0 hover colour (not transparent-black) so AnimatedContainer lerps
    // only alpha on hover↔idle, avoiding a dark-gray flash.
    return t.hover.withValues(alpha: 0);
  }

  Widget _buildBody(
    DesignSystemTokens t,
    Color background, {
    required bool collapsed,
    required bool transitioning,
  }) {
    final fg = selected ? t.accent : t.textSecondary;

    final Widget container = AnimatedContainer(
      duration: CcMotion.fast,
      curve: CcMotion.standard,
      // The expanded row height is fixed at 32px (design rule); the 18px icon
      // and label center vertically inside it.
      height: collapsed ? null : kCcSidebarItemExtent,
      // The 10px left inset aligns the icon's left edge with the group
      // header's text (8px sidebar inset + 1px reserved border + 9px padding
      // = the header's 8 + 10). It also puts the icon's center at x=27 from
      // the sidebar edge — the exact spot the rail's centered 32px square
      // puts it (rail width 54, content center 27) — so toggling the sidebar
      // moves nothing (27 − 8 sidebar inset − 9 half-icon = 10).
      padding: collapsed
          ? EdgeInsets.zero
          // Left 9 + the 1px reserved border (which insets the child) = the
          // visual 10px inset: the icon's left edge lands exactly where
          // CcSidebarGroup's header padding (10) starts the section title,
          // and its center on the x=27 line the collapsed rail's squares
          // center on, so toggling the rail never moves the icon. While the
          // width animates the trailing inset drops to 0: the row keeps its
          // expanded geometry (labels fading) down to the rail's 38px
          // content width without the fixed icon + gap + padding
          // overflowing it (18 + 8 + 9 + 2 borders = 37 ≤ 38).
          : EdgeInsets.only(left: 9, right: transitioning ? 0 : 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.brSm,
        // A 1px border is reserved on every row (alpha-0 when idle) so the
        // layout never shifts when [selected] toggles the brand border on.
        border: Border.all(
          color: selected ? t.accent : t.accent.withValues(alpha: 0),
          width: 1,
        ),
      ),
      child: collapsed
          ? Center(child: Icon(icon, size: 18, color: fg))
          : Row(
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  // The label fades while the sidebar's width animates
                  // (kept in the layout so the row geometry never changes),
                  // which is what makes the toggle read as labels
                  // appearing/disappearing instead of anything moving.
                  child: AnimatedOpacity(
                    opacity: transitioning ? 0 : 1,
                    duration: CcMotion.fast,
                    curve: CcMotion.standard,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: selected
                            ? CcTypography.mediumWeight
                            : CcTypography.regularWeight,
                        color: fg,
                      ),
                    ),
                  ),
                ),
                // The badge leaves the layout entirely during the width
                // animation: as the row narrows it would overflow otherwise.
                if (badge != null && !transitioning) ...[
                  const SizedBox(width: AppSpacing.sm),
                  badge!,
                ],
              ],
            ),
    );

    if (!collapsed) {
      return container;
    }
    // Rail mode: the button is a fixed 32×32 square centered in the rail
    // content width. The badge — the same [badge] the expanded row shows
    // trailing, count and all, never a bare dot — straddles the square's
    // top-right corner like a notification badge.
    return Center(
      child: SizedBox.square(
        dimension: kCcSidebarItemExtent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: container),
            if (badge != null)
              Positioned(
                top: -AppSpacing.xs,
                right: -AppSpacing.sm,
                child: badge!,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final collapsed = CcSidebarScope.collapsedOf(context) ?? this.collapsed;
    final transitioning = CcSidebarScope.transitioningOf(context) ?? false;

    final Widget result;
    if (onPressed == null) {
      result = _buildBody(
        t,
        selected ? t.accentSoft : t.hover.withValues(alpha: 0),
        collapsed: collapsed,
        transitioning: transitioning,
      );
    } else {
      result = CcTappable(
        onPressed: onPressed,
        borderRadius: AppRadii.brSm,
        semanticLabel: label,
        builder: (context, states) => _buildBody(
          t,
          _background(t, states),
          collapsed: collapsed,
          transitioning: transitioning,
        ),
      );
    }

    // In the icon-only rail the label is hidden; surface it on hover/focus so a
    // sighted user can still identify the destination. The tooltip opens to the
    // RIGHT of the rail — the sidebar hugs the window's left edge, so that is
    // the only side with room, and opening below would cover the items under
    // it.
    if (collapsed) {
      return CcTooltip(
        placement: CcTooltipPlacement.right,
        message: label,
        child: result,
      );
    }
    return result;
  }
}
