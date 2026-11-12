import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/connect/providers/workspace_connect_providers.dart';
import 'package:control_center/features/forge/presentation/widgets/github_installations_group.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/forge/providers/workspace_github_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/provider_app_fields.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Workspace → Integrations → Code hosting: the GitHub App this
/// workspace runs on.
///
/// Admin-only. Where the App is installed is always shown, since that is what
/// lets it see the workspace's repositories. Only while the workspace uses
/// its own apps ([WorkspaceConnectMode.own]) does the card also hold that
/// App's credentials: there is no per-provider switch any more, the
/// workspace's Connect choice decides. Secrets stay on the server. Shown
/// while [watchWorkspaceGitHubAppApplies] holds.
class WorkspaceGitHubAppCard extends ConsumerWidget {
  /// Creates a [WorkspaceGitHubAppCard].
  const WorkspaceGitHubAppCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(workspaceGitHubStatusProvider).value;
    final workspace = ref.watch(activeWorkspaceProvider);
    if (status == null || workspace == null) {
      return const SizedBox.shrink();
    }
    final own =
        ref.watch(workspaceConnectModeProvider(workspace.id)) ==
        WorkspaceConnectMode.own;
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.workspaceGitHubAppTitle,
      subtitle: Text(
        own
            ? l10n.workspaceGitHubAppOwnDescription
            : l10n.workspaceGitHubAppSharedDescription,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (own) ...[
            _OwnGitHubAppFields(workspace: workspace, status: status),
            const SizedBox(height: AppSpacing.lg),
          ],
          GitHubInstallationsGroup(workspaceId: workspace.id),
          if (own && status.app.error.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              status.app.error,
              style: CcTypography.bodySm.copyWith(
                color: (context.designSystem ?? DesignSystemTokens.light())
                    .textErrorPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Whether [WorkspaceGitHubAppCard] has anything to show: inside a workspace,
/// once the workspace's GitHub status has arrived. Members and a demo
/// server never get one.
bool watchWorkspaceGitHubAppApplies(WidgetRef ref) =>
    ref.watch(activeWorkspaceProvider) != null &&
    ref.watch(workspaceGitHubStatusProvider).value != null;

/// The workspace's own App: the identity it acts as, and the OAuth client
/// that signs members in.
class _OwnGitHubAppFields extends ConsumerStatefulWidget {
  const _OwnGitHubAppFields({required this.workspace, required this.status});

  final Workspace workspace;
  final WorkspaceGitHubStatusView status;

  @override
  ConsumerState<_OwnGitHubAppFields> createState() =>
      _OwnGitHubAppFieldsState();
}

class _OwnGitHubAppFieldsState extends ConsumerState<_OwnGitHubAppFields> {
  bool _testing = false;

  Future<void> _setAppId(String appId) async {
    // The App id lives on the workspace row; the generic update carries it
    // but never the Connect choice, which only `workspaceConnect.set` changes.
    await ref
        .read(workspaceRepositoryProvider)
        .upsert(
          widget.workspace.copyWith(
            githubAppId: appId,
            updatedAt: DateTime.now(),
          ),
        );
    // A new App id changes which GitHub identity the workspace acts as.
    ref.invalidate(workspaceGitHubStatusProvider);
    invalidateForgeState(ref.invalidate);
  }

  Future<void> _test() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _testing = true);
    try {
      final result = await testWorkspaceGitHubApp(ref);
      if (!mounted) {
        return;
      }
      CcToastScope.of(context).show(
        result.app.error.isNotEmpty
            ? result.app.error
            : l10n.providerAppInstalledOn(result.app.installations.join(', ')),
        variant: result.app.error.isEmpty
            ? CcToastVariant.success
            : CcToastVariant.danger,
      );
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(
          context,
        ).show(failureMessage(l10n, e), variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = widget.status.app;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsGroup(
          title: l10n.workspaceGitHubAppActingTitle,
          description: l10n.workspaceGitHubAppActingDescription,
          gap: AppSpacing.md,
          children: [
            ProviderAppSecretField(
              title: l10n.providerAppId,
              value: widget.workspace.githubAppId,
              onSet: _setAppId,
            ),
            ProviderAppSecretField(
              title: l10n.providerPrivateKey,
              configured: app.hasPrivateKey,
              secret: true,
              multiline: true,
              onSet: (v) => saveWorkspaceGitHubApp(ref, {'private_key': v}),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CcButton(
                loading: _testing,
                onPressed: _testing ? null : _test,
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                child: Text(l10n.testLabel),
              ),
            ),
            SettingsField(
              label: l10n.providerAppBotLogin,
              layout: SettingsFieldLayout.stacked,
              child: SettingsCopyField(
                value: app.botLogin,
                emptyLabel: l10n.providerAppBotLoginEmpty,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsGroup(
          title: l10n.providerAppsGroupSignIn,
          description: l10n.providerAppsGroupSignInDescription,
          gap: AppSpacing.md,
          children: [
            ProviderAppSecretField(
              title: l10n.providerClientId,
              value: app.clientId,
              onSet: (v) => saveWorkspaceGitHubApp(ref, {'client_id': v}),
            ),
            ProviderAppSecretField(
              title: l10n.providerClientSecret,
              configured: app.hasClientSecret,
              secret: true,
              onSet: (v) => saveWorkspaceGitHubApp(ref, {'client_secret': v}),
            ),
          ],
        ),
      ],
    );
  }
}
