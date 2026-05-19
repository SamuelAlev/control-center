/// Provisioning state of a space's conversation workspace.
///
/// Tracks whether the per-conversation repo worktrees + per-agent overlay +
/// derived `.mcp.json` are ready for agent dispatch. Provisioning now runs in
/// the background at space creation; message dispatch is gated on [ready].
///
/// Stored as a column on the space row (`provisioning_status`). Existing
/// (pre-migration) rows default to [ready] so they remain usable.
enum SpaceProvisioningStatus {
  /// Worktrees + overlay + `.mcp.json` are provisioned; dispatch proceeds.
  ready,

  /// Provisioning is in flight (background). Dispatch is queued until [ready].
  provisioning,

  /// Provisioning failed; the user must retry before dispatch can proceed.
  failed,

  /// Provisioning was STOPPED — by the operator pressing stop in the space, or
  /// by the pipeline run that owned the space being cancelled. Behaves like
  /// [failed] (dispatch stays gated, retry re-provisions) and is a separate
  /// state only so the UI can say "stopped" rather than blaming a failure on
  /// work somebody deliberately interrupted.
  cancelled;

  /// Whether provisioning ended without the workspace being ready — the two
  /// states that gate dispatch and offer a retry.
  bool get isStopped => this == failed || this == cancelled;

  /// Parses the database serialization. Unknown / null → [ready].
  static SpaceProvisioningStatus fromDbValue(String? raw) {
    for (final s in values) {
      if (s.name == raw) {
        return s;
      }
    }
    return ready;
  }

  /// Serializes for the `spaces.provisioning_status` column.
  String toDbValue() => name;
}
