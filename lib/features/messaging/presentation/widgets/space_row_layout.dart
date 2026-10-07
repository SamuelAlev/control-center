import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_label.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';

export 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart'
    show kSpaceSidebarTrailingControl;

/// Horizontal inset of a space row.
const double kSpaceSidebarPad = 10;

/// Status-mark column. The title starts one gap to its end.
const double kSpaceSidebarMarkSlot = 16;

/// Gap after the status mark, wide enough to clear the open-PR count.
const double kSpaceSidebarMarkGap = 16;

/// Nested-conversation status column: a dot or spinner, no hanging PR count.
const double kConversationMarkSlot = 12;

/// Gap after a conversation mark. Nothing hangs past the dot.
const double kConversationMarkGap = AppSpacing.xs;

/// Conversation titles. One step under the space name: [CcTypography.bodySm].
const double kConversationLabelFontSize = 13;

/// Nested conversation row. Shorter than a space so the list stays tight.
const double kConversationRowExtent = 24;

/// Width the overflow trigger occupies, including its leading gap.
const double kSpaceSidebarOverflowSlot = kSpaceSidebarTrailingControl + 4;

/// Air inside a two-line row, so the branch shares the title's wash.
const double _kTwoLinePad = AppSpacing.xxs;

/// Title, optional subtitle, and an overflow slot that does not shift text.
class SpaceRowLayout extends StatelessWidget {
  /// Creates a [SpaceRowLayout].
  const SpaceRowLayout({
    super.key,
    required this.tokens,
    required this.leading,
    required this.label,
    this.labelScrambling = false,
    required this.contentColor,
    required this.caption,
    required this.filled,
    required this.indent,
    this.cardInset = EdgeInsets.zero,
    required this.transitioning,
    required this.hasMenu,
    required this.showMenu,
    required this.status,
    required this.unread,
    required this.leadingHandlesRunning,
    required this.muted,
    required this.hoverColor,
    this.markSlot = kSpaceSidebarMarkSlot,
    this.markGap = kSpaceSidebarMarkGap,
    this.labelFontSize = 14,
    this.extent = kCcSidebarItemExtent,
    this.subtitle,
    this.trailingLabel,
    this.count,
    this.menuItems,
    this.menuSemanticLabel,
  });

  /// Tokens for the brand fill and its border.
  final DesignSystemTokens tokens;

  /// Status mark, spinner, or badge.
  final Widget leading;

  /// Primary line.
  final String label;

  /// Whether [label]'s letters churn (see [CcScrambleText]).
  final bool labelScrambling;

  /// Animated foreground colour.
  final Color contentColor;

  /// Colour for the subtitle and the relative time.
  final Color caption;

  /// Whether the brand fill is showing.
  final bool filled;

  /// Extra start inset.
  final double indent;

  /// Vertical air the fill paints, matching the space row card inset.
  final EdgeInsets cardInset;

  /// Sidebar width is animating, so trailing chrome is hidden.
  final bool transitioning;

  /// Whether a slot is reserved for the overflow trigger.
  final bool hasMenu;

  /// Whether the trigger is painted in that slot.
  final bool showMenu;

  /// Drives the trailing unread / needs-input indicator.
  final SpaceStatus status;

  /// Whether the unread dot should show.
  final bool unread;

  /// Whether the leading slot already shows the running signal.
  final bool leadingHandlesRunning;

  /// Width of the leading column.
  final double markSlot;

  /// Space between the leading column and the title.
  final double markGap;

  /// Primary-line size. Space titles stay at 14; conversations step down.
  final double labelFontSize;

  /// Single-line height. Spaces use the sidebar item extent.
  final double extent;

  /// Muted agent-DM row. Hides the trailing indicator.
  final bool muted;

  /// Hover wash, already resolved against the fluid-hover group.
  final Color hoverColor;

  /// Second line under the title.
  final String? subtitle;

  /// Short trailing caption.
  final String? trailingLabel;

  /// Optional count chip. Null hides it.
  final int? count;

  /// Overflow actions. Null hides the trigger.
  final List<CcMenuItem>? menuItems;

  /// Accessible name for the overflow trigger.
  final String? menuSemanticLabel;

  bool get _twoLine => subtitle != null && subtitle!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    // Fixed columns. The rail is narrower than these mid-animation.
    final minRowWidth =
        markSlot + markGap + (hasMenu ? kSpaceSidebarOverflowSlot : 0);
    return AnimatedContainer(
      duration: CcMotion.resolve(context, CcMotion.fast),
      curve: CcMotion.standard,
      height: _twoLine ? null : extent + cardInset.vertical,
      decoration: BoxDecoration(color: hoverColor, borderRadius: AppRadii.brSm),
      foregroundDecoration: BoxDecoration(
        border: Border.all(
          color: filled ? t.accent : t.accent.withValues(alpha: 0),
          width: 1,
        ),
        borderRadius: AppRadii.brSm,
      ),
      child: Stack(
        // Expand so a one-line title centers in the fixed height.
        fit: _twoLine ? StackFit.loose : StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: filled ? 1 : 0,
                duration: CcMotion.fast,
                curve: CcMotion.standard,
                child: ColoredBox(color: t.bgBrandSolid),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: kSpaceSidebarPad + indent,
              end: transitioning ? 0 : kSpaceSidebarPad,
              top: (_twoLine ? _kTwoLinePad : 0) + cardInset.top,
              bottom: (_twoLine ? _kTwoLinePad : 0) + cardInset.bottom,
            ),
            // While the sidebar width animates the rail drops below the fixed
            // columns. Lay out at their width and let the hidden title spill
            // past the end instead of overflowing the row.
            child: LayoutBuilder(
              builder: (context, constraints) => OverflowBox(
                alignment: AlignmentDirectional.centerStart,
                fit: OverflowBoxFit.deferToChild,
                maxWidth: math.max(constraints.maxWidth, minRowWidth),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: markSlot,
                      height: markSlot,
                      child: Center(
                        child: IconTheme.merge(
                          data: IconThemeData(
                            color: contentColor,
                            size: markSlot,
                          ),
                          child: leading,
                        ),
                      ),
                    ),
                    SizedBox(width: markGap),
                    Expanded(
                      child: AnimatedOpacity(
                        opacity: transitioning ? 0 : 1,
                        duration: CcMotion.fast,
                        curve: CcMotion.standard,
                        child: SpaceRowLabel(
                          label: label,
                          labelScrambling: labelScrambling,
                          labelFontSize: labelFontSize,
                          contentColor: contentColor,
                          caption: caption,
                          filled: filled,
                          transitioning: transitioning,
                          status: status,
                          unread: unread,
                          leadingHandlesRunning: leadingHandlesRunning,
                          muted: muted,
                          subtitle: subtitle,
                          trailingLabel: trailingLabel,
                          count: count,
                        ),
                      ),
                    ),
                    if (hasMenu)
                      const SizedBox(width: kSpaceSidebarOverflowSlot),
                  ],
                ),
              ),
            ),
          ),
          if (hasMenu)
            PositionedDirectional(
              // Inset is fill; the trigger stays on the title block.
              top: cardInset.top,
              bottom: cardInset.bottom,
              end: kSpaceSidebarPad,
              child: Center(
                child: SpaceRowOverflowMenu(
                  items: menuItems!,
                  semanticLabel: menuSemanticLabel!,
                  color: contentColor,
                  revealed: showMenu,
                  selected: filled,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
