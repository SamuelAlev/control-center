/// Why a Control Center Connect is not usable right now. [none] when it is
/// fine.
///
/// The stable codes `connect.status` and `workspaceConnect.status` report, so
/// the server's card and a workspace's card explain a failure in the same
/// words.
enum ConnectHealthError {
  /// Healthy.
  none(''),

  /// The hosted service has no apps for this build yet.
  hostedUnprovisioned('hosted_unprovisioned'),

  /// The signed configuration did not verify.
  signature('signature'),

  /// The configuration is older than one already seen.
  rollback('rollback'),

  /// Connect did not answer.
  unreachable('unreachable'),

  /// Connect refuses this server.
  installBlocked('install_blocked'),

  /// Connect's signing keys changed and wait for an admin's confirmation.
  pinsChanged('pins_changed'),

  /// Connect speaks a protocol this server does not.
  protocol('protocol'),

  /// A code this client does not know.
  unknown('?');

  const ConnectHealthError(this.wire);

  /// The wire spelling.
  final String wire;

  /// Parses a wire value; [none] for an empty one, [unknown] for others.
  static ConnectHealthError fromWire(Object? wire) {
    if (wire is! String || wire.isEmpty) {
      return none;
    }
    for (final error in values) {
      if (error.wire == wire) {
        return error;
      }
    }
    return unknown;
  }
}
