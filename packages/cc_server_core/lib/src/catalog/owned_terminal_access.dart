import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/environment_ops.dart'
    show RepoReadGrantCheck;

/// Whether the caller of [ctx] may type into, resize or close terminal
/// [sessionId].
///
/// A person's own terminal is the port's to check (only its opener reaches
/// it). An owned session (an environment's start or process) runs on the
/// host, so driving it takes what `environment.ensure` takes in its
/// space: the space is in the workspace and the caller's, and the caller
/// holds a write grant (admins implicitly) on every repo the space exposes,
/// each readable through their own forge sign-in. False means the caller is
/// treated as if the session did not exist.
Future<bool> mayDriveTerminal(
  RepoOpContext ctx, {
  required String sessionId,
  required TerminalSessionPort terminals,
  required WorkspaceMembershipRepository? members,
  required RepoAccessRepoResolver reposExposedBySpace,
  required RepoReadGrantCheck requireRepoForgeRead,
  required Future<void> Function(
    String workspaceId,
    String spaceId,
    String userId,
  )
  assertSpaceOwned,
}) async {
  final owned = terminals.ownedSessionOf(sessionId);
  if (owned == null) {
    return true;
  }
  final spaceId = owned.spaceId;
  if (spaceId == null) {
    return false;
  }
  return mayOperateEnvironment(
    ctx,
    spaceId: spaceId,
    members: members,
    reposExposedBySpace: reposExposedBySpace,
    requireRepoForgeRead: requireRepoForgeRead,
    assertSpaceOwned: assertSpaceOwned,
  );
}

/// Refuses the caller of [ctx] watching terminal `session_id` when it is an
/// owned session (an environment's start or process, which every member of
/// the workspace could otherwise read) of a space they may not read. Null
/// when there is nothing to ask: a person's own session is the port's to
/// check, so its stream opens at once.
Future<void>? requireTerminalView(
  RepoOpContext ctx, {
  required TerminalSessionPort terminals,
  required Future<void> Function(
    String workspaceId,
    String spaceId,
    String userId,
  )
  assertSpaceOwned,
}) {
  final sessionId = ctx.args['session_id'];
  final spaceId = sessionId is String
      ? terminals.ownedSessionOf(sessionId)?.spaceId
      : null;
  return spaceId == null
      ? null
      : assertSpaceOwned(ctx.workspaceId!, spaceId, ctx.userId);
}

/// Whether the caller of [ctx] may operate the environment of [spaceId]:
/// what `environment.ensure` takes there. The space is in the workspace
/// and the caller's, and the caller holds a write grant (admins implicitly)
/// on every repo the space exposes, each readable through their own forge
/// sign-in.
///
/// Driving an environment's terminal ([mayDriveTerminal]) is the same right;
/// clients get it as `can_drive` and `can_operate` so they can disable what
/// would be refused.
Future<bool> mayOperateEnvironment(
  RepoOpContext ctx, {
  required String spaceId,
  required WorkspaceMembershipRepository? members,
  required RepoAccessRepoResolver reposExposedBySpace,
  required RepoReadGrantCheck requireRepoForgeRead,
  required Future<void> Function(
    String workspaceId,
    String spaceId,
    String userId,
  )
  assertSpaceOwned,
}) async {
  final workspaceId = ctx.workspaceId;
  if (workspaceId == null || members == null) {
    return false;
  }
  try {
    await assertSpaceOwned(workspaceId, spaceId, ctx.userId);
    final member = await members.getMember(workspaceId, ctx.userId);
    if (member == null) {
      return false;
    }
    final grants = member.role.isAdmin
        ? null
        : await members.getRepoGrants(workspaceId, ctx.userId);
    final repos = await reposExposedBySpace(
      RepoOpContext(
        args: {'space_id': spaceId},
        workspaceId: workspaceId,
        deviceId: ctx.deviceId,
        userId: ctx.userId,
        role: ctx.role,
      ),
    );
    for (final repoId in repos) {
      if (grants != null &&
          !(grants[repoId] ?? RepoGrantLevel.none).atLeast(
            RepoGrantLevel.write,
          )) {
        return false;
      }
      await requireRepoForgeRead(
        workspaceId: workspaceId,
        userId: ctx.userId,
        repoId: repoId,
      );
    }
    return true;
  } on AppException {
    return false;
  }
}
