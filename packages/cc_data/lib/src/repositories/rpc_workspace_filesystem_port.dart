import 'dart:convert';

import 'package:cc_data/src/absent_op.dart';
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
/// Every `fs.*` op is workspace-scoped and the host is STATELESS — it holds no
/// session workspace — so each call must carry its own `workspace_id`. This
/// adapter passes the one its port method was handed rather than leaning on
/// [RemoteRpcClient.activeWorkspaceId], which is the route's active workspace and
/// so is either absent (onboarding, before any workspace exists) or the wrong
/// workspace (creating a second one while another is open — that would have
/// persisted the new workspace's logo into the open workspace's directory).
///
/// The opaque-path methods ([ensureDir] / [writeString]) are the exception: they
/// take a server path and no workspace, so they still resolve against the active
/// workspace and are declared workspace-scoped on the host purely so an unbound
/// session cannot reach them.
class RpcWorkspaceFilesystemPort implements WorkspaceFilesystemPort {
  /// Creates an [RpcWorkspaceFilesystemPort] over [_client].
  RpcWorkspaceFilesystemPort(this._client);

  final RemoteRpcClient _client;

  static String _path(Map<String, dynamic> data) => data['path'] as String;

  // ---- Path accessors ----

  @override
  Future<String> workspaceDir(String workspaceId) async => _path(
    await _client.call('fs.workspaceDir', {'workspace_id': workspaceId}),
  );

  @override
  Future<String> spacesDir(String workspaceId) async =>
      _path(await _client.call('fs.spacesDir', {'workspace_id': workspaceId}));

  @override
  Future<String> spaceDir(String workspaceId, String conversationId) async =>
      _path(
        await _client.call('fs.spaceDir', {
          'workspace_id': workspaceId,
          'conversation_id': conversationId,
        }),
      );

  @override
  Future<String> ensureSpaceDir(
    String workspaceId,
    String conversationId,
  ) async => _path(
    await _client.call('fs.ensureSpaceDir', {
      'workspace_id': workspaceId,
      'conversation_id': conversationId,
    }),
  );

  @override
  Future<String> skillsDir(String workspaceId) async =>
      _path(await _client.call('fs.skillsDir', {'workspace_id': workspaceId}));

  @override
  Future<String> skillDir(String workspaceId, String skillSlug) async => _path(
    await _client.call('fs.skillDir', {
      'workspace_id': workspaceId,
      'skill_slug': skillSlug,
    }),
  );

  @override
  Future<String> skillFilePath(String workspaceId, String skillSlug) async =>
      _path(
        await _client.call('fs.skillFilePath', {
          'workspace_id': workspaceId,
          'skill_slug': skillSlug,
        }),
      );

  @override
  Future<String> agentsDir(String workspaceId) async =>
      _path(await _client.call('fs.agentsDir', {'workspace_id': workspaceId}));

  @override
  Future<String> agentDir(String workspaceId, String agentSlug) async => _path(
    await _client.call('fs.agentDir', {
      'workspace_id': workspaceId,
      'agent_slug': agentSlug,
    }),
  );

  @override
  Future<String> agentFilePath(String workspaceId, String agentSlug) async =>
      _path(
        await _client.call('fs.agentFilePath', {
          'workspace_id': workspaceId,
          'agent_slug': agentSlug,
        }),
      );

  @override
  Future<String> agentSkillsLinkDir(
    String workspaceId,
    String agentSlug,
  ) async => _path(
    await _client.call('fs.agentSkillsLinkDir', {
      'workspace_id': workspaceId,
      'agent_slug': agentSlug,
    }),
  );

  @override
  Future<String> prCloneDir(
    String workspaceId,
    String owner,
    String repo,
  ) async => _path(
    await _client.call('fs.prCloneDir', {
      'workspace_id': workspaceId,
      'owner': owner,
      'repo': repo,
    }),
  );

  // ---- Read content ----

  @override
  Future<String?> readSkillFile(String workspaceId, String skillSlug) async {
    final data = await _client.readOr('fs.readSkillFile', {
      'workspace_id': workspaceId,
      'skill_slug': skillSlug,
    }, const {});
    return data['content'] as String?;
  }

  // ---- List slugs ----

  @override
  Future<List<String>> listAgentSlugs(String workspaceId) async {
    final data = await _client.readOr('fs.listAgentSlugs', {
      'workspace_id': workspaceId,
    }, const {});
    return ((data['slugs'] as List?) ?? const [])
        .map((s) => s.toString())
        .toList();
  }

  @override
  Future<List<String>> listSkillSlugs(String workspaceId) async {
    final data = await _client.readOr('fs.listSkillSlugs', {
      'workspace_id': workspaceId,
    }, const {});
    return ((data['slugs'] as List?) ?? const [])
        .map((s) => s.toString())
        .toList();
  }

  // ---- Mutations ----

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) =>
      _client.call('fs.ensureWorkspaceDirs', {'workspace_id': workspaceId});

  @override
  Future<void> ensureAgentDir(String workspaceId, String agentSlug) =>
      _client.call('fs.ensureAgentDir', {
        'workspace_id': workspaceId,
        'agent_slug': agentSlug,
      });

  // NOTE: `ensureMcpSymlink` is intentionally NOT an override — it was removed
  // from [WorkspaceFilesystemPort] when MCP config consolidation moved the
  // derived `.mcp.json` into the per-agent cwd (written by cc_server, not the
  // filesystem port). The server-side `fs.ensureMcpSymlink` RPC handler is kept
  // as dead-but-callable surface for a separate presentation-only cleanup, so
  // this client method stays too (no breaking wire change).
  /// Ensures the MCP-server symlink for [agentSlug] exists in the workspace.
  Future<void> ensureMcpSymlink(String workspaceId, String agentSlug) =>
      _client.call('fs.ensureMcpSymlink', {
        'workspace_id': workspaceId,
        'agent_slug': agentSlug,
      });

  @override
  Future<void> writeAgentFile(
    String workspaceId,
    String agentSlug,
    String content,
  ) => _client.call('fs.writeAgentFile', {
    'workspace_id': workspaceId,
    'agent_slug': agentSlug,
    'content': content,
  });

  @override
  Future<void> deleteAgentDir(String workspaceId, String agentSlug) =>
      _client.call('fs.deleteAgentDir', {
        'workspace_id': workspaceId,
        'agent_slug': agentSlug,
      });

  @override
  Future<void> syncAgentSkillLinks(
    String workspaceId,
    String agentSlug,
    List<String> skillSlugs,
  ) => _client.call('fs.syncAgentSkillLinks', {
    'workspace_id': workspaceId,
    'agent_slug': agentSlug,
    'skill_slugs': skillSlugs,
  });

  @override
  Future<void> writeSkillFile(
    String workspaceId,
    String skillSlug,
    String content,
  ) => _client.call('fs.writeSkillFile', {
    'workspace_id': workspaceId,
    'skill_slug': skillSlug,
    'content': content,
  });

  @override
  Future<void> deleteSkillDir(String workspaceId, String skillSlug) =>
      _client.call('fs.deleteSkillDir', {
        'workspace_id': workspaceId,
        'skill_slug': skillSlug,
      });

  @override
  Future<String?> persistLogo(String workspaceId, String sourcePath) async {
    final data = await _client.call('fs.persistLogo', {
      'workspace_id': workspaceId,
      'source_path': sourcePath,
    });
    return data['path'] as String?;
  }

  @override
  Future<String?> persistLogoBytes(
    String workspaceId,
    List<int> bytes,
    String extension,
  ) async {
    final data = await _client.call('fs.persistLogoBytes', {
      'workspace_id': workspaceId,
      'bytes': base64.encode(bytes),
      'extension': extension,
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
