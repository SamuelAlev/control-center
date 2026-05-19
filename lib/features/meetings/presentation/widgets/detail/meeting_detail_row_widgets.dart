import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';

/// A full-width footer row that adds a new item, shared by the action-item and
/// decision tabs (an accent "+ {label}" affordance at the bottom of the list).
class MeetingAddRow extends StatelessWidget {
  /// Creates a [MeetingAddRow].
  const MeetingAddRow({super.key, required this.label, required this.onTap});

  /// The button label (e.g. "Add action item").
  final String label;

  /// Called when tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(AppIcons.plus, size: 15, color: ds.accent),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ds.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The empty state for a detail tab whose list the agent extracts: what is
/// missing, and the affordance to add one by hand.
///
/// Shared by the action-item and decision tabs so both read as the same
/// surface — they each used to hand-roll a bare centered `Text` plus a button,
/// which is the one empty-state treatment the design system already owns.
class MeetingTabEmptyState extends StatelessWidget {
  /// Creates a [MeetingTabEmptyState].
  const MeetingTabEmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAdd,
  });

  /// The glyph standing in for the missing content.
  final IconData icon;

  /// What is not here yet.
  final String message;

  /// Label for the add affordance.
  final String actionLabel;

  /// Called when the add affordance is pressed.
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: CcEmptyState(
        icon: icon,
        iconSize: 28,
        message: message,
        action: CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          onPressed: onAdd,
          icon: AppIcons.plus,
          child: Text(actionLabel),
        ),
      ),
    );
  }
}

/// A compact ghost icon button used for per-row edit/delete actions in the
/// action-item and decision tabs.
class MeetingRowIconButton extends StatelessWidget {
  /// Creates a [MeetingRowIconButton].
  const MeetingRowIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  /// The icon to show.
  final IconData icon;

  /// The hover/long-press tooltip.
  final String tooltip;

  /// Called when tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return CcTooltip(
      message: tooltip,
      child: CcTappable(
        onPressed: onTap,
        semanticLabel: tooltip,
        builder: (context, states) => Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 15,
            color: states.contains(WidgetState.hovered) ? ds.fg : ds.muted,
          ),
        ),
      ),
    );
  }
}
