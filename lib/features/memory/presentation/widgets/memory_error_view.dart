import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
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
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.unplug,
              size: 40,
              color: tokens.fgErrorSecondary,
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
              style: CcTypography.body.copyWith(
                color: tokens.textTertiary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            CcButton(
              onPressed: onRetry,
              variant: CcButtonVariant.secondary,
              icon: LucideIcons.refreshCw,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
