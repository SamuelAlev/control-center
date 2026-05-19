import 'dart:convert';

import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/channel_messages.dart';
import 'package:control_center/core/database/tables/channel_participants.dart';
import 'package:control_center/core/database/tables/channels.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart' show ConversationMode;
import 'package:drift/drift.dart';

part 'messaging_dao.g.dart';

/// Data access object for [ChannelsTable], [ChannelParticipantsTable], and
/// [ChannelMessagesTable].
@DriftAccessor(
  tables: [ChannelsTable, ChannelParticipantsTable, ChannelMessagesTable],
)
class MessagingDao extends DatabaseAccessor<AppDatabase>
    with _$MessagingDaoMixin {
  /// Creates a [MessagingDao] for the given database.
  MessagingDao(super.attachedDatabase);

  /// Watches all channels ordered by most recently updated.
  /// Each row includes `is_dm` derived from participant count and name
  /// (≤ 2 participants and no name = DM, otherwise Group).
  ///
  /// CROSS-WORKSPACE BY DESIGN — returns channels from **every workspace**, for
  /// the global dashboard view only. Agent-facing / workspace-scoped surfaces
  /// must use [watchChannelsByWorkspace] with the active `workspaceId`; filtering
  /// the global stream in memory has leaked other workspaces' channels before.
  Stream<List<({ChannelsTableData data, bool isDm})>> watchChannels() {
    return customSelect(
      '''
      SELECT c.*, (COUNT(p.id) <= 2 AND (c.name IS NULL OR c.name = '')) AS is_dm
      FROM channels c
      LEFT JOIN channel_participants p ON p.channel_id = c.id
      GROUP BY c.id
      ORDER BY c.updated_at DESC
      ''',
      readsFrom: {channelsTable, channelParticipantsTable},
    ).map((row) => (
      data: channelsTable.map(row.data),
      isDm: row.read<int>('is_dm') == 1,
    )).watch();
  }

  /// Watches participants for a channel.
  Stream<List<ChannelParticipantsTableData>> watchParticipants(
    String channelId,
  ) =>
      (select(channelParticipantsTable)
            ..where((t) => t.channelId.equals(channelId))
            ..orderBy([(t) => OrderingTerm.asc(t.joinedAt)]))
          .watch();

  /// Watches channels for a specific workspace ordered by most recently updated.
  Stream<List<({ChannelsTableData data, bool isDm})>> watchChannelsByWorkspace(
    String workspaceId,
  ) {
    return customSelect(
      '''
      SELECT c.*, (COUNT(p.id) <= 2 AND (c.name IS NULL OR c.name = '')) AS is_dm
      FROM channels c
      LEFT JOIN channel_participants p ON p.channel_id = c.id
      WHERE c.workspace_id = ?
      GROUP BY c.id
      ORDER BY c.updated_at DESC
      ''',
      variables: [Variable.withString(workspaceId)],
      readsFrom: {channelsTable, channelParticipantsTable},
    ).map((row) => (
      data: channelsTable.map(row.data),
      isDm: row.read<int>('is_dm') == 1,
    )).watch();
  }

  /// Watches messages for a channel ordered by creation time.
  Stream<List<ChannelMessagesTableData>> watchMessages(String channelId) =>
      (select(channelMessagesTable)
            ..where((t) => t.channelId.equals(channelId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  /// Watches top-level messages (no parent) for a channel.
  Stream<List<ChannelMessagesTableData>> watchTopLevelMessages(
    String channelId,
  ) =>
      (select(channelMessagesTable)
            ..where(
              (t) =>
                  t.channelId.equals(channelId) &
                  t.parentMessageId.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  /// Watches threaded replies to a specific parent message.
  Stream<List<ChannelMessagesTableData>> watchThread(String parentMessageId) =>
      (select(channelMessagesTable)
            ..where((t) => t.parentMessageId.equals(parentMessageId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  /// Returns a single message by ID or null.
  Future<ChannelMessagesTableData?> getMessageById(String messageId) =>
      (select(channelMessagesTable)..where((t) => t.id.equals(messageId)))
          .getSingleOrNull();

  /// Returns all messages for a channel in creation order.
  Future<List<ChannelMessagesTableData>> getMessages(String channelId) =>
      (select(channelMessagesTable)
            ..where((t) => t.channelId.equals(channelId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// Marks messages matching [ids] as compacted.
  Future<void> markCompacted(List<String> ids) async {
    await (update(channelMessagesTable)..where((t) => t.id.isIn(ids))).write(
      const ChannelMessagesTableCompanion(compacted: Value(true)),
    );
  }

  /// Inserts a channel.
  Future<void> insertChannel(ChannelsTableCompanion entry) =>
      into(channelsTable).insert(entry);

  /// Inserts a participant, ignoring conflicts (prevents duplicates).
  Future<void> insertParticipant(ChannelParticipantsTableCompanion entry) =>
      into(
        channelParticipantsTable,
      ).insert(entry, mode: InsertMode.insertOrIgnore);

  /// Inserts a message.
  Future<void> insertMessage(ChannelMessagesTableCompanion entry) =>
      into(channelMessagesTable).insert(entry);

  /// Updates the updatedAt timestamp for a channel.
  Future<void> updateChannelUpdatedAt(String channelId, DateTime updatedAt) =>
      (update(channelsTable)..where((t) => t.id.equals(channelId))).write(
        ChannelsTableCompanion(updatedAt: Value(updatedAt)),
      );

  /// Updates the [ConversationMode]-serialized value for a channel.
  Future<void> updateChannelMode(String channelId, String mode) =>
      (update(channelsTable)..where((t) => t.id.equals(channelId))).write(
        ChannelsTableCompanion(mode: Value(mode)),
      );

  /// Updates the content and/or metadata of an existing message.
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
  }) {
    return (update(
      channelMessagesTable,
    )..where((t) => t.id.equals(messageId))).write(
      ChannelMessagesTableCompanion(
        content: content != null ? Value(content) : const Value.absent(),
        metadata: metadata != null
            ? Value(jsonEncode(metadata))
            : const Value.absent(),
      ),
    );
  }

  /// Returns the channel row by id with `is_dm`, or null.
  Future<({ChannelsTableData data, bool isDm})?> getChannelById(
    String channelId,
  ) async {
    final result = await customSelect(
      '''
      SELECT c.*, (COUNT(p.id) <= 2 AND (c.name IS NULL OR c.name = '')) AS is_dm
      FROM channels c
      LEFT JOIN channel_participants p ON p.channel_id = c.id
      WHERE c.id = ?
      GROUP BY c.id
      ''',
      variables: [Variable.withString(channelId)],
      readsFrom: {channelsTable, channelParticipantsTable},
    ).map((row) => (
      data: channelsTable.map(row.data),
      isDm: row.read<int>('is_dm') == 1,
    )).get();
    return result.firstOrNull;
  }

  /// Returns an existing DM channel between the user and [agentId], or null.
  /// A DM is defined as a channel with exactly 2 participants (user + agent)
  /// and no name/title.
  Future<({ChannelsTableData data, bool isDm})?> getChannelByDmParticipant(
    String agentId,
  ) async {
    final result = await customSelect(
      '''
      SELECT c.*, (COUNT(p_all.id) <= 2 AND (c.name IS NULL OR c.name = '')) AS is_dm
      FROM channels c
      LEFT JOIN channel_participants p_all ON p_all.channel_id = c.id
      WHERE (c.name IS NULL OR c.name = '')
      AND EXISTS (
        SELECT 1 FROM channel_participants
        WHERE channel_id = c.id AND agent_id = 'user'
      )
      AND EXISTS (
        SELECT 1 FROM channel_participants
        WHERE channel_id = c.id AND agent_id = ?
      )
      GROUP BY c.id
      HAVING COUNT(p_all.id) = 2
      LIMIT 1
      ''',
      variables: [Variable.withString(agentId)],
      readsFrom: {channelsTable, channelParticipantsTable},
    ).map((row) => (
      data: channelsTable.map(row.data),
      isDm: row.read<int>('is_dm') == 1,
    )).get();
    return result.firstOrNull;
  }

  /// Returns all participants for a channel (for dedup checks).
  Future<List<ChannelParticipantsTableData>> getParticipants(
    String channelId,
  ) => (select(
    channelParticipantsTable,
  )..where((t) => t.channelId.equals(channelId))).get();

  /// Deletes a channel and all its messages and participants.
  Future<void> deleteChannelCascade(String channelId) => transaction(() async {
    await (delete(
      channelMessagesTable,
    )..where((t) => t.channelId.equals(channelId))).go();
    await (delete(
      channelParticipantsTable,
    )..where((t) => t.channelId.equals(channelId))).go();
    await (delete(channelsTable)..where((t) => t.id.equals(channelId))).go();
  });

  /// Updates the channel name.
  Future<void> updateChannelName(String channelId, String name) =>
      (update(channelsTable)..where((t) => t.id.equals(channelId))).write(
        ChannelsTableCompanion(name: Value(name)),
      );

  /// Deletes all messages in a channel.
  Future<void> clearChannelMessages(String channelId) => (delete(
    channelMessagesTable,
  )..where((t) => t.channelId.equals(channelId))).go();

  /// Removes a single participant from a channel.
  Future<void> removeParticipant(String channelId, String agentId) =>
      (delete(channelParticipantsTable)
            ..where((t) => t.channelId.equals(channelId))
            ..where((t) => t.agentId.equals(agentId)))
          .go();

  /// Updates the embedding blob for a message.
  Future<void> updateMessageEmbedding(String id, Uint8List embedding) =>
      (update(channelMessagesTable)..where((t) => t.id.equals(id))).write(
        ChannelMessagesTableCompanion(embedding: Value(embedding)),
      );

  /// Returns messages for a channel that have embeddings, ordered by creation.
  Future<List<ChannelMessagesTableData>> getMessagesWithEmbedding(
    String channelId,
  ) =>
      (select(channelMessagesTable)
            ..where(
              (t) =>
                  t.channelId.equals(channelId) & t.embedding.isNotNull(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// Returns messages that have NULL embedding, limited for batch processing.
  ///
  /// CROSS-WORKSPACE BY DESIGN — the embedding backfill runs once at startup
  /// and must process **every workspace's** un-embedded messages, so it is
  /// intentionally not workspace-scoped. Not for agent-facing reads.
  Future<List<ChannelMessagesTableData>> getMessagesWithoutEmbedding({
    int limit = 200,
  }) =>
      (select(channelMessagesTable)
            ..where((t) => t.embedding.isNull())
            ..where(
              (t) => t.messageType.isIn(['text', 'system']) &
                  t.compacted.equals(false),
            )
            ..limit(limit))
          .get();
}
