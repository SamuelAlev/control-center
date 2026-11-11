/// Why a lane cannot sign anyone in right now: the `unavailable_reason` a
/// server reports per lane in `oauth.lanes` and every client renders.
enum SignInUnavailableReason {
  /// Nothing set up: no own app and no Connect for this workspace.
  notConfigured('not_configured'),

  /// An own app is set up halfway; the lane's error says what to fix.
  misconfigured('misconfigured'),

  /// The workspace is on its own apps but has none for this lane.
  ownAppMissing('own_app_missing'),

  /// Control Center's hosted Connect is chosen, but this build carries no
  /// key to verify it.
  connectUnprovisioned('connect_unprovisioned'),

  /// The custom Connect changed its app identifiers; an admin has to
  /// confirm them first.
  connectPinsPending('connect_pins_pending'),

  /// The Connect could not be reached or its config could not be trusted.
  connectUnreachable('connect_unreachable'),

  /// The workspace chose a custom Connect whose URL is missing or unusable.
  connectUrlInvalid('connect_url_invalid'),

  /// The workspace chose its own Connect, but `CC_CONNECT_URL` pins where
  /// sign-ins go: an admin has to pick again.
  blockedByEnvironment('blocked_by_environment'),

  /// The service this workspace uses does not offer this lane.
  laneNotOffered('lane_not_offered');

  const SignInUnavailableReason(this.wire);

  /// The wire spelling.
  final String wire;

  /// Parses a wire value; null when absent or empty, [notConfigured] when
  /// unknown.
  static SignInUnavailableReason? fromWire(Object? wire) {
    if (wire is! String || wire.isEmpty) {
      return null;
    }
    for (final reason in values) {
      if (reason.wire == wire) {
        return reason;
      }
    }
    return notConfigured;
  }
}

/// Where a browser sign-in attempt stands: the `status` a server reports in
/// `oauth.begin`, `oauth.status` and `oauth.complete`.
enum SignInAttemptStatus {
  /// Waiting for the browser and then the confirmation code.
  pending,

  /// The grant is stored.
  succeeded,

  /// Refused, expired or failed; the attempt's error says why.
  failed;

  /// The wire spelling.
  String get wire => name;

  /// Parses a wire value; [failed] for anything unknown.
  static SignInAttemptStatus fromWire(Object? wire) => switch (wire) {
    'pending' => pending,
    'succeeded' => succeeded,
    _ => failed,
  };

  /// Whether the attempt is over.
  bool get isTerminal => this != pending;
}
