import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/credential_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/credentials/harness_connection_card.dart';
import 'package:cc_remote/widgets/credentials/personal_connection_card.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Credentials are managed on the host. The phone shows status and only the
/// self-service or server-owner writes the authenticated host supports.
class CredentialsScreen extends ConsumerWidget {
  const CredentialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
    final routeWorkspace = GoRouterState.of(
      context,
    ).uri.queryParameters['workspace_id'];
    final identity = ref.watch(remoteIdentityProvider);
    final role = ref.watch(workspaceRoleProvider);
    final owner = identity.value?.isServerOwner == true && !identity.isLoading;
    final member = workspaceId != null && role.value != null && !role.isLoading;
    final harness = ref.watch(remoteHarnessProvidersProvider);
    final forges = ref.watch(remoteForgeConnectionsProvider);
    final ticketing = ref.watch(remoteTicketConnectionsProvider);
    final signIns = ref.watch(remoteSignInProvidersProvider);
    final claude = owner ? ref.watch(remoteClaudeAccountsProvider) : null;
    final forgeById = {
      for (final c in forges.value ?? const <ForgeConnection>[])
        c.forge.wire: c,
    };
    final ticketById =
        ticketing.value ??
        const <String, ({bool connected, String username})>{};
    final advertised =
        signIns.value ?? const <String, ({String flow, String redirectUri})>{};

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          children: [
            DetailHeader(title: l.credentialsTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (routeWorkspace != null && routeWorkspace != workspaceId)
                    CcEmptyState(
                      icon: AppIcons.triangleAlert,
                      message: l.requestUnavailable,
                      description: l.credentialsSwitchWorkspace,
                    )
                  else ...[
                    Text(
                      l.credentialsIntro,
                      style: TextStyle(color: t.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    _heading(t, l.credentialsModelProviders),
                    if (identity.isLoading || harness.isLoading)
                      const Center(child: CcSpinner(size: 24)),
                    if (identity.hasError || harness.hasError)
                      _loadError(context, t, l, () {
                        ref.invalidate(remoteIdentityProvider);
                        ref.invalidate(remoteHarnessProvidersProvider);
                      }),
                    if (!owner && !identity.isLoading && !identity.hasError)
                      CcCard(
                        child: Text(
                          l.credentialsOwnerOnly,
                          style: TextStyle(color: t.textSecondary),
                        ),
                      ),
                    for (final provider
                        in harness.value ?? const <HarnessProviderInfo>[])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: HarnessConnectionCard(
                          key: ValueKey((workspaceId, provider.id)),
                          info: provider,
                          workspaceId: workspaceId ?? '',
                          canManage: owner && workspaceId != null,
                        ),
                      ),
                    if (!owner && !identity.isLoading && !identity.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          l.credentialsContactOwner,
                          style: TextStyle(color: t.textSecondary),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _heading(t, l.credentialsClaudeCode),
                    CcCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l.credentialsClaudeHostOnly,
                            style: TextStyle(color: t.textSecondary),
                          ),
                          if (owner && claude?.isLoading == true)
                            const Center(child: CcSpinner(size: 24)),
                          if (owner && claude?.hasError == true)
                            _loadError(
                              context,
                              t,
                              l,
                              () =>
                                  ref.invalidate(remoteClaudeAccountsProvider),
                            ),
                          if (owner)
                            for (final view
                                in claude?.value ?? const <ClaudeAccountView>[])
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${view.account.label}: ${view.account.loggedIn ? l.credentialsConnected : l.credentialsNotConnected}',
                                  style: TextStyle(color: t.textPrimary),
                                ),
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _heading(t, l.credentialsYourForgeAccounts),
                    if (!member && !role.isLoading)
                      CcCard(
                        child: Text(
                          l.credentialsMembershipRequired,
                          style: TextStyle(color: t.textSecondary),
                        ),
                      ),
                    if (forges.isLoading || signIns.isLoading)
                      const Center(child: CcSpinner(size: 24)),
                    if (forges.hasError || signIns.hasError)
                      _loadError(context, t, l, () {
                        ref.invalidate(remoteForgeConnectionsProvider);
                        ref.invalidate(remoteSignInProvidersProvider);
                      }),
                    if (member && !forges.hasError && !signIns.hasError)
                      for (final forge in ForgeHost.supported)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PersonalConnectionCard(
                            key: ValueKey((workspaceId, forge.wire)),
                            providerId: forge.wire,
                            name: forge.displayName,
                            workspaceId: workspaceId,
                            isForge: true,
                            connected:
                                forgeById[forge.wire]?.authenticated ?? false,
                            username: forgeById[forge.wire]?.username ?? '',
                            statusError: forgeById[forge.wire]?.error,
                            hostManaged:
                                forgeById[forge.wire]?.source ==
                                    ForgeCredentialSource.app ||
                                forgeById[forge.wire]?.source ==
                                    ForgeCredentialSource.environment,
                            canManage: member,
                            signInFlow: advertised[forge.wire]?.flow,
                            redirectUri:
                                advertised[forge.wire]?.redirectUri ?? '',
                          ),
                        ),
                    const SizedBox(height: 20),
                    _heading(t, l.credentialsYourTicketingAccount),
                    Text(
                      l.credentialsLocalTicketsNoLogin,
                      style: TextStyle(color: t.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    if (ticketing.isLoading)
                      const Center(child: CcSpinner(size: 24)),
                    if (ticketing.hasError)
                      _loadError(
                        context,
                        t,
                        l,
                        () => ref.invalidate(remoteTicketConnectionsProvider),
                      ),
                    if (member && !ticketing.hasError)
                      PersonalConnectionCard(
                        key: ValueKey((workspaceId, 'linear')),
                        providerId: 'linear',
                        name: 'Linear',
                        workspaceId: workspaceId,
                        isForge: false,
                        connected: ticketById['linear']?.connected ?? false,
                        username: ticketById['linear']?.username ?? '',
                        canManage: member,
                        signInFlow: advertised['linear']?.flow,
                        redirectUri: advertised['linear']?.redirectUri ?? '',
                      ),
                    const SizedBox(height: 16),
                    Text(
                      l.credentialsReturnToInbox,
                      style: TextStyle(color: t.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _heading(DesignSystemTokens t, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: TextStyle(
        color: t.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static Widget _loadError(
    BuildContext context,
    DesignSystemTokens t,
    AppLocalizations l,
    VoidCallback retry,
  ) => CcCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.credentialsLoadFailed,
          style: TextStyle(color: t.textErrorPrimary),
        ),
        const SizedBox(height: 8),
        CcButton(
          size: CcButtonSize.lg,
          variant: CcButtonVariant.secondary,
          onPressed: retry,
          child: Text(l.retry),
        ),
      ],
    ),
  );
}
