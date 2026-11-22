import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row.dart';
import 'package:flutter/widgets.dart';

/// A panel row that is not a space (approvals, all spaces) on the space
/// rows' geometry, so every label in the panel starts on one line.
class TrayPanelLinkRow extends StatelessWidget implements CcFluidHoverTarget {
  /// Creates a [TrayPanelLinkRow].
  const TrayPanelLinkRow({
    required this.icon,
    required this.label,
    required this.onPress,
    this.iconColor,
    this.trailingLabel,
    super.key,
  });

  /// The glyph in the mark column.
  final IconData icon;

  /// Its color; the secondary ink when null.
  final Color? iconColor;

  /// The row's title.
  final String label;

  /// A short caption at the end, such as a count.
  final String? trailingLabel;

  /// Opens what the row names.
  final VoidCallback onPress;

  @override
  bool get fluidHoverEnabled => true;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return SpaceRow(
      leading: Icon(icon, size: 16, color: iconColor ?? t.textSecondary),
      label: label,
      selected: false,
      trailingLabel: trailingLabel,
      onPress: onPress,
    );
  }
}

/// A quiet line in place of an empty list.
class TrayPanelNote extends StatelessWidget {
  /// Creates a [TrayPanelNote].
  const TrayPanelNote({required this.text, super.key});

  /// What to say.
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: AppSpacing.sm,
      ),
      child: Text(text, style: TextStyle(color: t.textTertiary, fontSize: 12)),
    );
  }
}
