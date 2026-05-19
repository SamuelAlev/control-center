import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A switch with a title and a description, laid out the same way everywhere.
///
/// There were four hand-rolled versions of this row in the settings tree, each
/// with its own gap, its own title weight and its own idea of whether the
/// description was 11px or 12px. They looked like four different controls doing
/// four different things, which is the opposite of what a settings page owes a
/// reader: a toggle should be recognisable as a toggle before you read a word
/// of it.
///
/// The whole row is the target. Tapping the text flips the switch — a 40x24
/// hit area on the far right of a 900px row is a phone-remote failure and a
/// desktop annoyance, and the switch itself stays keyboard-reachable.
class SettingsToggle extends StatelessWidget {
  /// Creates a [SettingsToggle].
  const SettingsToggle({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
    this.icon,
    this.badge,
    this.trailing,
  });

  /// What the switch controls. Sentence case, stated as the thing that is on.
  final String title;

  /// One sentence on what turning it on does. Prefer describing the
  /// consequence over restating the title.
  final String? description;

  /// Current state.
  final bool value;

  /// Fired with the new state. Null disables the row.
  final ValueChanged<bool>? onChanged;

  /// Optional leading glyph.
  final IconData? icon;

  /// Optional badge beside the title (scope, provenance, "needs restart").
  final Widget? badge;

  /// Optional extra control between the text and the switch.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final enabled = onChanged != null;
    final titleColor = enabled ? tokens.textPrimary : tokens.textDisabled;

    // The row is a POINTER convenience only: no focus node, no semantics of its
    // own. The switch already publishes a proper `toggled` node carrying the
    // title, so a second focusable node here would give the screen reader two
    // stops and two readings for one control, and give the keyboard user a tab
    // stop that does nothing the next one does not.
    return CcTappable(
      onPressed: enabled ? () => onChanged!(!value) : null,
      semanticButton: false,
      canRequestFocus: false,
      showFocusRing: false,
      mouseCursor: SystemMouseCursors.click,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered) && enabled;
        return AnimatedContainer(
          duration: CcMotion.fast,
          color: hovered ? tokens.hover : const Color(0x00000000),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: enabled ? tokens.fgTertiary : tokens.fgDisabled,
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: CcTypography.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                        ?badge,
                      ],
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        description!,
                        style: CcTypography.caption.copyWith(
                          color: enabled
                              ? tokens.textTertiary
                              : tokens.textDisabled,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                trailing!,
              ],
              const SizedBox(width: AppSpacing.md),
              CcSwitch(
                value: value,
                onChanged: onChanged,
                semanticLabel: title,
              ),
            ],
          ),
        );
      },
    );
  }
}
