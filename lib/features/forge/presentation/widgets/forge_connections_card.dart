import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart' show SignInLaneInfo, SignInLaneMode;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/auth/presentation/widgets/provider_sign_in_dialog.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_copy.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every code-hosting forge, connected or not, with the one action each needs.
///
/// ONE card, rendered by both onboarding and Settings → Integrations, so the
/// two surfaces cannot drift apart.
///
/// All supported forges are always shown, including the ones with no
/// credential: an operator cannot connect a forge they cannot see. GitHub is
/// sign-in only (the person's own App user token); GitLab and Bitbucket take a
/// pasted token. Connecting one is enough — the app does not require GitHub.
class ForgeConnectionsCard extends ConsumerWidget {
  /// Creates a [ForgeConnectionsCard].
  const ForgeConnectionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // A demo server does not wire the credential port at all, so `forge.*` is
    // absent from its op registry. Rendering the rows anyway would offer
    // sign-in buttons for a credential the demo cannot hold.
    if (ref.watch(isDemoServerProvider)) {
      return SectionCard(
        label: l10n.forgeConnections,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: DemoUnavailable(
            capability: DemoCapability.forge,
            compact: true,
          ),
        ),
      );
    }

    final async = ref.watch(forgeConnectionsProvider);
    final byForge = {
      for (final c in async.value ?? const <ForgeConnection>[]) c.forge: c,
    };

    return SectionCard(
      label: l10n.forgeConnections,
      subtitle: ref.watch(activeWorkspaceIdProvider) == null
          ? null
          : Text(l10n.forgeConnectionsThisWorkspace),
      child: Column(
        children: [
          for (var i = 0; i < ForgeHost.supported.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            ForgeConnectionRow(
              forge: ForgeHost.supported[i],
              connection: byForge[ForgeHost.supported[i]],
              loading: async.isLoading && byForge.isEmpty,
            ),
          ],
        ],
      ),
    );
  }
}

/// One forge's row: who you are on it, and how to change that.
class ForgeConnectionRow extends ConsumerWidget {
  /// Creates a [ForgeConnectionRow].
  const ForgeConnectionRow({
    required this.forge,
    required this.connection,
    required this.loading,
    super.key,
  });

  /// The forge this row is about.
  final ForgeHost forge;

  /// Its connection state, or null before the first answer.
  final ForgeConnection? connection;

  /// Whether the connection list is still loading.
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lane = signInLaneForForge(forge);
    final scope = ref.watch(githubSignInScopeProvider);
    final laneInfo = lane == null
        ? null
        : ref.watch(oauthLanesProvider(scope)).value?[lane];
    final connected = connection?.authenticated ?? false;

    final actions = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (connected)
          CcButton(
            onPressed: () => unawaited(_disconnect(context, ref, lane, scope)),
            variant: CcButtonVariant.ghost,
            child: Text(l10n.disconnect),
          ),
        if (lane != null)
          CcButton(
            onPressed:
                laneInfo == null || laneInfo.mode == SignInLaneMode.unavailable
                ? null
                : () => unawaited(
                    showProviderSignInDialog(
                      context,
                      lane: lane,
                      workspaceId: scope,
                    ),
                  ),
            variant: CcButtonVariant.secondary,
            child: Text(
              connected ? l10n.signInAgain : signInActionLabel(l10n, lane),
            ),
          )
        else
          CcButton(
            onPressed: () => showTokenDialog(
              context,
              title: l10n.forgeTokenTitle(forge.displayName),
              save: (token) => setForgeToken(ref, forge, token),
            ),
            variant: CcButtonVariant.secondary,
            child: Text(connected ? l10n.updateToken : l10n.addToken),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;
        final row = SettingsRow(
          icon: AppIcons.gitBranch,
          title: forge.displayName,
          subtitle: _subtitle(l10n, laneInfo, lane),
          subtitleWidget: loading ? const SkeletonBar(width: 140) : null,
          trailing: compact ? const SizedBox.shrink() : actions,
        );
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  row,
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: actions,
                  ),
                ],
              )
            : row;
      },
    );
  }

  Future<void> _disconnect(
    BuildContext context,
    WidgetRef ref,
    ConnectOAuthLane? lane,
    String? scope,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      if (lane != null) {
        await disconnectProviderLane(ref, lane, workspaceId: scope);
        ref.invalidate(forgeConnectionsProvider);
      } else {
        await clearForgeToken(ref, forge);
      }
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    }
  }

  /// The one line that has to carry both "is it working" and "why not", so an
  /// operator never has to guess whether a blank PR list is their setup or the
  /// forge being empty.
  String _subtitle(
    AppLocalizations l10n,
    SignInLaneInfo? laneInfo,
    ConnectOAuthLane? lane,
  ) {
    final c = connection;
    if (c == null || !c.authenticated) {
      if (c == null && loading) {
        return l10n.checkingConnection;
      }
      if (c != null && c.error.isNotEmpty) {
        return c.error;
      }
      // A sign-in nobody can start must say why, not just grey out.
      if (lane != null && laneInfo?.mode == SignInLaneMode.unavailable) {
        return laneInfo!.error.isNotEmpty
            ? laneInfo.error
            : l10n.signInUnavailable(signInProviderName(lane));
      }
      return l10n.notConnected;
    }
    final who = c.username.isEmpty
        ? l10n.signedIn
        : l10n.signedInAs(c.username);
    return switch (c.source) {
      // Naming the source matters: someone who sees the wrong account needs
      // to know an environment variable is what is answering.
      ForgeCredentialSource.oauth ||
      ForgeCredentialSource.connect ||
      ForgeCredentialSource.settings => who,
      ForgeCredentialSource.environment => '$who · ${l10n.fromEnvironment}',
      ForgeCredentialSource.none => l10n.notConnected,
    };
  }
}
