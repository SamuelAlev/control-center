import 'package:cc_data/cc_data.dart' show RpcMessagingRepository;
import 'package:cc_data/src/repositories/rpc_messaging_repository.dart'
    show RpcMessagingRepository;
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates channels + messages over the RPC client.
///
/// Mirrors the `messaging.*` ops + the `messaging.watch*` subscriptions. Returns
/// the wire DTOs — the [RpcMessagingRepository] wrapper maps them back to domain
/// entities.
///
/// A workspace id selects the database file server-side, so every op here names
/// its `workspace_id` explicitly rather than leaning on the RPC client's ambient
/// active workspace: that ambient id follows the active route and flips on a
/// workspace switch, independently of the workspace a caller is asking about.
/// Channel, conversation and message ids are uuids, but a uuid is not an access
/// boundary — the workspace scopes the lookup, so an id from another workspace
/// is simply not found. [watchChannels] and [watchChannelActivity] are the
/// documented exceptions: they accept a nullable id for the cross-workspace
/// dashboard views that legitimately follow the ambient workspace.
class RemoteMessagingRepository {
  /// Creates a [RemoteMessagingRepository] over [_client].
  RemoteMessagingRepository(this._client);

  final RemoteRpcClient _client;

  /// Channels in [workspaceId].
  Future<List<ChannelDto>> listChannels(String workspaceId) async {
    final data = await _client.call('messaging.listChannels', {
      'workspace_id': workspaceId,
    });
    return _channels(data);
  }

  /// Messages in [channelId] within [workspaceId]. When [conversationId] is
  /// set, scopes to that conversation (stream).
  Future<List<MessageDto>> getMessages(
    String workspaceId,
    String channelId, {
    String? conversationId,
  }) async {
    final data = await _client.call('messaging.getMessages', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'conversation_id': ?conversationId,
    });
    return _messages(data);
  }

  /// One cursor page of a conversation's history, newest page first.
  ///
  /// The server does the keyset paging, so the wire carries [limit] messages
  /// rather than the conversation. Segments are elided from this shape (the
  /// transcript is opened per message); the live watch keeps the full one.
  Future<({List<MessageDto> messages, bool hasMore, String? nextCursor})>
  getMessagePage(
    String workspaceId,
    String channelId,
    String conversationId, {
    required int limit,
    String? cursor,
  }) async {
    final data = await _client.call('messaging.getMessagePage', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'conversation_id': conversationId,
      'limit': limit,
      'cursor': ?cursor,
    });
    return (
      messages: _messages(data),
      hasMore: data['has_more'] == true,
      nextCursor: data['next_cursor'] as String?,
    );
  }

  /// Full-text search within [channelId] in [workspaceId].
  Future<List<MessageDto>> searchInChannel(
    String workspaceId,
    String channelId,
    String query, {
    int limit = 50,
  }) async {
    final data = await _client.call('messaging.searchInChannel', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'query': query,
      'limit': limit,
    });
    return _messages(data);
  }

  /// A single message by id within [workspaceId], or null when it doesn't
  /// exist there.
  Future<MessageDto?> getMessageById(
    String workspaceId,
    String messageId,
  ) async {
    final data = await _client.call('messaging.getMessageById', {
      'workspace_id': workspaceId,
      'message_id': messageId,
    });
    final message = data['message'];
    return message is Map
        ? MessageDto.fromJson(message.cast<String, dynamic>())
        : null;
  }

  /// Whether a channel row exists in [workspaceId].
  Future<bool> channelExists(String workspaceId, String channelId) async {
    final data = await _client.call('messaging.channelExists', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
    });
    return data['exists'] as bool? ?? false;
  }

  /// Participants of [channelId] within [workspaceId].
  Future<List<ChannelParticipantDto>> getParticipants(
    String workspaceId,
    String channelId,
  ) async {
    final data = await _client.call('messaging.getParticipants', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
    });
    return _participants(data);
  }

  /// Sends a message to [channelId] in [workspaceId]; returns the new message
  /// id. The host stamps the sender from the authenticated device unless a
  /// non-user [senderType] is supplied (the desktop's own trusted in-process
  /// client can post system/agent notices).
  Future<String> sendMessage({
    required String workspaceId,
    required String channelId,
    required String content,
    String? senderId,
    String? senderType,
    String? conversationId,
    String? messageType,
    Map<String, dynamic>? metadata,
    String? id,
  }) async {
    final data = await _client.call('messaging.sendMessage', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'content': content,
      'sender_id': ?senderId,
      'sender_type': ?senderType,
      'conversation_id': ?conversationId,
      'message_type': ?messageType,
      'metadata': ?metadata,
      'id': ?id,
    });
    return data['message_id'] as String;
  }

  /// Updates an existing message's content and/or metadata within
  /// [workspaceId].
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) => _client.call('messaging.updateMessage', {
    'workspace_id': workspaceId,
    'message_id': messageId,
    'content': ?content,
    'metadata': ?metadata,
  }, idempotencyKey: idempotencyKey);

  /// Sets the conversation [mode] (db-string) of [channelId] in [workspaceId].
  Future<void> setChannelMode(
    String workspaceId,
    String channelId,
    String mode,
  ) => _client.call('messaging.setChannelMode', {
    'workspace_id': workspaceId,
    'channel_id': channelId,
    'mode': mode,
  });

  /// Adds [agentId] as a participant of [channelId] in [workspaceId].
  Future<void> addParticipant(
    String workspaceId,
    String channelId,
    String agentId,
  ) => _client.call('messaging.addParticipant', {
    'workspace_id': workspaceId,
    'channel_id': channelId,
    'agent_id': agentId,
  });

  /// Reverts [channelId] in [workspaceId] to [messageId] (undo): every message
  /// after it (or including it when [inclusive]) is hidden but kept for an
  /// unrevert. The host additionally rolls the conversation's worktree back to
  /// that turn's git snapshot when it owns the checkout. Returns the affected
  /// (hidden) message ids and whether the worktree filesystem was rolled back.
  Future<({List<String> affected, bool filesystemRestored})>
  revertConversationTo(
    String workspaceId,
    String channelId,
    String messageId, {
    bool inclusive = false,
  }) async {
    final data = await _client.call('messaging.revertConversationTo', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'message_id': messageId,
      'inclusive': inclusive,
    });
    return (
      affected: ((data['affected_message_ids'] as List?) ?? const [])
          .cast<String>(),
      filesystemRestored: data['filesystem_restored'] as bool? ?? false,
    );
  }

  /// Undoes the most-recent revert (redo) in [channelId] within [workspaceId]:
  /// the latest reverted batch reappears. Returns the restored message ids.
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String channelId,
  ) async {
    final data = await _client.call('messaging.unrevertConversation', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
    });
    return ((data['affected_message_ids'] as List?) ?? const []).cast<String>();
  }

  /// Live channels of [workspaceId] — or of the client's ambient active
  /// workspace when it is omitted (the cross-workspace dashboard view).
  ///
  /// A caller that already knows which workspace it wants MUST pass it: the
  /// ambient id follows the active route and flips independently, so a
  /// workspace-keyed caller (a `family` provider keyed by workspace id) that
  /// relied on the injection could be answered with a DIFFERENT workspace's
  /// channels whenever it (re)subscribes across a switch — and then hand those
  /// foreign channel ids to workspace-scoped surfaces, which the server
  /// rightly rejects. An explicit `workspace_id` in the args wins over the
  /// ambient injection, so the stream is exactly the one the caller asked for.
  Stream<List<ChannelDto>> watchChannels({String? workspaceId}) => _client
      .subscribe('messaging.watchChannels', {'workspace_id': ?workspaceId})
      .map(_channels);

  /// Live messages of a conversation ([conversationId]) inside [channelId],
  /// within [workspaceId].
  Stream<List<MessageDto>> watchMessages(
    String workspaceId,
    String channelId,
    String conversationId,
  ) => _client
      .subscribe('messaging.watchMessages', {
        'workspace_id': workspaceId,
        'channel_id': channelId,
        'conversation_id': conversationId,
      })
      .map(_messages);

  /// Live newest-[limit] window of a conversation in [workspaceId], windowed
  /// SERVER-side so a long conversation never ships its full history per
  /// emission.
  Stream<({List<MessageDto> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String channelId,
    String conversationId, {
    required int limit,
  }) => _client
      .subscribe('messaging.watchMessagesWindow', {
        'workspace_id': workspaceId,
        'channel_id': channelId,
        'conversation_id': conversationId,
        'limit': limit,
      })
      .map(
        (data) => (
          messages: _messages(data),
          hasMore: data['has_more'] as bool? ?? false,
        ),
      );

  /// Raw live turn-relay frames for [channelId] (`seed` / `updates` — see
  /// `channelTurnEventFromWire` for the typed decode).
  ///
  /// Carries no `workspace_id`: `ChannelTurnRelayPort` is keyed by channel
  /// alone, so this subscription stays on the client's ambient active workspace
  /// — the only surface here that does.
  Stream<Map<String, dynamic>> watchChannelTurns(String channelId) => _client
      .subscribe('messaging.watchChannelTurns', {'channel_id': channelId});

  /// Live per-channel activity signals for [workspaceId] — or for the client's
  /// ambient active workspace when it is omitted (see [watchChannels] for why
  /// a workspace-keyed caller must pass its own id).
  Stream<List<Map<String, dynamic>>> watchChannelActivity({
    String? workspaceId,
  }) => _client
      .subscribe('messaging.watchChannelActivity', {
        'workspace_id': ?workspaceId,
      })
      .map(
        (data) => ((data['channels'] as List?) ?? const [])
            .whereType<Map>()
            .map((a) => a.cast<String, dynamic>())
            .toList(),
      );

  /// Live participants of [channelId] within [workspaceId].
  Stream<List<ChannelParticipantDto>> watchParticipants(
    String workspaceId,
    String channelId,
  ) => _client
      .subscribe('messaging.watchParticipants', {
        'workspace_id': workspaceId,
        'channel_id': channelId,
      })
      .map(_participants);

  List<ChannelDto> _channels(Map<String, dynamic> data) =>
      ((data['channels'] as List?) ?? const [])
          .whereType<Map>()
          .map((c) => ChannelDto.fromJson(c.cast<String, dynamic>()))
          .toList();

  List<MessageDto> _messages(Map<String, dynamic> data) =>
      ((data['messages'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => MessageDto.fromJson(m.cast<String, dynamic>()))
          .toList();

  List<ChannelParticipantDto> _participants(Map<String, dynamic> data) =>
      ((data['participants'] as List?) ?? const [])
          .whereType<Map>()
          .map((p) => ChannelParticipantDto.fromJson(p.cast<String, dynamic>()))
          .toList();

  /// Re-runs background channel-workspace provisioning (worktrees + overlay +
  /// `.mcp.json`) for [channelId] in [workspaceId] after a failure. The host
  /// re-provisions and flips the channel back to `provisioning` →
  /// `ready`/`failed`.
  Future<void> retryChannelProvisioning(String workspaceId, String channelId) =>
      _client.call('messaging.retryChannelProvisioning', {
        'workspace_id': workspaceId,
        'channel_id': channelId,
      });
}
