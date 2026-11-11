import 'dart:async';

import 'package:control_center/core/providers/session_scope_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/guards.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preference key (qualified by the session's [SessionScope]) recording that
/// onboarding was complete last time the live checks settled for this server
/// and user.
///
/// Present-and-`true` = complete, absent = unknown. An *incomplete* verdict is
/// deliberately not cached (the key is removed instead) — see the cached-gate
/// note in [onboardingGateProvider]. Non-sensitive.
///
/// It caches a DERIVED verdict for one server and account on this device ("was
/// the setup intact here last time?"). Scoped, because one device can pair with
/// several servers and accounts: an unscoped key let server B open on server
/// A's verdict and land in A's workspace. The question "have they ever been
/// set up?" is a fact about the USER and lives on the user row server-side —
/// see [onboardingFinishedProvider]. The pre-scope `onboarding_complete` key is
/// ignored: the first launch after upgrading resolves live.
const _onboardingCompleteKey = 'onboarding_complete';

/// Whether this user has ever finished first-run setup: `true` = yes, `false`
/// = definitively not, `null` = not known yet.
///
/// Read from the user's own row (`identity.me`'s `onboarding_finished_at`),
/// which only the flow's last step sets ([markOnboardingFinishedFromWidget]).
/// Every account passes the flow once, so `false` sends even an invited member
/// of a ready workspace to onboarding; there it sees only the steps it is
/// missing.
///
/// Null is NOT "no": treating it as one would route a returning operator into
/// onboarding for the frame before identity lands, and the guard never
/// redirects away from onboarding once you are in it, so they would be
/// stranded there. A failed first read is null for the same reason; a failed
/// re-read keeps the answer it had.
final onboardingFinishedProvider = Provider<bool?>((ref) {
  final identity = ref.watch(currentIdentityProvider);
  if (!identity.hasValue) {
    return null;
  }
  return identity.requireValue.user.onboardingFinishedAt != null;
});

/// Pushes the "finished first-run setup" flag and refreshes the identity that
/// [onboardingFinishedProvider] reads it back from.
///
/// Holds the in-flight future so a double tap on the flow's last step cannot
/// send it twice.
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
      // Swallowed on purpose: the flow's last step awaits this before
      // navigating, so a throw would strand the person on the final screen.
      // The flag stays unset, so the gate brings them back to the flow (just
      // the steps still missing) on the next verdict.
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
/// A narrow function rather than the repository itself, so a test can drive
/// the write through a two-line fake instead of an RPC host.
final onboardingFinishedPushProvider = Provider<Future<void> Function()>(
  (ref) => ref.read(identityRepositoryProvider).markOnboardingFinished,
);

final _onboardingFinishedWriterProvider = Provider<_OnboardingFinishedWriter>(
  (ref) => _OnboardingFinishedWriter(
    push: ref.read(onboardingFinishedPushProvider),
    refresh: () => ref.invalidate(currentIdentityProvider),
  ),
);

/// Records that this user has finished first-run setup, from the flow's last
/// step. Nothing else writes it: a setup that merely looks complete is not a
/// finished onboarding.
///
/// Writes to the user's own identity on the server; nothing is cached on the
/// device. Idempotent, and there is no way to unset it: the flag records that
/// setup happened, not that it is currently intact.
Future<void> markOnboardingFinishedFromWidget(WidgetRef ref) =>
    ref.read(_onboardingFinishedWriterProvider).mark();

/// The onboarding gate computed from live inputs only: null while any input
/// it needs (the finished flag, the workspaces stream and, for an incomplete
/// verdict, the forge connections) has not resolved.
///
/// * The flag unset: [OnboardingGate.incomplete], whatever else exists. Every
///   account passes the flow once; the flow shows only the steps missing.
/// * The flag set: complete once a workspace exists. A lapsed or missing
///   forge credential gates nothing for someone already set up: the workspace
///   shell warns in place (`ForgeSignInBanner`), and a workspace on its own
///   GitHub App can lack a sign-in its neighbours have.
/// * The flag set, no workspace, and no right to create one: complete too.
///   The flow has nothing left for them, so they land on the workspace
///   picker, which tells them an admin has to invite them.
///
/// [onboardingGateProvider] is what the router reads; it falls back to the
/// scoped cache while this is null. Side effects that follow a settled verdict
/// live in [onboardingGateEffectsProvider], never in a provider body.
final liveOnboardingGateProvider = Provider<OnboardingGate?>((ref) {
  // A PUBLIC DEMO is complete by construction, and this has to be decided
  // before anything else: a visitor's furnished workspace was set up for them,
  // their flag is never set, and the forge step has no answer they could give
  // (`oauth.*` and `credentials.*` are absent from a demo's op registry).
  if (ref.watch(isDemoServerProvider)) {
    return OnboardingGate.complete;
  }

  final finished = ref.watch(onboardingFinishedProvider);
  if (finished == null) {
    // Guessing costs a wrong screen the guard will not let us take back, so
    // hold the splash (or the cached verdict) instead.
    return null;
  }

  final workspacesAsync = ref.watch(workspacesProvider);
  if (!workspacesAsync.hasValue && !workspacesAsync.hasError) {
    return null;
  }
  final hasWorkspace = workspacesAsync.value?.isNotEmpty ?? false;
  if (finished && (hasWorkspace || !ref.watch(canCreateWorkspacesProvider))) {
    return OnboardingGate.complete;
  }

  // Incomplete. Held until the forge connections answer too, because the
  // flow plans its steps from them once, at its start. A failed read with no
  // earlier answer is UNRESOLVED, never "no forge"; the provider retries on
  // its own.
  if (!ref.watch(forgeConnectionsProvider).hasValue) {
    return null;
  }
  return OnboardingGate.incomplete;
});

/// Derives the current onboarding gate state from the finished flag and
/// workspace readiness.
///
/// On cold start the underlying inputs (identity, the workspaces stream, the
/// forge connections) are still loading. Reporting [OnboardingGate.loading] in that
/// window parks the router on the splash spinner. To avoid that for a
/// returning user, the gate falls back to the *cached* verdict of the previous
/// run for this same server and user ([SessionScope]) while the live checks
/// resolve — so the router can pick the inbox route on the first frame. Once
/// the live checks settle, [liveOnboardingGateProvider] takes over (correcting
/// the route if it disagrees). A first launch, a different server or account,
/// or a session whose scope could not be resolved has no cache and holds the
/// splash until the checks settle.
///
/// Pure: it reads, never writes. See [onboardingGateEffectsProvider].
final onboardingGateProvider = Provider<OnboardingGate>((ref) {
  final live = ref.watch(liveOnboardingGateProvider);
  if (live != null) {
    return live;
  }
  // Only a CACHED-COMPLETE verdict is trusted before the live checks settle.
  // A cached "incomplete" is worth nothing (an incomplete operator is headed
  // to onboarding either way, so it saves at most a splash frame) and costs a
  // trap: the router sends them to /onboarding on the strength of the cache,
  // and the guard deliberately never redirects AWAY from onboarding once the
  // gate flips to complete — that rule exists so the flow is not cut short
  // mid-step. A stale `false` therefore strands a fully set-up operator in the
  // flow, which creates a duplicate workspace every single launch. Waiting one
  // splash frame for the truth is the honest trade.
  final scope = ref.watch(sessionScopeProvider);
  if (scope == null) {
    return OnboardingGate.loading;
  }
  final cached = ref
      .watch(appPreferencesProvider)
      .getBool(scope.key(_onboardingCompleteKey));
  return (cached ?? false) ? OnboardingGate.complete : OnboardingGate.loading;
});

/// Acts on each settled (live) onboarding verdict. Kept alive by
/// `ControlCenterApp`.
///
/// A COMPLETE verdict is cached for this server and user so the next cold
/// start can route without the splash; anything else clears it, so a setup
/// torn down later (a deleted workspace) cannot keep claiming completeness.
/// Nothing is cached without a [SessionScope]. It never records the finished
/// flag: only the flow's last step does.
///
/// A demo server's verdict is complete by construction and records nothing.
final onboardingGateEffectsProvider = Provider<void>((ref) {
  void cacheVerdict() {
    final gate = ref.read(isDemoServerProvider)
        ? null
        : ref.read(liveOnboardingGateProvider);
    final scope = ref.read(sessionScopeProvider);
    if (gate == null || scope == null) {
      return;
    }
    final prefs = ref.read(appPreferencesProvider);
    final key = scope.key(_onboardingCompleteKey);
    unawaited(
      gate == OnboardingGate.complete
          ? prefs.setBool(key, value: true)
          : prefs.remove(key),
    );
  }

  ref.listen<OnboardingGate?>(
    liveOnboardingGateProvider,
    (_, _) => cacheVerdict(),
    fireImmediately: true,
  );
});
