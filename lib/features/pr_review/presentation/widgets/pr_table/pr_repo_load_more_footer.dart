import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/pr_table_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The sliver under a repo's PR card while more pages exist: a spinner while
/// the next page loads, a retry after a failed load, and nothing otherwise
/// (the scroll position, not a button, asks for the next page).
class PrRepoLoadMoreFooter extends StatelessWidget {
  /// Creates a [PrRepoLoadMoreFooter].
  const PrRepoLoadMoreFooter({
    super.key,
    required this.paging,
    required this.onRetry,
  });

  /// The shown repo's paging state.
  final PrRepoPaging paging;

  /// Loads the next page again after a failure.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (paging.loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CcSpinner(size: 16)),
        ),
      );
    }
    if (!paging.failed) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.failedToLoad,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(width: AppSpacing.md),
            CcButton(
              onPressed: onRetry,
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              icon: AppIcons.refreshCw,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
