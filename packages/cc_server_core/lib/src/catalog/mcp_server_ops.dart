import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_domain/features/mcp/domain/mcp_server_status.dart';
import 'package:cc_host/cc_host.dart'
    show RepoOp, ServerAuthority, SessionCapability;

/// The MCP HTTP surface the server hosts (`mcp.*`): one process-wide listener,
/// not workspace data, so every op is `workspaceScoped: false`. Absent when
/// the host wires no [mcp] (the demo), and the settings section then shows
/// "not available on this server".
///
/// `mcp.status` is for any member: it carries no credential. Everything else
/// is the server owner's: the token is their own credential for the whole
/// tool surface, and starting or stopping the listener changes every
/// workspace's agents. Those ops declare `ServerAuthority.serverOwner`, which
/// the dispatcher enforces. The token can be read and rotated, never cleared.
///
/// Wire:
///  * `mcp.status` → `{running, port, enabled}`;
///  * `mcp.token` → `{token}`;
///  * `mcp.rotateToken` → `{token}`, the new one;
///  * `mcp.start`, `mcp.stop`, `mcp.setEnabled {enabled}` → the status.
List<RepoOp> buildMcpServerOps({required McpServerControl? mcp}) {
  if (mcp == null) {
    return const [];
  }

  return [
    RepoOp(
      name: 'mcp.status',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async => (await mcp.status()).toJson(),
    ),
    RepoOp(
      name: 'mcp.token',
      serverAuthority: ServerAuthority.serverOwner,
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        return {'token': await mcp.token()};
      },
    ),
    RepoOp(
      name: 'mcp.rotateToken',
      serverAuthority: ServerAuthority.serverOwner,
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        return {'token': await mcp.rotateToken()};
      },
    ),
    RepoOp(
      name: 'mcp.start',
      serverAuthority: ServerAuthority.serverOwner,
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      handler: (ctx) async {
        await mcp.start();
        return (await mcp.status()).toJson();
      },
    ),
    RepoOp(
      name: 'mcp.stop',
      serverAuthority: ServerAuthority.serverOwner,
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      handler: (ctx) async {
        await mcp.stop();
        return (await mcp.status()).toJson();
      },
    ),
    RepoOp(
      name: 'mcp.setEnabled',
      serverAuthority: ServerAuthority.serverOwner,
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['enabled'],
      handler: (ctx) async {
        await mcp.setEnabled(enabled: ctx.args['enabled'] as bool);
        return (await mcp.status()).toJson();
      },
    ),
  ];
}
