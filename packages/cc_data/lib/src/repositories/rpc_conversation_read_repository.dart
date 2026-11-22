import 'package:cc_domain/core/domain/value_objects/feed_position.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_read_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [ConversationReadRepository] over the host's `conversation_read.*` op
/// and subscription.
///
/// The server resolves the acting user from the session's authenticated
/// device credential; the `userId` the interface carries is never sent over
/// the wire, so a client cannot read or move another person's cursor. Both
/// calls name their `workspace_id` explicitly rather than leaning on the
/// client's ambient active workspace, which can flip mid-call on a switch.
class RpcConversationReadRepository implements ConversationReadRepository {
  /// Creates an [RpcConversationReadRepository] over [_client].
  RpcConversationReadRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Future<void> markConversationRead(
    String workspaceId,
    String conversationId,
    String userId,
  ) => _client.call('conversation_read.markRead', {
    'workspace_id': workspaceId,
    'conversation_id': conversationId,
  });

  @override
  Stream<Map<String, FeedPosition>> watchUserConversationReads(
    String workspaceId,
    String userId,
  ) => _client
      .subscribe('conversation_read.watchUserReads', {
        'workspace_id': workspaceId,
      })
      .map(
        (data) => {
          for (final row in (data['reads'] as List? ?? const []))
            if (row is Map && row['conversation_id'] is String)
              row['conversation_id'] as String: ?FeedPosition.fromJson(
                row['last_read'],
              ),
        },
      );
}
