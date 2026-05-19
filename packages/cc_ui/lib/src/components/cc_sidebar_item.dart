import 'package:cc_ui/src/components/cc_sidebar.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A navigation row for [CcSidebar].
///
/// Renders an [icon] and [label] as a flat row. At rest the fill is transparent
/// so the sidebar background shows through; hovering washes it with `t.hover`.
/// The [selected] row reads as the current destination through a brand-tinted
/// `accentSoft` fill (the accent at reduced alpha) wrapped in a 1px `accent`
/// border, with accent-colored icon/label; unselected rows use `textSecondary`.
///
/// In [collapsed] (icon-only rail) mode the label is hidden, the icon centers,
/// and any [badge] collapses to a small accent dot in the corner. The collapsed
/// state is sourced from the nearest [CcSidebarScope] when present, falling back
/// to the local [collapsed] flag.
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

  /// The leading nav icon (e.g. a `lucide_icons_flutter` glyph).
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
  }) {
    final fg = selected ? t.accent : t.textSecondary;

    final Widget content = AnimatedContainer(
      duration: CcMotion.fast,
      curve: CcMotion.standard,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: AppSpacing.sm,
      ),
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
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      color: fg,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  badge!,
                ],
              ],
            ),
    );

    // Selected reads purely through the tinted fill + brand border above; the
    // only overlay left is the collapsed badge dot in the corner.
    return Stack(
      children: [
        content,
        if (collapsed && badge != null)
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: t.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final collapsed = CcSidebarScope.collapsedOf(context) ?? this.collapsed;

    if (onPressed == null) {
      return _buildBody(
        t,
        selected ? t.accentSoft : t.hover.withValues(alpha: 0),
        collapsed: collapsed,
      );
    }

    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brSm,
      semanticLabel: label,
      builder: (context, states) =>
          _buildBody(t, _background(t, states), collapsed: collapsed),
    );
  }
}
