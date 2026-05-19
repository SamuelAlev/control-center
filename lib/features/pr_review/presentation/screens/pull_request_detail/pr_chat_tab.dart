import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/conversation_pane.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The PR chat tab: a full space conversation scoped to the pull request.
///
/// The PR IS a space (created + provisioned at the PR head on first use via
/// `pr.ensureSpace`), so this reuses [ConversationPane] unchanged — composer,
/// streaming, agent dispatch, approvals, takeover, autonomy and parallel
/// conversations all work exactly as in the messaging IDE.
class PrChatTab extends ConsumerWidget {
  /// Creates a [PrChatTab].
  const PrChatTab({super.key, required this.pr});

  /// The pull request this chat is scoped to.
  final PullRequest pr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final spaceAsync = ref.watch(prSpaceProvider(pr));
    return spaceAsync.when(
      loading: () => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CcSpinner(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.preparingWorkspace,
              style: TextStyle(
                color: t.fgSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.triangleAlert, size: 32, color: t.textErrorPrimary),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.failedWithError('$e'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: t.fgSecondary,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              CcButton(
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                onPressed: () => ref.invalidate(prSpaceProvider(pr)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      // Commit & push now lives in its own Source Control tab, not under chat.
      data: (spaceId) => ConversationPane(spaceId: spaceId),
    );
  }
}
