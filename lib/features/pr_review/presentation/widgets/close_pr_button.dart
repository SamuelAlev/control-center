import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
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

    return FButton(
      onPress: () => _confirmAndClose(context, ref),
      mainAxisSize: MainAxisSize.min,
      size: FButtonSizeVariant.sm,
      variant: FButtonVariant.destructive,
      prefix: const Icon(LucideIcons.x, size: 16),
      child: Text(l10n.close),
    );
  }

  Future<void> _confirmAndClose(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.closePullRequest),
        body: Text(l10n.closePullRequestConfirm),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  onPress: () => Navigator.of(ctx).pop(false),
                  variant: FButtonVariant.outline,
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FButton(
                  onPress: () => Navigator.of(ctx).pop(true),
                  variant: FButtonVariant.destructive,
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
      scaffold.showSnackBar(SnackBar(content: Text(l10n.pullRequestClosed)));
    } on Exception catch (e) {
      if (!context.mounted) {
        return;
      }
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.failedToClosePr('$e'))),
      );
    }
  }
}
