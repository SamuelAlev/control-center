import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart' show ProviderConnection, SignInLaneMode;
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/provider_sign_in_dialog.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_copy.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where this workspace's tickets live, and who Control Center is when it
/// talks to them.
///
/// The vendor is workspace-scoped (admin-gated). Linear then has two
/// identities, each a browser sign-in and never a pasted token:
///
/// * the signed-in person's own account (`linear` lane), which every
///   interactive action they take runs as; and
/// * the workspace's Control Center app actor (`linear_app` lane), which
///   ticket sync, pipelines and agents use so automated issues appear as
///   Control Center. Connecting it is an admin decision.
///
/// No credential row for [TicketProvider.local] — local tickets live in this
/// server's own database and have nothing to authenticate to.
class TicketingConnectionCard extends ConsumerWidget {
  /// Creates a [TicketingConnectionCard].
  const TicketingConnectionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = ref.watch(activeTicketProviderProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    // No workspace yet (onboarding's connect step) is treated as editable:
    // there is no admin to consult, and the write is a no-op until a
    // workspace exists. Inside a workspace the server still refuses a
    // non-admin write even if this flag is wrong.
    final isAdmin =
        workspaceId == null ||
        (ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false);
    final connections = ref.watch(oauthConnectionsProvider(workspaceId));
    final lanes = ref.watch(oauthLanesProvider(workspaceId)).value ?? const {};

    return SectionCard(
      label: l10n.ticketing,
      child: Column(
        children: [
          SettingsRow(
            icon: AppIcons.ticket,
            title: l10n.ticketingProvider,
            subtitle: l10n.ticketingProviderHelp,
            trailing: SizedBox(
              width: 200,
              child: CcSelect<TicketProvider>(
                value: provider,
                enabled: isAdmin,
                options: [
                  for (final p in TicketProvider.values)
                    CcSelectOption(
                      value: p,
                      // The unimplemented vendors stay VISIBLE and say so.
                      label: _supported(p)
                          ? _label(p, l10n)
                          : l10n.providerComingSoon(_label(p, l10n)),
                    ),
                ],
                onChanged: (p) {
                  if (_supported(p)) {
                    unawaited(_select(context, ref, p));
                  }
                },
              ),
            ),
          ),
          if (provider == TicketProvider.linear) ...[
            const SizedBox(height: 8),
            LinearSignInRow(
              lane: ConnectOAuthLane.linear,
              workspaceId: workspaceId,
              connection: connections.value?[ConnectOAuthLane.linear],
              loading: connections.isLoading && !connections.hasValue,
              laneMode: lanes[ConnectOAuthLane.linear]?.mode,
              canManage: true,
            ),
            // The automation actor belongs to a workspace; before one exists
            // there is nothing for it to act in.
            if (workspaceId != null) ...[
              const SizedBox(height: 8),
              LinearSignInRow(
                lane: ConnectOAuthLane.linearApp,
                workspaceId: workspaceId,
                connection: connections.value?[ConnectOAuthLane.linearApp],
                loading: connections.isLoading && !connections.hasValue,
                laneMode: lanes[ConnectOAuthLane.linearApp]?.mode,
                canManage: isAdmin,
              ),
            ],
          ],
          if (workspaceId != null && !isAdmin) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.settingsWorkspaceAdminOnly,
                style: CcTypography.caption.copyWith(
                  color: context.designSystem?.textTertiary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Writes the workspace's choice, surfacing the server's refusal rather
  /// than letting the dropdown snap back with no explanation.
  static Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    TicketProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await setActiveTicketProvider(ref, provider);
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    }
  }

  static bool _supported(TicketProvider provider) =>
      provider == TicketProvider.local || provider == TicketProvider.linear;

  static String _label(TicketProvider provider, AppLocalizations l10n) =>
      switch (provider) {
        TicketProvider.local => l10n.ticketProviderLocal,
        TicketProvider.linear => 'Linear',
        TicketProvider.jira => 'Jira',
        TicketProvider.clickup => 'ClickUp',
      };
}

/// One Linear identity: the person's own account or the workspace's
/// automation actor, with its state and the sign-in that changes it.
class LinearSignInRow extends ConsumerWidget {
  /// Creates a [LinearSignInRow].
  const LinearSignInRow({
    super.key,
    required this.lane,
    required this.workspaceId,
    required this.connection,
    required this.loading,
    required this.laneMode,
    required this.canManage,
  });

  /// [ConnectOAuthLane.linear] or [ConnectOAuthLane.linearApp].
  final ConnectOAuthLane lane;

  /// The workspace the sign-in runs in.
  final String? workspaceId;

  /// The stored grant, or null when there is none.
  final ProviderConnection? connection;

  /// Whether the connection list is still loading.
  final bool loading;

  /// Who runs this lane's sign-in, or null before the server answers.
  final SignInLaneMode? laneMode;

  /// Whether the reader may change it (the automation actor is admin-only).
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = connection;
    final connected = c != null && c.connected && !c.needsSignIn;
    final automation = lane == ConnectOAuthLane.linearApp;
    final available = laneMode != null && laneMode != SignInLaneMode.unavailable;

    final String subtitle;
    if (loading) {
      subtitle = l10n.checkingConnection;
    } else if (c != null && c.needsSignIn) {
      subtitle = l10n.signInErrorNeedsSignIn('Linear');
    } else if (connected) {
      subtitle = c.account.isEmpty
          ? l10n.signedIn
          : (automation
                ? l10n.linearAutomationConnectedAs(c.account)
                : l10n.signedInAs(c.account));
    } else if (!available && laneMode != null) {
      subtitle = l10n.signInUnavailable('Linear');
    } else {
      subtitle = automation ? l10n.linearAutomationHint : l10n.notConnected;
    }

    return SettingsRow(
      icon: automation ? AppIcons.plug : AppIcons.keyRound,
      title: automation ? l10n.linearAutomationTitle : 'Linear',
      subtitle: subtitle,
      subtitleWidget: loading ? const SkeletonBar(width: 140) : null,
      trailing: !canManage
          ? const SizedBox.shrink()
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (connected) ...[
                  CcButton(
                    onPressed: () => unawaited(_disconnect(context, ref)),
                    variant: CcButtonVariant.ghost,
                    child: Text(l10n.disconnect),
                  ),
                  const SizedBox(width: 8),
                ],
                CcButton(
                  onPressed: available
                      ? () => unawaited(
                          showProviderSignInDialog(
                            context,
                            lane: lane,
                            workspaceId: workspaceId,
                          ),
                        )
                      : null,
                  variant: CcButtonVariant.secondary,
                  child: Text(
                    connected ? l10n.signInAgain : signInActionLabel(l10n, lane),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      await disconnectProviderLane(ref, lane, workspaceId: workspaceId);
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    }
  }
}
