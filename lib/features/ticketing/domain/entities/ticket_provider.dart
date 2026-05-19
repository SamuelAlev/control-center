/// The backend that owns a ticket's canonical data.
///
/// Chosen once during onboarding (mirrors `SandboxBackend`). [local] is the
/// always-available default — its data lives entirely in the Control Center
/// database. Remote providers ([linear], [jira], [clickup]) own the ticket
/// data externally and are mirrored locally; Control-Center-only orchestration
/// (agent/team assignment, collaboration, channel link, pipeline coupling) is
/// always stored locally regardless of provider.
enum TicketProvider {
  /// Tickets stored entirely in the local Drift database.
  local,

  /// Tickets backed by Linear.
  linear,

  /// Tickets backed by Jira (not yet implemented).
  jira,

  /// Tickets backed by ClickUp (not yet implemented).
  clickup;

  /// Parses the persisted value. Unknown / null → [local].
  static TicketProvider fromStorage(String? raw) {
    for (final p in values) {
      if (p.name == raw) return p;
    }
    return local;
  }

  /// Serializes for storage.
  String toStorageString() => name;

  /// Whether this provider stores its canonical data outside Control Center.
  bool get isRemote => this != TicketProvider.local;
}
