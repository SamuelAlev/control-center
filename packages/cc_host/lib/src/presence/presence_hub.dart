import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_domain/features/presence/domain/value_objects/presence_locus.dart';

/// The server-hubbed ephemeral awareness lane (PRD 16 §1).
///
/// Presence flows client → server (`presence.update`) and the server fans it
/// out per workspace (`presence.watch`); peers never exchange presence
/// directly, so the roster is identical regardless of topology mix. The
/// roster carries humans: an agent's live state is derived by each client from
/// the run log it already watches. Everything here is **in-memory only** — presence is never written to the database
/// (the awareness rule) and entries expire [PresenceCadence.expiry] after
/// their last update (three missed heartbeats).
class PresenceHub {
  /// Creates a hub. Inject [now] for deterministic tests.
  PresenceHub({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, Map<String, ParticipantPresence>> _byWorkspace = {};
  final Map<String, StreamController<void>> _signals = {};
  final Map<String, ({String name, DateTime at})> _names = {};

  /// How long a cached roster name is trusted. [renameUser] heals a rename
  /// made through `users.updateProfile` at once; this bounds any other path.
  static const Duration nameTtl = Duration(minutes: 5);
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
      typingInSpaceId: update['ty'] as String?,
      spotlightSpaceId: update['sp'] as String?,
      claims: update['cl'] is List
          ? [
              for (final c in update['cl'] as List)
                if (c is Map) SoftClaim.fromWire(c.cast<String, dynamic>()),
            ]
          : const [],
      updatedAt: _now(),
    );
    final entries = _entries(workspaceId);
    final previous = entries[principal.wire];
    entries[principal.wire] = entry;
    // A heartbeat re-sends unchanged state every [PresenceCadence.heartbeat]
    // only to keep the entry alive. Refreshing `updatedAt` is enough; waking
    // every watcher for it would re-broadcast the full roster per user per
    // heartbeat and the lane would never idle.
    if (previous == null || !_sameState(previous, entry)) {
      _signal(workspaceId);
    }
  }

  /// Whether [a] and [b] differ only in their receipt time.
  static bool _sameState(ParticipantPresence a, ParticipantPresence b) {
    final aw = a.toWire()..remove('u');
    final bw = b.toWire()..remove('u');
    return jsonEncode(aw) == jsonEncode(bw);
  }

  /// The roster name for [userId], looked up through [lookup] at most once
  /// per [nameTtl]. `presence.update` arrives at cursor cadence, so the name
  /// is cached here, per hub, rather than read per call.
  Future<String> displayNameFor(
    String userId,
    Future<String?> Function() lookup,
  ) async {
    final cached = _names[userId];
    if (cached != null && _now().difference(cached.at) < nameTtl) {
      return cached.name;
    }
    final name = await lookup() ?? userId;
    _names[userId] = (name: name, at: _now());
    return name;
  }

  /// Applies a rename at once: the cache and every live roster entry for
  /// [userId] take [displayName], so peers see it without waiting for
  /// [nameTtl] or the next heartbeat.
  void renameUser(String userId, String displayName) {
    if (_disposed) {
      return;
    }
    _names[userId] = (name: displayName, at: _now());
    final wire = Principal.of(PrincipalType.user, userId).wire;
    for (final MapEntry(key: workspaceId, value: entries)
        in _byWorkspace.entries) {
      final current = entries[wire];
      if (current == null || current.displayName == displayName) {
        continue;
      }
      entries[wire] = ParticipantPresence(
        principal: current.principal,
        displayName: displayName,
        availability: current.availability,
        locus: current.locus,
        typingInSpaceId: current.typingInSpaceId,
        spotlightSpaceId: current.spotlightSpaceId,
        claims: current.claims,
        updatedAt: current.updatedAt,
      );
      _signal(workspaceId);
    }
  }

  /// Removes one participant (went invisible, session closed).
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
    _shedEmptyWorkspaces();
    return reaped;
  }

  /// Drops the per-workspace maps (and their signal controllers) that no longer
  /// hold any participant AND have no listener.
  ///
  /// Presence is an ephemeral lane, but its INDEX was permanent: every
  /// workspace ever seen kept an empty map and a broadcast controller for the
  /// server's lifetime. Monotonic, small, and pointless — a workspace with no
  /// participants and nobody watching is exactly nothing.
  void _shedEmptyWorkspaces() {
    final empty = [
      for (final e in _byWorkspace.entries)
        if (e.value.isEmpty) e.key,
    ];
    for (final workspaceId in empty) {
      final controller = _signals[workspaceId];
      if (controller != null && controller.hasListener) {
        continue; // Someone is watching — keep the seat warm.
      }
      _byWorkspace.remove(workspaceId);
      _signals.remove(workspaceId);
      unawaited(controller?.close());
    }
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
    _names.clear();
  }
}
