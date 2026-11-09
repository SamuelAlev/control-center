import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart' show SignInLaneMode;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/provider_sign_in_dialog.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_copy.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
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
/// [lane] is the provider the action was about, used when the refusal does
/// not name one. [workspaceId] is the scope the sign-in should run in.
bool offerSignInForRefusal(
  BuildContext context,
  Object error, {
  required ConnectOAuthLane lane,
  String? workspaceId,
}) {
  final needed = needsSignInLane(error, fallback: lane);
  if (needed == null || !context.mounted) {
    return false;
  }
  unawaited(
    showSignInRequiredDialog(context, lane: needed, workspaceId: workspaceId),
  );
  return true;
}

/// Explains that an action needs the reader's own [lane] account and offers
/// to sign in.
Future<void> showSignInRequiredDialog(
  BuildContext context, {
  required ConnectOAuthLane lane,
  String? workspaceId,
}) async {
  final start = await showCcDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext);
      final provider = signInProviderName(lane);
      return CcDialog(
        title: l10n.signInRequiredTitle(provider),
        content: Text(l10n.signInRequiredBody(provider)),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(signInActionLabel(l10n, lane)),
          ),
        ],
      );
    },
  );
  if (start == true && context.mounted) {
    await showProviderSignInDialog(
      context,
      lane: lane,
      workspaceId: workspaceId,
    );
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

  /// The sign-in scope (null = server-wide).
  final String? workspaceId;

  /// Space below the notice when it shows, so a hidden notice leaves none.
  final double bottomGap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(oauthLanesProvider(workspaceId)).value?[lane];
    final connections = ref.watch(oauthConnectionsProvider(workspaceId));
    final connection = connections.value?[lane];
    if (info == null ||
        info.mode == SignInLaneMode.unavailable ||
        !connections.hasValue ||
        (connection != null &&
            connection.connected &&
            !connection.needsSignIn)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final alert = CcAlert(
      title: connection?.needsSignIn ?? false
          ? l10n.signInErrorNeedsSignIn(signInProviderName(lane))
          : l10n.signInRequiredBanner(signInProviderName(lane)),
      icon: AppIcons.keyRound,
      variant: CcAlertVariant.warning,
      trailing: CcButton(
        size: CcButtonSize.sm,
        variant: CcButtonVariant.secondary,
        onPressed: () => unawaited(
          showProviderSignInDialog(
            context,
            lane: lane,
            workspaceId: workspaceId,
          ),
        ),
        child: Text(signInActionLabel(l10n, lane)),
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
