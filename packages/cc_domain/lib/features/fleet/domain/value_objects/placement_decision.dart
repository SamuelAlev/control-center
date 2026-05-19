/// The machine-parseable outcome of a scheduling decision (PRD 20 §2, §7).
enum PlacementCode {
  /// Ran on a worker the job was explicitly pinned to.
  pinned('pinned'),

  /// Placed on a worker matching a preferred capability.
  preferred('preferred'),

  /// Placed on any free eligible worker (queue overflow / spill).
  spill('spill'),

  /// Left queued — no eligible worker free right now.
  queued('queued'),

  /// Left queued — no worker in the fleet has the required capabilities.
  noCapableWorker('no_capable_worker'),

  /// Left queued — the chosen worker's repo cache is warming.
  cacheWarming('cache_warming'),

  /// The lease expired and the job was reaped.
  reaped('reaped'),

  /// The job was requeued for retry.
  retried('retried'),

  /// The pinned worker exists but is not currently schedulable.
  pinnedWorkerUnavailable('pinned_worker_unavailable');

  const PlacementCode(this.wire);

  /// Stable wire/storage string.
  final String wire;

  /// Parses a [PlacementCode] from its [wire] string.
  static PlacementCode fromWire(String value) => PlacementCode.values
      .firstWhere((c) => c.wire == value, orElse: () => PlacementCode.queued);

  /// Whether this code means the job was placed on a worker.
  bool get isPlacement =>
      this == PlacementCode.pinned ||
      this == PlacementCode.preferred ||
      this == PlacementCode.spill;
}

/// A scheduler's decision for one job: whether/where it was placed and why.
///
/// Pure value object — the deterministic scheduler returns this and the caller
/// records it in the placement log so "why is this queued / why did it run
/// there?" always has an answer.
class PlacementDecision {
  /// Creates a [PlacementDecision].
  const PlacementDecision({
    required this.code,
    required this.reason,
    this.workerId,
  });

  /// A decision to leave a job queued (no worker chosen).
  const PlacementDecision.queued(
    this.reason, {
    this.code = PlacementCode.queued,
  }) : workerId = null;

  /// The decision code.
  final PlacementCode code;

  /// Human-readable explanation.
  final String reason;

  /// The chosen worker id, or null when the job stays queued.
  final String? workerId;

  /// Whether the job was placed on a worker.
  bool get placed => code.isPlacement && workerId != null;

  @override
  bool operator ==(Object other) =>
      other is PlacementDecision &&
      other.code == code &&
      other.reason == reason &&
      other.workerId == workerId;

  @override
  int get hashCode => Object.hash(code, reason, workerId);

  @override
  String toString() =>
      'PlacementDecision(${code.wire}, worker=$workerId, "$reason")';
}
