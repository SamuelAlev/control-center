import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Small count pill shown on a sidebar item (e.g. running agents).
class SidebarCountBadge extends StatelessWidget {
  /// Creates a [SidebarCountBadge].
  const SidebarCountBadge({
    super.key,
    required this.count,
    required this.selected,
  });

  /// The count shown; above 99 it reads `99+`.
  final int count;

  /// Whether the pill rides [CcSidebarItem]'s selected row. That row is a
  /// solid `bgBrandSolid` fill — the accent pill IS the fill's hue there, so
  /// it inverts: `accentOn` pill, `bgBrandSolid` digits (4.5:1+ on white in
  /// both brightnesses). Same treatment as the space rows'
  /// `_PrCountAdornment`.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    // The row's fill and ink lerp over CcMotion.fast; the pill travels WITH
    // them on one tween, or a white pill snaps on while the row is still its
    // pale mid-lerp self.
    return TweenAnimationBuilder<double>(
      duration: CcMotion.fast,
      curve: CcMotion.standard,
      tween: Tween<double>(end: selected ? 1 : 0),
      builder: (context, progress, _) => Container(
        constraints: const BoxConstraints(minWidth: 18),
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Color.lerp(t.accent, t.accentOn, progress),
          borderRadius: AppRadii.brSm,
        ),
        alignment: Alignment.center,
        child: Text(
          count > 99 ? '99+' : '$count',
          style: TextStyle(
            color: Color.lerp(t.accentOn, t.bgBrandSolid, progress),
            fontSize: 11,
            height: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// A sidebar hairline divider drawn edge-to-edge, carrying its own vertical
/// breathing room. [CcSidebar] pads its content by [AppSpacing.sm] on each
/// side, so the divider bleeds out via an [OverflowBox] (which permits
/// overflow by design, unlike negative padding, which asserts in debug) with
/// its height bounded so the footer's unbounded column constraints can't trip
/// it. The [AppSpacing.xs] vertical padding plus the neighbouring groups' own
/// [AppSpacing.xs] padding totals 8px — matching the sidebar's horizontal
/// content inset so the air reads uniform on all sides.
class SidebarHairline extends StatelessWidget {
  /// Creates a [SidebarHairline].
  const SidebarHairline({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: 1,
          child: OverflowBox(
            maxWidth: constraints.maxWidth + 2 * AppSpacing.sm,
            child: const CcDivider(),
          ),
        ),
      ),
    );
  }
}
