/// Lifecycle status of a fleet worker (PRD 20 §1, §8).
enum WorkerStatus {
  /// Online and eligible to receive leases.
  online('online'),

  /// Draining: finishes current jobs, takes no new leases (operator control).
  draining('draining'),

  /// Not currently connected (heartbeat lapsed or shut down cleanly).
  offline('offline'),

  /// Protocol-version mismatch with the server: withholds leases until the
  /// worker is upgraded (spec Clarifications — handshake, not compat matrix).
  incompatible('incompatible'),

  /// Revoked by the operator: its live session terminates, no leases ever.
  revoked('revoked');

  const WorkerStatus(this.wire);

  /// The stable wire/storage string.
  final String wire;

  /// Parses a [WorkerStatus] from its [wire] string, defaulting to [offline].
  static WorkerStatus fromWire(String value) => WorkerStatus.values.firstWhere(
    (s) => s.wire == value,
    orElse: () => WorkerStatus.offline,
  );

  /// Whether a worker in this status may be leased new jobs.
  bool get isSchedulable => this == WorkerStatus.online;
}
