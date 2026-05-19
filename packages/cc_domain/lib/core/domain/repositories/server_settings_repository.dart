/// Read/write access to install-wide settings.
///
/// The scope above a workspace: configuration that bounds what any process on
/// this host may do, regardless of which workspace asked. There is no
/// `workspaceId` here by design — one host serves every workspace, so a
/// per-workspace waiver of a host bound would be a host-wide waiver in
/// practice.
///
/// Writes are operator-level. The transport MUST gate them behind an explicit
/// in-handler check rather than a declared role floor: the repo-op dispatcher
/// evaluates `minRole` only for workspace-scoped ops, so declaring one on a
/// global op reads as protection and enforces nothing.
abstract class ServerSettingsRepository {
  /// The value of [key], or null when unset.
  Future<String?> get(String key);

  /// Every server setting.
  Future<Map<String, String>> getAll();

  /// Live view of every server setting.
  Stream<Map<String, String>> watchAll();

  /// Sets [key]. A null [value] deletes it.
  Future<void> set(String key, String? value);
}
