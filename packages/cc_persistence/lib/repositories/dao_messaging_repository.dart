import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_cursor.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/messaging_dao.dart';
import 'package:cc_persistence/mappers/messaging_mapper.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Drift DAO-backed implementation of [MessagingRepository].
class DaoMessagingRepository implements MessagingRepository {
  /// Creates a new [DaoMessagingRepository].
  DaoMessagingRepository(this._dao);

  final MessagingDao _dao;
  final MessagingMapper _mapper = const MessagingMapper();
  final _uuid = const Uuid();

  @override
  Stream<List<Channel>> watchChannels() =>
      _dao.watchChannels().map(_mapper.channelsToDomain);

  @override
  Stream<List<ChannelParticipant>> watchParticipants(String channelId) =>
      _dao.watchParticipants(channelId).map(_mapper.participantsToDomain);

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) =>
      _dao.watchChannelsByWorkspace(workspaceId).map(_mapper.channelsToDomain);

  @override
  Stream<List<ChannelMessage>> watchMessages(String channelId) =>
      _dao.watchMessages(channelId).map(_mapper.messagesToDomain);

  @override
  Stream<List<ChannelMessage>> watchTopLevelMessages(String channelId) =>
      _dao.watchTopLevelMessages(channelId).map(_mapper.messagesToDomain);

  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})>
      watchTopLevelMessagesWindow(String channelId, {required int limit}) =>
          _dao
              .watchTopLevelMessagesWindow(channelId, limit: limit)
              .map((rows) {
            final hasMore = rows.length > limit;
            // Rows are ascending (oldest-first); the extra hasMore row is the
            // oldest, so trim from the front to keep the newest `limit`.
            final windowRows =
                hasMore ? rows.sublist(rows.length - limit) : rows;
            return (
              messages: _mapper.messagesToDomain(windowRows),
              hasMore: hasMore,
            );
          });

  @override
  Stream<List<ChannelMessage>> watchThread(String parentMessageId) =>
      _dao.watchThread(parentMessageId).map(_mapper.messagesToDomain);

  @override
  Future<ChannelMessage?> getMessageById(String messageId) async {
    final row = await _dao.getMessageById(messageId);
    if (row == null) {
      return null;
    }
    return _mapper.messageToDomain(row);
  }

  @override
  Future<Channel> openDm(String agentId, {String? workspaceId}) async {
    final existing = await _dao.getChannelByDmParticipant(agentId);
    if (existing != null) {
      return _mapper.channelToDomain(existing.data, isDm: existing.isDm);
    }

    final id = _uuid.v4();
    await _dao.insertChannel(
      ChannelsTableCompanion(
        id: drift.Value(id),
        name: const drift.Value(''),
        workspaceId: workspaceId != null
            ? drift.Value(workspaceId)
            : const drift.Value.absent(),
      ),
    );
    await _dao.insertParticipant(
      ChannelParticipantsTableCompanion(
        id: drift.Value(_uuid.v4()),
        channelId: drift.Value(id),
        agentId: const drift.Value('user'),
      ),
    );
    await _dao.insertParticipant(
      ChannelParticipantsTableCompanion(
        id: drift.Value(_uuid.v4()),
        channelId: drift.Value(id),
        agentId: drift.Value(agentId),
      ),
    );

    final row = await _dao.getChannelById(id);
    if (row == null) {
      throw StateError('Failed to create DM channel');
    }
    return _mapper.channelToDomain(row.data, isDm: row.isDm);
  }

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
    String? pipelineRunId,
  }) {
    final id = _uuid.v4();
    return _dao.transaction(() async {
      await _dao.insertChannel(
        ChannelsTableCompanion(
          id: drift.Value(id),
          name: drift.Value(name),
          mode: drift.Value(mode.toDbValue()),
          workspaceId: workspaceId != null
              ? drift.Value(workspaceId)
              : const drift.Value.absent(),
          pipelineRunId: pipelineRunId != null
              ? drift.Value(pipelineRunId)
              : const drift.Value.absent(),
        ),
      );
      await _dao.insertParticipant(
        ChannelParticipantsTableCompanion(
          id: drift.Value(_uuid.v4()),
          channelId: drift.Value(id),
          agentId: const drift.Value('user'),
        ),
      );
      for (final agentId in agentIds) {
        await _dao.insertParticipant(
          ChannelParticipantsTableCompanion(
            id: drift.Value(_uuid.v4()),
            channelId: drift.Value(id),
            agentId: drift.Value(agentId),
          ),
        );
      }

      final row = await _dao.getChannelById(id);
      if (row == null) {
        throw StateError('Failed to create group channel');
      }
      return _mapper.channelToDomain(row.data, isDm: row.isDm);
    });
  }

  @override
  Future<bool> channelExists(String channelId) async =>
      await _dao.getChannelById(channelId) != null;

  @override
  Future<void> addParticipant(String channelId, String agentId) async {
    await _dao.insertParticipant(
      ChannelParticipantsTableCompanion(
        id: drift.Value(_uuid.v4()),
        channelId: drift.Value(channelId),
        agentId: drift.Value(agentId),
      ),
    );
  }

  @override
  Future<List<ChannelParticipant>> getParticipants(String channelId) async {
    final rows = await _dao.getParticipants(channelId);
    return _mapper.participantsToDomain(rows);
  }

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
  }) async {
    final messageId = id ?? _uuid.v4();
    await _dao.insertMessage(
      ChannelMessagesTableCompanion(
        id: drift.Value(messageId),
        channelId: drift.Value(channelId),
        senderId: drift.Value(senderId),
        senderType: drift.Value(senderType),
        content: drift.Value(content),
        messageType: drift.Value(messageType),
        metadata: drift.Value(metadata != null ? jsonEncode(metadata) : null),
        parentMessageId: parentMessageId != null
            ? drift.Value(parentMessageId)
            : const drift.Value.absent(),
      ),
    );
    await _dao.updateChannelUpdatedAt(channelId, DateTime.now());
    return messageId;
  }

  @override
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
  }) => _dao.updateMessage(messageId, content: content, metadata: metadata);

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async {
    final rows = await _dao.getMessages(channelId);
    return _mapper.messagesToDomain(rows);
  }

  /// Max extra messages pulled to back the page up to a user-message boundary,
  /// so a loaded page never begins mid-exchange (kilocode's assistant-boundary
  /// backfill, capped to avoid loading a whole runaway turn).
  static const int _backfillCap = 20;

  @override
  Future<MessagePage> getTopLevelMessagePage(
    String channelId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async {
    final decoded = MessageCursor.decode(cursor);
    // Fetch one extra to detect whether older history remains.
    final rows = await _dao.getTopLevelMessagePageRows(
      channelId,
      limit: limit + 1,
      beforeCreatedAtSeconds: decoded == null
          ? null
          : decoded.createdAtMs ~/ 1000,
      beforeRowid: decoded?.rowid,
    );

    var hasMore = rows.length > limit;
    var page = hasMore ? rows.sublist(0, limit) : rows;

    // Backfill: if the oldest row in the page is an agent message, pull older
    // rows until we reach a user message (turn start) or the cap.
    if (hasMore && page.isNotEmpty && page.last.data.senderType != 'user') {
      final oldest = page.last;
      final extra = await _dao.getTopLevelMessagePageRows(
        channelId,
        limit: _backfillCap + 1,
        beforeCreatedAtSeconds: oldest.data.createdAt.millisecondsSinceEpoch ~/ 1000,
        beforeRowid: oldest.rowid,
      );
      final taken = <({ChannelMessagesTableData data, int rowid})>[];
      for (final r in extra.take(_backfillCap)) {
        taken.add(r);
        if (r.data.senderType == 'user') {
          break;
        }
      }
      page = [...page, ...taken];
      // hasMore reflects whether anything remains before the backfilled tail.
      hasMore = extra.length > taken.length;
    }

    String? nextCursor;
    if (hasMore && page.isNotEmpty) {
      final boundary = page.last;
      nextCursor = MessageCursor(
        createdAtMs: boundary.data.createdAt.millisecondsSinceEpoch,
        rowid: boundary.rowid,
      ).encode();
    }

    // Rows are newest-first; reverse for oldest-first display.
    final messages = page.reversed
        .map((r) => _mapper.messageToDomain(r.data))
        .toList(growable: false);
    return MessagePage(
      messages: messages,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  @override
  Future<void> markCompacted(List<String> ids) => _dao.markCompacted(ids);

  @override
  Future<List<String>> revertConversationTo(
    String channelId,
    String messageId, {
    bool inclusive = false,
  }) async {
    // getMessages already returns only live (non-reverted) messages in order.
    final live = await _dao.getMessages(channelId);
    final targetIndex = live.indexWhere((m) => m.id == messageId);
    if (targetIndex < 0) {
      return const [];
    }
    final from = inclusive ? targetIndex : targetIndex + 1;
    final toRevert = live.sublist(from).map((m) => m.id).toList();
    if (toRevert.isEmpty) {
      return const [];
    }
    await _dao.revertMessages(toRevert, DateTime.now().millisecondsSinceEpoch);
    return toRevert;
  }

  @override
  Future<List<String>> unrevertConversation(String channelId) async {
    final batch = await _dao.getLatestRevertedBatch(channelId);
    if (batch.isEmpty) {
      return const [];
    }
    await _dao.unrevertMessages(batch);
    return batch;
  }

  @override
  Future<void> deleteChannel(String channelId) =>
      _dao.deleteChannelCascade(channelId);

  @override
  Future<void> updateChannelName(String channelId, String name) =>
      _dao.updateChannelName(channelId, name);

  @override
  Future<void> setChannelMode(String channelId, ConversationMode mode) =>
      _dao.updateChannelMode(channelId, mode.toDbValue());

  @override
  Future<void> clearChannelMessages(String channelId) =>
      _dao.clearChannelMessages(channelId);

  @override
  Future<void> removeParticipant(String channelId, String agentId) =>
      _dao.removeParticipant(channelId, agentId);

  @override
  Future<void> updateMessageEmbedding(
    String messageId,
    Uint8List embedding,
  ) =>
      _dao.updateMessageEmbedding(messageId, embedding);

  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(
    String channelId,
  ) async {
    final rows = await _dao.getMessagesWithEmbedding(channelId);
    return _mapper.embeddedMessagesToDomain(rows);
  }

  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding({int limit = 200}) async {
    final rows = await _dao.getMessagesWithoutEmbedding(limit: limit);
    return _mapper.messagesToDomain(rows);
  }
}
