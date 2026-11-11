import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, RepoOpKind, ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, RepoOpContext;
import 'package:cc_server_core/src/forge/forge_automation_tokens.dart';

/// The workspace's linked repositories.
typedef AutomationLinkedRepos = Future<List<Repo>> Function(String workspaceId);

/// `forge.listAutomationTokens`, `forge.setAutomationToken` and
/// `forge.clearAutomationToken`: the GitLab/Bitbucket automation-token slots
/// (see [ForgeAutomationTokens]). Admin-only, workspace-scoped (the
/// dispatcher validates the workspace, then membership and the admin role,
/// before a handler runs). A token goes in and never comes back out: the
/// list carries presence, the bot's name, the slot and status.
///
/// `repo_id` names a repository linked to the bound workspace (refused
/// otherwise); absent, the op is about the workspace's slot for `forge`.
/// [onChanged] runs after a save or clear (the open-PR poller re-sweeps the
/// workspace). Empty when no store is wired (demo).
List<RepoOp> buildForgeAutomationTokenOps({
  required ForgeAutomationTokens? tokens,
  required AutomationLinkedRepos linkedRepos,
  void Function(String workspaceId)? onChanged,
}) {
  if (tokens == null) {
    return const [];
  }

  ForgeHost forgeOf(RepoOpContext ctx) {
    final forge = ForgeHost.fromWire(ctx.args['forge'] as String?);
    if (!ForgeAutomationTokens.supports(forge)) {
      throw const ValidationException(
        'Automation tokens are for GitLab and Bitbucket.',
      );
    }
    return forge;
  }

  Future<Repo?> repoOf(RepoOpContext ctx, List<Repo> linked) async {
    final id = ctx.args['repo_id'];
    if (id == null) {
      return null;
    }
    if (id is! String || id.isEmpty) {
      throw const ValidationException('Invalid argument: repo_id');
    }
    for (final repo in linked) {
      if (repo.id == id) {
        return repo;
      }
    }
    // Not linked here (another workspace's, or gone): the same answer
    // either way, so nothing about other workspaces leaks.
    throw const NotFoundException('No such repository in this workspace.');
  }

  return [
    RepoOp(
      name: 'forge.listAutomationTokens',
      kind: RepoOpKind.read,
      minRole: WorkspaceRole.admin,
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final linked = await linkedRepos(workspaceId);
        return {
          'tokens': [
            for (final info in await tokens.list(workspaceId, linked))
              info.toJson(),
          ],
        };
      },
    ),
    RepoOp(
      name: 'forge.setAutomationToken',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.admin,
      requiredArgs: ['forge', 'token'],
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final forge = forgeOf(ctx);
        final token = ctx.args['token'];
        if (token is! String) {
          throw const ValidationException('Invalid argument: token');
        }
        final linked = await linkedRepos(workspaceId);
        final repo = await repoOf(ctx, linked);
        final saved = await tokens.save(
          workspaceId,
          forge: forge,
          token: token,
          linked: linked,
          repo: repo,
        );
        onChanged?.call(workspaceId);
        return {...saved.info.toJson(), 'unreadable_repos': saved.unreadable};
      },
    ),
    RepoOp(
      name: 'forge.clearAutomationToken',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.admin,
      requiredArgs: ['forge'],
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final forge = forgeOf(ctx);
        final linked = await linkedRepos(workspaceId);
        final repo = await repoOf(ctx, linked);
        final cleared = await tokens.clear(
          workspaceId,
          forge: forge,
          linked: linked,
          repoId: repo?.id,
        );
        onChanged?.call(workspaceId);
        return {'cleared': cleared};
      },
    ),
  ];
}
