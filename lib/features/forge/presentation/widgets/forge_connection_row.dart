import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectOAuthLane, SignInLaneMode;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/provider_sign_in_dialog.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_copy.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:control_center/features/forge/presentation/widgets/forge_token_dialog.dart';
import 'package:control_center/features/forge/presentation/widgets/forge_token_expiry.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One forge's row: who you are on it and the one action its state calls
/// for. Where the credential applies is the card's line above, not the row's.
///
/// Every [ForgeConnectionStatus] reads differently. A grant that needs a new
/// sign-in says so and offers it; a paused one (the workspace's sign-in
/// service changed) explains and offers no sign-in, which would replace the
/// grant that comes back with the service; an unreachable one says it is
/// retrying. GitHub signs in through the browser; GitLab and Bitbucket take
/// a pasted token, the person's own in every workspace. A token that expires
/// says when, and warns once that has passed.
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
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final laneInfo = lane == null
        ? null
        : ref.watch(oauthLanesProvider(workspaceId)).value?[lane];
    final status = connection?.status ?? ForgeConnectionStatus.notConnected;
    final hasGrant = status != ForgeConnectionStatus.notConnected;
    final unavailable =
        lane != null &&
        (laneInfo == null || laneInfo.mode == SignInLaneMode.unavailable);
    final setupAction = hasGrant
        ? null
        : signInUnavailableAction(context, ref, laneInfo);
    final expiresAt = hasGrant && !loading ? connection?.expiresAt : null;
    final expired =
        expiresAt != null && !expiresAt.isAfter(DateTime.now().toUtc());
    final urgent = status == ForgeConnectionStatus.needsSignIn || expired;

    final Widget? primary = switch (status) {
      // Not the person's fault and not theirs to fix: a fresh sign-in would
      // overwrite the parked grant. Retrying needs nothing from them either.
      ForgeConnectionStatus.paused || ForgeConnectionStatus.unreachable => null,
      _ when lane != null => CcButton(
        onPressed: unavailable
            ? null
            : () => unawaited(
                showProviderSignInDialog(
                  context,
                  lane: lane,
                  workspaceId: workspaceId,
                ),
              ),
        variant: urgent ? CcButtonVariant.primary : CcButtonVariant.secondary,
        child: Text(
          hasGrant ? l10n.signInAgain : signInActionLabel(l10n, lane),
        ),
      ),
      _ => CcButton(
        onPressed: () =>
            unawaited(showForgeTokenDialog(context, forge: forge)),
        variant: urgent ? CcButtonVariant.primary : CcButtonVariant.secondary,
        child: Text(hasGrant ? l10n.updateToken : l10n.addToken),
      ),
    };

    final actions = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (hasGrant && connection != null)
          CcButton(
            onPressed: () =>
                unawaited(_disconnect(context, ref, lane, connection!)),
            variant: CcButtonVariant.ghost,
            child: Text(l10n.disconnect),
          ),
        ?setupAction,
        ?primary,
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;
        final subtitle = _subtitle(
          l10n,
          lane,
          unavailable ? signInUnavailableMessage(l10n, lane, laneInfo) : null,
        );
        final row = SettingsRow(
          icon: AppIcons.gitBranch,
          title: forge.displayName,
          subtitle: subtitle,
          subtitleWidget: loading
              ? const SkeletonBar(width: 140)
              : expiresAt == null
              ? null
              : ForgeTokenExpiry(
                  summary: subtitle,
                  expiresAt: expiresAt,
                  expired: expired,
                ),
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
    ForgeConnection connection,
  ) async {
    final l10n = AppLocalizations.of(context);
    final toasts = CcToastScope.maybeOf(context);
    final inWorkspace = ref.read(activeWorkspaceIdProvider) != null;
    final thisWorkspace =
        inWorkspace && connection.scope == ForgeCredentialScope.workspace;
    final confirmed = await showCcConfirmDialog(
      context: context,
      title: l10n.disconnectProviderTitle(forge.displayName),
      message: !inWorkspace
          ? l10n.disconnectProviderBody(forge.displayName)
          : thisWorkspace
          ? l10n.disconnectScopeWorkspaceBody(forge.displayName)
          : l10n.disconnectScopeGlobalBody(forge.displayName),
      confirmLabel: l10n.disconnect,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!confirmed) {
      return;
    }
    try {
      if (lane != null) {
        await ref
            .read(providerSignInRepositoryProvider)
            .disconnect(lane, workspaceId: ref.read(activeWorkspaceIdProvider));
        invalidateForgeState(ref.invalidate);
      } else {
        await clearForgeToken(ref, forge);
      }
      if (inWorkspace) {
        toasts?.show(
          thisWorkspace
              ? l10n.disconnectedFromWorkspace(forge.displayName)
              : l10n.disconnectedFromAllWorkspaces(forge.displayName),
          variant: CcToastVariant.success,
        );
      }
    } on Object catch (e) {
      toasts?.show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
    }
  }

  /// The one line that has to carry both "is it working" and "why not", so an
  /// operator never has to guess whether a blank PR list is their setup or the
  /// forge being empty.
  String _subtitle(
    AppLocalizations l10n,
    ConnectOAuthLane? lane,
    String? unavailableLine,
  ) {
    final c = connection;
    if (c == null && loading) {
      return l10n.checkingConnection;
    }
    final provider = lane == null
        ? forge.displayName
        : signInProviderName(lane);
    final status = c?.status ?? ForgeConnectionStatus.notConnected;
    final problem = unusableConnectionLine(
      l10n,
      status,
      provider,
      account: c?.username ?? '',
    );
    if (problem != null) {
      return problem;
    }
    if (c == null || !c.isUsable) {
      if (c != null && c.error.isNotEmpty) {
        return c.error;
      }
      // A sign-in nobody can start must say why, not just grey out.
      if (unavailableLine != null) {
        return unavailableLine;
      }
      return l10n.notConnected;
    }
    return c.username.isEmpty ? l10n.signedIn : l10n.signedInAs(c.username);
  }
}
