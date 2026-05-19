import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [WorkspaceFilesystemPort] backed by the RPC client — the thin-client data
/// path for the workspace on-disk layout (agents / skills / conversation dirs).
///
/// The real filesystem lives on the SERVER's machine; this adapter forwards
/// every port method to the matching `fs.*` op the host catalog registers and
/// returns the wire result. Path accessors return the server's absolute path as
/// a `String` the client treats as an OPAQUE token (it hands it straight back to
/// a server-side op — e.g. the messaging terminal passes [agentDir] to
/// `terminal.spawn`); it never opens it as a local browser file. Mutations write
/// THROUGH this port to the server.
///
/// Carries no `workspace_id`: every `fs.*` op is workspace-scoped, so the host
/// injects the authoritative bound workspace per session and a client can never
/// touch another workspace's directories (the workspace-isolation invariant).
/// The opaque-path methods ([ensureDir] / [writeString]) are likewise declared
/// workspace-scoped on the host so an unbound session cannot reach them.
class RpcWorkspaceFilesystemPort implements WorkspaceFilesystemPort {
  /// Creates an [RpcWorkspaceFilesystemPort] over [_client].
  RpcWorkspaceFilesystemPort(this._client);

  final RemoteRpcClient _client;

  static String _path(Map<String, dynamic> data) => data['path'] as String;

  // ---- Path accessors ----

  @override
  Future<String> workspaceDir(String workspaceId) async =>
      _path(await _client.call('fs.workspaceDir', const {}));

  @override
  Future<String> conversationsDir(String workspaceId) async =>
      _path(await _client.call('fs.conversationsDir', const {}));

  @override
  Future<String> conversationDir(
    String workspaceId,
    String conversationId,
  ) async => _path(
    await _client.call('fs.conversationDir', {
      'conversation_id': conversationId,
    }),
  );

  @override
  Future<String> ensureConversationDir(
    String workspaceId,
    String conversationId,
  ) async => _path(
    await _client.call('fs.ensureConversationDir', {
      'conversation_id': conversationId,
    }),
  );

  @override
  Future<String> skillsDir(String workspaceId) async =>
      _path(await _client.call('fs.skillsDir', const {}));

  @override
  Future<String> skillDir(String workspaceId, String skillSlug) async => _path(
    await _client.call('fs.skillDir', {'skill_slug': skillSlug}),
  );

  @override
  Future<String> skillFilePath(String workspaceId, String skillSlug) async =>
      _path(
        await _client.call('fs.skillFilePath', {'skill_slug': skillSlug}),
      );

  @override
  Future<String> agentsDir(String workspaceId) async =>
      _path(await _client.call('fs.agentsDir', const {}));

  @override
  Future<String> agentDir(String workspaceId, String agentSlug) async => _path(
    await _client.call('fs.agentDir', {'agent_slug': agentSlug}),
  );

  @override
  Future<String> agentFilePath(String workspaceId, String agentSlug) async =>
      _path(
        await _client.call('fs.agentFilePath', {'agent_slug': agentSlug}),
      );

  @override
  Future<String> agentSkillsLinkDir(
    String workspaceId,
    String agentSlug,
  ) async => _path(
    await _client.call('fs.agentSkillsLinkDir', {'agent_slug': agentSlug}),
  );

  @override
  Future<String> prCloneDir(
    String workspaceId,
    String owner,
    String repo,
  ) async => _path(
    await _client.call('fs.prCloneDir', {'owner': owner, 'repo': repo}),
  );

  // ---- Read content ----

  @override
  Future<String?> readSkillFile(String workspaceId, String skillSlug) async {
    final data = await _client.call('fs.readSkillFile', {
      'skill_slug': skillSlug,
    });
    return data['content'] as String?;
  }

  // ---- List slugs ----

  @override
  Future<List<String>> listAgentSlugs(String workspaceId) async {
    final data = await _client.call('fs.listAgentSlugs', const {});
    return ((data['slugs'] as List?) ?? const [])
        .map((s) => s.toString())
        .toList();
  }

  @override
  Future<List<String>> listSkillSlugs(String workspaceId) async {
    final data = await _client.call('fs.listSkillSlugs', const {});
    return ((data['slugs'] as List?) ?? const [])
        .map((s) => s.toString())
        .toList();
  }

  // ---- Mutations ----

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) =>
      _client.call('fs.ensureWorkspaceDirs', const {});

  @override
  Future<void> ensureAgentDir(String workspaceId, String agentSlug) =>
      _client.call('fs.ensureAgentDir', {'agent_slug': agentSlug});

  @override
  Future<void> ensureMcpSymlink(String workspaceId, String agentSlug) =>
      _client.call('fs.ensureMcpSymlink', {'agent_slug': agentSlug});

  @override
  Future<void> writeAgentFile(
    String workspaceId,
    String agentSlug,
    String content,
  ) => _client.call('fs.writeAgentFile', {
    'agent_slug': agentSlug,
    'content': content,
  });

  @override
  Future<void> deleteAgentDir(String workspaceId, String agentSlug) =>
      _client.call('fs.deleteAgentDir', {'agent_slug': agentSlug});

  @override
  Future<void> syncAgentSkillLinks(
    String workspaceId,
    String agentSlug,
    List<String> skillSlugs,
  ) => _client.call('fs.syncAgentSkillLinks', {
    'agent_slug': agentSlug,
    'skill_slugs': skillSlugs,
  });

  @override
  Future<void> writeSkillFile(
    String workspaceId,
    String skillSlug,
    String content,
  ) => _client.call('fs.writeSkillFile', {
    'skill_slug': skillSlug,
    'content': content,
  });

  @override
  Future<void> deleteSkillDir(String workspaceId, String skillSlug) =>
      _client.call('fs.deleteSkillDir', {'skill_slug': skillSlug});

  @override
  Future<String?> persistLogo(String workspaceId, String sourcePath) async {
    final data = await _client.call('fs.persistLogo', {
      'source_path': sourcePath,
    });
    return data['path'] as String?;
  }

  @override
  Future<void> ensureDir(String path) =>
      _client.call('fs.ensureDir', {'path': path});

  @override
  Future<void> writeString(String path, String content) =>
      _client.call('fs.writeString', {'path': path, 'content': content});
}
