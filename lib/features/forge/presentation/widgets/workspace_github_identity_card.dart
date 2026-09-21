import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/github_auth_mode.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/forge/providers/workspace_github_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/provider_app_fields.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Workspace → General: how this workspace authenticates to GitHub.
///
/// Admin-only. Inherit workspaces use the install App from Server → Provider
/// apps; a different App or a PAT lives here. Secrets stay on the server.
class WorkspaceGitHubIdentityCard extends ConsumerWidget {
  /// Creates a [WorkspaceGitHubIdentityCard].
  const WorkspaceGitHubIdentityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(workspaceGitHubStatusProvider).value;
    final workspace = ref.watch(activeWorkspaceProvider);
    if (status == null || workspace == null) return const SizedBox.shrink();
    return _WorkspaceGitHubIdentityBody(
      workspace: workspace,
      status: status,
    );
  }
}

class _WorkspaceGitHubIdentityBody extends ConsumerStatefulWidget {
  const _WorkspaceGitHubIdentityBody({
    required this.workspace,
    required this.status,
  });

  final Workspace workspace;
  final WorkspaceGitHubStatusView status;

  @override
  ConsumerState<_WorkspaceGitHubIdentityBody> createState() =>
      _WorkspaceGitHubIdentityBodyState();
}

class _WorkspaceGitHubIdentityBodyState
    extends ConsumerState<_WorkspaceGitHubIdentityBody> {
  bool _testing = false;

  Future<void> _setMode(GithubAuthMode mode) async {
    await ref.read(workspaceRepositoryProvider).upsert(
      widget.workspace.copyWith(
        githubAuthMode: mode,
        githubAppId: mode == GithubAuthMode.app
            ? widget.workspace.githubAppId
            : '',
        updatedAt: DateTime.now(),
      ),
    );
    ref.invalidate(workspaceGitHubStatusProvider);
    ref.invalidate(signInProvidersProvider);
  }

  Future<void> _setAppId(String appId) async {
    await ref.read(workspaceRepositoryProvider).upsert(
      widget.workspace.copyWith(
        githubAppId: appId,
        githubAuthMode: GithubAuthMode.app,
        updatedAt: DateTime.now(),
      ),
    );
    ref.invalidate(workspaceGitHubStatusProvider);
  }

  Future<void> _test() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _testing = true);
    try {
      final result = await testWorkspaceGitHubApp(ref);
      if (!mounted) return;
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
        CcToastScope.of(context).show(
          l10n.failedWithError('$e'),
          variant: CcToastVariant.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mode = widget.workspace.githubAuthMode;
    final status = widget.status;
    return SectionCard(
      label: l10n.workspaceGitHubIdentity,
      subtitle: Text(l10n.workspaceGitHubIdentityDescription),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeOption(
            mode: GithubAuthMode.inherit,
            selected: mode,
            title: l10n.workspaceGitHubModeInherit,
            hint: l10n.workspaceGitHubInheritHint,
            onSelected: _setMode,
          ),
          _ModeOption(
            mode: GithubAuthMode.app,
            selected: mode,
            title: l10n.workspaceGitHubModeApp,
            hint: l10n.workspaceGitHubAppHint,
            onSelected: _setMode,
          ),
          _ModeOption(
            mode: GithubAuthMode.pat,
            selected: mode,
            title: l10n.workspaceGitHubModePat,
            hint: l10n.workspaceGitHubPatDescription,
            onSelected: _setMode,
          ),
          if (mode == GithubAuthMode.app) ...[
            const SizedBox(height: AppSpacing.lg),
            SettingsGroup(
              title: l10n.providerAppsGroupServer,
              description: l10n.providerAppsGroupServerDescription,
              gap: AppSpacing.md,
              children: [
                ProviderAppSecretField(
                  title: l10n.providerAppId,
                  value: widget.workspace.githubAppId,
                  onSet: _setAppId,
                ),
                ProviderAppSecretField(
                  title: l10n.providerPrivateKey,
                  configured: status.app.hasPrivateKey,
                  secret: true,
                  multiline: true,
                  onSet: (v) =>
                      saveWorkspaceGitHubApp(ref, {'private_key': v}),
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
                    value: status.app.botLogin,
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
                  value: status.app.clientId,
                  onSet: (v) =>
                      saveWorkspaceGitHubApp(ref, {'client_id': v}),
                ),
                ProviderAppSecretField(
                  title: l10n.providerClientSecret,
                  configured: status.app.hasClientSecret,
                  secret: true,
                  onSet: (v) =>
                      saveWorkspaceGitHubApp(ref, {'client_secret': v}),
                ),
              ],
            ),
          ],
          if (mode == GithubAuthMode.pat) ...[
            const SizedBox(height: AppSpacing.lg),
            ProviderAppSecretField(
              title: l10n.workspaceGitHubPatLabel,
              configured: status.hasBackgroundPat,
              secret: true,
              onSet: (v) => setWorkspaceGitHubPat(ref, v),
            ),
            Text(
              status.hasBackgroundPat
                  ? l10n.workspaceGitHubHasPat
                  : l10n.workspaceGitHubNoPat,
              style: CcTypography.caption.copyWith(
                color: (context.designSystem ?? DesignSystemTokens.light())
                    .textSecondary,
              ),
            ),
          ],
          if (status.app.error.isNotEmpty) ...[
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

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.selected,
    required this.title,
    required this.hint,
    required this.onSelected,
  });

  final GithubAuthMode mode;
  final GithubAuthMode selected;
  final String title;
  final String hint;
  final ValueChanged<GithubAuthMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return GestureDetector(
      onTap: () => onSelected(mode),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CcRadio<GithubAuthMode>(
              value: mode,
              groupValue: selected,
              onChanged: onSelected,
              semanticLabel: title,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
