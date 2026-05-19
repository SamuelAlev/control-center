/// Provisioning state of a channel's conversation workspace.
///
/// Tracks whether the per-conversation repo worktrees + per-agent overlay +
/// derived `.mcp.json` are ready for agent dispatch. Provisioning now runs in
/// the background at channel creation; message dispatch is gated on [ready].
///
/// Stored as a column on the channel row (`provisioning_status`). Existing
/// (pre-migration) rows default to [ready] so they remain usable.
enum ChannelProvisioningStatus {
  /// Worktrees + overlay + `.mcp.json` are provisioned; dispatch proceeds.
  ready,

  /// Provisioning is in flight (background). Dispatch is queued until [ready].
  provisioning,

  /// Provisioning failed; the user must retry before dispatch can proceed.
  failed;

  /// Parses the database serialization. Unknown / null → [ready].
  static ChannelProvisioningStatus fromDbValue(String? raw) {
    for (final s in values) {
      if (s.name == raw) {
        return s;
      }
    }
    return ready;
  }

  /// Serializes for the `channels.provisioning_status` column.
  String toDbValue() => name;
}
