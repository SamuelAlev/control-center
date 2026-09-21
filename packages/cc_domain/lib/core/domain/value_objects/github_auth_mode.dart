/// How one workspace authenticates to GitHub for background work.
///
/// The install-wide GitHub App remains the default. A workspace whose orgs
/// refused that App picks a different App or a PAT, and background work in
/// that workspace never silently falls through to the install App.
enum GithubAuthMode {
  /// Use this install's GitHub App (the [ProviderAppSettings] identity).
  inherit,

  /// Use a GitHub App configured on this workspace. Missing credentials are
  /// fail-closed — they do not inherit the install App.
  app,

  /// Never use any GitHub App. Background work uses a workspace PAT, then the
  /// server owner's pasted PAT, then the environment.
  pat;

  /// The value persisted in the database and sent over the wire.
  String get wireName => name;

  /// Parses a stored/wire value; unknown or empty values are [inherit] so a
  /// workspace predating this field keeps today's behaviour.
  static GithubAuthMode fromWire(String? value) {
    for (final mode in GithubAuthMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }
    return GithubAuthMode.inherit;
  }
}
