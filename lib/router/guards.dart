import 'package:control_center/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tri-state result of the onboarding-complete check.
///
/// `loading` means at least one input the check depends on (credentials,
/// `gh` CLI status, workspaces stream) has not resolved yet. Treating that
/// as `incomplete` would briefly flash the onboarding flow on startup, so
/// the router stays on the splash route until it settles.
enum OnboardingGate {
  /// At least one dependency has not resolved yet.
  loading,

  /// Onboarding is fully completed.
  complete,

  /// Onboarding has not been completed.
  incomplete,
}

/// Guards routes based on whether first-run onboarding has been completed.
///
/// Onboarding is complete when the user is authenticated to GitHub (PAT or
/// `gh` CLI) AND has registered at least one workspace.
String? onboardingGuard(
  BuildContext context,
  GoRouterState state,
  ValueNotifier<OnboardingGate> gateNotifier,
) {
  final gate = gateNotifier.value;
  final loc = state.matchedLocation;
  final isSplash = loc == splashRoute;
  final isOnboarding = loc.startsWith(onboardingRoute);

  if (gate == OnboardingGate.loading) {
    return isSplash ? null : splashRoute;
  }

  if (isSplash) {
    return gate == OnboardingGate.complete ? dashboardRoute : onboardingRoute;
  }

  if (gate == OnboardingGate.incomplete && !isOnboarding) {
    return onboardingRoute;
  }
  // Don't auto-redirect away from /onboarding when the gate flips to complete:
  // the workspace step finishes the gate's criteria but step 3 (voice model)
  // still needs to be shown. The screen navigates to the dashboard itself
  // once the user finishes or skips the final step.
  return null;
}
