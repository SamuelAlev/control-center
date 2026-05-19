import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/mode.dart' show Mode;
import 'package:cc_persistence/database/tables/channel_messages.dart';
import 'package:cc_persistence/database/tables/channel_participants.dart';
import 'package:cc_persistence/database/tables/channels.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:cc_persistence/database/utils/fts_query_utils.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
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
  tables: [
    ChannelsTable,
    ConversationsTable,
    ChannelParticipantsTable,
    ChannelMessagesTable,
  ],
)
class MessagingDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$MessagingDaoMixin {
  /// Creates a [MessagingDao] for the given database.
  MessagingDao(super.attachedDatabase);

  /// Watches this workspace's channels, most recently updated first.
  ///
  /// Unfiltered, and safe: this DAO hangs off one workspace's database, so
  /// "every channel in the file" is "every channel in the workspace". The
  /// all-workspaces dashboard view merges one of these streams per workspace
  /// through `CrossWorkspaceQueries.mergeStreams` — it does not filter a global
  /// stream in memory, which is how other workspaces' channels leaked before.
  Stream<List<ChannelsTableData>> watchChannels() => (select(
    channelsTable,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  /// Watches participants for a channel.
  Stream<List<ChannelParticipantsTableData>> watchParticipants(
    String channelId,
  ) =>
      (select(channelParticipantsTable)
            ..where((t) => t.channelId.equals(channelId))
            ..orderBy([(t) => OrderingTerm.asc(t.joinedAt)]))
          .watch();

  /// Watches channels for a specific workspace ordered by most recently updated.
  Stream<List<ChannelsTableData>> watchChannelsByWorkspace(
    String workspaceId,
  ) =>
      (select(channelsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  /// Watches the messages of one conversation ordered by creation time.
  /// Reverted messages are hidden (an unrevert restores them).
  Stream<List<ChannelMessagesTableData>> watchMessages(String conversationId) =>
      (select(channelMessagesTable)
            ..where(
              (t) =>
                  t.conversationId.equals(conversationId) &
                  t.reverted.equals(false),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (_) => OrderingTerm.asc(_rowid),
            ]))
          .watch();

  /// Watches the newest [limit] messages of a conversation, returned in
  /// ascending order (oldest-first) for display. Fetches `limit + 1` so the
  /// caller can tell whether older messages exist (the hasMore sentinel). The
  /// `(createdAt desc, rowid desc)` ordering keeps equal-timestamp rows stable.
  Stream<List<ChannelMessagesTableData>> watchMessagesWindow(
    String conversationId, {
    required int limit,
  }) =>
      (select(channelMessagesTable)
            ..where(
              (t) =>
                  t.conversationId.equals(conversationId) &
                  t.reverted.equals(false),
            )
            ..orderBy([
              (t) => OrderingTerm.desc(t.createdAt),
              (_) => OrderingTerm.desc(_rowid),
            ])
            ..limit(limit + 1))
          .watch()
          .map((rows) => rows.reversed.toList());

  /// Returns one page of a conversation's messages strictly older than the
  /// cursor, newest-first, each paired with its stable `rowid`. `created_at` is
  /// stored at second resolution, so `rowid` is the tie-breaker — the page
  /// predicate is `created_at < t OR (created_at = t AND rowid < r)`. Callers
  /// ask for `limit + 1` to detect whether older messages remain.
  Future<List<({ChannelMessagesTableData data, int rowid})>> getMessagePageRows(
    String conversationId, {
    required int limit,
    int? beforeCreatedAtSeconds,
    int? beforeRowid,
  }) {
    final hasCursor = beforeCreatedAtSeconds != null && beforeRowid != null;
    return customSelect(
          'SELECT *, rowid AS _rowid FROM channel_messages '
          'WHERE conversation_id = ? AND reverted = 0 '
          '${hasCursor ? 'AND (created_at < ? OR (created_at = ? AND rowid < ?)) ' : ''}'
          'ORDER BY created_at DESC, rowid DESC LIMIT ?',
          variables: [
            Variable.withString(conversationId),
            if (hasCursor) ...[
              Variable.withInt(beforeCreatedAtSeconds),
              Variable.withInt(beforeCreatedAtSeconds),
              Variable.withInt(beforeRowid),
            ],
            Variable.withInt(limit),
          ],
          readsFrom: {channelMessagesTable},
        )
        .map(
          (row) => (
            data: channelMessagesTable.map(row.data),
            rowid: row.read<int>('_rowid'),
          ),
        )
        .get();
  }

  /// Watches per-channel activity signals for one workspace: newest message
  /// time, newest agent-message time in the channel's `main` conversation (the
  /// unread-dot signal), and the open (unanswered) agent-question count in
  /// `main` (the needs-input signal). One aggregate row per channel — the
  /// sidebar's replacement for a full message-list subscription per row.
  /// Parentheses are intentionally excluded so side work never bumps the badge:
  /// the `main` conversation's id equals the channel id.
  Stream<
    List<
      ({
        String channelId,
        DateTime? lastMessageAt,
        DateTime? lastAgentMessageAt,
        int openQuestionCount,
      })
    >
  >
  watchChannelActivity(String workspaceId) =>
      customSelect(
        'SELECT m.channel_id AS channel_id, '
        'MAX(m.created_at) AS last_message_at, '
        "MAX(CASE WHEN m.sender_type = 'agent' "
        '  AND m.conversation_id = m.channel_id THEN m.created_at END) '
        'AS last_agent_message_at, '
        "COALESCE(SUM(CASE WHEN m.message_type = 'user_question' "
        '  AND m.conversation_id = m.channel_id '
        "  AND COALESCE(json_extract(m.metadata, '\$.answered'), 0) != 1 "
        'THEN 1 ELSE 0 END), 0) AS open_question_count '
        'FROM channel_messages m '
        'JOIN channels c ON c.id = m.channel_id '
        'WHERE c.workspace_id = ? AND m.reverted = 0 '
        'GROUP BY m.channel_id',
        variables: [Variable.withString(workspaceId)],
        readsFrom: {channelMessagesTable, channelsTable},
      ).watch().map(
        (rows) => [
          for (final row in rows)
            (
              channelId: row.read<String>('channel_id'),
              lastMessageAt: switch (row.readNullable<int>('last_message_at')) {
                final int s => DateTime.fromMillisecondsSinceEpoch(s * 1000),
                null => null,
              },
              lastAgentMessageAt: switch (row.readNullable<int>(
                'last_agent_message_at',
              )) {
                final int s => DateTime.fromMillisecondsSinceEpoch(s * 1000),
                null => null,
              },
              openQuestionCount: row.read<int>('open_question_count'),
            ),
        ],
      );

  /// Returns a single message by ID or null.
  Future<ChannelMessagesTableData?> getMessageById(String messageId) => (select(
    channelMessagesTable,
  )..where((t) => t.id.equals(messageId))).getSingleOrNull();

  /// Returns all (non-reverted) messages for a conversation in creation order.
  Future<List<ChannelMessagesTableData>> getMessages(String conversationId) =>
      (select(channelMessagesTable)
            ..where(
              (t) =>
                  t.conversationId.equals(conversationId) &
                  t.reverted.equals(false),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (_) => OrderingTerm.asc(_rowid),
            ]))
          .get();

  /// Reverts (rolls back) the given messages: marks them hidden and stamps a
  /// shared [revertedAtMs] so [getLatestRevertedBatch] can find this batch.
  ///
  /// If [revertedAtMs] would tie a prior batch's timestamp (rapid reverts
  /// inside one millisecond), it is bumped one past the channel's current max
  /// so each batch stays individually addressable for unrevert.
  Future<void> revertMessages(List<String> ids, int revertedAtMs) async {
    if (ids.isEmpty) {
      return;
    }
    final channelIds =
        await (selectOnly(channelMessagesTable)
              ..addColumns([channelMessagesTable.channelId])
              ..where(channelMessagesTable.id.isIn(ids)))
            .map((row) => row.read(channelMessagesTable.channelId))
            .get();
    var stamp = revertedAtMs;
    for (final channelId in channelIds.whereType<String>().toSet()) {
      final maxRow =
          await (selectOnly(channelMessagesTable)
                ..addColumns([channelMessagesTable.revertedAt])
                ..where(
                  channelMessagesTable.channelId.equals(channelId) &
                      channelMessagesTable.reverted.equals(true) &
                      channelMessagesTable.revertedAt.isNotNull(),
                ))
              .map((row) => row.read(channelMessagesTable.revertedAt) ?? 0)
              .get();
      final currentMax = maxRow.isEmpty
          ? 0
          : maxRow.reduce((a, b) => a > b ? a : b);
      if (stamp <= currentMax) {
        stamp = currentMax + 1;
      }
    }
    await (update(channelMessagesTable)..where((t) => t.id.isIn(ids))).write(
      ChannelMessagesTableCompanion(
        reverted: const Value(true),
        revertedAt: Value(stamp),
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

  /// Inserts a channel and seeds its `main` conversation (id == channel id) so
  /// the `conversation_id` FK on [ChannelMessagesTable] always resolves.
  Future<void> insertChannel(ChannelsTableCompanion entry) async {
    await into(channelsTable).insert(entry);
    if (entry.id.present) {
      await ensureMainConversation(
        entry.id.value,
        workspaceId: entry.workspaceId.present ? entry.workspaceId.value : null,
      );
    }
  }

  /// Ensures the channel's `main` conversation exists (id == channel id). Safe
  /// to call repeatedly; a conflict on the primary key is ignored. Called from
  /// channel creation and lazily before the first message so the
  /// `conversation_id` FK on [ChannelMessagesTable] always resolves.
  Future<void> ensureMainConversation(
    String channelId, {
    String? workspaceId,
  }) => into(conversationsTable).insert(
    ConversationsTableCompanion(
      id: Value(channelId),
      channelId: Value(channelId),
      workspaceId: workspaceId != null
          ? Value(workspaceId)
          : const Value.absent(),
      title: const Value('Main'),
      kind: const Value('main'),
      status: const Value('active'),
    ),
    mode: InsertMode.insertOrIgnore,
  );

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

  /// Updates the [Mode]-serialized value for a channel.
  Future<void> updateChannelMode(String channelId, String mode) =>
      (update(channelsTable)..where((t) => t.id.equals(channelId))).write(
        ChannelsTableCompanion(mode: Value(mode)),
      );

  /// Updates the provisioning status for a channel. Leaving `provisioning`
  /// also clears the granular step in the same write, so a non-null
  /// `provisioning_step` can never accompany a `ready`/`failed` row.
  Future<void> updateChannelProvisioningStatus(
    String channelId,
    String status,
  ) => (update(channelsTable)..where((t) => t.id.equals(channelId))).write(
    ChannelsTableCompanion(
      provisioningStatus: Value(status),
      provisioningStep: status == 'provisioning'
          ? const Value.absent()
          : const Value(null),
    ),
  );

  /// Updates the granular in-flight provisioning step for a channel
  /// (`ChannelProvisioningStep.toDbValue()` JSON, or null to clear).
  Future<void> updateChannelProvisioningStep(String channelId, String? step) =>
      (update(channelsTable)..where((t) => t.id.equals(channelId))).write(
        ChannelsTableCompanion(provisioningStep: Value(step)),
      );

  /// This workspace's channels whose provisioning status equals [status].
  ///
  /// Used by the boot reconciler to re-kick channels a previous session
  /// stranded in `provisioning` (the flip to ready/failed only ever comes from
  /// the in-flight provisioning future, so a restart mid-provision would leave
  /// them stuck forever). The reconciler visits every workspace's database in
  /// turn, so it reaches all of them without this query spanning any.
  Future<List<ChannelsTableData>> channelsByProvisioningStatus(String status) =>
      (select(
        channelsTable,
      )..where((t) => t.provisioningStatus.equals(status))).get();

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

  /// Full-text search within a single channel (§8.4). Matches [query] against
  /// message content via the `channel_messages_fts` index, scoped to
  /// [channelId] on the content table (the authoritative filter — messages have
  /// no `workspace_id`, so the caller/RPC validates channel ownership), newest
  /// results first for ties. Reverted (hidden) messages are excluded. Returns
  /// an empty list when the query has no usable search tokens.
  Future<List<ChannelMessagesTableData>> searchInChannel(
    String channelId,
    String query, {
    int limit = 50,
  }) {
    final orQuery = toFtsOrQuery(query);
    if (orQuery.isEmpty) {
      return Future.value(const []);
    }
    return customSelect(
      'SELECT m.* FROM channel_messages m '
      'JOIN channel_messages_fts fts ON fts.rowid = m.rowid '
      'WHERE fts.channel_messages_fts MATCH ? '
      'AND m.channel_id = ? '
      'AND m.reverted = 0 '
      'ORDER BY rank, m.rowid DESC '
      'LIMIT ?',
      variables: [
        Variable<String>('content : ($orQuery)'),
        Variable<String>(channelId),
        Variable<int>(limit),
      ],
      readsFrom: {channelMessagesTable},
    ).map((row) => channelMessagesTable.map(row.data)).get();
  }

  /// Returns the channel row by id, or null.
  Future<ChannelsTableData?> getChannelById(String channelId) => (select(
    channelsTable,
  )..where((t) => t.id.equals(channelId))).getSingleOrNull();

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

  /// Removes a single participant (agent or user) from a channel.
  Future<void> removeParticipant(String channelId, String principalId) =>
      (delete(channelParticipantsTable)
            ..where((t) => t.channelId.equals(channelId))
            ..where((t) => t.principalId.equals(principalId)))
          .go();

  /// Updates [userId]'s read cursor on [channelId] to now. Idempotent and
  /// cheap (a single write against that user's participant row). Lazily
  /// creates the row the first time a user opens a channel they weren't an
  /// original participant of (hidden/pipeline channels). Powers the sidebar
  /// unread indicator: once set, agent messages newer than this timestamp are
  /// "seen" only until another lands.
  Future<void> markChannelRead(String channelId, String userId) async {
    final updated =
        await (update(channelParticipantsTable)..where(
              (t) =>
                  t.channelId.equals(channelId) &
                  t.participantType.equals('user') &
                  t.principalId.equals(userId),
            ))
            .write(
              ChannelParticipantsTableCompanion(
                lastReadAt: Value(DateTime.now()),
              ),
            );
    if (updated == 0) {
      await into(channelParticipantsTable).insert(
        ChannelParticipantsTableCompanion(
          id: Value('$channelId-user-$userId'),
          channelId: Value(channelId),
          principalId: Value(userId),
          participantType: const Value('user'),
          lastReadAt: Value(DateTime.now()),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  /// Watches [userId]'s read cursor on [channelId], or null when no row
  /// exists yet / it has never been set.
  Stream<DateTime?> watchUserLastReadAt(String channelId, String userId) {
    return (select(channelParticipantsTable)..where(
          (t) =>
              t.channelId.equals(channelId) &
              t.participantType.equals('user') &
              t.principalId.equals(userId),
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

  /// This workspace's messages with a NULL embedding, limited for batch
  /// processing.
  ///
  /// The startup embedding backfill must reach every workspace's un-embedded
  /// messages, which it does by visiting each workspace's database in turn —
  /// each embedding is then written back to the file its message came from.
  Future<List<ChannelMessagesTableData>> getMessagesWithoutEmbedding({
    int limit = 200,
  }) =>
      (select(channelMessagesTable)
            ..where((t) => t.embedding.isNull())
            ..where(
              (t) =>
                  t.messageType.isIn([
                    'text',
                    'system',
                    'agent_turn',
                    'compaction',
                  ]) &
                  t.compacted.equals(false),
            )
            ..limit(limit))
          .get();
}
