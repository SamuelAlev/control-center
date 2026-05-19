import 'dart:async';

import 'package:cc_domain/features/auth/domain/usecases/check_onboarding_complete.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/utils/app_log.dart';

import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/guards.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared-preferences key recording that onboarding was complete last time the
/// live checks settled.
///
/// Present-and-`true` = complete, absent = unknown. An *incomplete* verdict is
/// deliberately not cached (the key is removed instead) — see the `cachedGate`
/// note in [onboardingGateProvider]. Non-sensitive, so `shared_preferences` is
/// appropriate.
///
/// This one is legitimately device-local: it caches a DERIVED verdict for one
/// machine ("was the setup intact here last time?"), which is a property of
/// this install, not of the person. The question "have they ever been set up?"
/// is a fact about the USER and lives on the user row server-side — see
/// [onboardingFinishedProvider].
const _onboardingCompleteKey = 'onboarding_complete';

/// Whether this user has ever finished first-run setup.
///
/// `true` = yes, `false` = definitively not, `null` = not known yet because
/// identity has not resolved. Null is NOT "no": treating it as one would route
/// a returning operator into onboarding for the frame before identity lands,
/// and the guard never redirects away from onboarding once you are in it — so
/// they would be stranded there.
///
/// Sourced from `users.onboarding_finished_at` on the caller's own identity,
/// with **no device-local lane at all**. It used to read a synced preference
/// local-copy-first, which was wrong in a way that only showed up on a second
/// install: the preference sync's one-time promotion pass pushes a device's
/// local values onto whatever account first signs in there, so a machine that
/// had onboarded once marked a brand-new user as already set up. The gate then
/// read "has been set up before" and offered the re-auth screen — a sign-in
/// and none of the setup that account had never done.
final onboardingFinishedProvider = Provider<bool?>((ref) {
  final identity = ref.watch(currentIdentityProvider);
  if (!identity.hasValue && !identity.hasError) {
    return null;
  }
  return identity.value?.user.onboardingFinishedAt != null;
});

/// Pushes the "finished first-run setup" flag and refreshes the identity that
/// [onboardingFinishedProvider] reads it back from.
///
/// Holds the in-flight future so the two callers cannot race into a double
/// write: the gate fires on every recomputation that observes a complete setup,
/// which can happen several times before the first round-trip returns.
class _OnboardingFinishedWriter {
  _OnboardingFinishedWriter({required this.push, required this.refresh});

  /// Sends `users.markOnboardingFinished` (idempotent server-side).
  final Future<void> Function() push;

  /// Re-reads `identity.me` so the new timestamp reaches the provider.
  final void Function() refresh;

  Future<void>? _inFlight;

  Future<void> mark() => _inFlight ??= _run();

  Future<void> _run() async {
    try {
      await push();
      refresh();
    } on Object catch (e) {
      // Swallowed on purpose, and neither caller could do better with it: the
      // gate fires this from a provider body (fire-and-forget, so a throw would
      // land as an unhandled async error) and the flow's last step awaits it
      // before navigating (so a throw would strand the operator on the final
      // screen of a setup that actually completed). A dropped write self-heals
      // — the gate re-fires on its next recomputation.
      AppLog.w('onboarding', 'could not record onboarding completion: $e');
    } finally {
      // Cleared either way, so a failure (offline, server restarting) does not
      // latch the writer shut for the rest of the session.
      _inFlight = null;
    }
  }
}

/// The one-line seam that actually records the flag server-side.
///
/// A narrow function rather than the repository itself, for the same reason
/// `UserPreferenceSync` takes its `push` that way: the gate's self-healing
/// write is worth a test, and driving it through a two-line fake beats
/// standing up an RPC host to observe one call.
final onboardingFinishedPushProvider = Provider<Future<void> Function()>(
  (ref) => ref.read(identityRepositoryProvider).markOnboardingFinished,
);

final _onboardingFinishedWriterProvider = Provider<_OnboardingFinishedWriter>(
  (ref) => _OnboardingFinishedWriter(
    push: ref.read(onboardingFinishedPushProvider),
    refresh: () => ref.invalidate(currentIdentityProvider),
  ),
);

/// Records that this user has finished first-run setup.
///
/// Writes to the user's own identity on the server; nothing is cached on the
/// device. Idempotent, and there is no way to unset it — the flag records that
/// setup happened, not that it is currently intact.
///
/// Two entry points because `Ref` (providers) and `WidgetRef` (widgets) share
/// no supertype in Riverpod, and both callers are real: the gate records a
/// setup it observes as complete, and the flow records reaching its end.
Future<void> markOnboardingFinished(Ref ref) =>
    ref.read(_onboardingFinishedWriterProvider).mark();

/// [markOnboardingFinished], for a widget's `ref`.
Future<void> markOnboardingFinishedFromWidget(WidgetRef ref) =>
    ref.read(_onboardingFinishedWriterProvider).mark();

/// Derives the current onboarding gate state from auth and workspace readiness.
///
/// On cold start the underlying inputs (forge connections, the workspaces
/// stream) are still loading. Reporting
/// [OnboardingGate.loading] in that window parks the router on the splash
/// spinner. To avoid that for returning users, we fall back to the *cached*
/// result of the previous run while the live checks resolve — so the router
/// can pick the inbox/onboarding route synchronously on the first frame.
/// Once the live checks settle, the real result is recomputed (correcting the
/// route if it disagrees) and re-cached. First-ever launch has no cache and so
/// still shows the splash until the checks settle.
final onboardingGateProvider = Provider<OnboardingGate>((ref) {
  // A PUBLIC DEMO is complete by construction, and this has to be decided
  // before anything else.
  //
  // The gate asks two questions — is a forge connected, and does a workspace
  // exist — and on a demo server the first one has no answer a visitor could
  // ever change: `oauth.*` and `credentials.*` are absent from the op registry
  // entirely, so there is no way to connect one. Left to run, the gate reads
  // "no forge" plus a visitor whose onboarding flag is set (redemption hands
  // them a furnished workspace, so they have not onboarded and must not be
  // sent to onboarding either) and resolves to [OnboardingGate.signedOut] —
  // offering a sign-in screen for a credential that cannot exist, in front of
  // a workspace that is already furnished.
  //
  // Answering `complete` is the honest verdict rather than a bypass: the
  // visitor's setup genuinely IS done, it was just done for them.
  if (ref.watch(isDemoServerProvider)) {
    return OnboardingGate.complete;
  }

  final prefs = ref.watch(appPreferencesProvider);

  // Only a CACHED-COMPLETE verdict is trusted before the live checks settle.
  // A cached "incomplete" is worth nothing (an incomplete operator is headed
  // to onboarding either way, so it saves at most a splash frame) and costs a
  // trap: the router sends them to /onboarding on the strength of the cache,
  // and the guard deliberately never redirects AWAY from onboarding once the
  // gate flips to complete — that rule exists so the flow is not cut short
  // mid-step. A stale `false` therefore strands a fully set-up operator in the
  // flow, which creates a duplicate workspace every single launch. Waiting one
  // splash frame for the truth is the honest trade.
  OnboardingGate cachedGate() =>
      (prefs.getBool(_onboardingCompleteKey) ?? false)
      ? OnboardingGate.complete
      : OnboardingGate.loading;

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

  // A missing forge credential means "sign in again" only for someone who HAS
  // been set up before. That is what [onboardingFinishedProvider] records, and
  // it is deliberately not inferred from "workspaces exist": an invited member
  // has a workspace they never created and has never onboarded, so the
  // inference would send a brand-new account to the re-authentication screen
  // and it would never offer them the rest of the setup.
  final finished = ref.watch(onboardingFinishedProvider);
  final OnboardingGate gate;
  if (result.isComplete) {
    gate = OnboardingGate.complete;
  } else if (!hasForge && finished == null) {
    // Whether this is a lapsed credential or a first run is exactly the
    // question the unresolved flag answers. Guessing costs a wrong screen the
    // guard will not let us take back, so hold the splash instead.
    return cachedGate();
  } else if (!hasForge && finished!) {
    gate = OnboardingGate.signedOut;
  } else {
    gate = OnboardingGate.incomplete;
  }

  // A complete setup IS a finished onboarding, whether or not this install ever
  // walked the flow (it predates the flag, or the workspace arrived by invite).
  // Recording it here is what lets a later credential lapse resolve to the
  // re-auth screen rather than a first-run flow — and it is what self-heals an
  // account whose flag was never set, now that nothing seeds it from a device.
  //
  // Guarded on the flag itself rather than fired unconditionally: the write
  // refreshes `identity.me`, which recomputes this provider, so an unguarded
  // call would be a round-trip loop.
  if (gate == OnboardingGate.complete && finished == false) {
    unawaited(markOnboardingFinished(ref));
  }

  // Cache a COMPLETE result so the next cold start can route without the
  // splash, and clear the key otherwise so a setup that was later torn down
  // (a data-dir reset, a revoked forge) cannot keep claiming completeness.
  // Fire-and-forget: the write must not block the gate computation.
  unawaited(
    gate == OnboardingGate.complete
        ? prefs.setBool(_onboardingCompleteKey, value: true)
        : prefs.remove(_onboardingCompleteKey),
  );

  return gate;
});
