import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A centered, muted "nothing here yet" surface for empty lists and panels.
///
/// Stacks a muted [icon], a primary [message], an optional [description] line
/// that teaches what fills the surface, and an optional [action] widget (e.g. a
/// `CcButton`). Everything is centered and constrained for comfortable reading.
class CcEmptyState extends StatelessWidget {
  /// Creates a [CcEmptyState].
  const CcEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.description,
    this.action,
    this.iconSize = 48,
    this.maxWidth = 320,
  });

  /// Icon shown above the message.
  final IconData icon;

  /// Primary line.
  final String message;

  /// Optional secondary line below the message.
  final String? description;

  /// Optional action widget (e.g. a button) shown below the text.
  final Widget? action;

  /// Size of the icon.
  final double iconSize;

  /// Max width for the text block.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final hasDescription =
        description != null && description!.trim().isNotEmpty;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: t.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 1.35,
                fontWeight: FontWeight.w400,
                color: t.textSecondary,
              ),
            ),
            if (hasDescription) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                  color: t.textTertiary,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
