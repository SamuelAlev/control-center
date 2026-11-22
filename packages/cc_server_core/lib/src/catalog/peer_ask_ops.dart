import 'package:cc_domain/cc_domain.dart'
    show RepoOpKind, ValidationException, WorkspaceMismatchException;
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/peer_ask_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show PeerAskService;

/// The `peerAsks` pack: the asks an agent made from a conversation (what it
/// waits on there) and a person's one control over one (cancel it). Members
/// who may read the asker's conversation's space; the workspace of an ask or
/// conversation comes from the record, and an id that is not in the
/// caller's workspace is a [WorkspaceMismatchException].
///
/// Cancelling settles the ask `cancelled`: the asker is not woken and the
/// recipient's run is not stopped (plan section 10).
///
/// A pack the catalog spreads, so `remote_rpc_catalog.dart` does not grow.
/// Empty when the host wires no peer asks.
({List<RepoOp> ops, List<WatchQuery> watches}) buildPeerAskOps({
  required PeerAskService? service,
  required PeerAskRepository? asks,
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
  if (service == null || asks == null) {
    return (ops: const [], watches: const []);
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
        name: 'peerAsks.cancel',
        kind: RepoOpKind.mutate,
        requiredArgs: ['ask_id'],
        minRole: WorkspaceRole.member,
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final id = ctx.args['ask_id'];
          if (id is! String || id.isEmpty) {
            throw const ValidationException('Missing ask_id');
          }
          final ask = await asks.getById(workspaceId, id);
          if (ask == null || ask.workspaceId != workspaceId) {
            throw const WorkspaceMismatchException(
              'Ask not found in this workspace',
            );
          }
          // Whoever may read the conversation the ask was made from.
          await requireSpace(workspaceId, ctx.userId, ask.askerSpaceId);
          return {'cancelled': await service.cancel(workspaceId, ask.id)};
        },
      ),
    ],
    watches: [
      WatchQuery(
        name: 'peerAsks.watchForConversation',
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
            asks
                .watchForConversation(workspaceId, conversationId as String)
                .map(
                  (list) => {
                    'asks': [
                      for (final ask in list)
                        if (ask.workspaceId == workspaceId) peerAskToWire(ask),
                    ],
                  },
                ),
          );
        },
      ),
    ],
  );
}

/// An ask as a client sees it: who asked whom from where, what kind and
/// mode, where it stands, and when. Outbound only: the once-only markers
/// (`promised_at`, `blocked_noticed_at`, `stall_noticed_run_id`) are written
/// by the server and never read from a client. The question and the reply
/// are messages, sent by id.
Map<String, dynamic> peerAskToWire(PeerAsk ask) => {
  'id': ask.id,
  'workspace_id': ask.workspaceId,
  'kind': ask.kind.wire,
  'mode': ask.mode.wire,
  'status': ask.status.wire,
  'asker_agent_id': ask.askerAgentId,
  'asker_conversation_id': ask.askerConversationId,
  'asker_space_id': ask.askerSpaceId,
  'recipient_agent_id': ask.recipientAgentId,
  'recipient_conversation_id': ?ask.recipientConversationId,
  'recipient_space_id': ?ask.recipientSpaceId,
  'question_message_id': ?ask.questionMessageId,
  'reply_message_id': ?ask.replyMessageId,
  'reply_inline': ask.replyInline,
  'error': ?ask.error,
  'requested_by_user_id': ?ask.requestedByUserId,
  'created_at': ask.createdAt.toUtc().toIso8601String(),
  'expires_at': ask.expiresAt.toUtc().toIso8601String(),
  'settled_at': ?ask.settledAt?.toUtc().toIso8601String(),
  'promised_at': ?ask.promisedAt?.toUtc().toIso8601String(),
  'blocked_noticed_at': ?ask.blockedNoticedAt?.toUtc().toIso8601String(),
  'stall_noticed_run_id': ?ask.stallNoticedRunId,
};
