import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/mcp_servers/workspace_mcp_servers.dart';

/// The MCP servers people configure by hand.
///
/// `mcpServers.*` are a workspace's servers: workspace admins list, add,
/// change, remove and reconnect them, and every run in the workspace gets
/// their tools. A stdio server runs on the host as the server's OS user, so
/// it starts only once the server owner approved it (`mcpServers.approve`,
/// owner only; the owner saving a server approves it too). Until then a
/// remote server reaches public addresses only. An edit by anyone else that
/// changes how a server is launched or reached drops the approval.
///
/// `mcp.client.saveServer` and `mcp.client.deleteServer` are the server
/// owner's personal servers, beside the ones discovered in their own tool
/// configs (`mcp.client.servers`).
///
/// Secret values (environment variables, headers) are written through the
/// draft's `env_set`/`header_set` and never returned: the wire carries names.
///
/// Wire:
///  * `mcpServers.list` → `{servers: [entry]}`;
///  * `mcpServers.save {…draft}` → `{server: entry}`;
///  * `mcpServers.delete {id}`, `mcpServers.reconnect {id}` → `{ok}`;
///  * `mcpServers.approve {id}` → `{server: entry}`;
///  * `mcp.client.saveServer {…draft}` → `{server: definition}`;
///  * `mcp.client.deleteServer {id}` → `{ok}`.
List<RepoOp> buildConfiguredMcpServerOps({
  required WorkspaceMcpServers? workspaceServers,
  required McpClientControl? personal,
}) {
  final workspace = workspaceServers;
  return [
    if (workspace != null) ...[
      RepoOp(
        name: 'mcpServers.list',
        kind: RepoOpKind.read,
        requiredCapability: SessionCapability.fullClient,
        minRole: WorkspaceRole.admin,
        handler: (ctx) async => {
          'servers': [
            for (final e in await workspace.list(ctx.workspaceId!)) e.toJson(),
          ],
        },
      ),
      RepoOp(
        name: 'mcpServers.save',
        kind: RepoOpKind.mutate,
        requiredCapability: SessionCapability.fullClient,
        minRole: WorkspaceRole.admin,
        actionClasses: const {ActionClass.processSpawn},
        requiredArgs: const ['name', 'transport'],
        handler: (ctx) async {
          final entry = await workspace.save(
            workspaceId: ctx.workspaceId!,
            draft: McpServerDraft.fromJson(ctx.args),
            actorUserId: ctx.userId,
          );
          return {'server': entry.toJson()};
        },
      ),
      RepoOp(
        name: 'mcpServers.delete',
        kind: RepoOpKind.mutate,
        requiredCapability: SessionCapability.fullClient,
        minRole: WorkspaceRole.admin,
        requiredArgs: const ['id'],
        handler: (ctx) async {
          await workspace.delete(
            workspaceId: ctx.workspaceId!,
            id: _id(ctx.args),
          );
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'mcpServers.reconnect',
        kind: RepoOpKind.mutate,
        requiredCapability: SessionCapability.fullClient,
        minRole: WorkspaceRole.admin,
        requiredArgs: const ['id'],
        audited: false,
        handler: (ctx) async {
          await workspace.reconnect(
            workspaceId: ctx.workspaceId!,
            id: _id(ctx.args),
          );
          return {'ok': true};
        },
      ),
      // The owner approves a server of a workspace they belong to; the
      // dispatcher checks membership and the server authority.
      RepoOp(
        name: 'mcpServers.approve',
        kind: RepoOpKind.mutate,
        serverAuthority: ServerAuthority.serverOwner,
        requiredCapability: SessionCapability.fullClient,
        actionClasses: const {ActionClass.processSpawn},
        requiredArgs: const ['id'],
        handler: (ctx) async {
          final entry = await workspace.approve(
            workspaceId: ctx.workspaceId!,
            id: _id(ctx.args),
            actorUserId: ctx.userId,
          );
          return {'server': entry.toJson()};
        },
      ),
    ],
    if (personal != null) ...[
      RepoOp(
        name: 'mcp.client.saveServer',
        kind: RepoOpKind.mutate,
        serverAuthority: ServerAuthority.serverOwner,
        requiredCapability: SessionCapability.fullClient,
        workspaceScoped: false,
        actionClasses: const {ActionClass.processSpawn},
        requiredArgs: const ['name', 'transport'],
        handler: (ctx) async {
          final saved = await personal.saveServer(
            McpServerDraft.fromJson(ctx.args),
          );
          return {'server': saved.toJson()};
        },
      ),
      RepoOp(
        name: 'mcp.client.deleteServer',
        kind: RepoOpKind.mutate,
        serverAuthority: ServerAuthority.serverOwner,
        requiredCapability: SessionCapability.fullClient,
        workspaceScoped: false,
        requiredArgs: const ['id'],
        handler: (ctx) async {
          await personal.deleteServer(_id(ctx.args));
          return {'ok': true};
        },
      ),
    ],
  ];
}

String _id(Map<String, dynamic> args) {
  final id = args['id'];
  if (id is! String || id.isEmpty) {
    throw const ValidationException('id must be a non-empty string');
  }
  return id;
}
