/// Shared key of the commit attribution setting in the user-preferences and
/// workspace-settings stores.
const String agentCommitAttributionSettingKey = 'agent_commit_attribution';

/// Commit policy shared by every adapter. Keep this shell-preflight safe.
const String agentCommitAttributionInstruction =
    'Use the supplied Git author and committer identities for every commit; '
    'do not override them. '
    'Leave commit signing exactly as it is configured: never turn it on, off '
    'or around, never sign tags, and never add Signed-off-by. '
    'If CC_GIT_COAUTHOR_TRAILER is nonempty, end every commit message with '
    'its exact lines as the only co-author trailer lines. Add no other '
    'Co-authored-by line, agent, AI or human: a push carrying one is refused. '
    'Do not add generated-by footers to commits or pull requests. '
    'Pass this attribution policy to every delegated agent.';

/// A workspace may decide commit attribution for every member or leave it to
/// each member's own preference.
enum AgentAttributionOverride {
  /// Each member decides; an unset preference is on.
  inherit,

  /// Co-author credit is on for everyone.
  enabled,

  /// Co-author credit is off for everyone.
  disabled;

  /// Missing or unrecognized stored values inherit the member's preference.
  static AgentAttributionOverride fromStored(String? value) => switch (value) {
    'true' => AgentAttributionOverride.enabled,
    'false' => AgentAttributionOverride.disabled,
    _ => AgentAttributionOverride.inherit,
  };

  /// The stored value, or null to remove the workspace override.
  String? get storedValue => switch (this) {
    AgentAttributionOverride.inherit => null,
    AgentAttributionOverride.enabled => 'true',
    AgentAttributionOverride.disabled => 'false',
  };

  /// The forced choice, or null when members choose for themselves.
  bool? get value => switch (this) {
    AgentAttributionOverride.inherit => null,
    AgentAttributionOverride.enabled => true,
    AgentAttributionOverride.disabled => false,
  };
}

/// Whether commits that involve a member carry co-author credit: the
/// workspace override when there is one, else the member's preference, else
/// on.
///
/// On a person's commits the credit names Control Center; on an automation's
/// commits it names the people accountable for it.
bool resolveAgentCommitAttribution({
  required String? userPreference,
  required String? workspaceOverride,
}) =>
    AgentAttributionOverride.fromStored(workspaceOverride).value ??
    (userPreference != 'false');
