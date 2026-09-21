import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Label + count row for the inbox, PR-repo and pipeline filter rails.
///
/// Selection is the wash only. Bumping [FontWeight] on the active label
/// makes SkWasm's text painter (variable Manrope + [TextOverflow.ellipsis])
/// report a huge advance, so a name that fits while idle ("ControlCenter/repo-a")
/// paints as "Contro..." with a gap before the count.
class CountRailItem extends StatelessWidget implements CcFluidHoverTarget {
  /// Creates a [CountRailItem].
  const CountRailItem({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onPressed,
  });

  /// Left-side label (section name, `owner/repo`, filter, …).
  final String label;

  /// Right-side tabular count.
  final int count;

  /// Whether this row is the current selection.
  final bool selected;

  /// Tap handler.
  final VoidCallback onPressed;

  @override
  bool get fluidHoverEnabled => true;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    return Semantics(
      selected: selected,
      child: CcTappable(
        onPressed: onPressed,
        semanticLabel: '$label · $count',
        builder: (context, states) {
          final hovered = states.contains(WidgetState.hovered);
          final fluidActive = CcFluidHover.isItemActive(context);
          // Translucent `hover` / `hoverStrong` as a box fill double-paints
          // glyphs on SkWasm. Pre-blend onto the page canvas so every fill
          // is opaque. Idle is the canvas itself, not alpha-0 of the hover
          // token: Color.lerp of that wash (fg RGB @ 0%) into the selected
          // blend peaks at a dark gray at t≈0.5 — the click flash on the
          // PR repo rail. Pointer hover is painted once by [CcFluidHover]
          // when this row is the nearest target.
          final Color bg;
          if (selected) {
            bg = Color.alphaBlend(tokens.hoverStrong, tokens.canvas);
          } else if (hovered && !fluidActive) {
            bg = Color.alphaBlend(tokens.hover, tokens.canvas);
          } else {
            bg = tokens.canvas;
          }
          return AnimatedContainer(
            duration: CcMotion.resolveFade(context, CcMotion.fast),
            curve: CcMotion.standard,
            width: double.infinity,
            height: kCcSidebarItemExtent,
            color: bg,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.caption.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$count',
                  style: CcTypography.caption.copyWith(
                    color: count > 0 ? tokens.textSecondary : tokens.idle,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
