/// Why the server refused a GitLab or Bitbucket token pasted as a person's
/// own credential (`credentials.setForgeToken`).
///
/// [wire] is the refusal's `code`; every client renders each one in its own
/// words. An unknown or absent code reads as null, and the client falls back
/// to the server's message.
enum PersonTokenRefusal {
  /// The forge could not be asked (unreachable, rate limited, failing).
  unreachable('person_token.unreachable'),

  /// The forge does not accept the token, or it is revoked.
  rejected('person_token.rejected'),

  /// The token is not a person's own (a bot, project, group or access token).
  wrongKind('person_token.wrong_kind'),

  /// The token lacks a scope reviewing and commenting need.
  narrowScope('person_token.narrow_scope'),

  /// The token has expired.
  expired('person_token.expired');

  const PersonTokenRefusal(this.wire);

  /// The refusal's code on the wire.
  final String wire;

  /// Parses a wire code; null for one this client does not know.
  static PersonTokenRefusal? fromWire(Object? wire) {
    for (final refusal in values) {
      if (refusal.wire == wire) {
        return refusal;
      }
    }
    return null;
  }

  /// The refusal an RPC error's `data` names under `code`; null when it
  /// names none this client knows.
  static PersonTokenRefusal? ofErrorData(Object? data) =>
      data is Map ? fromWire(data['code']) : null;
}
