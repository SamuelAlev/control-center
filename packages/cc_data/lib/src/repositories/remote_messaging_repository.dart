import 'package:cc_data/cc_data.dart' show RpcMessagingRepository;
import 'package:cc_data/src/repositories/rpc_messaging_repository.dart' show RpcMessagingRepository;
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates channels + messages over the RPC client.
///
/// Channels are workspace-scoped (bound server-side); messages are validated
/// for channel ownership by the host before any row is returned. Mirrors the
/// `messaging.*` ops + the `messaging.watch*` subscriptions. Returns the wire
/// DTOs — the [RpcMessagingRepository] wrapper maps them back to domain
/// entities. Carries no `workspace_id`: the host binds the authoritative
/// workspace per session.
class RemoteMessagingRepository {
  /// Creates a [RemoteMessagingRepository] over [_client].
  RemoteMessagingRepository(this._client);

  final RemoteRpcClient _client;

  /// Channels in the bound workspace.
  Future<List<ChannelDto>> listChannels() async {
    final data = await _client.call('messaging.listChannels', const {});
    return _channels(data);
  }

  /// Messages in [channelId] (ownership-checked server-side).
  Future<List<MessageDto>> getMessages(String channelId) async {
    final data = await _client.call('messaging.getMessages', {
      'channel_id': channelId,
    });
    return _messages(data);
  }

  /// A single message by id, or null when it doesn't exist / isn't owned.
  Future<MessageDto?> getMessageById(String messageId) async {
    final data = await _client.call('messaging.getMessageById', {
      'message_id': messageId,
    });
    final message = data['message'];
    return message is Map
        ? MessageDto.fromJson(message.cast<String, dynamic>())
        : null;
  }

  /// Whether a channel row exists in the bound workspace.
  Future<bool> channelExists(String channelId) async {
    final data = await _client.call('messaging.channelExists', {
      'channel_id': channelId,
    });
    return data['exists'] as bool? ?? false;
  }

  /// Participants of [channelId] (ownership-checked server-side).
  Future<List<ChannelParticipantDto>> getParticipants(String channelId) async {
    final data = await _client.call('messaging.getParticipants', {
      'channel_id': channelId,
    });
    return _participants(data);
  }

  /// Sends a message to [channelId]; returns the new message id. The host
  /// stamps the sender from the authenticated device unless a non-user
  /// [senderType] is supplied (the desktop's own trusted in-process client can
  /// post system/agent notices).
  Future<String> sendMessage({
    required String channelId,
    required String content,
    String? senderId,
    String? senderType,
    String? messageType,
    Map<String, dynamic>? metadata,
    String? id,
    String? parentMessageId,
  }) async {
    final data = await _client.call('messaging.sendMessage', {
      'channel_id': channelId,
      'content': content,
      'sender_id': ?senderId,
      'sender_type': ?senderType,
      'message_type': ?messageType,
      'metadata': ?metadata,
      'id': ?id,
      'parent_message_id': ?parentMessageId,
    });
    return data['message_id'] as String;
  }

  /// Updates an existing message's content and/or metadata.
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
  }) => _client.call('messaging.updateMessage', {
    'message_id': messageId,
    'content': ?content,
    'metadata': ?metadata,
  });

  /// Sets the conversation [mode] (db-string) of [channelId].
  Future<void> setChannelMode(String channelId, String mode) =>
      _client.call('messaging.setChannelMode', {
        'channel_id': channelId,
        'mode': mode,
      });

  /// Adds [agentId] as a participant of [channelId].
  Future<void> addParticipant(String channelId, String agentId) =>
      _client.call('messaging.addParticipant', {
        'channel_id': channelId,
        'agent_id': agentId,
      });

  /// Live channels in the bound workspace.
  Stream<List<ChannelDto>> watchChannels() =>
      _client.subscribe('messaging.watchChannels', const {}).map(_channels);

  /// Live messages in [channelId].
  Stream<List<MessageDto>> watchMessages(String channelId) => _client
      .subscribe('messaging.watchMessages', {'channel_id': channelId})
      .map(_messages);

  /// Live top-level (non-thread) messages in [channelId].
  Stream<List<MessageDto>> watchTopLevelMessages(String channelId) => _client
      .subscribe('messaging.watchTopLevelMessages', {'channel_id': channelId})
      .map(_messages);

  /// Live thread replies to [parentMessageId].
  Stream<List<MessageDto>> watchThread(String parentMessageId) => _client
      .subscribe('messaging.watchThread', {
        'parent_message_id': parentMessageId,
      })
      .map(_messages);

  /// Live participants of [channelId].
  Stream<List<ChannelParticipantDto>> watchParticipants(String channelId) =>
      _client
          .subscribe('messaging.watchParticipants', {'channel_id': channelId})
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
}
