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
/// The [selected] row reads as the current destination through a SOLID
/// `bgBrandSolid` fill (the accessible brand orange — `accentOn` clears 4.5:1
/// on it in both brightnesses, unlike the raw `accent` signal) carrying
/// `accentOn` ink at bold weight. Unselected rows use `textSecondary`.
///
/// Anything the caller hands to [badge] rides that fill, so an accent-tinted
/// badge would disappear into it: a badge must invert on the selected row
/// (`accentOn` pill, `bgBrandSolid` content). Callers already know [selected],
/// so they thread it into their own badge widget rather than the row guessing
/// at an arbitrary child's colors.
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
    this.iconBuilder,
    this.selected = false,
    this.onPressed,
    this.badge,
    this.badgeBesideLabel = false,
    this.collapsed = false,
  });

  /// The leading nav icon (an [IconData] from the bundled icon font —
  /// declare app glyphs via `tool/gen_icon_seams.py`; see [CcIcons]).
  final IconData icon;

  /// Renders the leading icon instead of the plain [Icon] when set — for an
  /// icon whose content is dynamic (e.g. the calendar destination's
  /// day-of-month). Receives the state-dependent foreground color and the
  /// 18px icon size so the custom art tracks selection/hover exactly like a
  /// font glyph.
  final Widget Function(Color color, double size)? iconBuilder;

  /// The destination label.
  final String label;

  /// Whether this is the current selection.
  final bool selected;

  /// Tap handler. When null the row is non-interactive.
  final VoidCallback? onPressed;

  /// Optional trailing badge (e.g. a count). Collapses to a dot in rail mode.
  final Widget? badge;

  /// Places the [badge] immediately after the label's text with a
  /// [AppSpacing.sm] gap instead of pinned to the row's trailing edge — for a
  /// badge that reports state (a status dot) rather than a count that reads as
  /// belonging to the whole row. The label relaxes to its intrinsic width, so
  /// a long label still ellipsizes before it can crowd the badge.
  ///
  /// Rail mode is unchanged: with no label the badge keeps its full content
  /// straddling the square's top-right corner either way.
  final bool badgeBesideLabel;

  /// Icon-only rail mode fallback when there is no [CcSidebarScope] ancestor.
  final bool collapsed;

  Color _background(DesignSystemTokens t, Set<WidgetState> states) {
    if (selected) {
      return t.bgBrandSolid;
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
    final fg = selected ? t.accentOn : t.textSecondary;
    const iconSize = 18.0;
    // The fill lerps over CcMotion.fast (the AnimatedContainer below); the
    // foreground must travel WITH it. A white label snapped on while the fill
    // is still its light mid-lerp self reads as white-on-white (and the
    // deselect reverse as dark-ink-on-orange). Same duration and curve, so
    // fill and ink stay in lockstep.
    return TweenAnimationBuilder<Color?>(
      duration: CcMotion.fast,
      curve: CcMotion.standard,
      tween: ColorTween(end: fg),
      builder: (context, animatedFg, _) {
        final contentColor = animatedFg ?? fg;
        final leadingIcon =
            iconBuilder?.call(contentColor, iconSize) ??
            Icon(icon, size: iconSize, color: contentColor);

        final Widget container = AnimatedContainer(
          duration: CcMotion.fast,
          curve: CcMotion.standard,
          // The expanded row height is fixed at 32px (design rule); the 18px
          // icon and label center vertically inside it.
          height: collapsed ? null : kCcSidebarItemExtent,
          // The 10px left inset aligns the icon's left edge with the group
          // header's text (8px sidebar inset + 1px reserved border + 9px
          // padding = the header's 8 + 10). It also puts the icon's center at
          // x=27 from the sidebar edge — the exact spot the rail's centered
          // 32px square puts it (rail width 54, content center 27) — so
          // toggling the sidebar moves nothing (27 − 8 sidebar inset − 9
          // half-icon = 10).
          padding: collapsed
              ? EdgeInsets.zero
              // Left 9 + the 1px reserved border (which insets the child) =
              // the visual 10px inset: the icon's left edge lands exactly
              // where CcSidebarGroup's header padding (10) starts the section
              // title, and its center on the x=27 line the collapsed rail's
              // squares center on, so toggling the rail never moves the icon.
              // While the width animates the trailing inset drops to 0: the
              // row keeps its expanded geometry (labels fading) down to the
              // rail's 38px content width without the fixed icon + gap +
              // padding overflowing it (18 + 8 + 9 + 2 borders = 37 ≤ 38).
              : EdgeInsets.only(left: 9, right: transitioning ? 0 : 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadii.brSm,
            // A 1px border is reserved on every row (alpha-0 when idle) so
            // the layout never shifts when [selected] toggles the brand
            // border on. It reads as the solid pill's edge: invisible in
            // light (where `accent` and `bgBrandSolid` are the same burnt
            // orange), a brighter rim in dark. Alpha-0 of the SAME accent
            // when idle, so the toggle lerps only alpha instead of travelling
            // through a gray mid-point.
            border: Border.all(
              color: selected ? t.accent : t.accent.withValues(alpha: 0),
              width: 1,
            ),
          ),
          child: collapsed
              ? Center(child: leadingIcon)
              : Row(
                  children: [
                    leadingIcon,
                    const SizedBox(width: AppSpacing.sm),
                    // The label fades while the sidebar's width animates
                    // (kept in the layout so the row geometry never
                    // changes), which is what makes the toggle read as
                    // labels appearing/disappearing instead of anything
                    // moving.
                    //
                    // Stretched tight either way — the hug of the
                    // beside-label variant happens INSIDE the paragraph, not
                    // through flex: a loose flex label cannot pull a
                    // following sibling along its actual text width (the flex
                    // algorithm seats that sibling at the end of the label's
                    // SLOT, which lands back on the trailing edge).
                    Flexible(
                      fit: FlexFit.tight,
                      child: AnimatedOpacity(
                        opacity: transitioning ? 0 : 1,
                        duration: CcMotion.fast,
                        curve: CcMotion.standard,
                        child:
                            badgeBesideLabel &&
                                badge != null && !transitioning
                            // The badge rides the text's own layout as a
                            // trailing WidgetSpan: a short label leaves the
                            // rest of the row empty (the badge hugs the words
                            // with a small gap) and a long label ellipsizes
                            // BEFORE the span instead of overflowing it.
                            ? Text.rich(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                TextSpan(
                                  text: label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : CcTypography.regularWeight,
                                    color: contentColor,
                                  ),
                                  children: [
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: AppSpacing.sm,
                                        ),
                                        child: badge!,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  // The selected label goes BOLD on the soft
                                  // tint — weight plus ink carry the current
                                  // destination.
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : CcTypography.regularWeight,
                                  color: contentColor,
                                ),
                              ),
                      ),
                    ),
                    // A trailing count badge sits outside the paragraph so it
                    // stays pinned to the row's right edge. Both badge flavors
                    // leave the layout entirely during the width animation: as
                    // the row narrows they would overflow otherwise.
                    if (!badgeBesideLabel && badge != null && !transitioning)
                      ...[
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
      },
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
        selected ? t.bgBrandSolid : t.hover.withValues(alpha: 0),
        collapsed: collapsed,
        transitioning: transitioning,
      );
    } else {
      result = CcTappable(
        onPressed: onPressed,
        borderRadius: AppRadii.brSm,
        semanticLabel: label,
        // The brand focus ring would vanish against the selected row's solid
        // brand fill, so on that row the ring is `accentOn` like its ink.
        focusRingColor: selected ? t.accentOn : null,
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
