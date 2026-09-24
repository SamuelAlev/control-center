import 'package:cc_domain/cc_domain.dart' show NotFoundException, RepoOpKind;
import 'package:cc_harness/cc_harness.dart' show ActionClass;
import 'package:cc_host/cc_host.dart' show RepoOp;
import 'package:cc_server_core/src/pr_review/pr_merge_conflict_service.dart';

/// `pr_review.mergeConflicts` and `pr_review.fixMergeConflicts`.
///
/// GitHub reports only that a branch conflicts; these name the files (a
/// `git merge-tree` on the server's PR clone) and start an agent resolving
/// them in the PR's space. Both act as the caller. Empty when the host wires
/// no [PrMergeConflictService] (a demo). Injected via `extraOps` so
/// `remote_rpc_catalog.dart` does not grow.
List<RepoOp> buildPrMergeConflictOps(PrMergeConflictService? conflicts) {
  if (conflicts == null) {
    return const [];
  }
  return [
    RepoOp(
      name: 'pr_review.mergeConflicts',
      kind: RepoOpKind.read,
      requiredArgs: ['workspace_id', 'owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = _requireRepoCoords(ctx.args);
        final listed = await conflicts.conflicts(
          workspaceId: ctx.workspaceId!,
          owner: c.owner,
          repo: c.repo,
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          userId: ctx.userId,
        );
        return listed.toWire();
      },
    ),
    RepoOp(
      name: 'pr_review.fixMergeConflicts',
      kind: RepoOpKind.mutate,
      // An agent run is a real process on the host.
      actionClasses: const {ActionClass.processSpawn},
      requiredArgs: ['workspace_id', 'owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = _requireRepoCoords(ctx.args);
        return conflicts.fixConflicts(
          workspaceId: ctx.workspaceId!,
          owner: c.owner,
          repo: c.repo,
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          userId: ctx.userId,
        );
      },
    ),
  ];
}

({String owner, String repo}) _requireRepoCoords(Map<String, dynamic> args) {
  final owner = args['owner'];
  final repo = args['repo'];
  if (owner is! String || owner.isEmpty || repo is! String || repo.isEmpty) {
    throw const NotFoundException('Missing or invalid argument: owner/repo');
  }
  return (owner: owner, repo: repo);
}
