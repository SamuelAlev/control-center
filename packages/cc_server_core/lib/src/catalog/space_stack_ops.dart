import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_domain/features/messaging/domain/ports/space_stack_port.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/cc_host.dart';

/// Stack ops for one space's checkout.
///
/// Always registered. A host with no [stack] answers an empty list and
/// refuses mutations, so a client call is never an unknown op.
///
/// Cut and checkout stay inside the isolated copy (the same containment as
/// `worktree.checkout`) and declare no effect class. Publish pushes and opens
/// pull requests, so it declares both.
List<RepoOp> buildSpaceStackOps({required SpaceStackPort? stack}) => [
  RepoOp(
    name: 'stack.list',
    kind: RepoOpKind.read,
    requiredArgs: const ['workspace_id', 'space_id'],
    handler: (ctx) async {
      if (stack == null) {
        return const {'ok': true, 'entries': <Object>[], 'dirty': false};
      }
      final view = await stack.list(
        workspaceId: ctx.workspaceId!,
        spaceId: ctx.args['space_id'] as String,
      );
      return view.toWire();
    },
  ),
  RepoOp(
    name: 'stack.cut',
    kind: RepoOpKind.mutate,
    requiredArgs: const ['workspace_id', 'space_id', 'name'],
    handler: (ctx) async {
      if (stack == null) {
        return const {'ok': false, 'error': 'stacks are not available'};
      }
      final view = await stack.cut(
        workspaceId: ctx.workspaceId!,
        spaceId: ctx.args['space_id'] as String,
        name: ctx.args['name'] as String,
        repoId: ctx.args['repo_id'] as String?,
        at: ctx.args['at'] as String?,
      );
      return view.toWire();
    },
  ),
  RepoOp(
    name: 'stack.checkout',
    kind: RepoOpKind.mutate,
    requiredArgs: const ['workspace_id', 'space_id', 'branch'],
    handler: (ctx) async {
      if (stack == null) {
        return const {'ok': false, 'error': 'stacks are not available'};
      }
      final view = await stack.checkout(
        workspaceId: ctx.workspaceId!,
        spaceId: ctx.args['space_id'] as String,
        branch: ctx.args['branch'] as String,
        repoId: ctx.args['repo_id'] as String?,
      );
      return view.toWire();
    },
  ),
  RepoOp(
    name: 'stack.publish',
    kind: RepoOpKind.mutate,
    actionClasses: const {ActionClass.gitPush, ActionClass.prCreate},
    requiredArgs: const ['workspace_id', 'space_id'],
    handler: (ctx) async {
      if (stack == null) {
        return const {'ok': false, 'error': 'stacks are not available'};
      }
      final view = await stack.publish(
        workspaceId: ctx.workspaceId!,
        spaceId: ctx.args['space_id'] as String,
        repoId: ctx.args['repo_id'] as String?,
        actingUserId: ctx.userId,
        draft: ctx.args['draft'] as bool? ?? true,
      );
      return view.toWire();
    },
  ),
];
