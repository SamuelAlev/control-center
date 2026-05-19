import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_kind.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [ConversationRepository] backed by the RPC client (`conversation.*` ops +
/// the `conversation.watchForChannel` subscription).
///
/// Every call names its `workspace_id`: the host is stateless and binds no
/// session workspace, and the client's ambient active workspace follows the
/// route — so it is the wrong scope for a keyed caller and absent entirely
/// before a workspace is open.
class RpcConversationRepository implements ConversationRepository {
  /// Creates an [RpcConversationRepository] over [_client].
  RpcConversationRepository(this._client);

  final RemoteRpcClient _client;

  static Conversation _fromWire(Map<String, dynamic> m) {
    final ws = m['workspace_id'] as String?;
    return Conversation(
      id: m['id'] as String? ?? '',
      workspaceId: (ws == null || ws.isEmpty) ? null : ws,
      channelId: m['channel_id'] as String? ?? '',
      title: m['title'] as String? ?? 'Main',
      kind: ConversationKind.fromWire(m['kind'] as String?),
      status: ConversationStatus.fromWire(m['status'] as String?),
      createdByPrincipalId: m['created_by_principal_id'] as String?,
      createdAt:
          DateTime.tryParse(m['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(m['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static List<Conversation> _list(Map<String, dynamic> data) =>
      ((data['conversations'] as List?) ?? const [])
          .whereType<Map>()
          .map((c) => _fromWire(c.cast<String, dynamic>()))
          .toList();

  @override
  Future<Conversation> ensureMain({
    required String workspaceId,
    required String channelId,
  }) async {
    final data = await _client.call('conversation.ensureMain', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
    });
    return _fromWire((data['conversation'] as Map).cast<String, dynamic>());
  }

  @override
  Future<Conversation> create({
    required String workspaceId,
    required String channelId,
    required String title,
    required Conversation conversation,
  }) async {
    final data = await _client.call('conversation.create', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'title': title,
    });
    return _fromWire((data['conversation'] as Map).cast<String, dynamic>());
  }

  @override
  Future<void> rename({
    required String workspaceId,
    required String conversationId,
    required String title,
  }) => _client.call('conversation.rename', {
    'workspace_id': workspaceId,
    'conversation_id': conversationId,
    'title': title,
  });

  @override
  Future<void> setStatus({
    required String workspaceId,
    required String conversationId,
    required ConversationStatus status,
  }) => _client.call('conversation.archive', {
    'workspace_id': workspaceId,
    'conversation_id': conversationId,
    'reopen': status == ConversationStatus.active,
  });

  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async {
    final list = await _client.call('conversation.list', {
      'workspace_id': workspaceId,
      // No dedicated get op; list then find. Channel unknown here, so this is
      // only used where the caller already has the list — kept for interface
      // completeness.
      'channel_id': conversationId,
    });
    return _list(list).where((c) => c.id == conversationId).firstOrNull;
  }

  @override
  Future<List<Conversation>> listForChannel({
    required String workspaceId,
    required String channelId,
  }) async {
    final data = await _client.call('conversation.list', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
    });
    return _list(data);
  }

  @override
  Stream<List<Conversation>> watchForChannel({
    required String workspaceId,
    required String channelId,
  }) => _client
      .subscribe('conversation.watchForChannel', {
        'workspace_id': workspaceId,
        'channel_id': channelId,
      })
      .map(_list);
}
