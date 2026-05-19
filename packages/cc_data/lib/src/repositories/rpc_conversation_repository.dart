import 'package:cc_data/src/wire_decode.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/thread_summary.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [ConversationRepository] backed by the RPC client (`conversation.*` ops +
/// the `conversation.watchForSpace` subscription).
///
/// Every call names its `workspace_id`: the host is stateless and binds no
/// session workspace and the client's ambient active workspace follows the
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
      spaceId: m['space_id'] as String? ?? '',
      title: m['title'] as String? ?? '',
      status: ConversationStatus.fromWire(m['status'] as String?),
      anchorMessageId: m['anchor_message_id'] as String?,
      createdByPrincipalId: m['created_by_principal_id'] as String?,
      createdAt:
          DateTime.tryParse(m['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(m['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static List<Conversation> _list(Map<String, dynamic> data) => decodeRows(
    ((data['conversations'] as List?) ?? const []).whereType<Map>().map(
      (c) => c.cast<String, dynamic>(),
    ),
    _fromWire,
    what: 'conversation',
  );

  @override
  Future<Conversation> ensure({
    required String workspaceId,
    required String spaceId,
  }) async {
    final data = await _client.call('conversation.ensure', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
    });
    return _fromWire((data['conversation'] as Map).cast<String, dynamic>());
  }

  @override
  Future<Conversation> create({
    required String workspaceId,
    required String spaceId,
    required String title,
    String? anchorMessageId,
    String? createdByPrincipalId,
  }) async {
    final data = await _client.call('conversation.create', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'title': title,
      'anchor_message_id': ?anchorMessageId,
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
    final data = await _client.call('conversation.getById', {
      'workspace_id': workspaceId,
      'conversation_id': conversationId,
    });
    final wire = data['conversation'];
    return wire is Map ? _fromWire(wire.cast<String, dynamic>()) : null;
  }

  @override
  Future<List<Conversation>> listForSpace({
    required String workspaceId,
    required String spaceId,
  }) async {
    final data = await _client.call('conversation.list', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
    });
    return _list(data);
  }

  @override
  Stream<List<Conversation>> watchForSpace({
    required String workspaceId,
    required String spaceId,
  }) => _client
      .subscribe('conversation.watchForSpace', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
      })
      .map(_list);

  @override
  Stream<List<ThreadSummary>> watchThreadSummaries({
    required String workspaceId,
    required String spaceId,
  }) => _client
      .subscribe('conversation.watchThreadSummaries', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
      })
      .map(
        (data) => decodeRows(
          ((data['threads'] as List?) ?? const []).whereType<Map>().map(
            (t) => t.cast<String, dynamic>(),
          ),
          _threadFromWire,
          what: 'thread summary',
        ),
      );

  static ThreadSummary _threadFromWire(Map<String, dynamic> m) => ThreadSummary(
    threadId: m['thread_id'] as String? ?? '',
    anchorMessageId: m['anchor_message_id'] as String? ?? '',
    title: m['title'] as String? ?? '',
    replyCount: (m['reply_count'] as num?)?.toInt() ?? 0,
    lastReplyAt: DateTime.tryParse(m['last_reply_at'] as String? ?? ''),
    participantIds: ((m['participant_ids'] as List?) ?? const [])
        .whereType<String>()
        .toList(growable: false),
  );
}
