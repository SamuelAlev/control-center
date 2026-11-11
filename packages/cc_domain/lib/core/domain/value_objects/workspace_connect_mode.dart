/// Whose provider apps one workspace signs people in through and runs its
/// background provider work on (GitHub, Google Calendar, Linear, Slack,
/// Klipy): the workspace's override of the server's Control Center Connect
/// choice.
///
/// GitHub is App-only: people act through their own App user token, and
/// everything else through one-repository tokens minted from an App. There is
/// no personal-access-token mode.
enum WorkspaceConnectMode {
  /// Follow the server's choice: its own apps, Control Center's Connect or
  /// its custom Connect, whichever the server owner picked.
  inherit,

  /// Control Center's hosted Connect, whatever the server uses.
  hosted,

  /// A Connect server this workspace names (`Workspace.connectUrl`).
  custom,

  /// This workspace's own apps only. A provider whose app is missing is off;
  /// one half set up is a setup error. Neither falls back to the server's
  /// apps or to any Connect.
  own;

  /// The value persisted in the database and sent over the wire.
  String get wireName => name;

  /// Whether the workspace overrides the server's choice. A person's grants
  /// then live in the workspace's own slot, never the server-wide one.
  bool get overridesServer => this != inherit;

  /// Whether the workspace routes sign-ins through a Connect it chose.
  bool get usesOwnConnect => this == hosted || this == custom;

  /// Parses a stored/wire value; anything unknown is [inherit].
  static WorkspaceConnectMode fromWire(String? value) {
    for (final mode in values) {
      if (mode.name == value) {
        return mode;
      }
    }
    return inherit;
  }
}
