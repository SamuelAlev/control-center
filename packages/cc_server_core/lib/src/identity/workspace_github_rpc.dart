import 'package:cc_domain/cc_domain.dart' show NotFoundException, RepoOpKind;
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';

/// Per-workspace GitHub App (`workspaceGitHub.*`).
///
/// Admin of the bound workspace. Secrets never leave the server. Injected via
/// `extraOps` so `remote_rpc_catalog.dart` does not grow. Empty when the host
/// wires no [WorkspaceGitHubAppSettings] (demo / tests).
List<RepoOp> buildWorkspaceGitHubOps({
  required WorkspaceRepository workspaceRepository,
  required WorkspaceGitHubAppSettings? apps,
}) {
  if (apps == null) {
    return const [];
  }
  return [
    RepoOp(
      name: 'workspaceGitHub.status',
      kind: RepoOpKind.read,
      minRole: WorkspaceRole.admin,
      handler: (ctx) async {
        final ws = await workspaceRepository.getById(ctx.workspaceId!);
        if (ws == null) {
          throw const NotFoundException('Workspace not found');
        }
        final status = await apps.status(ws, probe: ctx.args['probe'] == true);
        return {...status.toJson(), 'connect_mode': ws.connectMode.wireName};
      },
    ),
    RepoOp(
      name: 'workspaceGitHub.save',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.admin,
      handler: (ctx) async {
        final ws = await workspaceRepository.getById(ctx.workspaceId!);
        if (ws == null) {
          throw const NotFoundException('Workspace not found');
        }
        String? field(String key) {
          final value = ctx.args[key];
          return value is String ? value : null;
        }

        final saved = await apps.save(
          ws,
          clientId: field('client_id'),
          clientSecret: field('client_secret'),
          privateKeyPem: field('private_key'),
        );
        return {...saved.toJson(), 'connect_mode': ws.connectMode.wireName};
      },
    ),
    RepoOp(
      name: 'workspaceGitHub.test',
      kind: RepoOpKind.read,
      minRole: WorkspaceRole.admin,
      handler: (ctx) async {
        final ws = await workspaceRepository.getById(ctx.workspaceId!);
        if (ws == null) {
          throw const NotFoundException('Workspace not found');
        }
        final status = await apps.status(ws, probe: true);
        return {...status.toJson(), 'connect_mode': ws.connectMode.wireName};
      },
    ),
  ];
}
