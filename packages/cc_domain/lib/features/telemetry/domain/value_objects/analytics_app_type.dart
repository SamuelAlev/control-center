/// Which Control Center surface recorded an analytics event.
///
/// Every event carries this as `app_type`, and the Umami adapter also uses it
/// as the hostname, so the provider's own dashboards split by surface without
/// a custom filter.
enum AnalyticsAppType {
  /// The desktop app (macOS, Windows, Linux), connected to a local or a remote
  /// server.
  desktop,

  /// The full web client, always connected to a remote server.
  web,

  /// The phone PWA (`apps/cc_remote`).
  remote,

  /// The server itself, reporting domain facts (runs finished, workspaces
  /// created) that no single client observes once.
  server;

  /// Stable wire value.
  String get wire => name;
}
