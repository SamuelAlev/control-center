import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_domain/features/presence/domain/value_objects/presence_locus.dart';

/// The server-hubbed ephemeral awareness lane (PRD 16 §1).
///
/// Presence flows client → server (`presence.update`) and the server fans it
/// out per workspace (`presence.watch`); peers never exchange presence
/// directly, so the roster is identical regardless of topology mix. Agent
/// presence is synthesized server-side (agents have no client). Everything
/// here is **in-memory only** — presence is never written to the database
/// (the awareness rule), and entries expire [PresenceCadence.expiry] after
/// their last update (three missed heartbeats).
class PresenceHub {
  /// Creates a hub. Inject [now] for deterministic tests.
  PresenceHub({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, Map<String, ParticipantPresence>> _byWorkspace = {};
  final Map<String, StreamController<void>> _signals = {};
  Timer? _sweepTimer;
  bool _disposed = false;

  /// Starts the periodic expiry sweep. Idempotent.
  void start() {
    _sweepTimer ??= Timer.periodic(
      PresenceCadence.sweepInterval,
      (_) => sweep(),
    );
  }

  /// Applies one human presence update. Identity comes from the SESSION
  /// (deviceId → userId), never from client args — a client can only ever
  /// update its own presence. An `a: 'offline'` update (explicit disconnect
  /// or the do-not-disturb/invisible toggle) removes the entry immediately.
  void publishHuman({
    required String workspaceId,
    required String userId,
    required String displayName,
    required Map<String, dynamic> update,
  }) {
    if (_disposed) {
      return;
    }
    final principal = Principal.of(PrincipalType.user, userId);
    if (update['a'] == 'offline') {
      remove(workspaceId, principal.wire);
      return;
    }
    final entry = ParticipantPresence(
      principal: principal,
      displayName: displayName,
      availability: PresenceAvailability.fromWire(update['a'] as String?),
      locus: update['l'] is Map
          ? PresenceLocus.fromWire((update['l'] as Map).cast<String, dynamic>())
          : null,
      typingInChannelId: update['ty'] as String?,
      spotlightChannelId: update['sp'] as String?,
      claims: update['cl'] is List
          ? [
              for (final c in update['cl'] as List)
                if (c is Map) SoftClaim.fromWire(c.cast<String, dynamic>()),
            ]
          : const [],
      updatedAt: _now(),
    );
    _entries(workspaceId)[principal.wire] = entry;
    _signal(workspaceId);
  }

  /// Publishes a synthesized agent presence entry.
  void publishAgent({
    required String workspaceId,
    required String agentId,
    required String displayName,
    required AgentLiveStatus status,
    PresenceLocus? locus,
    List<SoftClaim> claims = const [],
  }) {
    if (_disposed) {
      return;
    }
    final principal = Principal.of(PrincipalType.agent, agentId);
    _entries(workspaceId)[principal.wire] = ParticipantPresence(
      principal: principal,
      displayName: displayName,
      availability: PresenceAvailability.online,
      locus: locus,
      agent: status,
      claims: claims,
      updatedAt: _now(),
    );
    _signal(workspaceId);
  }

  /// Removes one participant (agent run ended, human went invisible,
  /// session closed).
  void remove(String workspaceId, String principalWire) {
    final entries = _byWorkspace[workspaceId];
    if (entries == null || entries.remove(principalWire) == null) {
      return;
    }
    _signal(workspaceId);
  }

  /// The current roster snapshot for [workspaceId], as wire maps.
  List<Map<String, dynamic>> snapshot(String workspaceId) {
    final entries = _byWorkspace[workspaceId];
    if (entries == null || entries.isEmpty) {
      return const [];
    }
    return [for (final p in entries.values) p.toWire()];
  }

  /// A live roster stream for [workspaceId], coalesced to at most one
  /// emission per [minInterval] (the per-consumer tier throttle: desktop/web
  /// ride [PresenceCadence.fullTierMinInterval], the phone
  /// [PresenceCadence.summaryTierMinInterval]). The first emission is the
  /// current snapshot.
  ///
  /// Solo-mode zero-regression: with one human and no agents there are no
  /// updates, so the stream emits once and then stays silent — the lane
  /// idles at zero broadcast traffic.
  Stream<List<Map<String, dynamic>>> watch(
    String workspaceId, {
    required Duration minInterval,
  }) {
    late StreamController<List<Map<String, dynamic>>> controller;
    StreamSubscription<void>? signalSub;
    Timer? pending;
    var lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

    void emit() {
      pending?.cancel();
      pending = null;
      lastEmit = _now();
      if (!controller.isClosed) {
        controller.add(snapshot(workspaceId));
      }
    }

    void onSignal() {
      if (pending != null) {
        return; // An emission is already scheduled.
      }
      final elapsed = _now().difference(lastEmit);
      if (elapsed >= minInterval) {
        emit();
      } else {
        pending = Timer(minInterval - elapsed, emit);
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        emit();
        signalSub = _signalController(workspaceId).stream.listen((_) {
          onSignal();
        });
      },
      onCancel: () async {
        pending?.cancel();
        await signalSub?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  /// Expires entries older than [PresenceCadence.expiry]. Returns how many
  /// were reaped.
  int sweep() {
    if (_disposed) {
      return 0;
    }
    final cutoff = _now().subtract(PresenceCadence.expiry);
    var reaped = 0;
    for (final entry in _byWorkspace.entries) {
      final stale = entry.value.entries
          .where((e) => e.value.updatedAt.isBefore(cutoff))
          .map((e) => e.key)
          .toList();
      for (final key in stale) {
        entry.value.remove(key);
        reaped++;
      }
      if (stale.isNotEmpty) {
        _signal(entry.key);
      }
    }
    return reaped;
  }

  Map<String, ParticipantPresence> _entries(String workspaceId) =>
      _byWorkspace.putIfAbsent(workspaceId, () => {});

  StreamController<void> _signalController(String workspaceId) =>
      _signals.putIfAbsent(workspaceId, StreamController<void>.broadcast);

  void _signal(String workspaceId) {
    // The broadcast signal controllers are owned by this hub (closed in
    // [dispose]); read through the map so they aren't treated as local sinks.
    if (_signals[workspaceId] case final controller?
        when !controller.isClosed) {
      controller.add(null);
    } else if (_signals[workspaceId] == null &&
        _byWorkspace.containsKey(workspaceId)) {
      // First signal before any watcher: create the controller so a watcher
      // attaching a moment later still receives changes.
      _signalController(workspaceId);
    }
  }

  /// Stops the sweep and closes every stream. The hub is unusable after.
  void dispose() {
    _disposed = true;
    _sweepTimer?.cancel();
    _sweepTimer = null;
    for (final c in _signals.values) {
      c.close();
    }
    _signals.clear();
    _byWorkspace.clear();
  }
}
