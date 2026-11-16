import 'package:cc_domain/cc_domain.dart'
    show
        NotFoundException,
        RepoOpKind,
        ValidationException,
        WorkspaceMismatchException;
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_outline_entry.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, WatchQuery;
import 'package:cc_server_core/src/catalog/catalog_wire.dart'
    show messageToWireLite;
import 'package:cc_server_core/src/catalog/pr_data_gate.dart';

/// The most messages a range subscription reads on either side of its
/// anchor.
const int maxMessagesRangeSide = 200;

/// The conversation feed's whole-conversation reads, beside the newest-N
/// window (`messaging.watchMessagesWindow`):
///
/// * `messaging.getConversationOutline` — one compact entry per live
///   message, so a scrollbar can span the whole conversation while only a
///   window of it is loaded.
/// * `messaging.watchMessagesRange` — the messages around an anchor (a
///   permalink, a scrollbar drag), so jumping far back does not grow the
///   newest-N window to reach it.
///
/// Both read a conversation's content, so both gate as the window does: the
/// space is the call's workspace's and passes [prData]'s space gate for the caller,
/// and the watch streams through `guardSpace`. Unlike the window, the
/// conversation is checked against the space: it must be one of the space's
/// own, read off the conversation itself, so owning one space never reads
/// another's conversation. The repository reads are scoped by the space as
/// well.
({List<RepoOp> ops, List<WatchQuery> watches}) buildConversationOutlineOps({
  required MessagingRepository messaging,
  required ConversationRepository conversations,
  required PrDataGate prData,
}) {
  // The space is this workspace's and the caller may read it; the
  // conversation is that space's.
  Future<({String spaceId, String conversationId})> requireConversation(
    String workspaceId,
    String userId,
    Map<String, dynamic> args,
  ) async {
    final spaceId = args['space_id'];
    final conversationId = args['conversation_id'];
    if (spaceId is! String || spaceId.isEmpty) {
      throw const NotFoundException('Missing space_id');
    }
    if (conversationId is! String || conversationId.isEmpty) {
      throw const NotFoundException('Missing conversation_id');
    }
    if (await messaging.getSpaceById(workspaceId, spaceId) == null) {
      throw const WorkspaceMismatchException(
        'Space belongs to a different workspace',
      );
    }
    await prData.requireSpace(workspaceId, userId, spaceId);
    final conversation = await conversations.getById(
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    if (conversation == null ||
        conversation.workspaceId != workspaceId ||
        conversation.spaceId != spaceId) {
      throw const NotFoundException('Conversation not found in this space');
    }
    return (spaceId: spaceId, conversationId: conversationId);
  }

  int side(Object? raw) => raw is num
      ? raw.toInt().clamp(0, maxMessagesRangeSide)
      : throw const ValidationException('before and after must be numbers');

  return (
    ops: [
      RepoOp(
        name: 'messaging.getConversationOutline',
        kind: RepoOpKind.read,
        requiredArgs: ['space_id', 'conversation_id'],
        handler: (ctx) async {
          final target = await requireConversation(
            ctx.workspaceId!,
            ctx.userId,
            ctx.args,
          );
          final outline = await messaging.getConversationOutline(
            ctx.workspaceId!,
            target.spaceId,
            target.conversationId,
          );
          return {'entries': outline.map(outlineEntryToWire).toList()};
        },
      ),
    ],
    watches: [
      WatchQuery(
        name: 'messaging.watchMessagesRange',
        handler: (ctx) async* {
          final anchorId = ctx.args['anchor_id'];
          if (anchorId is! String || anchorId.isEmpty) {
            throw const NotFoundException('Missing anchor_id');
          }
          final before = side(ctx.args['before']);
          final after = side(ctx.args['after']);
          final target = await requireConversation(
            ctx.workspaceId!,
            ctx.userId,
            ctx.args,
          );
          yield* prData.guardSpace(
            ctx.workspaceId!,
            ctx.userId,
            target.spaceId,
            messaging
                .watchMessagesRange(
                  ctx.workspaceId!,
                  target.spaceId,
                  target.conversationId,
                  anchorId: anchorId,
                  before: before,
                  after: after,
                )
                .map(
                  (range) => {
                    'messages': range.messages.map(messageToWireLite).toList(),
                    'has_older': range.hasOlder,
                    'has_newer': range.hasNewer,
                  },
                ),
          );
        },
      ),
    ],
  );
}

/// One outline entry as the compact array the wire carries: `[id,
/// created_at_ms, sender_id, sender_type, message_type, content_chars,
/// segment_count?, steer_state?, answered (0/1), revision]`.
///
/// Sender and message type are in the message wire's form (`.name`, as
/// `messageToWire` sends them); the steer state in its stored form. A
/// 5,000-message conversation is a few hundred kilobytes this way, not the
/// megabytes keyed objects would cost.
List<Object?> outlineEntryToWire(ConversationOutlineEntry e) => [
  e.id,
  e.createdAt.millisecondsSinceEpoch,
  e.senderId,
  e.senderType.name,
  e.messageType.name,
  e.contentChars,
  e.segmentCount,
  e.steerState?.wire,
  if (e.answered) 1 else 0,
  e.revision,
];
