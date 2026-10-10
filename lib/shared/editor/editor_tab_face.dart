import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// The painted face of one editor tab: background, borders, leading, label,
/// trailing status and the close/dirty slot, with the accent rule under the
/// selected tab.
///
/// Purely visual. `EditorTabBar` wraps it in the tab's semantics, focus,
/// hover and gestures; the drag ghost and the landing flight paint the same
/// face, so a tab in flight looks exactly like the tab it lifted from the
/// strip rather than a stand-in chip.
class EditorTabFace extends StatelessWidget {
  /// Creates an [EditorTabFace].
  const EditorTabFace({
    super.key,
    required this.label,
    required this.selected,
    this.hovered = false,
    this.icon,
    this.leading,
    this.trailing,
    this.scrambling = false,
    this.reserveAffordance = false,
    this.affordance,
  });

  /// The tab's label, already localized.
  final String label;

  /// Whether this is the leaf's selected tab (body-colored, accent rule).
  final bool selected;

  /// Whether the tab shows the hover wash.
  final bool hovered;

  /// Leading glyph, used when [leading] is null.
  final IconData? icon;

  /// Leading widget builder taking the resolved label color; wins over [icon].
  final Widget Function(Color color)? leading;

  /// Trailing status builder taking the resolved label color.
  final Widget Function(Color color)? trailing;

  /// Whether the label churns while a model works out its text.
  final bool scrambling;

  /// Whether the 16×16 close/dirty slot is reserved. Reserved even when
  /// [affordance] is null, so the label never shifts as the slot fills.
  final bool reserveAffordance;

  /// The close/dirty slot's content, or null for an empty slot.
  final Widget? affordance;

  /// Max width of a single tab cell. Longer labels ellipsize (VS Code parity)
  /// so one long path can't blow the tab out to the full bar width.
  static const double maxWidth = 220;

  /// Resolved label color for a tab in [selected] state.
  static Color labelColorFor(DesignSystemTokens t, {required bool selected}) =>
      selected ? t.fg : t.textTertiary;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final labelColor = labelColorFor(t, selected: selected);
    final background = selected
        ? t.bgPrimary
        : (hovered ? t.hover : const Color(0x00000000));
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: BorderDirectional(
            end: BorderSide(color: t.borderPrimary),
            // The strip's single divider line is the editor body's top border
            // (drawn by the host). The active tab alone paints its own bottom
            // rule in the body color so it visually "opens" onto the content;
            // inactive tabs have no bottom border — otherwise the line doubles
            // against the body's top border.
            bottom: selected ? BorderSide(color: t.bgPrimary) : BorderSide.none,
          ),
        ),
        // The accent rule is an overlay (not a border) so selecting a tab
        // doesn't inset — and thus nudge — the label.
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              // widthFactor: 1 makes the cell shrink-wrap its content (up to
              // maxWidth) instead of expanding to fill it; heightFactor stays
              // null so it still centers vertically in the strip.
              child: Center(
                widthFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leading != null) ...[
                      leading!(labelColor),
                      const SizedBox(width: 6),
                    ] else if (icon != null) ...[
                      Icon(icon, size: 14, color: labelColor),
                      const SizedBox(width: 6),
                    ],
                    Flexible(child: _label(labelColor)),
                    if (trailing != null) ...[
                      const SizedBox(width: 6),
                      trailing!(labelColor),
                    ],
                    // Close / dirty affordance: the slot is always reserved
                    // (so the label never shifts).
                    if (reserveAffordance) ...[
                      const SizedBox(width: 6),
                      SizedBox(width: 16, height: 16, child: affordance),
                    ],
                  ],
                ),
              ),
            ),
            if (selected)
              // Accent underline at the BOTTOM — matches the sidebar's CcTabs
              // indicator so the two tab strips read as aligned. Offset by the
              // 1px rule the strip draws under itself, exactly as CcTabs does,
              // so the two accents land on the same scanline; the selected
              // cell's body-colored bottom border then stays visible below it,
              // breaking the rule so the tab "opens" onto its content.
              Positioned(
                bottom: 1,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: SizedBox(
                    height: 2,
                    child: ColoredBox(color: t.accent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The selected label is medium (w500), which measures wider than the
  /// resting w400 — Manrope is a variable font, so weight really changes
  /// advance widths. An invisible w500 twin reserves the selected width up
  /// front, so switching tabs restyles the label without resizing the cell
  /// (which would shift every tab to its right).
  Widget _label(Color labelColor) {
    return CcTooltip(
      message: label,
      // Below the strip: the bar sits under the window chrome, so a tooltip
      // above it has nowhere to go.
      placement: CcTooltipPlacement.bottom,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          ExcludeSemantics(
            child: Opacity(
              opacity: 0,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          CcScrambleText(
            label,
            scrambling: scrambling,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected
                  ? CcTypography.mediumWeight
                  : CcTypography.regularWeight,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
