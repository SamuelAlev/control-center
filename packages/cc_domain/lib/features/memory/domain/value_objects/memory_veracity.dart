/// Provenance/veracity of a memory and the Bayesian confidence maths that
/// rides on it, ported from oh-my-pi mnemopi `core/veracity-consolidation.ts`.
library;

/// How a memory came to be known. Each level carries a weight used to seed a
/// new memory's confidence and to size every re-mention's confidence bump.
enum MemoryVeracity {
  /// Directly stated by the user. Highest trust.
  stated('stated', weight: 1.0),

  /// Inferred by an agent from other signals.
  inferred('inferred', weight: 0.7),

  /// Produced by a tool/observation (lower trust than a human statement).
  tool('tool', weight: 0.5),

  /// Imported from an external store.
  imported('imported', weight: 0.6),

  /// Provenance unknown.
  unknown('unknown', weight: 0.8);

  const MemoryVeracity(this.wireName, {required this.weight});

  /// The lowercase string persisted in the DB and used on the wire.
  final String wireName;

  /// Confidence weight in `[0,1]` for this provenance.
  final double weight;

  /// Parses a stored [wireName], defaulting to [stated] (the historical default
  /// for un-tagged rows, which were almost all user/agent assertions).
  static MemoryVeracity parse(String? value) {
    if (value == null) {
      return MemoryVeracity.stated;
    }
    final lower = value.toLowerCase();
    for (final v in MemoryVeracity.values) {
      if (v.wireName == lower) {
        return v;
      }
    }
    return MemoryVeracity.stated;
  }
}

/// Base confidence for a brand-new memory of the given [veracity]: `weight*0.5`.
/// Mirrors mnemopi's `baseConfidence = weight * 0.5`.
double baseConfidenceFor(MemoryVeracity veracity) => veracity.weight * 0.5;

/// Bayesian confidence update applied on each corroborating re-mention:
///
///     increment = (1 - current) * weight * 0.3
///     next      = min(current + increment, 1.0)
///
/// Confidence asymptotically approaches 1.0; higher-veracity re-mentions move it
/// faster. Mirrors mnemopi's `bayesianUpdate`.
double bayesianUpdate(double current, MemoryVeracity veracity) {
  final clamped = current.clamp(0.0, 1.0);
  final increment = (1.0 - clamped) * veracity.weight * 0.3;
  final next = clamped + increment;
  return next > 1.0 ? 1.0 : next;
}
