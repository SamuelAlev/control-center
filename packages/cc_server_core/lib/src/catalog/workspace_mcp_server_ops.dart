import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart'
    show providerOAuthHttpOrigin;
import 'package:cc_server_core/src/mcp_servers/workspace_mcp_servers.dart';

/// The MCP servers people configure by hand in a workspace.
///
/// Every `mcpServers.*` op but `approve` names a `scope`. `workspace` is the
/// workspace's servers: its admins list, add, change, remove, reconnect and
/// sign in to them, and every run in the workspace gets their tools.
/// `personal` is the caller's own servers in that workspace: every member
/// does the same with theirs, and only the runs that member starts there get
/// their tools. Whose server an id names is decided from the session, so
/// another member's own server is `mcp_server.not_found`.
///
/// A stdio server runs on the host as the server's OS user, so it starts only
/// once the server owner approved it (`mcpServers.approve`, owner only; the
/// owner saving a server approves it too), and only the owner adds one of
/// their own. Until then a remote server reaches public addresses only. An
/// edit by anyone else that changes how a server is launched or reached drops
/// the approval.
///
/// Secret values (environment variables, headers) are written through the
/// draft's `env_set`/`header_set` and never returned: the wire carries names.
/// A browser sign-in begins with `mcpServers.authorize`, comes back to this
/// server's `/oauth/mcp/callback`, and is stored only when the person who
/// began it presents the confirmation code (`mcpServers.authorizeComplete`).
///
/// Wire:
///  * `mcpServers.list {scope}` → `{servers: [entry]}`;
///  * `mcpServers.save {scope, …draft}` → `{server: entry}`;
///  * `mcpServers.delete {scope, id}`, `mcpServers.reconnect {scope, id}` →
///    `{ok}`;
///  * `mcpServers.approve {id}` → `{server: entry}`;
///  * `mcpServers.authorize {scope, id}` → authorization;
///  * `mcpServers.authorizeComplete {scope, attempt_id, code}` →
///    authorization.
List<RepoOp> buildConfiguredMcpServerOps({
  required WorkspaceMcpServers? workspaceServers,
  required String pairingServerUrl,
}) {
  final workspace = workspaceServers;
  if (workspace == null) {
    return const [];
  }
  // The workspace's servers are its admins'; a member's own need membership
  // only, which the dispatcher already checked.
  McpServerScope scopeOf(RepoOpContext ctx) {
    final scope = McpServerScope.fromWire(ctx.args['scope']);
    if (scope == McpServerScope.workspace) {
      final role = ctx.role;
      if (role == null || !role.isAdmin) {
        throw const AuthException(
          'Only workspace admins manage the workspace\'s MCP servers.',
        );
      }
    }
    return scope;
  }

  return [
    RepoOp(
      name: 'mcpServers.list',
      kind: RepoOpKind.read,
      requiredCapability: SessionCapability.fullClient,
      requiredArgs: const ['scope'],
      handler: (ctx) async => {
        'servers': [
          for (final e in await workspace.list(
            ctx.workspaceId!,
            scopeOf(ctx),
            actorUserId: ctx.userId,
          ))
            e.toJson(),
        ],
      },
    ),
    RepoOp(
      name: 'mcpServers.save',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      actionClasses: const {ActionClass.processSpawn},
      requiredArgs: const ['scope', 'name', 'transport'],
      handler: (ctx) async {
        final entry = await workspace.save(
          workspaceId: ctx.workspaceId!,
          scope: scopeOf(ctx),
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
      requiredArgs: const ['scope', 'id'],
      handler: (ctx) async {
        await workspace.delete(
          workspaceId: ctx.workspaceId!,
          scope: scopeOf(ctx),
          id: _id(ctx.args),
          actorUserId: ctx.userId,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'mcpServers.reconnect',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      requiredArgs: const ['scope', 'id'],
      audited: false,
      handler: (ctx) async {
        await workspace.reconnect(
          workspaceId: ctx.workspaceId!,
          scope: scopeOf(ctx),
          id: _id(ctx.args),
          actorUserId: ctx.userId,
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
    RepoOp(
      name: 'mcpServers.authorize',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      requiredArgs: const ['scope', 'id'],
      handler: (ctx) async {
        final authorization = await workspace.beginAuthorization(
          workspaceId: ctx.workspaceId!,
          scope: scopeOf(ctx),
          id: _id(ctx.args),
          actorUserId: ctx.userId,
          origin: providerOAuthHttpOrigin(pairingServerUrl),
        );
        return authorization.toJson();
      },
    ),
    RepoOp(
      name: 'mcpServers.authorizeComplete',
      kind: RepoOpKind.mutate,
      requiredCapability: SessionCapability.fullClient,
      requiredArgs: const ['scope', 'attempt_id', 'code'],
      handler: (ctx) async {
        final attemptId = ctx.args['attempt_id'];
        final code = ctx.args['code'];
        if (attemptId is! String ||
            attemptId.length > 64 ||
            code is! String ||
            code.length > 32) {
          throw const ValidationException('attempt_id or code is not valid');
        }
        final authorization = await workspace.completeAuthorization(
          workspaceId: ctx.workspaceId!,
          scope: scopeOf(ctx),
          attemptId: attemptId,
          code: code,
          actorUserId: ctx.userId,
        );
        return authorization.toJson();
      },
    ),
  ];
}

String _id(Map<String, dynamic> args) {
  final id = args['id'];
  if (id is! String || id.isEmpty) {
    throw const ValidationException('id must be a non-empty string');
  }
  return id;
}
