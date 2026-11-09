/// The closed set of failures Connect reports. Connect never echoes an
/// upstream provider's error body: every failure is one of these codes.
enum ConnectErrorCode {
  /// The grant is gone (revoked, expired, retired app or generation). The
  /// server clears the seal and asks the person to sign in again.
  needsSignIn('needs_sign_in', 401),

  /// The caller may not do this (bad signature, wrong install, wrong role,
  /// seal from another server, blocked scope), or the provider refused what
  /// it was asked for.
  accessDenied('access_denied', 403),

  /// A claim's confirmation code (or PKCE verifier) does not match the
  /// login. Counted against the login's attempts; the person may retry.
  codeMismatch('code_mismatch', 403),

  /// The app is not installed where the request needs it.
  notInstalled('not_installed', 404),

  /// A GitHub organization installation is bound to other servers.
  installationBoundElsewhere('installation_bound_elsewhere', 409),

  /// A Slack workspace is bound to another server.
  teamBoundElsewhere('team_bound_elsewhere', 409),

  /// Connecting a Slack workspace the first time takes one of its admins or
  /// owners, and the person who approved is neither.
  notAdmin('not_admin', 403),

  /// The installation or account is suspended.
  suspended('suspended', 423),

  /// Slow down.
  rateLimited('rate_limited', 429),

  /// The lane is not configured, or the provider is failing. Never clears a
  /// seal: it is transient by definition.
  providerUnavailable('provider_unavailable', 503),

  /// This install is not allowed on this Connect.
  installBlocked('install_blocked', 403),

  /// A signature outside the clock window, a replayed nonce, an expired
  /// login.
  staleRequest('stale_request', 400),

  /// The request body does not parse into the route's schema.
  invalidRequest('invalid_request', 400);

  const ConnectErrorCode(this.wire, this.httpStatus);

  /// The wire spelling.
  final String wire;

  /// The HTTP status Connect answers with.
  final int httpStatus;

  /// Parses a wire value; [providerUnavailable] for anything unknown, which
  /// is the one failure a client must never treat as "sign out".
  static ConnectErrorCode fromWire(Object? wire) {
    for (final code in values) {
      if (code.wire == wire) {
        return code;
      }
    }
    return providerUnavailable;
  }

  /// Whether a server should drop the stored seal on this failure.
  bool get clearsGrant => this == needsSignIn;
}

/// A failure answered by Connect (or synthesised by a client for a transport
/// failure, always as [ConnectErrorCode.providerUnavailable]).
final class ConnectException implements Exception {
  /// Creates the exception.
  const ConnectException(this.code, {this.reason = ''});

  /// What failed.
  final ConnectErrorCode code;

  /// Why, for the operator's log only: a short slug such as the provider's
  /// own error code. Never sent on the wire, never a token or a secret.
  final String reason;

  /// The wire body.
  Map<String, Object?> toJson() => {'error': code.wire};

  @override
  String toString() => reason.isEmpty
      ? 'ConnectException(${code.wire})'
      : 'ConnectException(${code.wire}: $reason)';
}
