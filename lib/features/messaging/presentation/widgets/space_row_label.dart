import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter/widgets.dart';

/// Text block of a space or conversation row: the title line with its count
/// chip, trailing caption and unread / needs-input indicator, plus the
/// optional subtitle line under it.
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
    required this.status,
    required this.unread,
    required this.leadingHandlesRunning,
    required this.muted,
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

  /// Drives the trailing unread / needs-input indicator.
  final SpaceStatus status;

  /// Whether the unread dot should show.
  final bool unread;

  /// Whether the leading slot already shows the running signal.
  final bool leadingHandlesRunning;

  /// Muted agent-DM row. Hides the trailing indicator.
  final bool muted;

  /// Second line under the title.
  final String? subtitle;

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
    final showIndicator =
        !muted &&
        !transitioning &&
        SpaceTrailingIndicator.shouldShow(
          status: status,
          unread: unread,
          leadingHandlesRunning: leadingHandlesRunning,
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: CcScrambleText(
                label,
                scrambling: labelScrambling,
                style: _labelStyle,
              ),
            ),
            if (showCount) ...[
              const SizedBox(width: AppSpacing.sm),
              SpaceCountChip(count: count!, selected: filled),
            ],
            if (showTrailing) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                trailingLabel!,
                style: CcTypography.caption.copyWith(color: caption),
              ),
            ],
            if (showIndicator) ...[
              const SizedBox(width: AppSpacing.sm),
              SpaceTrailingIndicator(
                status: status,
                unread: unread,
                leadingHandlesRunning: leadingHandlesRunning,
                selected: filled,
              ),
            ],
          ],
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // RTL carve-out: a branch name is a git ref.
            textDirection: TextDirection.ltr,
            style: CcTypography.caption.copyWith(color: caption),
          ),
        ],
      ],
    );
  }
}
