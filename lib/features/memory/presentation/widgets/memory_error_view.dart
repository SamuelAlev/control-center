import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Friendly failure state for the memory surfaces. Replaces the raw
/// `e.toString()` dump with a titled message, the underlying detail kept
/// secondary, and a retry action that re-subscribes the provider.
class MemoryErrorView extends StatelessWidget {
  /// Creates a [MemoryErrorView].
  const MemoryErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  /// The underlying error, surfaced as quiet secondary detail.
  final Object error;

  /// Invoked when the user asks to retry (typically `ref.invalidate`).
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final colors = context.theme.colors;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.unplug,
              size: 40,
              color: tokens?.fgErrorSecondary ?? colors.destructive,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.memoryLoadError,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.sm.copyWith(
                color: tokens?.textTertiary ?? colors.mutedForeground,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FButton(
              onPress: onRetry,
              mainAxisSize: MainAxisSize.min,
              variant: FButtonVariant.outline,
              prefix: const Icon(LucideIcons.refreshCw, size: 14),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
