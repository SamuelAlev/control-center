import 'package:control_center/features/auth/presentation/widgets/sign_in_prompts.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hands a `control-center://oauth-done` code to the sign-in this app started,
/// or warns.
///
/// No provider OAuth redirect ever lands in the app: the server (or Connect)
/// runs every authorization-code exchange, and this link only confirms an
/// attempt this client started. A login id this client never started came from
/// somebody else's server: completing it would sign the reader's account in
/// THERE. The controller sends nothing for it, and the reader is told why.
Future<void> completeSignInFromDeepLink(
  ProviderContainer container, {
  required String loginId,
  required String code,
}) async {
  final known = await container
      .read(providerSignInControllerProvider.notifier)
      .completeFromDeepLink(loginId, code);
  if (known) {
    return;
  }
  final context = rootNavigatorKey.currentContext;
  if (context != null && context.mounted) {
    await showSignInPhishingWarning(context);
  }
}
