import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/shared/icons/app_icons.dart';
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
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.brSm,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 15, color: ds.muted),
        ),
      ),
    );
  }
}
