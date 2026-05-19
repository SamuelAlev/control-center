/// The derived 4-state health of an agent runtime, computed from how long ago
/// it last phoned home.
///
/// This is a pure function of the last-seen timestamp and the current time —
/// it is never stored, only derived (see [deriveRuntimeHealth]). Presentation
/// pairs each state with colour + shape + label so health is never conveyed by
/// colour alone (DESIGN.md status rule).
enum RuntimeHealth {
  /// Heartbeat is current — the runtime is reachable.
  online('Online'),

  /// Contact was lost within the last few minutes — possibly a transient drop.
  recentlyLost('Recently lost'),

  /// No heartbeat for long enough to be considered down.
  offline('Offline'),

  /// Stale for days — eligible for the garbage-collection sweep.
  aboutToGc('About to GC');

  /// Creates a [RuntimeHealth] with a display [label].
  const RuntimeHealth(this.label);

  /// Human-readable display label.
  final String label;
}

/// Thresholds governing runtime-health derivation and the GC sweep.
class RuntimeHealthThresholds {
  const RuntimeHealthThresholds._();

  /// A heartbeat newer than this counts as [RuntimeHealth.online].
  static const Duration onlineWindow = Duration(minutes: 1);

  /// A heartbeat older than [onlineWindow] but no older than this counts as
  /// [RuntimeHealth.recentlyLost].
  static const Duration recentlyLostCutoff = Duration(minutes: 5);

  /// A runtime stale for at least this long is [RuntimeHealth.aboutToGc].
  static const Duration aboutToGcThreshold = Duration(days: 6);

  /// A runtime stale for at least this long is reaped by the GC sweep.
  static const Duration gcThreshold = Duration(days: 7);
}

/// Derives the [RuntimeHealth] of a runtime from its [lastSeenAt] timestamp
/// relative to [now].
///
/// A null [lastSeenAt] (never phoned home) is [RuntimeHealth.offline]. The
/// boundaries are inclusive at the upper edge so a runtime last seen exactly
/// five minutes ago reads as [RuntimeHealth.recentlyLost].
RuntimeHealth deriveRuntimeHealth({
  required DateTime? lastSeenAt,
  required DateTime now,
}) {
  if (lastSeenAt == null) {
    return RuntimeHealth.offline;
  }
  final age = now.difference(lastSeenAt);
  if (age.isNegative || age < RuntimeHealthThresholds.onlineWindow) {
    return RuntimeHealth.online;
  }
  if (age <= RuntimeHealthThresholds.recentlyLostCutoff) {
    return RuntimeHealth.recentlyLost;
  }
  if (age >= RuntimeHealthThresholds.aboutToGcThreshold) {
    return RuntimeHealth.aboutToGc;
  }
  return RuntimeHealth.offline;
}

/// Whether a runtime last seen at [lastSeenAt] is stale enough to be reaped by
/// the GC sweep at [now].
bool isReadyForGc({required DateTime? lastSeenAt, required DateTime now}) {
  if (lastSeenAt == null) {
    return false;
  }
  return now.difference(lastSeenAt) >= RuntimeHealthThresholds.gcThreshold;
}
