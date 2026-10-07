import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_row_painter.dart';
import 'package:flutter/widgets.dart';

/// A clickable "Show N lines" / "Show end of file" expand affordance, rendered
/// as a real widget so it gets native hover + cursor feedback.
// RTL carve-out: diff canvas — gap rows align to the LTR code gutter and the
// h-scrollbar/overlays position in pixel space.
class GapRow extends StatelessWidget {
  /// Creates a [GapRow].
  const GapRow({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.enabled,
    this.showTopBorder = true,
    this.showBottomBorder = true,
  });

  /// Button label (`Show N lines` / `Show end of file`).
  final String label;

  /// Trailing expand icon.
  final IconData icon;

  /// Expands the collapsed hunk.
  final VoidCallback onTap;

  /// Whether the row can be activated.
  final bool enabled;

  /// Drop the top/bottom hairline when this gap abuts a file header, whose own
  /// 1px border already separates them — otherwise the gap's 0.5px line stacks
  /// with it and reads as a doubled border.
  final bool showTopBorder;

  /// See [showTopBorder].
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ds;
    final hoverBg = tokens.bgPrimaryHover;
    final surface = tokens.bgPrimary;
    // A real tappable, not a bare gesture detector: keyboard users reach it
    // with Tab or the diff's arrow keys and expand it with Enter/Space, and a
    // screen reader announces it as a button.
    return CcTappable(
      onPressed: enabled ? onTap : null,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          height: kDiffLineHeight,
          padding: const EdgeInsets.only(left: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: hovered ? hoverBg : surface,
            border: Border(
              top: showTopBorder
                  ? BorderSide(color: tokens.borderSecondary, width: 0.5)
                  : BorderSide.none,
              bottom: showBottomBorder
                  ? BorderSide(color: tokens.borderSecondary, width: 0.5)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  icon,
                  size: 12,
                  color: hovered ? tokens.fgSecondaryHover : tokens.fgTertiary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.caption.copyWith(
                  color: hovered
                      ? tokens.textSecondaryHover
                      : tokens.textTertiary,
                  height: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
