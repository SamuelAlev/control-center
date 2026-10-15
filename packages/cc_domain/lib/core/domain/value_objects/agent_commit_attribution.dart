/// Shared key in the user-preferences and workspace-settings stores.
const String agentCommitAttributionSettingKey = 'agent_commit_attribution';

/// Commit policy shared by every adapter. Keep this shell-preflight safe.
const String agentCommitAttributionInstruction =
    'Use the supplied requesting user Git identity as both author and committer '
    'for every commit; do not override it with an agent identity. '
    'If CC_GIT_COAUTHOR_TRAILER is nonempty, append its exact value to the '
    'commit message. Otherwise do not add agent or AI co-author trailers. '
    'Do not add generated-by footers to commits or pull requests. '
    'Pass this attribution policy to every delegated agent.';

/// A workspace may override every member or defer to each member's preference.
enum AgentAttributionOverride {
  /// Leave the decision to each member; an unset user preference defaults on.
  inherit,

  /// Credit Control Center as co-author regardless of the member's preference.
  enabled,

  /// Use only the requesting member's Git identity.
  disabled;

  /// Missing or unrecognized stored values inherit the user preference.
  static AgentAttributionOverride fromStored(String? value) => switch (value) {
    'true' => AgentAttributionOverride.enabled,
    'false' => AgentAttributionOverride.disabled,
    _ => AgentAttributionOverride.inherit,
  };

  /// The wire value, or null to remove the workspace override.
  String? get storedValue => switch (this) {
    AgentAttributionOverride.inherit => null,
    AgentAttributionOverride.enabled => 'true',
    AgentAttributionOverride.disabled => 'false',
  };

  /// The forced choice, or null when members can choose for themselves.
  bool? get value => switch (this) {
    AgentAttributionOverride.inherit => null,
    AgentAttributionOverride.enabled => true,
    AgentAttributionOverride.disabled => false,
  };
}

/// Resolves agent attribution; workspace override → user preference → on.
bool resolveAgentCommitAttribution({
  required String? userPreference,
  required String? workspaceOverride,
}) =>
    AgentAttributionOverride.fromStored(workspaceOverride).value ??
    (userPreference != 'false');
