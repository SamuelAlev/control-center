import 'dart:math';

/// The classified reason behind a rate-limit / quota error.
/// Each reason maps to a different recovery
/// strategy (rotate vs. wait and how long).
enum RateLimitReason {
  /// Account/model daily or monthly cap hit. Long wait; rotate to a sibling
  /// credential if one exists.
  quotaExhausted,

  /// Transient per-minute / per-hour cap. Short wait; stay on the credential.
  rateLimitExceeded,

  /// Service overloaded (temporary). Medium wait with jitter; stay.
  modelCapacity,

  /// 5xx / internal error. Short wait; stay.
  serverError,

  /// Could not classify — treated conservatively like a quota hit.
  unknown;

  /// The wire id.
  String get id => name;
}

/// The decision derived from a classified rate-limit error: how long to wait,
/// whether to rotate credentials and any random jitter to spread retries.
class RateLimitClassification {
  /// Creates a [RateLimitClassification].
  const RateLimitClassification({
    required this.reason,
    required this.baseBackoff,
    required this.shouldRotate,
    this.maxJitter = Duration.zero,
  });

  /// The classified reason.
  final RateLimitReason reason;

  /// The minimum wait before retrying.
  final Duration baseBackoff;

  /// Whether to rotate to a sibling credential rather than wait in place.
  final bool shouldRotate;

  /// Maximum random jitter to add on top of [baseBackoff].
  final Duration maxJitter;

  /// The effective wait: [baseBackoff] plus a random slice of [maxJitter].
  /// Pass a seeded [Random] in tests for determinism; omit for production.
  Duration effectiveBackoff([Random? rng]) {
    if (maxJitter == Duration.zero) {
      return baseBackoff;
    }
    final r = rng ?? Random();
    final jitterMs = (r.nextDouble() * maxJitter.inMilliseconds).round();
    return baseBackoff + Duration(milliseconds: jitterMs);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RateLimitClassification &&
          reason == other.reason &&
          baseBackoff == other.baseBackoff &&
          shouldRotate == other.shouldRotate &&
          maxJitter == other.maxJitter;

  @override
  int get hashCode => Object.hash(reason, baseBackoff, shouldRotate, maxJitter);

  @override
  String toString() =>
      'RateLimitClassification($reason, backoff=$baseBackoff, rotate=$shouldRotate)';
}
