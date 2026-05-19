import 'dart:async';

import 'package:cc_domain/features/auth/domain/usecases/check_onboarding_complete.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/guards.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared-preferences key caching the last *resolved* onboarding gate.
///
/// `true` = onboarding was complete, `false` = incomplete, absent = never
/// resolved (first-ever launch). Non-sensitive, so `shared_preferences` is
/// appropriate.
const _onboardingCompleteKey = 'onboarding_complete';

/// Derives the current onboarding gate state from auth and workspace readiness.
///
/// On cold start the underlying checks (keychain credentials, `gh` CLI status,
/// the workspaces DB stream) are still loading. Reporting
/// [OnboardingGate.loading] in that window parks the router on the splash
/// spinner. To avoid that for returning users, we fall back to the *cached*
/// result of the previous run while the live checks resolve — so the router
/// can pick the inbox/onboarding route synchronously on the first frame.
/// Once the live checks settle, the real result is recomputed (correcting the
/// route if it disagrees) and re-cached. First-ever launch has no cache and so
/// still shows the splash until the checks settle.
final onboardingGateProvider = Provider<OnboardingGate>((ref) {
  final prefs = ref.watch(appPreferencesProvider);

  OnboardingGate cachedGate() =>
      switch (prefs.getBool(_onboardingCompleteKey)) {
        true => OnboardingGate.complete,
        false => OnboardingGate.incomplete,
        null => OnboardingGate.loading,
      };

  // The gate is "at least one forge connected", not "GitHub connected": an
  // operator who works only on GitLab has a complete setup. It resolves as
  // soon as the FIRST forge reports in, so a slow or unreachable second forge
  // can never stall a working one behind the splash.
  final connectionsAsync = ref.watch(forgeConnectionsProvider);
  final hasForge = ref.watch(hasAnyForgeConnectedProvider);
  if (!hasForge && !connectionsAsync.hasValue && !connectionsAsync.hasError) {
    return cachedGate();
  }

  final workspacesAsync = ref.watch(workspacesProvider);
  if (!workspacesAsync.hasValue && !workspacesAsync.hasError) {
    return cachedGate();
  }

  final workspaces = workspacesAsync.value ?? const [];
  final result = const CheckOnboardingCompleteUseCase().execute(
    hasForgeConnection: hasForge,
    workspaces: workspaces,
  );
  final gate = result.isComplete
      ? OnboardingGate.complete
      : OnboardingGate.incomplete;

  // Cache the settled result so the next cold start can route without the
  // splash. Fire-and-forget: the write must not block the gate computation.
  unawaited(
    prefs.setBool(
      _onboardingCompleteKey,
      value: gate == OnboardingGate.complete,
    ),
  );

  return gate;
});
