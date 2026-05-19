import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_activity.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_cursor.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/messaging_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/messaging_mapper.dart';
import 'package:cc_persistence/repositories/distinct_rows.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Drift DAO-backed implementation of [MessagingRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).messagingDao` per call: channels, conversations,
/// participants and messages all live in the workspace's own database file, so
/// the workspace id picks the file before any SQL runs. [watchChannels] is the
/// one read that spans files.
class DaoMessagingRepository implements MessagingRepository {
  /// Creates a [DaoMessagingRepository] over the per-workspace databases.
  DaoMessagingRepository(this._dbs) : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;
  final MessagingMapper _mapper = const MessagingMapper();
  final _uuid = const Uuid();

  MessagingDao _dao(String workspaceId) => _dbs.of(workspaceId).messagingDao;

  /// Suppresses value-identical re-emissions of a drift watch. Shared with
  /// the other hot list watches — see `distinct_rows.dart` for why.
  Stream<List<T>> _distinctRows<T>(Stream<List<T>> source) =>
      distinctRows(source);

  /// Newest-activity-first, the order the channel list is displayed in. Applied
  /// to the merged cross-workspace list, which concatenation would otherwise
  /// leave interleaved by workspace.
  static int _newestFirst(ChannelsTableData a, ChannelsTableData b) =>
      b.updatedAt.compareTo(a.updatedAt);

  /// CROSS-WORKSPACE BY DESIGN: the dashboard's all-channels view, which is
  /// defined over every workspace. Workspace-scoped surfaces use
  /// [watchChannelsByWorkspace].
  @override
  Stream<List<Channel>> watchChannels() => _cross
      .mergeStreams((db) => db.messagingDao.watchChannels(), sort: _newestFirst)
      .map(_mapper.channelsToDomain);

  @override
  Stream<List<ChannelParticipant>> watchParticipants(
    String workspaceId,
    String channelId,
  ) => _dao(
    workspaceId,
  ).watchParticipants(channelId).map(_mapper.participantsToDomain);

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) => _dao(
    workspaceId,
  ).watchChannelsByWorkspace(workspaceId).map(_mapper.channelsToDomain);

  @override
  Stream<List<ChannelMessage>> watchMessages(
    String workspaceId,
    String channelId,
    String conversationId,
  ) => _distinctRows(
    _dao(workspaceId).watchMessages(conversationId),
  ).map(_mapper.messagesToDomain);

  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String channelId,
    String conversationId, {
    required int limit,
  }) =>
      _distinctRows(
        _dao(workspaceId).watchMessagesWindow(conversationId, limit: limit),
      ).map((rows) {
        final hasMore = rows.length > limit;
        // Rows are ascending (oldest-first); the extra hasMore row is the
        // oldest, so trim from the front to keep the newest `limit`.
        final windowRows = hasMore ? rows.sublist(rows.length - limit) : rows;
        return (
          messages: _mapper.messagesToDomain(windowRows),
          hasMore: hasMore,
        );
      });

  /// Per-channel activity signals for [workspaceId], computed in SQL. NOT
  /// part of [MessagingRepository]: server-only projection behind
  /// `messaging.watchChannelActivity`.
  Stream<List<ChannelActivity>> watchChannelActivity(String workspaceId) =>
      _distinctRows(_dao(workspaceId).watchChannelActivity(workspaceId)).map(
        (rows) => [
          for (final row in rows)
            ChannelActivity(
              channelId: row.channelId,
              lastMessageAt: row.lastMessageAt,
              lastAgentMessageAt: row.lastAgentMessageAt,
              openQuestionCount: row.openQuestionCount,
            ),
        ],
      );

  @override
  Future<ChannelMessage?> getMessageById(
    String workspaceId,
    String messageId,
  ) async {
    final row = await _dao(workspaceId).getMessageById(messageId);
    if (row == null) {
      return null;
    }
    return _mapper.messageToDomain(row);
  }

  @override
  Future<Channel?> getChannelById(String workspaceId, String channelId) async {
    final row = await _dao(workspaceId).getChannelById(channelId);
    if (row == null) {
      return null;
    }
    return _mapper.channelToDomain(row);
  }

  @override
  Future<Channel> createChannel(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    ChannelOrigin origin = ChannelOrigin.user,
    List<String> repoIds = const [],
  }) async {
    final id = _uuid.v4();
    final dao = _dao(workspaceId);
    return dao.transaction(() async {
      await dao.insertChannel(
        ChannelsTableCompanion(
          id: drift.Value(id),
          name: drift.Value(name),
          mode: drift.Value(mode.toDbValue()),
          origin: drift.Value(origin.wire),
          // New channels start provisioning; the background provisioner flips
          // this to `ready` (or `failed`). Channels with no repos/agents short-
          // circuit to `ready` immediately.
          provisioningStatus: drift.Value(
            ChannelProvisioningStatus.provisioning.toDbValue(),
          ),
          workspaceId: drift.Value(workspaceId),
          pipelineRunId: pipelineRunId != null
              ? drift.Value(pipelineRunId)
              : const drift.Value.absent(),
        ),
      );
      // Seed the `main` conversation (id == channel id) so the message
      // `conversation_id` FK resolves for the first send.
      await dao.ensureMainConversation(id, workspaceId: workspaceId);
      if (createdByUserId != null) {
        await dao.insertParticipant(
          ChannelParticipantsTableCompanion(
            id: drift.Value(_uuid.v4()),
            channelId: drift.Value(id),
            principalId: drift.Value(createdByUserId),
            participantType: const drift.Value('user'),
          ),
        );
      }
      for (final agentId in agentIds) {
        await dao.insertParticipant(
          ChannelParticipantsTableCompanion(
            id: drift.Value(_uuid.v4()),
            channelId: drift.Value(id),
            principalId: drift.Value(agentId),
            participantType: const drift.Value('agent'),
          ),
        );
      }

      // Record the per-channel repo selection (no-op when empty → all repos).
      if (repoIds.isNotEmpty) {
        // Isolation chokepoint: a repo id only exists inside its own
        // workspace's database file, so refuse any id not registered here
        // instead of persisting a dangling — or cross-workspace — selection.
        final repoDao = _dbs.of(workspaceId).repoDao;
        for (final repoId in repoIds) {
          if (!await repoDao.exists(repoId)) {
            throw ValidationException(
              'Repo $repoId does not belong to workspace $workspaceId.',
            );
          }
        }
        await _dbs
            .of(workspaceId)
            .channelRepoDao
            .setReposForChannel(
              workspaceId: workspaceId,
              channelId: id,
              repoIds: repoIds,
            );
      }

      final row = await dao.getChannelById(id);
      if (row == null) {
        throw StateError('Failed to create channel');
      }
      return _mapper.channelToDomain(row);
    });
  }

  @override
  Future<bool> channelExists(String workspaceId, String channelId) async =>
      await _dao(workspaceId).getChannelById(channelId) != null;

  @override
  Future<void> addParticipant(
    String workspaceId,
    String channelId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {
    await _dao(workspaceId).insertParticipant(
      ChannelParticipantsTableCompanion(
        id: drift.Value(_uuid.v4()),
        channelId: drift.Value(channelId),
        principalId: drift.Value(principalId),
        participantType: drift.Value(participantType.wireName),
      ),
    );
  }

  @override
  Future<List<ChannelParticipant>> getParticipants(
    String workspaceId,
    String channelId,
  ) async {
    final rows = await _dao(workspaceId).getParticipants(channelId);
    return _mapper.participantsToDomain(rows);
  }

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String channelId,
    required String content,
    required String senderId,
    required String senderType,
    String? conversationId,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
  }) async {
    final messageId = id ?? _uuid.v4();
    final dao = _dao(workspaceId);
    // Default to the channel's `main` conversation (id == channel id). Ensure
    // the row exists so the `conversation_id` FK resolves even for a channel
    // whose `main` row is somehow missing (defensive).
    //
    // The workspace MUST be stamped: a `conversations` row with a null
    // `workspace_id` is invisible to `ConversationDao.listForChannel` and, worse,
    // the sync trigger fires only `WHEN NEW.workspace_id IS NOT NULL`, so delta
    // clients would never learn the conversation exists.
    final convId = conversationId ?? channelId;
    // ONE transaction for the whole send. These three writes used to
    // auto-commit separately: three fsyncs and three rounds of trigger +
    // watch-subscriber invalidation per message, and an agent streaming
    // replies multiplies it. They are also logically atomic — a message that
    // landed without its channel's `updated_at` bump sorts wrong in the
    // sidebar until the next write.
    await dao.transaction(() async {
      if (convId == channelId) {
        await dao.ensureMainConversation(channelId, workspaceId: workspaceId);
      }
      await dao.insertMessage(
        ChannelMessagesTableCompanion(
          id: drift.Value(messageId),
          channelId: drift.Value(channelId),
          conversationId: drift.Value(convId),
          senderId: drift.Value(senderId),
          senderType: drift.Value(senderType),
          content: drift.Value(content),
          messageType: drift.Value(messageType),
          metadata: drift.Value(metadata != null ? jsonEncode(metadata) : null),
        ),
      );
      await dao.updateChannelUpdatedAt(channelId, DateTime.now());
    });
    return messageId;
  }

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    // Dedup happens at the RPC dispatcher's write ledger before this handler
    // runs (PRD 19 §3); the DAO write itself needs no key.
    String? idempotencyKey,
  }) => _dao(
    workspaceId,
  ).updateMessage(messageId, content: content, metadata: metadata);

  @override
  Future<List<ChannelMessage>> getMessages(
    String workspaceId,
    String channelId, {
    String? conversationId,
  }) async {
    final rows = await _dao(
      workspaceId,
    ).getMessages(conversationId ?? channelId);
    return _mapper.messagesToDomain(rows);
  }

  @override
  Future<List<ChannelMessage>> searchInChannel(
    String workspaceId,
    String channelId,
    String query, {
    int limit = 50,
  }) async {
    final rows = await _dao(
      workspaceId,
    ).searchInChannel(channelId, query, limit: limit);
    return _mapper.messagesToDomain(rows);
  }

  /// Max extra messages pulled to back the page up to a user-message boundary,
  /// so a loaded page never begins mid-exchange (the assistant-boundary
  /// backfill, capped to avoid loading a whole runaway turn).
  static const int _backfillCap = 20;

  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String channelId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async {
    final dao = _dao(workspaceId);
    final decoded = MessageCursor.decode(cursor);
    // Fetch one extra to detect whether older history remains.
    final rows = await dao.getMessagePageRows(
      channelId,
      conversationId,
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
      final extra = await dao.getMessagePageRows(
        channelId,
        conversationId,
        limit: _backfillCap + 1,
        beforeCreatedAtSeconds:
            oldest.data.createdAt.millisecondsSinceEpoch ~/ 1000,
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
  Future<void> markCompacted(String workspaceId, List<String> ids) =>
      _dao(workspaceId).markCompacted(ids);

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String channelId,
    String messageId, {
    bool inclusive = false,
  }) async {
    final dao = _dao(workspaceId);
    // getMessages already returns only live (non-reverted) messages in order.
    final live = await dao.getMessages(channelId);
    final targetIndex = live.indexWhere((m) => m.id == messageId);
    if (targetIndex < 0) {
      return const [];
    }
    final from = inclusive ? targetIndex : targetIndex + 1;
    final toRevert = live.sublist(from).map((m) => m.id).toList();
    if (toRevert.isEmpty) {
      return const [];
    }
    await dao.revertMessages(toRevert, DateTime.now().millisecondsSinceEpoch);
    return toRevert;
  }

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String channelId,
  ) async {
    final dao = _dao(workspaceId);
    final batch = await dao.getLatestRevertedBatch(channelId);
    if (batch.isEmpty) {
      return const [];
    }
    await dao.unrevertMessages(batch);
    return batch;
  }

  @override
  Future<void> deleteChannel(String workspaceId, String channelId) =>
      _dao(workspaceId).deleteChannelCascade(channelId);

  @override
  Future<void> updateChannelName(
    String workspaceId,
    String channelId,
    String name,
  ) => _dao(workspaceId).updateChannelName(channelId, name);

  @override
  Future<void> setChannelMode(
    String workspaceId,
    String channelId,
    Mode mode,
  ) => _dao(workspaceId).updateChannelMode(channelId, mode.toDbValue());

  @override
  Future<void> clearChannelMessages(String workspaceId, String channelId) =>
      _dao(workspaceId).clearChannelMessages(channelId);

  @override
  Future<void> removeParticipant(
    String workspaceId,
    String channelId,
    String principalId,
  ) => _dao(workspaceId).removeParticipant(channelId, principalId);

  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  ) => _dao(workspaceId).updateMessageEmbedding(messageId, embedding);

  @override
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String channelId,
  ) async {
    final rows = await _dao(workspaceId).getMessagesWithEmbedding(channelId);
    return _mapper.embeddedMessagesToDomain(rows);
  }

  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  }) async {
    final rows = await _dao(
      workspaceId,
    ).getMessagesWithoutEmbedding(limit: limit);
    return _mapper.messagesToDomain(rows);
  }
}
