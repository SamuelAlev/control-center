/// Port for workspace filesystem operations (agents, skills, directories).
///
/// **`dart:io`-free by design.** Every "directory" accessor returns the
/// directory's absolute PATH as a `String` (the caller constructs a `Directory`
/// itself when it needs `dart:io` semantics), and [readSkillFile] returns the
/// file's CONTENT (or `null` when absent) rather than a `dart:io` `File`. Keeping
/// the interface free of `dart:io` lets the web build name the port and bind it
/// to a real RPC-backed implementation (`RpcWorkspaceFilesystemPort` in
/// `cc_data`) without dragging native filesystem types into the web compile
/// graph; the desktop/server implementation (`WorkspaceFilesystemService` in
/// `cc_infra`) does all the real `dart:io` work behind it.
///
/// The interface lives in the pure-Dart `cc_domain` contract layer so BOTH the
/// web-safe RPC adapter (`cc_data`) and the VM `dart:io` adapter (`cc_infra`)
/// can implement it without a package-graph back-edge. `cc_infra` re-exports
/// this symbol from `src/ports/workspace_filesystem_port.dart` so its existing
/// importers (and `cc_mcp`) keep their import path unchanged.
///
/// All returned paths are on the SERVER's filesystem. A thin/web client treats
/// them as OPAQUE tokens it hands back to a server-side operation (e.g. the
/// terminal panel passes [agentDir] to `terminal.spawn`); it never opens them as
/// local files.
abstract interface class WorkspaceFilesystemPort {
  /// Workspace dir path.
  Future<String> workspaceDir(String workspaceId);
  /// Conversations container dir path (parent of all per-conversation folders).
  Future<String> conversationsDir(String workspaceId);
  /// Per-conversation working dir path. Used as the sandbox terminal's `pwd`.
  Future<String> conversationDir(String workspaceId, String conversationId);
  /// Creates [conversationDir] if it doesn't exist and returns its path.
  Future<String> ensureConversationDir(
    String workspaceId,
    String conversationId,
  );
  /// Skills dir path.
  Future<String> skillsDir(String workspaceId);
  /// Skill dir path.
  Future<String> skillDir(String workspaceId, String skillSlug);
  /// Skill file path.
  Future<String> skillFilePath(String workspaceId, String skillSlug);
  /// Agents dir path.
  Future<String> agentsDir(String workspaceId);
  /// Agent dir path.
  Future<String> agentDir(String workspaceId, String agentSlug);
  /// Agent file path.
  Future<String> agentFilePath(String workspaceId, String agentSlug);
  /// Agent skills link dir path.
  Future<String> agentSkillsLinkDir(String workspaceId, String agentSlug);
  /// Ensure workspace dirs.
  Future<void> ensureWorkspaceDirs(String workspaceId);
  /// Ensure agent dir.
  Future<void> ensureAgentDir(String workspaceId, String agentSlug);
  /// Ensure MCP config symlink exists in agent dir pointing to root mcp.json.
  Future<void> ensureMcpSymlink(String workspaceId, String agentSlug);
  /// Write agent file.
  Future<void> writeAgentFile(
    String workspaceId,
    String agentSlug,
    String content,
  );
  /// Delete agent dir.
  Future<void> deleteAgentDir(String workspaceId, String agentSlug);

  /// Returns the slugs of every agent under the workspace.
  Future<List<String>> listAgentSlugs(String workspaceId);

  /// Sync agent skill links.
  Future<void> syncAgentSkillLinks(
    String workspaceId,
    String agentSlug,
    List<String> skillSlugs,
  );
  /// Write skill file.
  Future<void> writeSkillFile(
    String workspaceId,
    String skillSlug,
    String content,
  );
  /// Read a skill's `SKILL.md` content, or `null` when it does not exist.
  Future<String?> readSkillFile(String workspaceId, String skillSlug);
  /// Delete skill dir.
  Future<void> deleteSkillDir(String workspaceId, String skillSlug);

  /// Returns the slugs of every skill under the workspace.
  Future<List<String>> listSkillSlugs(String workspaceId);

  /// Copies the file at [sourcePath] into the workspace's own directory and
  /// returns the absolute path of the copy. Used so the workspace owns its
  /// logo asset and isn't broken if the user later deletes the original.
  ///
  /// Returns null when [sourcePath] is empty or does not exist.
  Future<String?> persistLogo(String workspaceId, String sourcePath);

  /// Path of the directory used to store managed blobless git clones for large
  /// PRs.
  ///
  /// Layout: `<workspace>/<workspaceId>/pr_clones/<owner>__<repo>/`
  Future<String> prCloneDir(
    String workspaceId,
    String owner,
    String repo,
  );

  /// Ensures the directory at [path] exists, creating it and parents if needed.
  Future<void> ensureDir(String path);

  /// Writes [content] to the file at [path], creating it if it doesn't exist.
  Future<void> writeString(String path, String content);
}
