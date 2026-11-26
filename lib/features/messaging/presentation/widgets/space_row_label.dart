import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart';
import 'package:flutter/widgets.dart';

/// Space between the signal and the title.
const double _kSignalGap = 6;

/// Text block of a space or conversation row: the title line with its count
/// chip and trailing caption, plus the optional subtitle line under it. The
/// unread and needs-input signal leads the row instead (see [AttentionDot]).
class SpaceRowLabel extends StatelessWidget {
  /// Creates a [SpaceRowLabel].
  const SpaceRowLabel({
    super.key,
    required this.label,
    required this.labelScrambling,
    required this.labelFontSize,
    required this.contentColor,
    required this.caption,
    required this.filled,
    required this.transitioning,
    this.titleNamesRow = false,
    this.signal,
    this.subtitle,
    this.trailingLabel,
    this.count,
  });

  /// Primary line.
  final String label;

  /// Whether [label]'s letters churn (see [CcScrambleText]).
  final bool labelScrambling;

  /// Primary-line size. Space titles stay at 14; conversations step down.
  final double labelFontSize;

  /// Animated foreground colour.
  final Color contentColor;

  /// Colour for the subtitle and the relative time.
  final Color caption;

  /// Whether the brand fill is showing.
  final bool filled;

  /// Sidebar width is animating, so trailing chrome is hidden.
  final bool transitioning;

  /// The row's own node already carries [label] as its name, so the painted
  /// title (and its tooltip) stay out of semantics instead of reading twice.
  final bool titleNamesRow;

  /// The spinner or attention dot in front of the title, centred on the
  /// title line. The title moves over to make room for it; the subtitle
  /// does not.
  final Widget? signal;

  /// Second line under the title, painted in the caption style and colour.
  final Widget? subtitle;

  /// Short trailing caption.
  final String? trailingLabel;

  /// Optional count chip. Null hides it.
  final int? count;

  /// Body at medium for spaces; bodySm at regular for conversations.
  TextStyle get _labelStyle {
    final conversation = labelFontSize <= CcTypography.bodySm.fontSize!;
    final base = conversation ? CcTypography.bodySm : CcTypography.body;
    return base.copyWith(
      color: contentColor,
      fontWeight: conversation
          ? CcTypography.regularWeight
          : CcTypography.mediumWeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showTrailing =
        trailingLabel != null && trailingLabel!.isNotEmpty && !transitioning;
    // The chip leaves with the other trailing chrome: as the row narrows it
    // would overflow the title line.
    final showCount = count != null && !transitioning;
    final titleLine = Row(
      children: [
        // The title and its chip take the free width so the caption always
        // sits flush at the end, whatever the title's length. The inner row
        // stays loose: the tooltip hugs the text.
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: ExcludeSemantics(
                  excluding: titleNamesRow,
                  child: CcTooltip(
                    message: label,
                    showDelay: const Duration(milliseconds: 700),
                    placement: CcTooltipPlacement.end,
                    maxWidth: 480,
                    child: CcScrambleText(
                      label,
                      scrambling: labelScrambling,
                      style: _labelStyle,
                    ),
                  ),
                ),
              ),
              if (showCount) ...[
                const SizedBox(width: AppSpacing.sm),
                SpaceCountChip(count: count!, selected: filled),
              ],
            ],
          ),
        ),
        if (showTrailing) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            trailingLabel!,
            style: CcTypography.caption.copyWith(color: caption),
          ),
        ],
      ],
    );
    final signal = this.signal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (signal == null)
          titleLine
        else
          // Only the title makes room for the signal; the subtitle keeps the
          // row's start edge.
          Row(
            children: [
              // Painted only: [SpaceRow] reads the signal out as its value.
              ExcludeSemantics(
                child: SizedBox(
                  width: kSpaceRowSignalSize,
                  child: Center(child: signal),
                ),
              ),
              const SizedBox(width: _kSignalGap),
              Expanded(child: titleLine),
            ],
          ),
        if (subtitle case final subtitle?)
          DefaultTextStyle.merge(
            style: CcTypography.caption.copyWith(color: caption),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: subtitle,
          ),
      ],
    );
  }
}
