import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Workspaces whose read-only notice was dismissed this session.
///
/// Session-scoped and per workspace, like the missing-sign-in warning: the
/// notice comes back after a restart while the workspace is still read-only.
class DismissedReadOnlyNoticeNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Hides the notice for [workspaceId] until the app restarts.
  void dismiss(String workspaceId) => state = {...state, workspaceId};
}

/// Tracks dismissed read-only notices.
final dismissedReadOnlyNoticeProvider =
    NotifierProvider<DismissedReadOnlyNoticeNotifier, Set<String>>(
      DismissedReadOnlyNoticeNotifier.new,
    );

/// The workspace shell's notice that the active workspace takes no writes:
/// its database failed an integrity check and serves reads until the server
/// owner restores it.
///
/// One calm line under the title bar, for every member, before anyone types
/// into something that will be refused. Nothing is disabled client-side:
/// writes still go to the server and come back as `storage.read_only`, worded
/// where they fail. The server owner gets the way to Backups; anyone else is
/// told who can fix it. Hidden on the Backups page, which already says so.
class WorkspaceReadOnlyBanner extends ConsumerWidget {
  /// Creates a [WorkspaceReadOnlyBanner].
  const WorkspaceReadOnlyBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(activeWorkspaceProvider);
    if (workspace == null ||
        !workspace.isReadOnly ||
        ref.watch(dismissedReadOnlyNoticeProvider).contains(workspace.id)) {
      return const SizedBox.shrink();
    }
    final backupsRoute = settingsBackupRoute(workspace.id);
    if (GoRouterState.of(context).matchedLocation == backupsRoute) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final owner = ref.watch(isServerOwnerProvider);

    // Shell chrome like the title bar above it: same fill and a closing
    // hairline, so the panes below start on a clean edge.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(bottom: BorderSide(color: t.borderPrimary)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: CcAlert(
          variant: CcAlertVariant.warning,
          icon: AppIcons.lock,
          title: l10n.workspaceReadOnlyBannerTitle,
          description: Text(
            owner
                ? l10n.workspaceReadOnlyBannerOwnerBody
                : l10n.workspaceReadOnlyBannerBody,
          ),
          trailing: owner
              ? CcButton(
                  size: CcButtonSize.sm,
                  onPressed: () => context.go(backupsRoute),
                  child: Text(l10n.workspaceReadOnlyBannerAction),
                )
              : null,
          onClose: () => ref
              .read(dismissedReadOnlyNoticeProvider.notifier)
              .dismiss(workspace.id),
        ),
      ),
    );
  }
}
