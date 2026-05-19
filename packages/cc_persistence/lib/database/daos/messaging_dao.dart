import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/mode.dart' show Mode;
import 'package:cc_persistence/database/tables/conversation_messages.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:cc_persistence/database/tables/space_participants.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
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

/// Data access object for [SpacesTable], [SpaceParticipantsTable] and
/// [ConversationMessagesTable].
@DriftAccessor(
  tables: [
    SpacesTable,
    ConversationsTable,
    SpaceParticipantsTable,
    ConversationMessagesTable,
  ],
)
class MessagingDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$MessagingDaoMixin {
  /// Creates a [MessagingDao] for the given database.
  MessagingDao(super.attachedDatabase);

  /// Watches this workspace's spaces, most recently updated first.
  ///
  /// Unfiltered and safe: this DAO hangs off one workspace's database, so
  /// "every space in the file" is "every space in the workspace". The
  /// all-workspaces dashboard view merges one of these streams per workspace
  /// through `CrossWorkspaceQueries.mergeStreams` — it does not filter a global
  /// stream in memory, which is how other workspaces' spaces leaked before.
  Stream<List<SpacesTableData>> watchSpaces() => (select(
    spacesTable,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  /// Watches participants for a space.
  Stream<List<SpaceParticipantsTableData>> watchParticipants(String spaceId) =>
      (select(spaceParticipantsTable)
            ..where((t) => t.spaceId.equals(spaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.joinedAt)]))
          .watch();

  /// Watches spaces for a specific workspace ordered by most recently updated.
  Stream<List<SpacesTableData>> watchSpacesByWorkspace(String workspaceId) =>
      (select(spacesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  /// Every `conversation_messages` column except `embedding`, as a SELECT list.
  ///
  /// The embedding is a 1,536-byte FLOAT32 blob per row that exists only for
  /// semantic recall — nothing that reads a message LIST ever looks at it, and
  /// no wire shape carries it. A `SELECT *` over a 10k-message conversation
  /// therefore dragged ~15 MB off disk (and re-read all of it on every write
  /// to the table) to hand back rows whose blob is then dropped.
  ///
  /// Derived from the table's own column list rather than spelled out, so a
  /// column added later is included automatically instead of silently
  /// arriving null.
  late final String _messageColumnsSansEmbedding = conversationMessagesTable
      .$columns
      .where((c) => c.name != 'embedding')
      .map((c) => c.name)
      .join(', ');

  /// Watches the messages of one conversation ordered by creation time.
  /// Reverted messages are hidden (an unrevert restores them).
  Stream<List<ConversationMessagesTableData>> watchMessages(
    String conversationId,
  ) =>
      customSelect(
        'SELECT $_messageColumnsSansEmbedding FROM conversation_messages '
        'WHERE conversation_id = ? AND reverted = 0 '
        'ORDER BY created_at ASC, rowid ASC',
        variables: [Variable.withString(conversationId)],
        readsFrom: {conversationMessagesTable},
      ).watch().map(
        (rows) => rows
            .map((r) => conversationMessagesTable.map(r.data))
            .toList(growable: false),
      );

  /// Watches the newest [limit] messages of a conversation, returned in
  /// ascending order (oldest-first) for display. Fetches `limit + 1` so the
  /// caller can tell whether older messages exist (the hasMore sentinel). The
  /// `(createdAt desc, rowid desc)` ordering keeps equal-timestamp rows stable.
  Stream<List<ConversationMessagesTableData>> watchMessagesWindow(
    String conversationId, {
    required int limit,
  }) =>
      customSelect(
        'SELECT $_messageColumnsSansEmbedding FROM conversation_messages '
        'WHERE conversation_id = ? AND reverted = 0 '
        'ORDER BY created_at DESC, rowid DESC LIMIT ?',
        variables: [
          Variable.withString(conversationId),
          Variable.withInt(limit + 1),
        ],
        readsFrom: {conversationMessagesTable},
      ).watch().map(
        (rows) => rows.reversed
            .map((r) => conversationMessagesTable.map(r.data))
            .toList(growable: false),
      );

  /// Watches the per-message character counts of a conversation's LIVE region
  /// (not reverted, not compacted), oldest-first.
  ///
  /// Three small integers per row instead of the row: the context meters need
  /// a sum, and reading whole messages to produce one meant an unbounded
  /// `SELECT` — content, metadata and every agent turn's transcript blob —
  /// re-run and re-shipped on every write to the table.
  ///
  /// `transcript_chars` is extracted IN SQLITE. It lives inside the metadata
  /// JSON alongside `segments`, which is the megabyte the projection exists to
  /// leave behind; pulling the column into Dart to read one integer off it
  /// would move the cost rather than remove it. A row without the field (an
  /// older turn, or any non-turn message) reports 0 and the caller falls back
  /// to its content length, exactly as the entity-level estimator does.
  ///
  /// Per-row rather than a single `SUM`: the estimate rounds UP per message,
  /// so summing characters first and rounding once would drift from
  /// `estimateMessages` by up to one token per message — and the meter is
  /// supposed to agree with the compaction trigger.
  Stream<List<({String messageType, int contentChars, int transcriptChars})>>
  watchConversationCharCounts(String conversationId) =>
      customSelect(
        'SELECT message_type, '
        'LENGTH(content) AS content_chars, '
        "CAST(COALESCE(json_extract(metadata, '\$.transcriptChars'), 0) AS INTEGER) "
        'AS transcript_chars '
        'FROM conversation_messages '
        'WHERE conversation_id = ? AND reverted = 0 AND compacted = 0 '
        'ORDER BY created_at ASC, rowid ASC',
        variables: [Variable.withString(conversationId)],
        readsFrom: {conversationMessagesTable},
      ).watch().map(
        (rows) => rows
            .map(
              (r) => (
                messageType: r.read<String>('message_type'),
                contentChars: r.read<int>('content_chars'),
                transcriptChars: r.read<int>('transcript_chars'),
              ),
            )
            .toList(growable: false),
      );

  /// Returns one page of a conversation's messages strictly older than the
  /// cursor, newest-first, each paired with its stable `rowid`. `created_at` is
  /// stored at second resolution, so `rowid` is the tie-breaker — the page
  /// predicate is `created_at < t OR (created_at = t AND rowid < r)`. Callers
  /// ask for `limit + 1` to detect whether older messages remain.
  ///
  /// Scoped by [spaceId] as well as [conversationId], and that is an
  /// AUTHORIZATION predicate, not a filter. A conversation belongs to exactly
  /// one space, so for a legitimate caller the extra equality changes
  /// nothing — but the caller-supplied conversation id used to be the ONLY
  /// predicate. Callers prove they own a SPACE; if the query does not also
  /// bind to that space, owning any one space reads every conversation in
  /// the workspace file. Cheap, too:
  /// `idx_conversation_messages_conversation_created` still drives the scan
  /// and this narrows it.
  Future<List<({ConversationMessagesTableData data, int rowid})>>
  getMessagePageRows(
    String spaceId,
    String conversationId, {
    required int limit,
    int? beforeCreatedAtSeconds,
    int? beforeRowid,
  }) {
    final hasCursor = beforeCreatedAtSeconds != null && beforeRowid != null;
    return customSelect(
          'SELECT $_messageColumnsSansEmbedding, rowid AS _rowid '
          'FROM conversation_messages '
          'WHERE space_id = ? AND conversation_id = ? AND reverted = 0 '
          '${hasCursor ? 'AND (created_at < ? OR (created_at = ? AND rowid < ?)) ' : ''}'
          'ORDER BY created_at DESC, rowid DESC LIMIT ?',
          variables: [
            Variable.withString(spaceId),
            Variable.withString(conversationId),
            if (hasCursor) ...[
              Variable.withInt(beforeCreatedAtSeconds),
              Variable.withInt(beforeCreatedAtSeconds),
              Variable.withInt(beforeRowid),
            ],
            Variable.withInt(limit),
          ],
          readsFrom: {conversationMessagesTable},
        )
        .map(
          (row) => (
            data: conversationMessagesTable.map(row.data),
            rowid: row.read<int>('_rowid'),
          ),
        )
        .get();
  }

  /// Watches per-space activity signals for one workspace: newest message
  /// time, newest agent-message time (the unread-dot signal) and the open
  /// (unanswered) agent-question count (the needs-input signal). One aggregate
  /// row per space — the sidebar's replacement for a full message-list
  /// subscription per row.
  ///
  /// EVERY conversation in the space counts, threads included: read marks are
  /// space-scoped, so unread aggregates across the whole space. This used to
  /// narrow both signals with `m.conversation_id = m.space_id` to exclude side
  /// conversations. That predicate can no longer be true — a conversation owns
  /// its own uuid — so it silently zeroed the agent-reply dot and the
  /// open-question count for every space.
  ///
  /// Archived spaces are excluded: an archived space's row is gone from the
  /// sidebar, so its unread/needs-input signals would have no visible home —
  /// and a hidden room must not keep demanding attention. Restoring the
  /// space brings its signals back (nothing was deleted).
  Stream<
    List<
      ({
        String spaceId,
        DateTime? lastMessageAt,
        DateTime? lastAgentMessageAt,
        int openQuestionCount,
      })
    >
  >
  watchSpaceActivity(String workspaceId) =>
      customSelect(
        'SELECT m.space_id AS space_id, '
        'MAX(m.created_at) AS last_message_at, '
        "MAX(CASE WHEN m.sender_type = 'agent' "
        'THEN m.created_at END) '
        'AS last_agent_message_at, '
        "COALESCE(SUM(CASE WHEN m.message_type = 'user_question' "
        "  AND COALESCE(json_extract(m.metadata, '\$.answered'), 0) != 1 "
        'THEN 1 ELSE 0 END), 0) AS open_question_count '
        'FROM conversation_messages m '
        'JOIN spaces c ON c.id = m.space_id '
        'WHERE c.workspace_id = ? AND m.reverted = 0 '
        'AND c.archived_at IS NULL '
        'GROUP BY m.space_id',
        variables: [Variable.withString(workspaceId)],
        readsFrom: {conversationMessagesTable, spacesTable},
      ).watch().map(
        (rows) => [
          for (final row in rows)
            (
              spaceId: row.read<String>('space_id'),
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
  Future<ConversationMessagesTableData?> getMessageById(String messageId) =>
      (select(
        conversationMessagesTable,
      )..where((t) => t.id.equals(messageId))).getSingleOrNull();

  /// Returns all (non-reverted) messages for a conversation in creation order.
  Future<List<ConversationMessagesTableData>> getMessages(
    String conversationId,
  ) =>
      customSelect(
        'SELECT $_messageColumnsSansEmbedding FROM conversation_messages '
        'WHERE conversation_id = ? AND reverted = 0 '
        'ORDER BY created_at ASC, rowid ASC',
        variables: [Variable.withString(conversationId)],
        readsFrom: {conversationMessagesTable},
      ).get().then(
        (rows) => rows
            .map((r) => conversationMessagesTable.map(r.data))
            .toList(growable: false),
      );

  /// Reverts (rolls back) the given messages: marks them hidden and stamps a
  /// shared [revertedAtMs] so [getLatestRevertedBatch] can find this batch.
  ///
  /// If [revertedAtMs] would tie a prior batch's timestamp (rapid reverts
  /// inside one millisecond), it is bumped one past the space's current max
  /// so each batch stays individually addressable for unrevert.
  Future<void> revertMessages(List<String> ids, int revertedAtMs) async {
    if (ids.isEmpty) {
      return;
    }
    final spaceIds =
        await (selectOnly(conversationMessagesTable)
              ..addColumns([conversationMessagesTable.spaceId])
              ..where(conversationMessagesTable.id.isIn(ids)))
            .map((row) => row.read(conversationMessagesTable.spaceId))
            .get();
    var stamp = revertedAtMs;
    for (final spaceId in spaceIds.whereType<String>().toSet()) {
      final maxRow =
          await (selectOnly(conversationMessagesTable)
                ..addColumns([conversationMessagesTable.revertedAt])
                ..where(
                  conversationMessagesTable.spaceId.equals(spaceId) &
                      conversationMessagesTable.reverted.equals(true) &
                      conversationMessagesTable.revertedAt.isNotNull(),
                ))
              .map((row) => row.read(conversationMessagesTable.revertedAt) ?? 0)
              .get();
      final currentMax = maxRow.isEmpty
          ? 0
          : maxRow.reduce((a, b) => a > b ? a : b);
      if (stamp <= currentMax) {
        stamp = currentMax + 1;
      }
    }
    await (update(
      conversationMessagesTable,
    )..where((t) => t.id.isIn(ids))).write(
      ConversationMessagesTableCompanion(
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
    await (update(
      conversationMessagesTable,
    )..where((t) => t.id.isIn(ids))).write(
      const ConversationMessagesTableCompanion(
        reverted: Value(false),
        revertedAt: Value(null),
      ),
    );
  }

  /// Returns the message ids reverted in the most-recent revert batch for a
  /// space (those sharing the maximum `reverted_at`), for unrevert.
  Future<List<String>> getLatestRevertedBatch(String spaceId) async {
    final rows = await customSelect(
      'SELECT id FROM conversation_messages '
      'WHERE space_id = ? AND reverted = 1 AND reverted_at = '
      '(SELECT MAX(reverted_at) FROM conversation_messages '
      ' WHERE space_id = ? AND reverted = 1)',
      variables: [Variable.withString(spaceId), Variable.withString(spaceId)],
      readsFrom: {conversationMessagesTable},
    ).get();
    return rows.map((r) => r.read<String>('id')).toList();
  }

  /// Marks messages matching [ids] as compacted.
  Future<void> markCompacted(List<String> ids) async {
    await (update(
      conversationMessagesTable,
    )..where((t) => t.id.isIn(ids))).write(
      const ConversationMessagesTableCompanion(compacted: Value(true)),
    );
  }

  /// Inserts a space. Deliberately seeds NO conversation: the standing one is
  /// minted lazily by `ConversationDao.ensureStandingConversation` with its
  /// own uuid on first use — there is no main-conversation id aliasing, and a
  /// space the pipeline fills with named conversations never grows an extra
  /// one. The `conversation_id` FK on [ConversationMessagesTable] still always
  /// resolves because every write path mints the standing row before insert.
  Future<void> insertSpace(SpacesTableCompanion entry) async {
    await into(spacesTable).insert(entry);
  }

  /// Inserts a participant, ignoring conflicts (prevents duplicates).
  Future<void> insertParticipant(SpaceParticipantsTableCompanion entry) => into(
    spaceParticipantsTable,
  ).insert(entry, mode: InsertMode.insertOrIgnore);

  /// Inserts a message.
  Future<void> insertMessage(ConversationMessagesTableCompanion entry) =>
      into(conversationMessagesTable).insert(entry);

  /// Deletes one message row by id.
  ///
  /// Queue-surgery affordance for steering rows only: they never become the
  /// conversation leaf (`DaoMessagingRepository.insertSteeringMessage` skips
  /// `setLeaf`), so no other row's `parent_message_id` can point at one and
  /// the delete cannot orphan the branch tree. Callers must have validated
  /// the row's type/state.
  Future<void> deleteMessageById(String messageId) => (delete(
    conversationMessagesTable,
  )..where((t) => t.id.equals(messageId))).go();

  /// Deletes one message row by id AND conversation — the ownership-checked
  /// form of `deleteMessageById` so a foreign workspace's row id resolves to
  /// nothing rather than to a hit.
  Future<void> deleteMessageInConversation(
    String conversationId,
    String messageId,
  ) =>
      (delete(conversationMessagesTable)
            ..where((t) => t.id.equals(messageId))
            ..where((t) => t.conversationId.equals(conversationId)))
          .go();

  /// The conversation's current branch tip, or the newest message when the
  /// conversation predates the tree.
  ///
  /// Falls back rather than returning null so an existing conversation joins
  /// the tree on its next message instead of starting a second root beside
  /// its own history.
  Future<String?> currentLeaf(String conversationId) async {
    final row = await (select(
      conversationsTable,
    )..where((t) => t.id.equals(conversationId))).getSingleOrNull();
    final pointer = row?.leafMessageId;
    if (pointer != null && pointer.isNotEmpty) {
      return pointer;
    }
    final newest =
        await (select(conversationMessagesTable)
              ..where((t) => t.conversationId.equals(conversationId))
              ..where((t) => t.reverted.equals(false))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return newest?.id;
  }

  /// Points a conversation at [messageId] (null = the newest message).
  Future<void> setLeaf(String conversationId, String? messageId) =>
      (update(conversationsTable)..where((t) => t.id.equals(conversationId)))
          .write(ConversationsTableCompanion(leafMessageId: Value(messageId)));

  /// Walks from [leafId] back to the root, newest first.
  ///
  /// Depth-capped: a corrupt parent chain that loops would otherwise walk
  /// forever, and a conversation is never legitimately this deep.
  Future<List<ConversationMessagesTableData>> branchFrom(
    String conversationId,
    String leafId, {
    int maxDepth = 10000,
  }) async {
    final all = await (select(
      conversationMessagesTable,
    )..where((t) => t.conversationId.equals(conversationId))).get();
    final byId = {for (final row in all) row.id: row};
    final path = <ConversationMessagesTableData>[];
    final seen = <String>{};
    String? cursor = leafId;
    while (cursor != null && path.length < maxDepth) {
      if (!seen.add(cursor)) {
        break;
      }
      final row = byId[cursor];
      if (row == null) {
        break;
      }
      path.add(row);
      cursor = row.parentMessageId;
    }
    return path.reversed.toList();
  }

  /// Every message in the conversation, whichever branch it is on.
  Future<List<ConversationMessagesTableData>> allMessagesForTree(
    String conversationId,
  ) =>
      (select(conversationMessagesTable)
            ..where((t) => t.conversationId.equals(conversationId))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .get();

  /// Updates the updatedAt timestamp for a space.
  Future<void> updateSpaceUpdatedAt(String spaceId, DateTime updatedAt) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(updatedAt: Value(updatedAt)),
      );

  /// Updates the [Mode]-serialized value for a space.
  Future<void> updateSpaceMode(String spaceId, String mode) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(mode: Value(mode)),
      );

  /// Updates the provisioning status for a space. Leaving `provisioning`
  /// also clears the granular step in the same write, so a non-null
  /// `provisioning_step` can never accompany a `ready`/`failed` row.
  Future<void> updateSpaceProvisioningStatus(String spaceId, String status) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(
          provisioningStatus: Value(status),
          provisioningStep: status == 'provisioning'
              ? const Value.absent()
              : const Value(null),
        ),
      );

  /// Updates the granular in-flight provisioning step for a space
  /// (`SpaceProvisioningStep.toDbValue()` JSON, or null to clear).
  Future<void> updateSpaceProvisioningStep(String spaceId, String? step) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(provisioningStep: Value(step)),
      );

  /// This workspace's spaces whose provisioning status equals [status].
  ///
  /// Used by the boot reconciler to re-kick spaces a previous session
  /// stranded in `provisioning` (the flip to ready/failed only ever comes from
  /// the in-flight provisioning future, so a restart mid-provision would leave
  /// them stuck forever). The reconciler visits every workspace's database in
  /// turn, so it reaches all of them without this query spanning any.
  Future<List<SpacesTableData>> spacesByProvisioningStatus(String status) =>
      (select(
        spacesTable,
      )..where((t) => t.provisioningStatus.equals(status))).get();

  /// Updates the content and/or metadata of an existing message.
  Future<void> updateMessage(
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? messageType,
  }) {
    return (update(
      conversationMessagesTable,
    )..where((t) => t.id.equals(messageId))).write(
      ConversationMessagesTableCompanion(
        content: content != null ? Value(content) : const Value.absent(),
        metadata: metadata != null
            ? Value(jsonEncode(metadata))
            : const Value.absent(),
        messageType: messageType != null
            ? Value(messageType)
            : const Value.absent(),
      ),
    );
  }

  /// Full-text search within a single space (§8.4). Matches [query] against
  /// message content via the `conversation_messages_fts` index, scoped to
  /// [spaceId] on the content table (the authoritative filter — messages have
  /// no `workspace_id`, so the caller/RPC validates space ownership), newest
  /// results first for ties. Reverted (hidden) messages are excluded. Returns
  /// an empty list when the query has no usable search tokens.
  Future<List<ConversationMessagesTableData>> searchInSpace(
    String spaceId,
    String query, {
    int limit = 50,
  }) {
    final orQuery = toFtsOrQuery(query);
    if (orQuery.isEmpty) {
      return Future.value(const []);
    }
    return customSelect(
      'SELECT m.* FROM conversation_messages m '
      'JOIN conversation_messages_fts fts ON fts.rowid = m.rowid '
      'WHERE fts.conversation_messages_fts MATCH ? '
      'AND m.space_id = ? '
      'AND m.reverted = 0 '
      'ORDER BY rank, m.rowid DESC '
      'LIMIT ?',
      variables: [
        Variable<String>('content : ($orQuery)'),
        Variable<String>(spaceId),
        Variable<int>(limit),
      ],
      readsFrom: {conversationMessagesTable},
    ).map((row) => conversationMessagesTable.map(row.data)).get();
  }

  /// Returns the space row by id, or null.
  Future<SpacesTableData?> getSpaceById(String spaceId) => (select(
    spacesTable,
  )..where((t) => t.id.equals(spaceId))).getSingleOrNull();

  /// Returns all participants for a space (for dedup checks).
  Future<List<SpaceParticipantsTableData>> getParticipants(String spaceId) =>
      (select(
        spaceParticipantsTable,
      )..where((t) => t.spaceId.equals(spaceId))).get();

  /// Deletes a space and all its messages and participants.
  ///
  /// The SPACE row goes first and FK `ON DELETE CASCADE` takes the children
  /// with it. Order matters for cost, not correctness: the sync-feed triggers
  /// on the child tables resolve their workspace with
  /// `(SELECT workspace_id FROM spaces WHERE id = OLD.space_id)` and fire
  /// only `WHEN` that is non-null. Deleting children first left the parent in
  /// place, so every one of a 10k-message space's rows ran three statements
  /// plus that subselect and wrote a `sync_changes` row — inside the database's
  /// only write transaction. With the parent gone the guard is false and the
  /// cascade is silent, which is also what delta clients expect: they see the
  /// space's own delete change and cascade child removal locally.
  Future<void> deleteSpaceCascade(String spaceId) => transaction(() async {
    await (delete(spacesTable)..where((t) => t.id.equals(spaceId))).go();
    // Belt and braces for a row whose FK somehow did not cascade (a legacy
    // file created before the constraint, or `foreign_keys` off).
    await (delete(
      conversationMessagesTable,
    )..where((t) => t.spaceId.equals(spaceId))).go();
    await (delete(
      spaceParticipantsTable,
    )..where((t) => t.spaceId.equals(spaceId))).go();
  });

  /// Updates the space name.
  Future<void> updateSpaceName(String spaceId, String name) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(name: Value(name)),
      );

  /// Stamps (or clears, when [archivedAt] is null) a space's archive time.
  /// `updatedAt` is deliberately untouched: archiving is a hide, not an
  /// activity, so a restored space keeps its recency position in the list.
  Future<void> setSpaceArchived(String spaceId, DateTime? archivedAt) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(archivedAt: Value(archivedAt)),
      );

  /// Sets the space's `no_repos` flag — the only way "explicitly no repos"
  /// is expressible, since zero `space_repos` rows already means "all repos".
  Future<void> updateSpaceNoRepos(String spaceId, bool noRepos) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(noRepos: Value(noRepos)),
      );

  /// Deletes all messages in a space.
  Future<void> clearSpaceMessages(String spaceId) => (delete(
    conversationMessagesTable,
  )..where((t) => t.spaceId.equals(spaceId))).go();

  /// Removes a single participant (agent or user) from a space.
  Future<void> removeParticipant(String spaceId, String principalId) =>
      (delete(spaceParticipantsTable)
            ..where((t) => t.spaceId.equals(spaceId))
            ..where((t) => t.principalId.equals(principalId)))
          .go();

  /// Updates [userId]'s read cursor on [spaceId] to now. Idempotent and
  /// cheap (a single write against that user's participant row). Lazily
  /// creates the row the first time a user opens a space they weren't an
  /// original participant of (hidden/pipeline spaces). Powers the sidebar
  /// unread indicator: once set, agent messages newer than this timestamp are
  /// "seen" only until another lands.
  Future<void> markSpaceRead(String spaceId, String userId) async {
    final updated =
        await (update(spaceParticipantsTable)..where(
              (t) =>
                  t.spaceId.equals(spaceId) &
                  t.participantType.equals('user') &
                  t.principalId.equals(userId),
            ))
            .write(
              SpaceParticipantsTableCompanion(
                lastReadAt: Value(DateTime.now()),
              ),
            );
    if (updated == 0) {
      await into(spaceParticipantsTable).insert(
        SpaceParticipantsTableCompanion(
          id: Value('$spaceId-user-$userId'),
          spaceId: Value(spaceId),
          principalId: Value(userId),
          participantType: const Value('user'),
          lastReadAt: Value(DateTime.now()),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  /// Watches [userId]'s read cursor on [spaceId], or null when no row
  /// exists yet / it has never been set.
  Stream<DateTime?> watchUserLastReadAt(String spaceId, String userId) {
    return (select(spaceParticipantsTable)..where(
          (t) =>
              t.spaceId.equals(spaceId) &
              t.participantType.equals('user') &
              t.principalId.equals(userId),
        ))
        .watchSingleOrNull()
        .map((row) => row?.lastReadAt);
  }

  /// Updates the embedding blob for a message.
  Future<void> updateMessageEmbedding(String id, Uint8List embedding) =>
      (update(conversationMessagesTable)..where((t) => t.id.equals(id))).write(
        ConversationMessagesTableCompanion(embedding: Value(embedding)),
      );

  /// Watches all (non-reverted) messages in a space, across every conversation
  /// it holds, in creation order. Streaming twin of [getMessagesForSpace].
  Stream<List<ConversationMessagesTableData>> watchMessagesForSpace(
    String spaceId,
  ) =>
      customSelect(
        'SELECT $_messageColumnsSansEmbedding FROM conversation_messages '
        'WHERE space_id = ? AND reverted = 0 '
        'ORDER BY created_at ASC, rowid ASC',
        variables: [Variable.withString(spaceId)],
        readsFrom: {conversationMessagesTable},
      ).watch().map(
        (rows) => rows
            .map((r) => conversationMessagesTable.map(r.data))
            .toList(growable: false),
      );

  /// Returns all (non-reverted) messages in a space, across every conversation
  /// it holds, in creation order.
  ///
  /// The sibling [getMessages] is conversation-scoped. This one exists for the
  /// space-wide readers (the PR review surface), which must see a message
  /// whichever thread it was posted in.
  Future<List<ConversationMessagesTableData>> getMessagesForSpace(
    String spaceId,
  ) =>
      customSelect(
        'SELECT $_messageColumnsSansEmbedding FROM conversation_messages '
        'WHERE space_id = ? AND reverted = 0 '
        'ORDER BY created_at ASC, rowid ASC',
        variables: [Variable.withString(spaceId)],
        readsFrom: {conversationMessagesTable},
      ).get().then(
        (rows) => rows
            .map((r) => conversationMessagesTable.map(r.data))
            .toList(growable: false),
      );

  /// Returns messages for a space that have embeddings, ordered by creation.
  Future<List<ConversationMessagesTableData>> getMessagesWithEmbedding(
    String spaceId,
  ) =>
      (select(conversationMessagesTable)
            ..where(
              (t) =>
                  t.spaceId.equals(spaceId) &
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
  Future<List<ConversationMessagesTableData>> getMessagesWithoutEmbedding({
    int limit = 200,
  }) =>
      (select(conversationMessagesTable)
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
