/// Whether an agent is shared across its workspace or kept private to its
/// creator.
enum AgentVisibility {
  /// Visible to everyone in the workspace (the default).
  workspace,

  /// Private to the creating user; hidden from the shared roster.
  private;

  /// Parses a stored value (case-insensitive), defaulting to [workspace].
  static AgentVisibility fromStorage(String? value) {
    if (value == null) {
      return AgentVisibility.workspace;
    }
    return AgentVisibility.values
            .where((v) => v.name.toLowerCase() == value.toLowerCase())
            .firstOrNull ??
        AgentVisibility.workspace;
  }
}
