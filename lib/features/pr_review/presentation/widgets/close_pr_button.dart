import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Button that closes a pull request with a confirmation dialog.
class ClosePrButton extends ConsumerWidget {
  /// ClosePrButton.
  const ClosePrButton({super.key, required this.pr});

  /// Pull request to close.
  final PullRequest pr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!pr.isOpen) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);

    return CcButton(
      onPressed: () => _confirmAndClose(context, ref),
      size: CcButtonSize.sm,
      variant: CcButtonVariant.destructive,
      icon: LucideIcons.x,
      child: Text(l10n.close),
    );
  }

  Future<void> _confirmAndClose(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);

    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.closePullRequest,
        content: Text(l10n.closePullRequestConfirm),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CcButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  variant: CcButtonVariant.secondary,
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                CcButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  variant: CcButtonVariant.destructive,
                  child: Text(l10n.confirm),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final repo = ref.read(prReviewRepositoryProvider);
    try {
      await repo.closePullRequest(prNumber: pr.number);
      toaster.show(l10n.pullRequestClosed, variant: CcToastVariant.success);
    } on Exception catch (e) {
      if (!context.mounted) {
        return;
      }
      toaster.show(l10n.failedToClosePr('$e'), variant: CcToastVariant.danger);
    }
  }
}
