import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/role_definition.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_role_repository.dart';
import 'package:cc_domain/core/domain/services/permission_resolver.dart';
import 'package:cc_domain/core/domain/value_objects/permission.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, RepoOpContext;
import 'package:cc_infra/cc_infra.dart'
    show SteeringForceOutcome, SteeringQueueService;

/// The permission `dispatch.stopRun` derives (a member-floor mutation under
/// `dispatch`). `steering.forceSend` may stop runs only for a caller holding
/// it, so a custom role that may steer but not stop is refused here exactly as
/// it would be on the stop op itself.
const Permission kStopRunPermission = Permission(
  'dispatch',
  PermissionTier.write,
);

/// `steering.forceSend`: "send now" on a queued card, as one server step.
///
/// The client used to orchestrate this as three calls (deliver, reorder, then
/// `dispatch.stopRun` on each run), so a failure halfway left the card
/// reordered with the runs still going, or stopped runs with the card behind
/// others. [SteeringQueueService.forceSend] does it in order on the server.
///
/// A pack the catalog spreads, so `remote_rpc_catalog.dart` does not grow.
/// Absent when the host wires no steering queue.
List<RepoOp> buildSteeringForceOps({
  required SteeringQueueService? steeringQueue,
  required MessagingPort? dispatch,
  required Future<void> Function(
    String workspaceId,
    String spaceId,
    String userId,
  )
  assertSpaceOwned,
  required Future<RoleDefinition?> Function(String workspaceId, String userId)?
  resolveRoleDefinition,
}) {
  if (steeringQueue == null || dispatch == null) {
    return const [];
  }
  Future<bool> mayStop(RepoOpContext ctx) async {
    final resolve = resolveRoleDefinition;
    // No identity wiring (single-user catalogs): the dispatcher applies no
    // role gate either, so neither does this.
    if (resolve == null) {
      return true;
    }
    final role = await resolve(ctx.workspaceId!, ctx.userId);
    return const PermissionResolver()
        .can(
          PermissionPrincipal(userId: ctx.userId, role: role),
          kStopRunPermission,
        )
        .allowed;
  }

  return [
    RepoOp(
      name: 'steering.forceSend',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id', 'conversation_id', 'message_id'],
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final spaceId = ctx.args['space_id'] as String;
        final conversationId = ctx.args['conversation_id'] as String;
        final messageId = ctx.args['message_id'] as String;
        await assertSpaceOwned(workspaceId, spaceId, ctx.userId);
        final outcome = await steeringQueue.forceSend(
          workspaceId: workspaceId,
          spaceId: spaceId,
          conversationId: conversationId,
          messageId: messageId,
          mayStop: await mayStop(ctx),
          stopRun: (runId) => dispatch.stopRun(workspaceId, runId),
        );
        if (outcome == SteeringForceOutcome.stopRefused) {
          throw const AuthException(
            'Sending now needs to stop the running agent, which your role '
            'does not allow.',
          );
        }
        return {'outcome': outcome.wire};
      },
    ),
  ];
}

/// Builds the role-definition resolver [buildSteeringForceOps] checks the
/// stop permission with, from the same membership + custom-role rows the
/// dispatcher's gate reads.
Future<RoleDefinition?> Function(String workspaceId, String userId)?
steeringRoleResolver({
  required WorkspaceMembershipRepository? members,
  required WorkspaceRoleRepository? roles,
}) {
  if (members == null) {
    return null;
  }
  return (workspaceId, userId) async {
    final member = await members.getMember(workspaceId, userId);
    if (member == null) {
      return null;
    }
    final customId = RoleDefinition.customIdOf(member.roleWire);
    if (customId == null || roles == null) {
      return RoleDefinition.preset(member.role);
    }
    // A member holding a role that no longer exists falls back to the base
    // preset — never to something broader (same rule as the dispatcher).
    return await roles.byId(workspaceId, customId) ??
        RoleDefinition.preset(member.role);
  };
}
