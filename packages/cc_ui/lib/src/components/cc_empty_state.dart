import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:flutter/widgets.dart';

/// Density of a [CcEmptyState].
enum CcEmptyStateSize {
  /// Page and panel empty surfaces — large muted icon, title-sized message.
  md,

  /// Nested cards and settings sections — body-sized copy, small icon.
  sm,
}

/// A centered, muted "nothing here yet" surface for empty lists and panels.
///
/// Stacks a muted [icon], a primary [message], an optional [description] line
/// that teaches what fills the surface and an optional [action] widget (e.g. a
/// `CcButton`). Everything is centered and constrained for comfortable reading.
///
/// Use [CcEmptyStateSize.md] for a page or panel that is empty. Use
/// [CcEmptyStateSize.sm] inside a nested card — the title-sized default
/// shouts over the card's own heading.
class CcEmptyState extends StatelessWidget {
  /// Creates a [CcEmptyState].
  const CcEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.description,
    this.action,
    this.size = CcEmptyStateSize.md,
    this.iconSize,
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

  /// Visual density. Defaults to [CcEmptyStateSize.md].
  final CcEmptyStateSize size;

  /// Size of the icon. Defaults to 48 on [CcEmptyStateSize.md], 24 on
  /// [CcEmptyStateSize.sm].
  final double? iconSize;

  /// Max width for the text block.
  final double maxWidth;

  bool get _compact => size == CcEmptyStateSize.sm;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final hasDescription =
        description != null && description!.trim().isNotEmpty;
    final resolvedIconSize = iconSize ?? (_compact ? 24.0 : 48.0);
    final messageStyle = _compact
        ? CcTypography.bodySm.copyWith(color: t.textSecondary)
        : CcTypography.title.copyWith(color: t.textSecondary);
    final descriptionStyle = _compact
        ? CcTypography.caption.copyWith(color: t.textTertiary)
        : CcTypography.bodySm.copyWith(color: t.textTertiary);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: _compact ? AppSpacing.md : 0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: resolvedIconSize, color: t.textTertiary),
              SizedBox(height: _compact ? AppSpacing.sm : AppSpacing.lg),
              Text(
                message,
                textAlign: TextAlign.center,
                style: messageStyle,
              ),
              if (hasDescription) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: descriptionStyle,
                ),
              ],
              if (action != null) ...[
                SizedBox(height: _compact ? AppSpacing.md : AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
