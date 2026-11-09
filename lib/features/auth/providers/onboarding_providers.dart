import 'dart:async';

import 'package:cc_domain/features/auth/domain/usecases/check_onboarding_complete.dart';
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

/// Whether this user has ever finished first-run setup.
/// `true` = yes, `false` = definitively not, `null` = not known yet because identity has
/// not resolved.
/// Null is NOT "no": treating it as one would route a returning operator into onboarding
/// for the frame before identity lands, and the guard never redirects away from onboarding
/// once you are in it — so they would be stranded there.
/// It used to read a synced preference local-copy-first, which was wrong in a way that only
/// showed up on a second install: the preference sync's one-time promotion pass pushes a
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
/// write: [onboardingGateEffectsProvider] fires on every settled complete
/// verdict, which can happen several times before the first round-trip
/// returns.
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
      // gate effects fire this from a listener (fire-and-forget, so a throw
      // would land as an unhandled async error) and the flow's last step
      // awaits it before navigating (so a throw would strand the operator on
      // the final screen of a setup that actually completed). A dropped write
      // self-heals — the effects re-fire on the next settled verdict.
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
/// no supertype in Riverpod, and both callers are real: the gate effects record
/// a setup they observe as complete, and the flow records reaching its end.
Future<void> markOnboardingFinished(Ref ref) =>
    ref.read(_onboardingFinishedWriterProvider).mark();

/// [markOnboardingFinished], for a widget's `ref`.
Future<void> markOnboardingFinishedFromWidget(WidgetRef ref) =>
    ref.read(_onboardingFinishedWriterProvider).mark();

/// The onboarding gate computed from live inputs only: null while any of them
/// (forge connections, the workspaces stream, the finished flag when it
/// matters) has not resolved.
///
/// [onboardingGateProvider] is what the router reads; it falls back to the
/// scoped cache while this is null. Side effects that follow a settled verdict
/// live in [onboardingGateEffectsProvider], never in a provider body.
final liveOnboardingGateProvider = Provider<OnboardingGate?>((ref) {
  // A PUBLIC DEMO is complete by construction, and this has to be decided
  // before anything else.
  //
  // The gate asks two questions — is a forge connected, and does a workspace
  // exist — and on a demo server the first one has no answer a visitor could
  // ever change: `oauth.*` and `credentials.*` are absent from the op registry
  // entirely, so there is no way to connect one. Left to run, the gate reads
  // "no forge" plus a visitor whose onboarding flag is set (redemption hands
  // them a furnished workspace, so they have not onboarded and must not be
  // sent to onboarding either) and resolves to [OnboardingGate.incomplete] —
  // offering a setup flow for a credential that cannot exist, in front of a
  // workspace that is already furnished.
  //
  // Answering `complete` is the honest verdict rather than a bypass: the
  // visitor's setup genuinely IS done, it was just done for them.
  if (ref.watch(isDemoServerProvider)) {
    return OnboardingGate.complete;
  }

  // The gate is "at least one forge connected", not "GitHub connected": an
  // operator who works only on GitLab has a complete setup. One
  // `forge.listConnections` answer carries every forge. A failed read with no
  // earlier answer is UNRESOLVED, never "no forge": an unreachable host would
  // otherwise send a set-up person to onboarding. The provider retries on its
  // own; a later failure keeps the previous list, so the verdict holds.
  final connectionsAsync = ref.watch(forgeConnectionsProvider);
  final hasForge = ref.watch(hasAnyForgeConnectedProvider);
  if (!connectionsAsync.hasValue) {
    return null;
  }

  final workspacesAsync = ref.watch(workspacesProvider);
  if (!workspacesAsync.hasValue && !workspacesAsync.hasError) {
    return null;
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
  // inference would skip the rest of the setup for a brand-new account.
  final finished = ref.watch(onboardingFinishedProvider);
  if (result.isComplete) {
    return OnboardingGate.complete;
  }
  if (!hasForge && finished == null) {
    // Whether this is a lapsed credential or a first run is exactly the
    // question the unresolved flag answers. Guessing costs a wrong screen the
    // guard will not let us take back, so hold the splash instead.
    return null;
  }
  if (!hasForge && finished!) {
    // A lapsed credential gates nothing for someone already set up: the
    // workspace shell warns in place (`ForgeSignInBanner`), and a workspace
    // on its own GitHub App can lack a sign-in its neighbours have. Only a
    // missing workspace still sends them to onboarding.
    return const CheckOnboardingCompleteUseCase()
            .execute(hasForgeConnection: true, workspaces: workspaces)
            .isComplete
        ? OnboardingGate.complete
        : OnboardingGate.incomplete;
  }
  return OnboardingGate.incomplete;
});

/// Derives the current onboarding gate state from auth and workspace readiness.
///
/// On cold start the underlying inputs (forge connections, the workspaces
/// stream) are still loading. Reporting [OnboardingGate.loading] in that
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
/// * A complete setup IS a finished onboarding, whether or not this install
///   ever walked the flow (it predates the flag, or the workspace arrived by
///   invite). Recording it is what lets a later credential lapse resolve to the
///   re-auth screen rather than a first-run flow — and it self-heals an account
///   whose flag was never set. Guarded on the flag itself: the write refreshes
///   `identity.me`, which re-settles the gate, so an unguarded call would be a
///   round-trip loop.
/// * A COMPLETE verdict is cached for this server and user so the next cold
///   start can route without the splash; anything else clears it, so a setup
///   torn down later (a revoked forge, a deleted workspace) cannot keep
///   claiming completeness. Nothing is cached without a [SessionScope].
///
/// A demo server's verdict is complete by construction and records nothing.
final onboardingGateEffectsProvider = Provider<void>((ref) {
  OnboardingGate? settled() => ref.read(isDemoServerProvider)
      ? null
      : ref.read(liveOnboardingGateProvider);

  void recordFinished() {
    if (settled() == OnboardingGate.complete &&
        ref.read(onboardingFinishedProvider) == false) {
      unawaited(markOnboardingFinished(ref));
    }
  }

  void cacheVerdict() {
    final gate = settled();
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

  ref
    ..listen<OnboardingGate?>(liveOnboardingGateProvider, (_, _) {
      recordFinished();
      cacheVerdict();
    }, fireImmediately: true)
    // The flag can resolve after the verdict settled (identity lands late),
    // and the verdict does not change when it does.
    ..listen<bool?>(onboardingFinishedProvider, (_, _) => recordFinished());
});
