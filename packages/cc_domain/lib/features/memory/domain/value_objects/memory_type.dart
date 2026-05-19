/// Typed classification for a memory, ported from oh-my-pi mnemopi
/// `core/typed-memory.ts` + `core/weibull.ts`.
///
/// Each type carries its own Weibull temporal-decay parameters (`k` = shape,
/// `eta` = scale in hours) so a stale `request` and a long-lived `profile` rank
/// differently at recall time. The decay curve is `exp(-((ageHours/eta)^k))`.
library;

/// How a type behaves over time — drives consolidation and surfacing.
enum TypePriority {
  /// Long-lived, slowly-decaying knowledge (facts, relationships).
  stable,

  /// Moderately durable (preferences).
  moderate,

  /// Important but evolving (goals, context, decisions).
  high,

  /// Time-boxed obligations that expire (commitments).
  timeCritical,

  /// Loses relevance quickly (events, raw context).
  decaying,

  /// Grows richer with repetition (learnings).
  accumulating,

  /// Shifts as understanding changes (observations).
  evolving,

  /// Sticks around because it must not recur (errors).
  persistent,

  /// Pointer to an external artifact.
  reference,
}

/// The 14 memory types (plus `request`, used for short-lived asks) with their
/// per-type Weibull decay parameters and consolidation priority.
enum MemoryType {
  /// Objective, verifiable information. Slow decay.
  fact('fact', k: 0.8, eta: 720, priority: TypePriority.stable),

  /// A like/dislike or stated preference.
  preference('preference', k: 0.4, eta: 4380, priority: TypePriority.moderate),

  /// A choice that affects future work.
  decision('decision', k: 1.0, eta: 336, priority: TypePriority.high),

  /// A promise/obligation with a deadline. Expires fastest of the durable set.
  commitment('commitment', k: 1.0, eta: 240, priority: TypePriority.timeCritical),

  /// An objective to achieve.
  goal('goal', k: 0.9, eta: 720, priority: TypePriority.high),

  /// A historical occurrence. Decays quickly.
  event('event', k: 1.2, eta: 168, priority: TypePriority.decaying),

  /// A rule/guideline directed at the agent. Very slow decay.
  instruction('instruction', k: 0.9, eta: 480, priority: TypePriority.stable),

  /// A connection between entities. Slow decay.
  relationship('relationship', k: 0.35, eta: 8760, priority: TypePriority.stable),

  /// Situational state ("currently working on X"). Decays quickly.
  context('context', k: 0.85, eta: 360, priority: TypePriority.high),

  /// A lesson learned. Accumulates value.
  learning('learning', k: 0.7, eta: 1440, priority: TypePriority.accumulating),

  /// A noticed pattern. Evolves.
  observation('observation', k: 0.9, eta: 480, priority: TypePriority.evolving),

  /// A mistake to avoid. Persistent so it does not recur.
  error('error', k: 1.1, eta: 336, priority: TypePriority.persistent),

  /// A document/code reference.
  artifact('artifact', k: 0.75, eta: 2160, priority: TypePriority.reference),

  /// A short-lived ask/request. Fastest decay (3-day scale).
  request('request', k: 1.5, eta: 72, priority: TypePriority.decaying),

  /// Unclassified. Falls back to the general half-life.
  unknown('unknown', k: 1.0, eta: 168, priority: TypePriority.moderate);

  const MemoryType(
    this.wireName, {
    required this.k,
    required this.eta,
    required this.priority,
  });

  /// The lowercase string persisted in the DB and used on the wire.
  final String wireName;

  /// Weibull shape parameter.
  final double k;

  /// Weibull scale parameter, in hours.
  final double eta;

  /// How this type behaves over time.
  final TypePriority priority;

  /// Parses a stored [wireName] back to a [MemoryType], defaulting to [fact]
  /// when [value] is null/unknown (the historical default for un-typed rows).
  static MemoryType parse(String? value) {
    if (value == null) {
      return MemoryType.fact;
    }
    final lower = value.toLowerCase();
    for (final t in MemoryType.values) {
      if (t.wireName == lower) {
        return t;
      }
    }
    return MemoryType.fact;
  }

  /// Human-readable, sentence-case display label (mirrors the `AgentRole.label`
  /// precedent — short enum labels live on the enum, not in l10n).
  String get label {
    switch (this) {
      case MemoryType.fact:
        return 'Fact';
      case MemoryType.preference:
        return 'Preference';
      case MemoryType.decision:
        return 'Decision';
      case MemoryType.commitment:
        return 'Commitment';
      case MemoryType.goal:
        return 'Goal';
      case MemoryType.event:
        return 'Event';
      case MemoryType.instruction:
        return 'Instruction';
      case MemoryType.relationship:
        return 'Relationship';
      case MemoryType.context:
        return 'Context';
      case MemoryType.learning:
        return 'Learning';
      case MemoryType.observation:
        return 'Observation';
      case MemoryType.error:
        return 'Error';
      case MemoryType.artifact:
        return 'Artifact';
      case MemoryType.request:
        return 'Request';
      case MemoryType.unknown:
        return 'Unknown';
    }
  }

  /// Recall-ranking priority weight (higher = surfaced first when scores tie).
  /// Mirrors mnemopi `getTypePriority`.
  int get rankPriority {
    switch (this) {
      case MemoryType.instruction:
        return 10;
      case MemoryType.commitment:
        return 9;
      case MemoryType.error:
        return 8;
      case MemoryType.goal:
        return 7;
      case MemoryType.decision:
        return 6;
      case MemoryType.preference:
        return 5;
      case MemoryType.fact:
      case MemoryType.relationship:
        return 4;
      case MemoryType.learning:
      case MemoryType.observation:
        return 3;
      case MemoryType.event:
      case MemoryType.context:
        return 2;
      case MemoryType.artifact:
        return 1;
      case MemoryType.request:
      case MemoryType.unknown:
        return 0;
    }
  }

  /// Whether memories of this type should roll from the hot (working) tier into
  /// the durable (episodic) tier during a consolidation `sleep()` pass.
  /// Mirrors mnemopi `shouldConsolidate`.
  bool get consolidatable {
    switch (this) {
      case MemoryType.fact:
      case MemoryType.preference:
      case MemoryType.decision:
      case MemoryType.goal:
      case MemoryType.learning:
      case MemoryType.observation:
      case MemoryType.relationship:
      case MemoryType.instruction:
        return true;
      case MemoryType.commitment:
      case MemoryType.event:
      case MemoryType.context:
      case MemoryType.error:
      case MemoryType.artifact:
      case MemoryType.request:
      case MemoryType.unknown:
        return false;
    }
  }
}
