import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_domain/features/presence/domain/value_objects/presence_locus.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/app_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// shared_preferences key for the persisted do-not-disturb choice (non-
/// sensitive, so [appPreferencesProvider] rather than secure storage).
const String presenceDndPrefKey = 'presence_dnd_v1';

/// Sentinel used by [MyPresenceState.copyWith] to distinguish "leave this
/// field unchanged" from "explicitly set it to null".
const Object _unset = Object();

/// The ephemeral presence lane's client adapter (PRD 16 §1). Never touches
/// storage — the server holds presence in memory and expires it ~30s after
/// the last update.
final presenceRepositoryProvider = Provider<RpcPresenceRepository>(
  (ref) => RpcPresenceRepository(ref.watch(rpcClientProvider)),
);

/// The live roster for `workspaceId`: humans and agents as co-equal
/// [ParticipantPresence] entries (PRD 16 §2). `tier: 'full'` — the desktop/web
/// cadence; the phone tier asks for the coalesced `'summary'` budget
/// elsewhere.
final presenceRosterProvider =
    StreamProvider.family<List<ParticipantPresence>, String>(
      (ref, workspaceId) => ref
          .watch(presenceRepositoryProvider)
          .watchRoster(workspaceId: workspaceId, tier: 'full'),
    );

/// This client's own presence intent — what [MyPresenceNotifier] publishes.
///
/// Immutable snapshot; every field mirrors a key in the publish wire map
/// (`a`/`l`/`ty`/`sp`/`cl`), except [dnd] which maps to sending `a: 'offline'`
/// (the do-not-disturb/invisible mechanism — PRD 16 adversarial review).
class MyPresenceState {
  /// Creates a [MyPresenceState].
  const MyPresenceState({
    this.dnd = false,
    this.locus,
    this.typingChannelId,
    this.spotlightChannelId,
    this.claims = const [],
  });

  /// Do-not-disturb / invisible: while true, this client publishes
  /// `a: 'offline'` and suspends its heartbeat.
  final bool dnd;

  /// What this client is currently viewing/editing, when known.
  final PresenceLocus? locus;

  /// The channel this client is typing in right now, or null.
  final String? typingChannelId;

  /// The channel this client is spotlighting (presenting), or null.
  final String? spotlightChannelId;

  /// Soft-claims this client currently holds.
  final List<SoftClaim> claims;

  /// Returns a copy with the given fields replaced. Pass an explicit `null`
  /// for [locus]/[typingChannelId]/[spotlightChannelId] to clear that field;
  /// omitting the parameter leaves it unchanged.
  MyPresenceState copyWith({
    bool? dnd,
    Object? locus = _unset,
    Object? typingChannelId = _unset,
    Object? spotlightChannelId = _unset,
    List<SoftClaim>? claims,
  }) => MyPresenceState(
    dnd: dnd ?? this.dnd,
    locus: identical(locus, _unset) ? this.locus : locus as PresenceLocus?,
    typingChannelId: identical(typingChannelId, _unset)
        ? this.typingChannelId
        : typingChannelId as String?,
    spotlightChannelId: identical(spotlightChannelId, _unset)
        ? this.spotlightChannelId
        : spotlightChannelId as String?,
    claims: claims ?? this.claims,
  );
}

/// Publishes this client's presence for the active workspace and tracks its
/// own online/idle availability.
///
/// Behavior (PRD 16 §1, clarifications):
/// - Publishes on every state change, coalesced to at most one publish per
///   [PresenceCadence.fullTierMinInterval] (≤10/s), plus an unconditional
///   [PresenceCadence.heartbeat] (10s) refresh.
/// - Flips online → idle after [PresenceCadence.idleAfter] (5 min) with no
///   [touch] calls; a subsequent [touch] flips back to online immediately.
/// - [setDnd] `true` publishes `a: 'offline'` once and suspends the
///   heartbeat until re-enabled — the do-not-disturb/invisible toggle.
/// - Every publish is fire-and-forget with errors swallowed: presence must
///   never break the app. A [RemoteRpcException] carrying
///   [RpcErrorCodes.opUnknown] (an older server with no presence lane)
///   disables this notifier permanently for the session.
class MyPresenceNotifier extends Notifier<MyPresenceState> {
  bool _started = false;
  bool _disabled = false;
  PresenceAvailability _availability = PresenceAvailability.online;

  Timer? _heartbeatTimer;
  Timer? _idleTimer;
  Timer? _typingClearTimer;
  Timer? _coalesceTimer;

  DateTime? _lastPublishAt;
  bool _coalescePending = false;

  /// Cadence overrides (a clock/timer seam for tests — see
  /// `my_presence_notifier_test.dart`, which subclasses this with
  /// millisecond-scale durations rather than waiting out the real 10s/5min
  /// production cadences).
  @visibleForTesting
  Duration get heartbeatInterval => PresenceCadence.heartbeat;

  /// See [heartbeatInterval].
  @visibleForTesting
  Duration get idleTimeout => PresenceCadence.idleAfter;

  /// See [heartbeatInterval].
  @visibleForTesting
  Duration get typingClearDelay => const Duration(seconds: 5);

  /// See [heartbeatInterval].
  @visibleForTesting
  Duration get coalesceWindow => PresenceCadence.fullTierMinInterval;

  @override
  MyPresenceState build() {
    final dnd =
        ref.watch(appPreferencesProvider).getBool(presenceDndPrefKey) ?? false;

    if (!_started) {
      _started = true;
      ref.onDispose(_disposeTimers);
      if (!dnd) {
        _startHeartbeat();
      }
      _restartIdleTimer();
      // A workspace switch re-scopes every publish; nudge one out immediately
      // so the new workspace's roster sees us without waiting for the next
      // heartbeat or state change.
      ref.listen<String?>(activeWorkspaceIdProvider, (previous, next) {
        if (previous != next) {
          _publish(force: true);
        }
      });
      if (!dnd) {
        scheduleMicrotask(() => _publish(force: true));
      }
    }

    return MyPresenceState(dnd: dnd);
  }

  void _disposeTimers() {
    _heartbeatTimer?.cancel();
    _idleTimer?.cancel();
    _typingClearTimer?.cancel();
    _coalesceTimer?.cancel();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      heartbeatInterval,
      (_) => _publish(force: true),
    );
  }

  void _restartIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, _goIdle);
  }

  void _goIdle() {
    if (_availability == PresenceAvailability.idle) {
      return;
    }
    _availability = PresenceAvailability.idle;
    _publish(force: true);
  }

  /// Registers input activity — wired from a top-level pointer/key listener
  /// in the shell. Flips idle → online immediately and restarts the idle
  /// countdown; a no-op (beyond the countdown restart) while already online.
  ///
  /// Throttled: the shell calls this for EVERY pointer move/hover/scroll and
  /// key event, and cancelling + recreating the idle [Timer] hundreds of
  /// times per second is measurable CPU for zero fidelity gain — against a
  /// minutes-long idle timeout, restarting the countdown once per
  /// [_touchThrottle] is indistinguishable. The idle → online flip is never
  /// throttled.
  void touch() {
    final wasIdle = _availability == PresenceAvailability.idle;
    final now = DateTime.now();
    if (!wasIdle &&
        _lastTouchAt != null &&
        now.difference(_lastTouchAt!) < _touchThrottle) {
      return;
    }
    _lastTouchAt = now;
    _availability = PresenceAvailability.online;
    _restartIdleTimer();
    if (wasIdle && !state.dnd) {
      _publish(force: true);
    }
  }

  static const Duration _touchThrottle = Duration(seconds: 5);
  DateTime? _lastTouchAt;

  /// Updates this client's locus (what it's viewing/editing). Called from
  /// [presenceLocusSyncProvider] as the route changes.
  void setLocus(PresenceLocus? locus) {
    if (state.locus == locus) {
      return;
    }
    state = state.copyWith(locus: locus);
    _publish();
  }

  /// Sets the channel this client is typing in (`null` to clear). Clears
  /// itself after 5s of inactivity — call again on every keystroke to keep it
  /// alive.
  void setTyping(String? channelId) {
    _typingClearTimer?.cancel();
    final changed = state.typingChannelId != channelId;
    if (changed) {
      state = state.copyWith(typingChannelId: channelId);
    }
    if (channelId != null) {
      _typingClearTimer = Timer(typingClearDelay, () => setTyping(null));
    }
    if (changed) {
      _publish();
    }
  }

  /// Sets (or clears) the channel this client is spotlighting/presenting.
  void setSpotlight(String? channelId) {
    if (state.spotlightChannelId == channelId) {
      return;
    }
    state = state.copyWith(spotlightChannelId: channelId);
    _publish(force: true);
  }

  /// Adds [claim] to this client's soft-claims (PRD 16 §14) — a no-op if
  /// already held. Publishes immediately so the roster reflects it promptly.
  void addClaim(SoftClaim claim) {
    if (state.claims.contains(claim)) {
      return;
    }
    state = state.copyWith(claims: [...state.claims, claim]);
    _publish(force: true);
  }

  /// Removes any soft-claim matching `(entityType, entityId)` — a no-op if
  /// not held. Publishes immediately.
  void removeClaim({required String entityType, required String entityId}) {
    final next = [
      for (final c in state.claims)
        if (!(c.entityType == entityType && c.entityId == entityId)) c,
    ];
    if (next.length == state.claims.length) {
      return;
    }
    state = state.copyWith(claims: next);
    _publish(force: true);
  }

  /// Toggles do-not-disturb / invisible. `true` publishes `a: 'offline'` once
  /// (removing this client from every roster) and suspends the heartbeat;
  /// `false` resumes normal publishing. Persisted non-sensitively so the
  /// choice survives restarts.
  // ignore: avoid_positional_boolean_parameters
  Future<void> setDnd(bool dnd) async {
    if (state.dnd == dnd) {
      return;
    }
    state = state.copyWith(dnd: dnd);
    unawaited(
      ref.read(appPreferencesProvider).setBool(presenceDndPrefKey, value: dnd),
    );
    if (dnd) {
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
      _idleTimer?.cancel();
      await _publishOffline();
    } else {
      _availability = PresenceAvailability.online;
      _startHeartbeat();
      _restartIdleTimer();
      _publish(force: true);
    }
  }

  Future<void> _publishOffline() async {
    if (_disabled) {
      return;
    }
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    try {
      await ref
          .read(presenceRepositoryProvider)
          .publish(workspaceId: workspaceId, presence: const {'a': 'offline'});
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        _disabled = true;
        _disposeTimers();
      }
    } on Object {
      // Presence must never break the app.
    }
  }

  /// Coalesced, fire-and-forget publish of the current wire state. [force]
  /// bypasses the ≤10/s coalescing window — used by the heartbeat and
  /// availability flips, which must land promptly even mid-burst.
  void _publish({bool force = false}) {
    if (_disabled || state.dnd) {
      return;
    }
    final now = DateTime.now();
    final last = _lastPublishAt;
    if (!force && last != null && now.difference(last) < coalesceWindow) {
      if (_coalescePending) {
        return;
      }
      _coalescePending = true;
      _coalesceTimer = Timer(coalesceWindow - now.difference(last), () {
        _coalescePending = false;
        _publish(force: true);
      });
      return;
    }
    _lastPublishAt = now;
    unawaited(_publishNow());
  }

  Future<void> _publishNow() async {
    if (_disabled) {
      return;
    }
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final wire = <String, dynamic>{
      'a': _availability.name,
      'l': ?state.locus?.toWire(),
      'ty': ?state.typingChannelId,
      'sp': ?state.spotlightChannelId,
      if (state.claims.isNotEmpty)
        'cl': [for (final c in state.claims) c.toWire()],
    };
    try {
      await ref
          .read(presenceRepositoryProvider)
          .publish(workspaceId: workspaceId, presence: wire);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        _disabled = true;
        _disposeTimers();
      }
    } on Object {
      // Presence must never break the app.
    }
  }
}

/// This client's own presence intent + publisher.
final myPresenceProvider =
    NotifierProvider<MyPresenceNotifier, MyPresenceState>(
      MyPresenceNotifier.new,
    );

/// Resolves the presence [PresenceLocus] for a path (query stripped), or null
/// when the location has no direct locus. Pure so it's independently
/// testable; also used by [presenceLocusSyncProvider].
PresenceLocus? presenceLocusForPath(String path) {
  final channel = RegExp(
    r'^/workspaces/[^/]+/channels/([^/]+)$',
  ).firstMatch(path);
  if (channel != null) {
    return ChannelLocus(channelId: channel.group(1)!);
  }

  final pr = RegExp(
    r'^/workspaces/[^/]+/pull-requests/([^/]+)/([^/]+)/(\d+)$',
  ).firstMatch(path);
  if (pr != null) {
    return PrLocus(
      repoFullName: '${pr.group(1)}/${pr.group(2)}',
      prNumber: int.parse(pr.group(3)!),
    );
  }

  final ticket = RegExp(
    r'^/workspaces/[^/]+/tickets/([^/]+)$',
  ).firstMatch(path);
  if (ticket != null) {
    return TicketLocus(ticketId: ticket.group(1)!);
  }

  return null;
}

/// Mirrors the current route onto [myPresenceProvider]'s locus (PRD 16 §3).
///
/// Listens to the `GoRouter` delegate directly (mirroring
/// `workspaceUrlSyncProvider`) rather than watching a route-state provider,
/// and defers the sync off the build frame for the same reason: GoRouter can
/// fire delegate notifications synchronously mid-build. Kept alive from the
/// shell (see `ControlCenterApp`).
final presenceLocusSyncProvider = Provider<void>((ref) {
  final router = ref.watch(routerProvider);
  var disposed = false;

  void sync() {
    if (disposed) {
      return;
    }
    String location;
    try {
      location = router.state.uri.toString();
    } on Object {
      return;
    }
    final path = Uri.parse(location).path;
    ref.read(myPresenceProvider.notifier).setLocus(presenceLocusForPath(path));
  }

  void scheduleSync() => Future.microtask(sync);
  router.routerDelegate.addListener(scheduleSync);
  ref.onDispose(() {
    disposed = true;
    router.routerDelegate.removeListener(scheduleSync);
  });
  Future.microtask(sync);
});
