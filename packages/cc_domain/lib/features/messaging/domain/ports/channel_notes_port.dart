/// A read/write handle to a channel's shared Notes / handoff document (PRD 16
/// §11). The doc is a single markdown column updated by authoritative LWW —
/// both humans (via the UI) and agents (via MCP tools) read and write it.
///
/// This port lives in the domain layer so the MCP tools (cc_mcp) can depend on
/// it without reaching into cc_persistence. The server runtime wires a
/// DAO-backed adapter.
abstract interface class ChannelNotesPort {
  /// Reads the channel's Notes doc, or null when none exists yet.
  Future<({String contentMarkdown, String updatedBy, DateTime updatedAt})?>
  getNote(String workspaceId, String channelId);

  /// Creates or replaces the channel's Notes doc with [contentMarkdown],
  /// attributed to [updatedBy] (a principal wire string, e.g. `user:<id>` or
  /// `agent:<id>`). Returns the post-write snapshot.
  Future<({String contentMarkdown, String updatedBy, DateTime updatedAt})>
  upsertNote({
    required String workspaceId,
    required String channelId,
    required String contentMarkdown,
    required String updatedBy,
  });
}
