/// Read/write access to one workspace's settings.
///
/// The workspace-scoped mirror of `UserPreferencesRepository`: an opaque
/// key/value space whose schema the client owns, for configuration two members
/// of a workspace must agree on (branch naming, agent/model defaults, the
/// default sandbox capability set, the data-sharing policy).
///
/// Every method takes a required `workspaceId`. It is what selects the database
/// file, so it can never be optional, nullable-with-a-default, or resolved from
/// an implicit "current" workspace.
abstract class WorkspaceSettingsRepository {
  /// The value of [key] in [workspaceId], or null when unset.
  Future<String?> get(String workspaceId, String key);

  /// Every setting in [workspaceId].
  Future<Map<String, String>> getAll(String workspaceId);

  /// Live view of every setting in [workspaceId].
  Stream<Map<String, String>> watchAll(String workspaceId);

  /// Sets [key] in [workspaceId]. A null [value] deletes it.
  Future<void> set(String workspaceId, String key, String? value);
}
