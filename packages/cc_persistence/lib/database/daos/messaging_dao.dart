import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart' show ConversationMode;
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/channel_messages.dart';
import 'package:cc_persistence/database/tables/channel_participants.dart';
import 'package:cc_persistence/database/tables/channels.dart';
import 'package:drift/drift.dart';

part 'messaging_dao.g.dart';

/// Implicit SQLite `rowid` — a monotonic integer assigned in insertion order
/// for this (normal, not `WITHOUT ROWID`) table. Used as a stable tie-breaker
/// for message ordering: `created_at` is stored at **second** resolution (Drift
/// `currentDateAndTime` truncates to whole seconds), so messages inserted in
/// the same second — e.g. a user message and its immediately-dispatched agent
/// reply — share an identical `created_at` and `ORDER BY created_at` alone
/// returns them in an unspecified order. That surfaced as agent replies
/// rendering *above* the user message that triggered them. The `id` column is a
/// random UUID and is *not* a valid tie-breaker.
const _rowid = CustomExpression<int>('rowid');

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

  /// Watches messages for a channel ordered by creation time. Reverted
  /// messages are hidden (an unrevert restores them).
  Stream<List<ChannelMessagesTableData>> watchMessages(String channelId) =>
      (select(channelMessagesTable)
            ..where(
              (t) => t.channelId.equals(channelId) & t.reverted.equals(false),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (_) => OrderingTerm.asc(_rowid),
            ]))
          .watch();

  /// Watches top-level messages (no parent) for a channel. Reverted messages
  /// are hidden.
  Stream<List<ChannelMessagesTableData>> watchTopLevelMessages(
    String channelId,
  ) =>
      (select(channelMessagesTable)
            ..where(
              (t) =>
                  t.channelId.equals(channelId) &
                  t.parentMessageId.isNull() &
                  t.reverted.equals(false),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (_) => OrderingTerm.asc(_rowid),
            ]))
          .watch();

  /// Watches the newest [limit] top-level messages for a channel, returned in
  /// ascending order (oldest-first) for display. Fetches `limit + 1` so the
  /// caller can tell whether older messages exist (the hasMore sentinel). The
  /// `(createdAt desc, rowid desc)` ordering keeps equal-timestamp rows stable.
  Stream<List<ChannelMessagesTableData>> watchTopLevelMessagesWindow(
    String channelId, {
    required int limit,
  }) =>
      (select(channelMessagesTable)
            ..where(
              (t) =>
                  t.channelId.equals(channelId) &
                  t.parentMessageId.isNull() &
                  t.reverted.equals(false),
            )
            ..orderBy([
              (t) => OrderingTerm.desc(t.createdAt),
              (_) => OrderingTerm.desc(_rowid),
            ])
            ..limit(limit + 1))
          .watch()
          .map((rows) => rows.reversed.toList());

  /// Returns one page of top-level messages strictly older than the cursor,
  /// newest-first, each paired with its stable `rowid`. `created_at` is stored
  /// at second resolution, so `rowid` is the tie-breaker — the page predicate
  /// is `created_at < t OR (created_at = t AND rowid < r)`. Callers ask for
  /// `limit + 1` to detect whether older messages remain.
  Future<List<({ChannelMessagesTableData data, int rowid})>>
      getTopLevelMessagePageRows(
    String channelId, {
    required int limit,
    int? beforeCreatedAtSeconds,
    int? beforeRowid,
  }) {
    final hasCursor = beforeCreatedAtSeconds != null && beforeRowid != null;
    return customSelect(
      'SELECT *, rowid AS _rowid FROM channel_messages '
      'WHERE channel_id = ? AND parent_message_id IS NULL AND reverted = 0 '
      '${hasCursor ? 'AND (created_at < ? OR (created_at = ? AND rowid < ?)) ' : ''}'
      'ORDER BY created_at DESC, rowid DESC LIMIT ?',
      variables: [
        Variable.withString(channelId),
        if (hasCursor) ...[
          Variable.withInt(beforeCreatedAtSeconds),
          Variable.withInt(beforeCreatedAtSeconds),
          Variable.withInt(beforeRowid),
        ],
        Variable.withInt(limit),
      ],
      readsFrom: {channelMessagesTable},
    ).map((row) => (
          data: channelMessagesTable.map(row.data),
          rowid: row.read<int>('_rowid'),
        )).get();
  }

  /// Watches threaded replies to a specific parent message.
  Stream<List<ChannelMessagesTableData>> watchThread(String parentMessageId) =>
      (select(channelMessagesTable)
            ..where((t) => t.parentMessageId.equals(parentMessageId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (_) => OrderingTerm.asc(_rowid),
            ]))
          .watch();

  /// Returns a single message by ID or null.
  Future<ChannelMessagesTableData?> getMessageById(String messageId) =>
      (select(channelMessagesTable)..where((t) => t.id.equals(messageId)))
          .getSingleOrNull();

  /// Returns all (non-reverted) messages for a channel in creation order.
  Future<List<ChannelMessagesTableData>> getMessages(String channelId) =>
      (select(channelMessagesTable)
            ..where(
              (t) => t.channelId.equals(channelId) & t.reverted.equals(false),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (_) => OrderingTerm.asc(_rowid),
            ]))
          .get();

  /// Reverts (rolls back) the given messages: marks them hidden and stamps a
  /// shared [revertedAtMs] so [getLatestRevertedBatch] can find this batch.
  Future<void> revertMessages(List<String> ids, int revertedAtMs) async {
    if (ids.isEmpty) {
      return;
    }
    await (update(channelMessagesTable)..where((t) => t.id.isIn(ids))).write(
      ChannelMessagesTableCompanion(
        reverted: const Value(true),
        revertedAt: Value(revertedAtMs),
      ),
    );
  }

  /// Clears the reverted flag on the given messages (an unrevert/redo).
  Future<void> unrevertMessages(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await (update(channelMessagesTable)..where((t) => t.id.isIn(ids))).write(
      const ChannelMessagesTableCompanion(
        reverted: Value(false),
        revertedAt: Value(null),
      ),
    );
  }

  /// Returns the message ids reverted in the most-recent revert batch for a
  /// channel (those sharing the maximum `reverted_at`), for unrevert.
  Future<List<String>> getLatestRevertedBatch(String channelId) async {
    final rows = await customSelect(
      'SELECT id FROM channel_messages '
      'WHERE channel_id = ? AND reverted = 1 AND reverted_at = '
      '(SELECT MAX(reverted_at) FROM channel_messages '
      ' WHERE channel_id = ? AND reverted = 1)',
      variables: [
        Variable.withString(channelId),
        Variable.withString(channelId),
      ],
      readsFrom: {channelMessagesTable},
    ).get();
    return rows.map((r) => r.read<String>('id')).toList();
  }

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
  /// Updates the read cursor for the user participant of [channelId] to now.
  /// Idempotent and cheap (a single write against the sentinel `'user'` row).
  /// Powers the sidebar unread indicator: once set, agent messages newer than
  /// this timestamp are "seen" only until another lands.
  Future<void> markChannelRead(String channelId) =>
      (update(channelParticipantsTable)
            ..where(
              (t) => t.channelId.equals(channelId) & t.agentId.equals('user'),
            ))
          .write(
            ChannelParticipantsTableCompanion(lastReadAt: Value(DateTime.now())),
          );

  /// Watches the user participant's read cursor for [channelId], or null when
  /// no user row exists yet / it has never been set.
  Stream<DateTime?> watchUserLastReadAt(String channelId) {
    return (select(channelParticipantsTable)
          ..where(
            (t) => t.channelId.equals(channelId) & t.agentId.equals('user'),
          ))
        .watchSingleOrNull()
        .map((row) => row?.lastReadAt);
  }

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
                  t.channelId.equals(channelId) &
                  t.embedding.isNotNull() &
                  t.reverted.equals(false),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (_) => OrderingTerm.asc(_rowid),
            ]))
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
              (t) => t.messageType
                      .isIn(['text', 'system', 'agent_turn', 'compaction']) &
                  t.compacted.equals(false),
            )
            ..limit(limit))
          .get();
}
