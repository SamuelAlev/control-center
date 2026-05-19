import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/compose_pr_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The bar shown when the chosen compare branch exists only in the launching
/// conversation's worktree: GitHub has never seen it, so a pull request cannot
/// name it as head until it is pushed.
///
/// This is the step the chat "Create pull request" flow was missing entirely. A
/// conversation worktree is branched locally and never given an upstream, so the
/// compose screen used to offer nothing to compare and both create buttons stayed
/// disabled with no explanation of why.
///
/// The push is explicit, never implicit in "Create pull request": publishing
/// makes local work visible on a shared remote, which is not something to do as a
/// side effect of a different button. It is also push-only — uncommitted changes
/// are reported, never committed on the user's behalf.
class ComposeUnpushedHeadNotice extends ConsumerWidget {
  /// Creates a [ComposeUnpushedHeadNotice] for [branch] in [channelId].
  const ComposeUnpushedHeadNotice({
    super.key,
    required this.branch,
    required this.channelId,
  });

  /// The local-only branch staged as the compare head.
  final String branch;

  /// The conversation whose worktree holds [branch].
  final String channelId;

  Future<void> _publish(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.maybeOf(context);
    final result = await ref
        .read(composePrProvider.notifier)
        .publishHead(channelId: channelId);
    if (!context.mounted) {
      return;
    }
    if (result == null || !result.pushed) {
      final error = ref.read(composePrProvider).error;
      toaster?.show(
        l10n.failedWithError(error ?? l10n.pushFailed),
        variant: CcToastVariant.danger,
      );
      return;
    }
    // The branch now exists on the remote, so the pickers and the comparison
    // must re-resolve — otherwise the notice would linger over a published
    // branch and the diff would stay empty.
    ref.invalidate(repoBranchesProvider);
    toaster?.show(
      result.uncommitted > 0
          ? l10n.branchPublishedWithUncommitted(result.uncommitted)
          : l10n.branchPublished(result.branch),
      variant: result.uncommitted > 0
          ? CcToastVariant.warning
          : CcToastVariant.success,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final publishing = ref.watch(composePrProvider.select((s) => s.publishing));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.borderSecondary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon + text, never colour alone (DESIGN.md).
          Icon(AppIcons.gitBranch, size: 15, color: t.textWarningPrimary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.branchNotOnRemote(branch),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.branchNotOnRemoteHint,
                  style: TextStyle(fontSize: 11.5, color: t.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          CcButton(
            onPressed: publishing ? null : () => _publish(context, ref),
            loading: publishing,
            size: CcButtonSize.sm,
            variant: CcButtonVariant.secondary,
            icon: AppIcons.upload,
            child: Text(l10n.publishBranch),
          ),
        ],
      ),
    );
  }
}
