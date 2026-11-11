import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectOAuthLane, SignInLaneMode;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart'
    show ForgeConnectionStatus;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/provider_sign_in_dialog.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_copy.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/forge/presentation/widgets/forge_token_dialog.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Warns that an `oauth-done` link names a sign-in this app never started.
///
/// Somebody else's server minted it. Completing it would sign the reader's
/// account in to that server, so nothing was sent and the only action is to
/// close.
Future<void> showSignInPhishingWarning(BuildContext context) =>
    showCcDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        return CcDialog(
          title: l10n.signInPhishingTitle,
          content: CcAlert(
            title: l10n.signInPhishingBody,
            description: Text(l10n.signInPhishingDetail),
            icon: AppIcons.shieldAlert,
            variant: CcAlertVariant.danger,
          ),
          actions: [
            CcButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );

/// Offers to sign in when [error] is the server refusing an interactive
/// action with `needs_sign_in`, and says whether it did — the caller reports
/// every other failure its own way.
///
/// [fallback] is what the action was about, used when the refusal names no
/// lane. [workspaceId] is the active workspace the sign-in starts from. A
/// token-only forge (GitLab, Bitbucket) opens its token dialog instead of a
/// browser sign-in.
bool offerSignInForRefusal(
  BuildContext context,
  Object error, {
  required SignInNeed fallback,
  String? workspaceId,
}) {
  final needed = needsSignIn(error, fallback: fallback);
  if (needed == null || !context.mounted) {
    return false;
  }
  unawaited(
    showSignInRequiredDialog(context, need: needed, workspaceId: workspaceId),
  );
  return true;
}

/// Explains that an action needs the reader's own account and offers to
/// sign in ([LaneSignInNeed]) or to add a token ([TokenSignInNeed]).
Future<void> showSignInRequiredDialog(
  BuildContext context, {
  required SignInNeed need,
  String? workspaceId,
}) async {
  final provider = switch (need) {
    LaneSignInNeed(:final lane) => signInProviderName(lane),
    TokenSignInNeed(:final forge) => forge.displayName,
  };
  final start = await showCcDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext);
      return CcDialog(
        title: l10n.signInRequiredTitle(provider),
        content: Text(
          need is TokenSignInNeed
              ? l10n.forgeTokenRequiredBody(provider)
              : l10n.signInRequiredBody(provider),
        ),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(switch (need) {
              LaneSignInNeed(:final lane) => signInActionLabel(l10n, lane),
              TokenSignInNeed() => l10n.addToken,
            }),
          ),
        ],
      );
    },
  );
  if (start != true || !context.mounted) {
    return;
  }
  switch (need) {
    case LaneSignInNeed(:final lane):
      await showProviderSignInDialog(
        context,
        lane: lane,
        workspaceId: workspaceId,
      );
    case TokenSignInNeed(:final forge):
      await showForgeTokenDialog(context, forge: forge);
  }
}

/// An inline notice where an interactive action would run as the reader:
/// shown when the reader has no usable grant of their own for [lane].
///
/// Renders nothing while the lists load, when the reader is signed in, or
/// when no sign-in is available for [lane] here (an unreachable server reads
/// as that too), so it never flashes for someone who is signed in and never
/// offers a sign-in that cannot work.
class SignInRequiredBanner extends ConsumerWidget {
  /// Creates a [SignInRequiredBanner].
  const SignInRequiredBanner({
    super.key,
    required this.lane,
    required this.workspaceId,
    this.bottomGap = 0,
  });

  /// The provider the surface acts on.
  final ConnectOAuthLane lane;

  /// The active workspace (null only before any workspace exists).
  final String? workspaceId;

  /// Space below the notice when it shows, so a hidden notice leaves none.
  final double bottomGap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(oauthLanesProvider(workspaceId)).value?[lane];
    final connections = ref.watch(oauthConnectionsProvider(workspaceId));
    final connection = connections.value?[lane];
    final status = connection?.status ?? ForgeConnectionStatus.notConnected;
    if (info == null ||
        info.mode == SignInLaneMode.unavailable ||
        !connections.hasValue ||
        status == ForgeConnectionStatus.connected ||
        // Retrying on its own: nothing for the reader to do.
        status == ForgeConnectionStatus.unreachable) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final provider = signInProviderName(lane);
    // A paused grant comes back with the workspace's sign-in service; a
    // fresh sign-in would replace it, so the notice explains and offers
    // nothing to click.
    final paused = status == ForgeConnectionStatus.paused;
    final alert = CcAlert(
      title:
          unusableConnectionLine(
            l10n,
            status,
            provider,
            account: connection?.account ?? '',
          ) ??
          l10n.signInRequiredBanner(provider),
      icon: paused ? AppIcons.pause : AppIcons.keyRound,
      variant: paused ? CcAlertVariant.info : CcAlertVariant.warning,
      trailing: paused
          ? null
          : CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              onPressed: () => unawaited(
                showProviderSignInDialog(
                  context,
                  lane: lane,
                  workspaceId: workspaceId,
                ),
              ),
              child: Text(
                status == ForgeConnectionStatus.needsSignIn
                    ? l10n.signInAgain
                    : signInActionLabel(l10n, lane),
              ),
            ),
    );
    return bottomGap == 0
        ? alert
        : Padding(
            padding: EdgeInsetsDirectional.only(bottom: bottomGap),
            child: alert,
          );
  }
}
