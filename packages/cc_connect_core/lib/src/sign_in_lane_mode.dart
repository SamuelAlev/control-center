/// Who runs a lane's browser sign-in on a server: the wire value
/// `oauth.lanes` reports per lane and every client renders.
enum SignInLaneMode {
  /// The server's own OAuth app; the provider redirects to the server.
  own,

  /// Control Center Connect; the browser shows an 8-character code that the
  /// client hands back.
  connect,

  /// Neither is set up, or the own app is half-configured.
  unavailable;

  /// Parses a wire value; [unavailable] for anything unknown.
  static SignInLaneMode fromWire(Object? wire) => switch (wire) {
    'own' => own,
    'connect' => connect,
    _ => unavailable,
  };
}
