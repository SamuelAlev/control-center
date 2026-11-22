import 'package:cc_data/src/wire_decode.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_peer_asks_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_rpc/cc_rpc.dart';

DateTime? _at(Object? raw) => raw is String ? DateTime.parse(raw) : null;

/// Decodes one `peerAsks.watchForConversation` row. Throws on a row the
/// client cannot read (an unknown kind, mode or status), which `decodeRows`
/// drops.
PeerAskView peerAskViewFromWire(Map<String, dynamic> w) => PeerAskView(
  id: w['id'] as String,
  workspaceId: w['workspace_id'] as String,
  kind:
      PeerAskKindWire.tryParse(w['kind'] as String?) ??
      (throw FormatException('unknown ask kind ${w['kind']}')),
  mode:
      PeerAskModeWire.tryParse(w['mode'] as String?) ??
      (throw FormatException('unknown ask mode ${w['mode']}')),
  status:
      PeerAskStatusWire.tryParse(w['status'] as String?) ??
      (throw FormatException('unknown ask status ${w['status']}')),
  askerAgentId: w['asker_agent_id'] as String,
  askerConversationId: w['asker_conversation_id'] as String,
  recipientAgentId: w['recipient_agent_id'] as String,
  recipientConversationId: w['recipient_conversation_id'] as String?,
  questionMessageId: w['question_message_id'] as String?,
  replyMessageId: w['reply_message_id'] as String?,
  replyInline: w['reply_inline'] == true,
  error: w['error'] as String?,
  createdAt: DateTime.parse(w['created_at'] as String),
  expiresAt: DateTime.parse(w['expires_at'] as String),
  settledAt: _at(w['settled_at']),
  promisedAt: _at(w['promised_at']),
  blockedNoticedAt: _at(w['blocked_noticed_at']),
);

/// [ConversationPeerAsksRepository] over the `peerAsks.*` RPC ops.
class RpcConversationPeerAsksRepository
    implements ConversationPeerAsksRepository {
  /// Creates the repository over [_client].
  RpcConversationPeerAsksRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Stream<List<PeerAskView>> watchForConversation(
    String workspaceId,
    String conversationId,
  ) => _client
      .subscribe('peerAsks.watchForConversation', {
        'workspace_id': workspaceId,
        'conversation_id': conversationId,
      })
      .map(
        (data) => decodeRows(
          [
            for (final row in (data['asks'] as List?) ?? const [])
              if (row is Map) row.cast<String, dynamic>(),
          ],
          peerAskViewFromWire,
          what: 'ask',
        ),
      );

  @override
  Future<bool> cancel(String workspaceId, String askId) async {
    final data = await _client.call('peerAsks.cancel', {
      'workspace_id': workspaceId,
      'ask_id': askId,
    });
    return data['cancelled'] == true;
  }
}
