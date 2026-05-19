import 'package:cc_data/cc_data.dart' show RpcMessagingRepository;
import 'package:cc_data/src/repositories/rpc_messaging_repository.dart'
    show RpcMessagingRepository;
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates spaces + messages over the RPC client.
///
/// Mirrors the `messaging.*` ops + the `messaging.watch*` subscriptions. Returns
/// the wire DTOs — the [RpcMessagingRepository] wrapper maps them back to domain
/// entities.
///
/// A workspace id selects the database file server-side, so every op here names
/// its `workspace_id` explicitly rather than leaning on the RPC client's ambient
/// active workspace: that ambient id follows the active route and flips on a
/// workspace switch, independently of the workspace a caller is asking about.
/// Space, conversation and message ids are uuids, but a uuid is not an access
/// boundary — the workspace scopes the lookup, so an id from another workspace
/// is simply not found. [watchSpaces] and [watchSpaceActivity] are the
/// documented exceptions: they accept a nullable id for the cross-workspace
/// dashboard views that legitimately follow the ambient workspace.
class RemoteMessagingRepository {
  /// Creates a [RemoteMessagingRepository] over [_client].
  RemoteMessagingRepository(this._client);

  final RemoteRpcClient _client;

  /// Spaces in [workspaceId].
  Future<List<SpaceDto>> listSpaces(String workspaceId) async {
    final data = await _client.call('messaging.listSpaces', {
      'workspace_id': workspaceId,
    });
    return _spaces(data);
  }

  /// Messages in [spaceId] within [workspaceId]. When [conversationId] is
  /// set, scopes to that conversation (stream).
  Future<List<MessageDto>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async {
    final data = await _client.call('messaging.getMessages', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
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
    String spaceId,
    String conversationId, {
    required int limit,
    String? cursor,
  }) async {
    final data = await _client.call('messaging.getMessagePage', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
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

  /// Full-text search within [spaceId] in [workspaceId].
  Future<List<MessageDto>> searchInSpace(
    String workspaceId,
    String spaceId,
    String query, {
    int limit = 50,
  }) async {
    final data = await _client.call('messaging.searchInSpace', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
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

  /// Whether a space row exists in [workspaceId].
  Future<bool> spaceExists(String workspaceId, String spaceId) async {
    final data = await _client.call('messaging.spaceExists', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
    });
    return data['exists'] as bool? ?? false;
  }

  /// Participants of [spaceId] within [workspaceId].
  Future<List<SpaceParticipantDto>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async {
    final data = await _client.call('messaging.getParticipants', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
    });
    return _participants(data);
  }

  /// Sends a message to [spaceId] in [workspaceId]; returns the new message
  /// id. The host stamps the sender from the authenticated device unless a
  /// non-user [senderType] is supplied (the desktop's own trusted in-process
  /// client can post system/agent notices).
  Future<String> sendMessage({
    required String workspaceId,
    required String spaceId,
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
      'space_id': spaceId,
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
  /// [workspaceId]. [messageType] is accepted for interface parity but
  /// deliberately NOT sent: rewriting a message's rendering type (the
  /// steering queue's queued→text conversion) is a server-side act — a
  /// client-settable type would let a member turn their own text into a
  /// `plan`/`artifact` card and inject UI.
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? messageType,
    String? idempotencyKey,
  }) => _client.call('messaging.updateMessage', {
    'workspace_id': workspaceId,
    'message_id': messageId,
    'content': ?content,
    'metadata': ?metadata,
  }, idempotencyKey: idempotencyKey);

  /// Sets the conversation [mode] (db-string) of [spaceId] in [workspaceId].
  Future<void> setSpaceMode(String workspaceId, String spaceId, String mode) =>
      _client.call('messaging.setSpaceMode', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
        'mode': mode,
      });

  /// Adds [agentId] as a participant of [spaceId] in [workspaceId].
  Future<void> addParticipant(
    String workspaceId,
    String spaceId,
    String agentId,
  ) => _client.call('messaging.addParticipant', {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'agent_id': agentId,
  });

  /// The conversation's branch tree.
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async {
    final data = await _client.call('messaging.conversationTree', {
      'workspace_id': workspaceId,
      'conversation_id': conversationId,
    });
    return ConversationTree(
      leafMessageId: data['leaf_message_id'] as String?,
      branchCount: (data['branch_count'] as num?)?.toInt() ?? 0,
      nodes: [
        for (final raw in (data['nodes'] as List?) ?? const [])
          if (raw is Map)
            ConversationTreeNode(
              messageId: raw['message_id'] as String? ?? '',
              parentMessageId: raw['parent_message_id'] as String?,
              senderType: raw['sender_type'] as String? ?? 'user',
              senderId: raw['sender_id'] as String? ?? '',
              preview: raw['preview'] as String? ?? '',
              createdAt:
                  DateTime.tryParse('${raw['created_at']}') ??
                  DateTime.fromMillisecondsSinceEpoch(0),
              onCurrentBranch: raw['on_current_branch'] == true,
              childCount: (raw['child_count'] as num?)?.toInt() ?? 0,
            ),
      ],
    );
  }

  /// Points the conversation at [messageId].
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async {
    await _client.call('messaging.branchConversationAt', {
      'workspace_id': workspaceId,
      'conversation_id': conversationId,
      'message_id': messageId,
    });
  }

  /// Copies a branch into a new conversation and returns its id.
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async {
    final data = await _client.call('messaging.forkConversation', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'conversation_id': conversationId,
      'message_id': ?messageId,
      'title': ?title,
    });
    return data['conversation_id'] as String? ?? '';
  }

  /// Reverts [spaceId] in [workspaceId] to [messageId] (undo): every message
  /// after it (or including it when [inclusive]) is hidden but kept for an
  /// unrevert. The host additionally rolls the conversation's worktree back to
  /// that turn's git snapshot when it owns the checkout. Returns the affected
  /// (hidden) message ids and whether the worktree filesystem was rolled back.
  Future<({List<String> affected, bool filesystemRestored})>
  revertConversationTo(
    String workspaceId,
    String spaceId,
    String messageId, {
    bool inclusive = false,
  }) async {
    final data = await _client.call('messaging.revertConversationTo', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'message_id': messageId,
      'inclusive': inclusive,
    });
    return (
      affected: ((data['affected_message_ids'] as List?) ?? const [])
          .cast<String>(),
      filesystemRestored: data['filesystem_restored'] as bool? ?? false,
    );
  }

  /// Undoes the most-recent revert (redo) in [spaceId] within [workspaceId]:
  /// the latest reverted batch reappears. Returns the restored message ids.
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String spaceId,
  ) async {
    final data = await _client.call('messaging.unrevertConversation', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
    });
    return ((data['affected_message_ids'] as List?) ?? const []).cast<String>();
  }

  /// Live spaces of [workspaceId] — or of the client's ambient active
  /// workspace when it is omitted (the cross-workspace dashboard view).
  ///
  /// A caller that already knows which workspace it wants MUST pass it: the
  /// ambient id follows the active route and flips independently, so a
  /// workspace-keyed caller (a `family` provider keyed by workspace id) that
  /// relied on the injection could be answered with a DIFFERENT workspace's
  /// spaces whenever it (re)subscribes across a switch — and then hand those
  /// foreign space ids to workspace-scoped surfaces, which the server
  /// rightly rejects. An explicit `workspace_id` in the args wins over the
  /// ambient injection, so the stream is exactly the one the caller asked for.
  Stream<List<SpaceDto>> watchSpaces({String? workspaceId}) => _client
      .subscribe('messaging.watchSpaces', {'workspace_id': ?workspaceId})
      .map(_spaces);

  /// Live messages of a conversation ([conversationId]) inside [spaceId],
  /// within [workspaceId].
  Stream<List<MessageDto>> watchMessages(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) => _client
      .subscribe('messaging.watchMessages', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
        'conversation_id': conversationId,
      })
      .map(_messages);

  /// Live view of EVERY message in [spaceId], across all its conversations.
  Stream<List<MessageDto>> watchSpaceMessages(
    String workspaceId,
    String spaceId,
  ) => _client
      .subscribe('messaging.watchSpaceMessages', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
      })
      .map(_messages);

  /// Live newest-[limit] window of a conversation in [workspaceId], windowed
  /// SERVER-side so a long conversation never ships its full history per
  /// emission.
  Stream<({List<MessageDto> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String spaceId,
    String conversationId, {
    required int limit,
  }) => _client
      .subscribe('messaging.watchMessagesWindow', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
        'conversation_id': conversationId,
        'limit': limit,
      })
      .map(
        (data) => (
          messages: _messages(data),
          hasMore: data['has_more'] as bool? ?? false,
        ),
      );

  /// Live size of a conversation's live region — `{tokens, chars}` — computed
  /// SERVER-side, so a context meter never pulls the conversation to measure
  /// it.
  Stream<Map<String, dynamic>> watchConversationTokens(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) => _client.subscribe('messaging.watchConversationTokens', {
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'conversation_id': conversationId,
  });

  /// Raw live turn-relay frames for [spaceId] (`seed` / `updates` — see
  /// `spaceTurnEventFromWire` for the typed decode).
  ///
  /// Carries no `workspace_id`: `SpaceTurnRelayPort` is keyed by space
  /// alone, so this subscription stays on the client's ambient active workspace
  /// — the only surface here that does.
  Stream<Map<String, dynamic>> watchSpaceTurns(String spaceId) =>
      _client.subscribe('messaging.watchSpaceTurns', {'space_id': spaceId});

  /// Live per-space activity signals for [workspaceId] — or for the client's
  /// ambient active workspace when it is omitted (see [watchSpaces] for why
  /// a workspace-keyed caller must pass its own id).
  Stream<List<Map<String, dynamic>>> watchSpaceActivity({
    String? workspaceId,
  }) => _client
      .subscribe('messaging.watchSpaceActivity', {'workspace_id': ?workspaceId})
      .map(
        (data) => ((data['spaces'] as List?) ?? const [])
            .whereType<Map>()
            .map((a) => a.cast<String, dynamic>())
            .toList(),
      );

  /// Live participants of [spaceId] within [workspaceId].
  Stream<List<SpaceParticipantDto>> watchParticipants(
    String workspaceId,
    String spaceId,
  ) => _client
      .subscribe('messaging.watchParticipants', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
      })
      .map(_participants);

  List<SpaceDto> _spaces(Map<String, dynamic> data) =>
      ((data['spaces'] as List?) ?? const [])
          .whereType<Map>()
          .map((c) => SpaceDto.fromJson(c.cast<String, dynamic>()))
          .toList();

  List<MessageDto> _messages(Map<String, dynamic> data) =>
      ((data['messages'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => MessageDto.fromJson(m.cast<String, dynamic>()))
          .toList();

  List<SpaceParticipantDto> _participants(Map<String, dynamic> data) =>
      ((data['participants'] as List?) ?? const [])
          .whereType<Map>()
          .map((p) => SpaceParticipantDto.fromJson(p.cast<String, dynamic>()))
          .toList();

  /// Re-runs background space-workspace provisioning (worktrees + overlay +
  /// `.mcp.json`) for [spaceId] in [workspaceId] after a failure. The host
  /// re-provisions and flips the space back to `provisioning` →
  /// `ready`/`failed`.
  Future<void> retrySpaceProvisioning(String workspaceId, String spaceId) =>
      _client.call('messaging.retrySpaceProvisioning', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
      });

  /// Stops the in-flight provisioning of [spaceId] in [workspaceId]: the host
  /// kills the running clone/fetch, checks out no further repo and flips the
  /// space to `cancelled` (retry re-provisions).
  Future<void> cancelSpaceProvisioning(String workspaceId, String spaceId) =>
      _client.call('messaging.cancelSpaceProvisioning', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
      });
}
