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

/// The write gate of steering: whether the caller holds the write grant on
/// every repository the space exposes (so their card may enter a live run
/// that does not act for them); throws the gate's own refusal
/// ([RepoGrantRequiredException]) when the text would reach such a run now
/// and they do not. A space with no repositories passes.
typedef SteeringWriteGate =
    Future<bool> Function(
      RepoOpContext ctx,
      String spaceId,
      String conversationId,
    );

/// Builds the [SteeringWriteGate] over [requireSpaceWrite]
/// (`SpaceRepoAccess.requireWrite`). A person with read access must not
/// steer a run that acts on someone else's forge sign-in (or on nobody's):
/// their own run could not have pushed.
SteeringWriteGate steeringWriteGate({
  required SteeringQueueService? steeringQueue,
  required Future<void> Function(
    String workspaceId,
    String userId,
    String spaceId,
  )
  requireSpaceWrite,
}) => (ctx, spaceId, conversationId) async {
  final workspaceId = ctx.workspaceId!;
  try {
    await requireSpaceWrite(workspaceId, ctx.userId, spaceId);
    return true;
  } on RepoGrantRequiredException {
    if (await steeringQueue?.steersAnother(
          workspaceId,
          conversationId,
          ctx.userId,
        ) ??
        false) {
      rethrow;
    }
    return false;
  }
};

/// `steering.update` (only its writer edits a card), `steering.deliver`,
/// `steering.forceSend`: "send now" on a queued card, as one server step,
/// and `steering.release`: resume the cards a person's stop held.
/// `deliver` and `forceSend` pass [steerGate] first.
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
  required SteeringWriteGate steerGate,
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
      name: 'steering.update',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id', 'conversation_id', 'message_id', 'message'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId, ctx.userId);
        // Only its writer: the card is sent as them
        // (`steering_not_yours` otherwise).
        final ok = await steeringQueue.edit(
          workspaceId: ctx.workspaceId!,
          conversationId: ctx.args['conversation_id'] as String,
          messageId: ctx.args['message_id'] as String,
          content: ctx.args['message'] as String,
          callerId: ctx.userId,
        );
        return {'ok': ok};
      },
    ),
    RepoOp(
      name: 'steering.deliver',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id', 'conversation_id', 'message_id'],
      handler: (ctx) async {
        final spaceId = ctx.args['space_id'] as String;
        final conversationId = ctx.args['conversation_id'] as String;
        await assertSpaceOwned(ctx.workspaceId!, spaceId, ctx.userId);
        await steerGate(ctx, spaceId, conversationId);
        final delivered = await steeringQueue.deliver(
          workspaceId: ctx.workspaceId!,
          conversationId: conversationId,
          messageId: ctx.args['message_id'] as String,
        );
        return {'delivered': delivered};
      },
    ),
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
        await steerGate(ctx, spaceId, conversationId);
        final outcome = await steeringQueue.forceSend(
          workspaceId: workspaceId,
          spaceId: spaceId,
          conversationId: conversationId,
          messageId: messageId,
          callerId: ctx.userId,
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
    // `steering.release`: the person sends their own cards held under
    // `held_by` (the exact holder a card carries). `stop`: the caller's
    // cards a stop (or a pause that did not resume) held go back to
    // `queued` and, with no run live, are converted and sent the way a
    // run's end sends them; other people's stay held (a release starts a
    // run on its writer's sign-in), and a caller with none while others
    // have some is refused (`steering_not_yours`). `limit:<runId>`:
    // refused (`steering_held_by_limit`, with the reset): a usage-limit
    // pause's cards go out only through its own resume. Same space
    // authorization as `steering.deliver`. Result: `released` (sent) and
    // `kept` (other people's cards still held).
    RepoOp(
      name: 'steering.release',
      kind: RepoOpKind.mutate,
      requiredArgs: ['space_id', 'conversation_id', 'held_by'],
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final spaceId = ctx.args['space_id'] as String;
        final conversationId = ctx.args['conversation_id'] as String;
        final heldBy = ctx.args['held_by'];
        final limit = heldBy is String && heldBy.startsWith('limit:')
            ? heldBy.substring('limit:'.length)
            : null;
        if (heldBy != SteeringQueueService.heldByStop &&
            (limit == null || limit.trim().isEmpty)) {
          throw const ValidationException(
            'held_by must be "stop" or "limit:<runId>".',
          );
        }
        await assertSpaceOwned(workspaceId, spaceId, ctx.userId);
        if (limit != null) {
          throw SteeringHeldByLimitException(
            resetsAt: await steeringQueue.heldResetAt(
              workspaceId: workspaceId,
              spaceId: spaceId,
              conversationId: conversationId,
              heldBy: heldBy as String,
            ),
          );
        }
        final released = await steeringQueue.releaseHeldBy(
          workspaceId: workspaceId,
          spaceId: spaceId,
          conversationId: conversationId,
          heldBy: SteeringQueueService.heldByStop,
          senderId: ctx.userId,
        );
        final kept = (await steeringQueue.heldCards(
          workspaceId: workspaceId,
          spaceId: spaceId,
          conversationId: conversationId,
          heldBy: SteeringQueueService.heldByStop,
        )).where((card) => card.senderId != ctx.userId).length;
        if (released == 0 && kept > 0) {
          throw SteeringNotYoursException(othersHeld: kept);
        }
        return {'released': released, 'kept': kept};
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
