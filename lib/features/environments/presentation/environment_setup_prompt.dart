import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/settings/environment_editor_seed.dart';
import 'package:control_center/features/environments/presentation/settings/environment_settings_selection.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Opens Settings → Environments on the definition for [repoId], or on a new
/// one bound to it when the workspace has none. Without a repo it opens the
/// list.
void openEnvironmentSetup(
  BuildContext context,
  WidgetRef ref, {
  required String workspaceId,
  String? repoId,
}) {
  if (repoId != null) {
    ref.read(environmentRepoFocusProvider.notifier).focus(repoId);
  }
  GoRouter.of(context).go(settingsEnvironmentsRoute(workspaceId));
}

/// Opens Settings → Environments straight on the editor for [seed], at the URL
/// of its definition.
void openEnvironmentEditor(
  BuildContext context,
  WidgetRef ref,
  EnvironmentEditorSeed seed,
) {
  ref.read(environmentEditorRequestProvider.notifier).request(seed);
  GoRouter.of(context).go(
    settingsEnvironmentRoute(
      seed.workspaceId,
      seed.record?.id ?? settingsNewEnvironmentId,
    ),
  );
}

/// What a space or pull request with no environment, and nothing it could
/// start, shows instead: what an environment would give it and the way to set
/// one up.
///
/// Setting one up is an admin's job, so a member reads who to ask instead of a
/// button that would refuse them.
class EnvironmentSetupPrompt extends ConsumerWidget {
  /// Creates an [EnvironmentSetupPrompt].
  const EnvironmentSetupPrompt({
    super.key,
    required this.workspaceId,
    required this.message,
    this.repoId,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The repo a new definition binds, when the surface has one.
  final String? repoId;

  /// What has no environment, said for this surface.
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isAdmin =
        ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: CcEmptyState(
        icon: AppIcons.boxes,
        size: CcEmptyStateSize.sm,
        message: message,
        description: isAdmin
            ? l10n.environmentSetupBody
            : '${l10n.environmentSetupBody} ${l10n.environmentsAdminOnly}',
        action: isAdmin
            ? CcButton(
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                onPressed: () => openEnvironmentSetup(
                  context,
                  ref,
                  workspaceId: workspaceId,
                  repoId: repoId,
                ),
                child: Text(l10n.environmentSetUp),
              )
            : null,
      ),
    );
  }
}
