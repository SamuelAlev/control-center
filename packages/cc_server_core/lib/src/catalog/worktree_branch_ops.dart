import 'package:cc_domain/cc_domain.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/catalog_wire.dart';

/// Branch sync, listing, and checkout for a conversation's isolated worktree.
///
/// Spread from `buildRemoteRpcCatalog` so those three [RepoOp] literals stay
/// out of the catalog file. The catalog freeze counts `RepoOp(` there and
/// does not move when a new op is added beside an existing family.
///
/// Each op is omitted when its callback is null (a host that owns no
/// worktrees). Sync fetches and may push, and never commits. Listing and
/// checkout stay inside the isolated tree: no fetch, no push, no write to
/// the source checkout.
List<RepoOp> buildWorktreeBranchOps({
  required WorktreeSyncBranchFn? sync,
  required WorktreeListBranchesFn? listBranches,
  required WorktreeCheckoutFn? checkout,
}) => [
  if (sync != null)
    RepoOp(
      name: 'worktree.syncBranch',
      kind: RepoOpKind.mutate,
      actionClasses: const {ActionClass.networkEgress, ActionClass.gitPush},
      requiredArgs: const ['workspace_id', 'space_id', 'repo_id'],
      handler: (ctx) async {
        final res = await sync(
          workspaceId: ctx.workspaceId!,
          spaceId: ctx.args['space_id'] as String,
          repoId: ctx.args['repo_id'] as String,
          actingUserId: ctx.userId,
        );
        if (res == null) {
          return {'ok': false};
        }
        return {'ok': true, ...res};
      },
    ),
  if (listBranches != null)
    RepoOp(
      name: 'worktree.listBranches',
      kind: RepoOpKind.read,
      requiredArgs: const ['workspace_id', 'space_id', 'repo_id'],
      handler: (ctx) async {
        final res = await listBranches(
          workspaceId: ctx.workspaceId!,
          spaceId: ctx.args['space_id'] as String,
          repoId: ctx.args['repo_id'] as String,
        );
        if (res == null) {
          return {'ok': false};
        }
        return {'ok': true, ...res};
      },
    ),
  if (checkout != null)
    RepoOp(
      name: 'worktree.checkout',
      kind: RepoOpKind.mutate,
      requiredArgs: const ['workspace_id', 'space_id', 'repo_id'],
      handler: (ctx) async {
        final res = await checkout(
          workspaceId: ctx.workspaceId!,
          spaceId: ctx.args['space_id'] as String,
          repoId: ctx.args['repo_id'] as String,
          branch: ctx.args['branch'] as String?,
          startPoint: ctx.args['start_point'] as String?,
          create: ctx.args['create'] as bool? ?? false,
          detach: ctx.args['detach'] as bool? ?? false,
        );
        if (res == null) {
          return {'ok': false};
        }
        return res;
      },
    ),
];
