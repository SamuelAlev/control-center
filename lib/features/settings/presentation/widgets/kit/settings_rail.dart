/// The master-detail scaffold shared by the dense pick-one-and-configure-it
/// settings surfaces (providers & models, detected runners, the agent roster,
/// skills): a narrow rail of selectable items on the left, a hairline divider,
/// and the detail pane for the selected item on the right.
///
/// Why shared: the pattern was rebuilt for the providers surface (Z.ai's model
/// settings) and immediately wanted by three more. Four copies of a selected-
/// wash row with a status dot would drift; one carries the interaction
/// (hover/press/selected fills, the focus ring, the a11y status announcement)
/// for all of them.
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Lays [rail] and [detail] side by side with a hairline divider between them.
/// Both columns size to content — the surrounding settings page owns the
/// scrolling.
///
/// The divider is a [Positioned] line in a [Stack] rather than a border on
/// either column: a border stops at ITS column's content, so it ran short
/// whenever the other column was the taller one (an eleven-row rail beside a
/// not-connected provider's three-line pane). Stretching the row with
/// `IntrinsicHeight` is not an option either — a `LayoutBuilder` descendant
/// cannot answer an intrinsic-height query, and both panes have them.
class SettingsMasterDetail extends StatelessWidget {
  /// Creates a [SettingsMasterDetail].
  const SettingsMasterDetail({
    super.key,
    required this.rail,
    required this.detail,
    this.railWidth = 232,
    this.stretch = false,
    this.railPadding,
  });

  /// The left column (search field, group labels, [SettingsRailItem]s).
  final Widget rail;

  /// The right pane for the selected item.
  final Widget detail;

  /// Rail column width.
  final double railWidth;

  /// When true the row stretches children to the full cross-axis height,
  /// which is needed when the rail or detail contain [Expanded] widgets that
  /// rely on bounded vertical constraints (e.g. the agent roster's ListView).
  final bool stretch;

  /// Padding around the rail content. Defaults to [AppSpacing.lg] on all
  /// sides. Pass [EdgeInsets.zero] for content that manages its own insets.
  final EdgeInsetsGeometry? railPadding;

  /// Hairline thickness, reserved in the row so the detail pane never sits
  /// under the line the stack paints over it.
  static const double _dividerWidth = 1;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Row(
          crossAxisAlignment: stretch
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: railWidth,
              child: Padding(
                padding: railPadding ?? const EdgeInsets.all(AppSpacing.lg),
                child: rail,
              ),
            ),
            const SizedBox(width: _dividerWidth),
            Expanded(child: detail),
          ],
        ),
        PositionedDirectional(
          start: railWidth,
          top: 0,
          bottom: 0,
          width: _dividerWidth,
          child: ColoredBox(color: tokens.borderSecondary),
        ),
      ],
    );
  }
}

/// The small uppercase mono label above a group of rail items ("PROVIDERS",
/// "CUSTOM PROVIDERS").
class SettingsRailGroupLabel extends StatelessWidget {
  /// Creates a [SettingsRailGroupLabel].
  const SettingsRailGroupLabel({super.key, required this.label});

  /// The group heading text.
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Text(
      label,
      style: CcFonts.code(
        textStyle: CcTypography.caption.copyWith(
          color: tokens.textTertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// The muted note a rail group renders when it has nothing to show.
class SettingsRailEmptyNote extends StatelessWidget {
  /// Creates a [SettingsRailEmptyNote].
  const SettingsRailEmptyNote({super.key, required this.message});

  /// The note text.
  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        message,
        style: CcTypography.caption.copyWith(color: tokens.textTertiary),
      ),
    );
  }
}

/// One rail row: a status dot (or a leading icon) and a name. Selected reads
/// as a filled wash; keyboard focus keeps the standard ring. The [tone] dot is
/// always paired with [statusLabel] in the semantic announcement, so state
/// never rides on color alone.
class SettingsRailItem extends StatelessWidget {
  /// Creates a [SettingsRailItem].
  const SettingsRailItem({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone,
    this.statusLabel,
    this.icon,
    this.selected = false,
    this.trailing,
  });

  /// The row's name.
  final String label;

  /// The status-dot tone; omit for action rows (e.g. "Add provider").
  final CcStatusTone? tone;

  /// The state's word ("available", "denied") for assistive tech, paired with
  /// [tone] in the semantic label.
  final String? statusLabel;

  /// A leading icon when there is no [tone] dot.
  final IconData? icon;

  /// Whether the row is the selected one.
  final bool selected;

  /// Optional trailing content (a count, a small badge).
  final Widget? trailing;

  /// Tap handler.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final statusLabel = this.statusLabel;
    return CcTappable(
      onPressed: onPressed,
      semanticLabel: statusLabel == null ? label : '$label, $statusLabel',
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final fill = pressed || selected
            ? tokens.hoverStrong
            : hovered
            ? tokens.hover
            : null;
        return Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(color: fill),
          child: Row(
            children: [
              if (tone != null)
                CcStatusDot(tone: tone!)
              else if (icon != null)
                Icon(icon, size: 15, color: tokens.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.bodySm.copyWith(
                    color: selected || hovered
                        ? tokens.textPrimary
                        : tokens.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        );
      },
    );
  }
}
