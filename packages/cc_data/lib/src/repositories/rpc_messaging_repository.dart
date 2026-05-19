import 'dart:typed_data';

import 'package:cc_data/cc_data.dart' show RpcMessagingPort;
import 'package:cc_data/src/repositories/remote_messaging_repository.dart';
import 'package:cc_data/src/repositories/rpc_messaging_port.dart' show RpcMessagingPort;
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_cursor.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [MessagingRepository] backed by the RPC client — the thin-client data path.
///
/// Implements the domain interface over the host's `messaging.*` ops + the
/// `messaging.watch*` subscriptions, mapping the channel/message/participant
/// wire DTOs back to domain entities. The host owns persistence and validates
/// channel ownership against the bound workspace before returning any row; this
/// client never touches a database.
///
/// The reads/watches/mutations the UI reaches through the public repository
/// provider are served. The host-owned surface a thin client never drives
/// directly — channel lifecycle (`openDm`/`createGroup`/`deleteChannel`/…, all
/// invoked via the server-side `MessagingService`), embedding backfill, and
/// compaction — throws [UnsupportedError] or returns an empty fallback.
class RpcMessagingRepository implements MessagingRepository {
  /// Creates an [RpcMessagingRepository] over [client].
  RpcMessagingRepository(RemoteRpcClient client)
    : _remote = RemoteMessagingRepository(client);

  final RemoteMessagingRepository _remote;

  /// Rebuilds a [Channel] from its wire DTO. Missing timestamps fall back to
  /// the epoch; a missing/unknown mode falls back to chat. Public so the
  /// sibling [RpcMessagingPort] (channel-lifecycle dispatch) reuses the exact
  /// same DTO→entity mapping rather than duplicating it.
  static Channel channelFromDto(ChannelDto d) => Channel(
    id: d.id,
    name: d.name,
    isDm: d.isDm,
    workspaceId: d.workspaceId.isEmpty ? null : d.workspaceId,
    createdAt: d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt:
        d.updatedAt ?? d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    mode: ConversationMode.fromDbValue(d.mode),
    pipelineRunId: d.pipelineRunId,
  );

  /// Rebuilds a [ChannelMessage] from its wire DTO. The DTO carries the parent
  /// channel id; when absent (a lossy older surface) it falls back to
  /// [fallbackChannelId] so the non-empty-channelId invariant holds.
  static ChannelMessage _messageFromDto(
    MessageDto d, {
    String? fallbackChannelId,
  }) {
    final metadata = d.metadata;
    return ChannelMessage(
      id: d.id,
      channelId: d.channelId ?? fallbackChannelId ?? '',
      senderId: d.senderId,
      senderType:
          ChannelSenderType.values.asNameMap()[d.senderType] ??
          ChannelSenderType.user,
      content: d.content,
      messageType:
          ChannelMessageType.values.asNameMap()[d.messageType] ??
          ChannelMessageType.text,
      metadata: metadata is Map
          ? metadata.cast<String, dynamic>()
          : null,
      parentMessageId: d.parentMessageId,
      compacted: d.compacted,
      createdAt: d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static ChannelParticipant _participantFromDto(ChannelParticipantDto d) =>
      ChannelParticipant(
        id: d.id,
        channelId: d.channelId,
        agentId: d.agentId,
        role: d.role,
        joinedAt: d.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        lastReadAt: d.lastReadAt,
      );

  // ---- Watches (served over the catalog `messaging.watch*` queries) ----

  @override
  Stream<List<Channel>> watchChannels() =>
      _remote.watchChannels().map((dtos) => dtos.map(channelFromDto).toList());

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      // The host binds the authoritative workspace per session, so the channel
      // stream is already scoped — the workspaceId arg is informational only.
      watchChannels();

  @override
  Stream<List<ChannelMessage>> watchMessages(String channelId) =>
      _remote.watchMessages(channelId).map(
        (dtos) =>
            dtos.map((d) => _messageFromDto(d, fallbackChannelId: channelId)).toList(),
      );

  @override
  Stream<List<ChannelMessage>> watchTopLevelMessages(String channelId) =>
      _remote.watchTopLevelMessages(channelId).map(
        (dtos) =>
            dtos.map((d) => _messageFromDto(d, fallbackChannelId: channelId)).toList(),
      );

  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})>
  watchTopLevelMessagesWindow(String channelId, {required int limit}) =>
      // Derive the window client-side from the full top-level stream: the host
      // streams ascending (oldest-first), so the newest `limit` is the tail and
      // `hasMore` is true when more exist beyond it.
      _remote.watchTopLevelMessages(channelId).map((dtos) {
        final all = dtos
            .map((d) => _messageFromDto(d, fallbackChannelId: channelId))
            .toList();
        final hasMore = all.length > limit;
        final window = hasMore ? all.sublist(all.length - limit) : all;
        return (messages: window, hasMore: hasMore);
      });

  @override
  Stream<List<ChannelMessage>> watchThread(String parentMessageId) =>
      _remote
          .watchThread(parentMessageId)
          .map((dtos) => dtos.map(_messageFromDto).toList());

  @override
  Stream<List<ChannelParticipant>> watchParticipants(String channelId) =>
      _remote.watchParticipants(channelId).map(
        (dtos) => dtos.map(_participantFromDto).toList(),
      );

  // ---- Reads ----

  @override
  Future<ChannelMessage?> getMessageById(String messageId) async {
    final dto = await _remote.getMessageById(messageId);
    return dto == null ? null : _messageFromDto(dto);
  }

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async {
    final dtos = await _remote.getMessages(channelId);
    return dtos
        .map((d) => _messageFromDto(d, fallbackChannelId: channelId))
        .toList();
  }

  @override
  Future<MessagePage> getTopLevelMessagePage(
    String channelId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async {
    // Thin-client fallback: the host returns the full channel, so paginate the
    // top-level messages in memory. The cursor encodes the boundary message's
    // createdAt (rowid is unavailable client-side, so 0 is used as a sentinel
    // tie-breaker — strictly-older-by-time is sufficient for display paging).
    final all = (await getMessages(channelId))
        .where((m) => m.parentMessageId == null)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final decoded = MessageCursor.decode(cursor);
    final older = decoded == null
        ? all
        : all
            .where((m) => m.createdAt.millisecondsSinceEpoch < decoded.createdAtMs)
            .toList();
    final hasMore = older.length > limit;
    final page = hasMore ? older.sublist(older.length - limit) : older;
    String? nextCursor;
    if (hasMore && page.isNotEmpty) {
      nextCursor = MessageCursor(
        createdAtMs: page.first.createdAt.millisecondsSinceEpoch,
        rowid: 0,
      ).encode();
    }
    return MessagePage(messages: page, hasMore: hasMore, nextCursor: nextCursor);
  }

  @override
  Future<bool> channelExists(String channelId) =>
      _remote.channelExists(channelId);

  @override
  Future<List<ChannelParticipant>> getParticipants(String channelId) async {
    final dtos = await _remote.getParticipants(channelId);
    return dtos.map(_participantFromDto).toList();
  }

  // ---- Mutations ----

  @override
  Future<String> sendMessage({
    required String channelId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? parentMessageId,
  }) => _remote.sendMessage(
    channelId: channelId,
    content: content,
    senderId: senderId,
    senderType: senderType,
    messageType: messageType,
    metadata: metadata,
    id: id,
    parentMessageId: parentMessageId,
  );

  @override
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
  }) => _remote.updateMessage(messageId, content: content, metadata: metadata);

  @override
  Future<void> setChannelMode(String channelId, ConversationMode mode) =>
      _remote.setChannelMode(channelId, mode.toDbValue());

  @override
  Future<void> addParticipant(String channelId, String agentId) =>
      _remote.addParticipant(channelId, agentId);

  // ---- Host-owned surface: channel lifecycle, embeddings, compaction. ----
  // The UI reaches these through the server-side `MessagingService` (Dao-backed
  // execution), never through this thin-client repository.
  @override
  Future<Channel> openDm(String agentId, {String? workspaceId}) =>
      throw UnsupportedError('openDm is host-side only');

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
    String? pipelineRunId,
  }) => throw UnsupportedError('createGroup is host-side only');

  @override
  Future<List<String>> revertConversationTo(
    String channelId,
    String messageId, {
    bool inclusive = false,
  }) =>
      throw UnsupportedError('revertConversationTo is host-side only');

  @override
  Future<List<String>> unrevertConversation(String channelId) =>
      throw UnsupportedError('unrevertConversation is host-side only');

  @override
  Future<void> deleteChannel(String channelId) =>
      throw UnsupportedError('deleteChannel is host-side only');

  @override
  Future<void> updateChannelName(String channelId, String name) =>
      throw UnsupportedError('updateChannelName is host-side only');

  @override
  Future<void> clearChannelMessages(String channelId) =>
      throw UnsupportedError('clearChannelMessages is host-side only');

  @override
  Future<void> removeParticipant(String channelId, String agentId) =>
      throw UnsupportedError('removeParticipant is host-side only');

  @override
  Future<void> markCompacted(List<String> ids) =>
      throw UnsupportedError('markCompacted is host-side only');

  @override
  Future<void> updateMessageEmbedding(String messageId, Uint8List embedding) =>
      throw UnsupportedError('updateMessageEmbedding is host-side only');

  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(
    String channelId,
  ) => throw UnsupportedError('getMessagesWithEmbedding is host-side only');

  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding({int limit = 200}) =>
      throw UnsupportedError('getMessagesWithoutEmbedding is host-side only');
}
