import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Tri-state result of the onboarding-complete check.
///
/// `loading` means at least one input the check depends on (forge connections,
/// workspaces stream) has not resolved yet. Treating that
/// as `incomplete` would briefly flash the onboarding flow on startup, so
/// the router stays on the splash route until it settles.
enum OnboardingGate {
  /// At least one dependency has not resolved yet.
  loading,

  /// Onboarding is fully completed.
  complete,

  /// Onboarding has not been completed.
  incomplete,

  /// Onboarding WAS completed and the forge credential has since gone: the
  /// operator has workspaces but no forge answers for them any more (a token
  /// expired, was revoked, or the app's authorization was removed).
  ///
  /// Distinct from [incomplete] because nothing is missing except the
  /// credential — there is no workspace to create, no sandbox to configure and
  /// no model to pick, so the first-run flow would ask for work already done.
  signedOut,
}

/// Guards routes based on whether first-run onboarding has been completed.
///
/// Onboarding is complete when at least one forge is connected AND the user has
/// registered at least one workspace. Losing the forge credential later is NOT
/// the same as never having onboarded — that case routes to [signedOutRoute],
/// which asks only for the sign-in.
///
/// [landingWorkspaceId] resolves the workspace to land in once onboarding is
/// complete (the persisted last-active workspace, or the first one). Every
/// in-app destination is workspace-scoped, so the splash redirect needs a
/// concrete id to build the inbox URL; when none is available (a state
/// that should not occur once the gate is complete) we fall back to the
/// workspace picker.
String? onboardingGuard(
  BuildContext context,
  GoRouterState state,
  ValueNotifier<OnboardingGate> gateNotifier,
  String? Function() landingWorkspaceId,
) {
  final gate = gateNotifier.value;
  final loc = state.matchedLocation;
  final isSplash = loc == splashRoute;
  final isOnboarding = loc.startsWith(onboardingRoute);
  final isSignedOut = loc == signedOutRoute;

  if (gate == OnboardingGate.loading) {
    return isSplash ? null : splashRoute;
  }

  String landing() {
    final id = landingWorkspaceId();
    return id == null ? workspaceListRoute : inboxRoute(id);
  }

  if (isSplash) {
    return switch (gate) {
      OnboardingGate.complete => landing(),
      OnboardingGate.signedOut => signedOutRoute,
      _ => onboardingRoute,
    };
  }

  // Signing back in is one action with no steps after it, so this screen —
  // unlike onboarding below — IS left automatically the moment the credential
  // lands. Leaving the operator on it would read as a sign-in that failed.
  if (isSignedOut && gate == OnboardingGate.complete) {
    return landing();
  }

  // Onboarding still wins while it is on screen: a credential that expires
  // mid-flow must not eject the user into the re-auth screen and strand the
  // steps after it, and step 1 already carries the same forge card.
  if (gate == OnboardingGate.signedOut && !isSignedOut && !isOnboarding) {
    return signedOutRoute;
  }

  if (gate == OnboardingGate.incomplete && !isOnboarding) {
    return onboardingRoute;
  }
  // Don't auto-redirect away from /onboarding when the gate flips to complete:
  // the workspace step finishes the gate's criteria but step 3 (voice model)
  // still needs to be shown. The screen navigates to the inbox itself
  // once the user finishes or skips the final step.
  return null;
}
