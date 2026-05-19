import 'dart:io';

/// Port for workspace filesystem operations (agents, skills, directories).
///
/// **Known design trade-off:** This port returns `dart:io` types (`File`,
/// `Directory`) directly. Abstracting them behind custom value objects would
/// cascade changes through every implementation and caller with no material
/// benefit — the port's sole purpose is filesystem access, and any
/// alternative implementation would need the same semantics. We accept the
/// `dart:io` dependency here as pragmatic, not architectural.
abstract interface class WorkspaceFilesystemPort {
  /// Workspace dir.
  Future<Directory> workspaceDir(String workspaceId);
  /// Conversations container dir (parent of all per-conversation folders).
  Future<Directory> conversationsDir(String workspaceId);
  /// Per-conversation working dir. Used as the sandbox terminal's `pwd`.
  Future<Directory> conversationDir(String workspaceId, String conversationId);
  /// Creates [conversationDir] if it doesn't exist and returns it.
  Future<Directory> ensureConversationDir(
    String workspaceId,
    String conversationId,
  );
  /// Skills dir.
  Future<Directory> skillsDir(String workspaceId);
  /// Skill dir.
  Future<Directory> skillDir(String workspaceId, String skillSlug);
  /// Skill file path.
  Future<String> skillFilePath(String workspaceId, String skillSlug);
  /// Agents dir.
  Future<Directory> agentsDir(String workspaceId);
  /// Agent dir.
  Future<Directory> agentDir(String workspaceId, String agentSlug);
  /// Agent file path.
  Future<String> agentFilePath(String workspaceId, String agentSlug);
  /// Agent skills link dir.
  Future<Directory> agentSkillsLinkDir(String workspaceId, String agentSlug);
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
  /// Read skill file.
  Future<File?> readSkillFile(String workspaceId, String skillSlug);
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

  /// Directory used to store managed blobless git clones for large PRs.
  ///
  /// Layout: `<workspace>/<workspaceId>/pr_clones/<owner>__<repo>/`
  Future<Directory> prCloneDir(
    String workspaceId,
    String owner,
    String repo,
  );

  /// Ensures the directory at [path] exists, creating it and parents if needed.
  Future<void> ensureDir(String path);

  /// Writes [content] to the file at [path], creating it if it doesn't exist.
  Future<void> writeString(String path, String content);
}
