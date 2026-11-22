import 'package:cc_domain/cc_domain.dart'
    show RepoOpKind, ValidationException, WorkspaceMismatchException;
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show WakeQueueService;

/// The state reason of a wake a person cancelled.
const String wakeCancelledByPersonReason = 'cancelled_by_person';

/// The `wakes` pack: what a person sees of a conversation's waiting wakes
/// and the three things they can do with one (cancel it, release a held one,
/// deliver one now). Members who may read the conversation's space; the
/// workspace of a wake or conversation comes from the record, and an id that
/// is not in the caller's workspace is a [WorkspaceMismatchException]. A
/// wake that acts for a person is released or delivered only by that person
/// (`AuthException`, kind `wake_not_yours`); anyone with the space may
/// cancel one.
///
/// A pack the catalog spreads, so `remote_rpc_catalog.dart` does not grow.
/// Empty when the host wires no wake queue.
({List<RepoOp> ops, List<WatchQuery> watches}) buildWakeOps({
  required WakeQueueService Function()? wakeQueue,
  required WakeRepository? wakes,
  required ConversationRepository conversations,
  required Future<void> Function(
    String workspaceId,
    String userId,
    String spaceId,
  )
  requireSpace,
  required Stream<Map<String, dynamic>> Function(
    String workspaceId,
    String userId,
    String spaceId,
    Stream<Map<String, dynamic>> source,
  )
  guardSpace,
}) {
  if (wakeQueue == null || wakes == null) {
    return (ops: const [], watches: const []);
  }

  // The wake is the caller's workspace's and its space readable to them.
  Future<Wake> requireWake(RepoOpContext ctx) async {
    final id = ctx.args['wake_id'];
    if (id is! String || id.isEmpty) {
      throw const ValidationException('Missing wake_id');
    }
    final wake = await wakes.getById(ctx.workspaceId!, id);
    if (wake == null) {
      throw const WorkspaceMismatchException(
        'Wake not found in this workspace',
      );
    }
    await requireSpace(ctx.workspaceId!, ctx.userId, wake.spaceId);
    return wake;
  }

  // The conversation is the caller's workspace's; returns its space.
  Future<String> requireConversation(
    String workspaceId,
    String userId,
    Object? conversationId,
  ) async {
    if (conversationId is! String || conversationId.isEmpty) {
      throw const ValidationException('Missing conversation_id');
    }
    final conversation = await conversations.getById(
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    if (conversation == null || conversation.workspaceId != workspaceId) {
      throw const WorkspaceMismatchException(
        'Conversation not found in this workspace',
      );
    }
    await requireSpace(workspaceId, userId, conversation.spaceId);
    return conversation.spaceId;
  }

  return (
    ops: [
      RepoOp(
        name: 'wakes.cancel',
        kind: RepoOpKind.mutate,
        requiredArgs: ['wake_id'],
        minRole: WorkspaceRole.member,
        handler: (ctx) async {
          final wake = await requireWake(ctx);
          final cancelled = await wakeQueue().cancel(
            ctx.workspaceId!,
            wake.id,
            reason: wakeCancelledByPersonReason,
          );
          return {'cancelled': cancelled};
        },
      ),
      // Held wakes (a person's stop, a recovery waiting for Resume) go back
      // to pending and are delivered: one wake, or the conversation's.
      RepoOp(
        name: 'wakes.release',
        kind: RepoOpKind.mutate,
        minRole: WorkspaceRole.member,
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          if (ctx.args['wake_id'] != null) {
            final wake = await requireWake(ctx);
            return {
              'released': await wakeQueue().release(
                workspaceId,
                wakeId: wake.id,
                userId: ctx.userId,
              ),
            };
          }
          final conversationId = ctx.args['conversation_id'];
          await requireConversation(workspaceId, ctx.userId, conversationId);
          return {
            'released': await wakeQueue().release(
              workspaceId,
              conversationId: conversationId as String,
              userId: ctx.userId,
            ),
          };
        },
      ),
      RepoOp(
        name: 'wakes.deliverNow',
        kind: RepoOpKind.mutate,
        requiredArgs: ['wake_id'],
        minRole: WorkspaceRole.member,
        handler: (ctx) async {
          final wake = await requireWake(ctx);
          if (wake.state.isSettled) {
            throw const ValidationException(
              'That wake has already settled',
              code: 'wake_settled',
            );
          }
          return wakeReceiptToWire(
            await wakeQueue().deliverNow(
              ctx.workspaceId!,
              wake.id,
              userId: ctx.userId,
            ),
          );
        },
      ),
    ],
    watches: [
      WatchQuery(
        name: 'wakes.watchForConversation',
        minRole: WorkspaceRole.member,
        handler: (ctx) async* {
          final workspaceId = ctx.workspaceId!;
          final conversationId = ctx.args['conversation_id'];
          final spaceId = await requireConversation(
            workspaceId,
            ctx.userId,
            conversationId,
          );
          yield* guardSpace(
            workspaceId,
            ctx.userId,
            spaceId,
            wakes
                .watchForConversation(workspaceId, conversationId as String)
                .map(
                  (list) => {
                    'wakes': [
                      for (final wake in list)
                        if (wake.workspaceId == workspaceId)
                          wakeToWire(wake, viewerId: ctx.userId),
                    ],
                  },
                ),
          );
        },
      ),
    ],
  );
}

/// A waiting wake as a client sees it: what it is (reason, origin label,
/// first line), when (not before), where it is (state, its reason, lane),
/// and whether [viewerId] may release or deliver it (`can_release`, the
/// server's answer; a client never compares ids itself), plus the ids of
/// what raised it (`source_agent_id`, `goal_id`, `rule_id`, `ask_id`, each
/// left out when absent) so a client can name the source and link the
/// record. The payload is the agent's data and is not sent.
Map<String, dynamic> wakeToWire(Wake wake, {required String viewerId}) => {
  'id': wake.id,
  'workspace_id': wake.workspaceId,
  'space_id': wake.spaceId,
  'conversation_id': wake.conversationId,
  'agent_id': wake.agentId,
  'reason': wake.reason.wire,
  'origin': wakeLabel(wake),
  'headline': wakeHeadline(wake),
  'state': wake.state.wire,
  'state_reason': ?wake.stateReason,
  'lane': wake.lane.wire,
  'not_before': wake.notBefore.toUtc().toIso8601String(),
  'expires_at': ?wake.expiresAt?.toUtc().toIso8601String(),
  'created_at': wake.createdAt.toUtc().toIso8601String(),
  'requested_by_user_id': ?wake.requestedByUserId,
  'attempt': wake.attempt,
  'can_release': WakeQueueService.mayAct(wake, viewerId),
  'source_agent_id': ?wake.detail.sourceAgentId,
  'goal_id': ?wake.detail.goalId,
  'rule_id': ?wake.detail.ruleId,
  'ask_id': ?wake.detail.askId,
};

/// A delivery receipt on the wire: `outcome` (`started`, `pushed`,
/// `waiting`, `skipped`, `duplicate`), `run_id` for the first two, `kind`
/// for the next two.
Map<String, dynamic> wakeReceiptToWire(WakeReceipt receipt) =>
    switch (receipt) {
      WakeStarted(:final runId) => {'outcome': 'started', 'run_id': runId},
      WakePushed(:final runId) => {'outcome': 'pushed', 'run_id': runId},
      WakeWaiting(:final kind) => {'outcome': 'waiting', 'kind': kind},
      WakeSkipped(:final kind) => {'outcome': 'skipped', 'kind': kind},
      WakeDuplicate() => {'outcome': 'duplicate'},
    };
