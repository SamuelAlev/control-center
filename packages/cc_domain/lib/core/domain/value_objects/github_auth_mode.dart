/// How one workspace authenticates to GitHub.
///
/// GitHub is App-only: people act through their own App user token, and
/// everything else through one-repository tokens minted from an App. There is
/// no personal-access-token mode.
enum GithubAuthMode {
  /// Use this server's GitHub lane: its own GitHub App when one is fully
  /// configured, otherwise Control Center Connect.
  inherit,

  /// Use a GitHub App configured on this workspace. Missing credentials are
  /// fail-closed — they never fall back to the server's lane.
  app;

  /// The value persisted in the database and sent over the wire.
  String get wireName => name;

  /// Parses a stored/wire value; anything else (including the deleted
  /// `pat` mode) is [inherit].
  static GithubAuthMode fromWire(String? value) {
    for (final mode in GithubAuthMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }
    return GithubAuthMode.inherit;
  }
}
