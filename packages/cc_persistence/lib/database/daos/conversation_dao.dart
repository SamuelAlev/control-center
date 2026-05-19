import 'package:cc_persistence/database/tables/conversation_messages.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

part 'conversation_dao.g.dart';

/// Data access object for [ConversationsTable] (the message streams inside a
/// space). Every read is workspace-scoped (isolation invariant).
@DriftAccessor(tables: [ConversationsTable, ConversationMessagesTable])
class ConversationDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ConversationDaoMixin {
  /// Creates a [ConversationDao].
  ConversationDao(super.attachedDatabase);

  /// Watches the conversations of a space (active first, then oldest-first),
  /// scoped to [workspaceId].
  Stream<List<ConversationsTableData>> watchForSpace(
    String workspaceId,
    String spaceId,
  ) =>
      (select(conversationsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.spaceId.equals(spaceId),
            )
            ..orderBy([
              // Active first, then oldest-first within a status. Ordered on an
              // explicit predicate rather than the raw column: 'archived'
              // sorts AFTER 'active' ascending, so a plain DESC on `status`
              // put the closed ones on top.
              (t) => OrderingTerm(
                expression: t.status.equals('active'),
                mode: OrderingMode.desc,
              ),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

  /// Lists the conversations of a space, scoped to [workspaceId].
  Future<List<ConversationsTableData>> listForSpace(
    String workspaceId,
    String spaceId,
  ) =>
      (select(conversationsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.spaceId.equals(spaceId),
            )
            ..orderBy([
              (t) => OrderingTerm(
                expression: t.status.equals('active'),
                mode: OrderingMode.desc,
              ),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .get();

  /// Idempotently returns the space's standing conversation id: its oldest
  /// active, unanchored conversation, or — when the space has none, e.g. one
  /// freshly provisioned — a newly minted row with its own uuid and NO title.
  /// There is no main-id aliasing.
  ///
  /// The minted row stays untitled on purpose: the UI renders an empty title
  /// as "Untitled conversation" and the workspace's title model (when one is
  /// configured) names it from its first human message — see
  /// `ConversationTitleService`, whose default-title rule covers the empty
  /// string. A read path has no better name to offer, and a space-name label
  /// only pretended it did.
  ///
  /// Archived rows and threads are both excluded on purpose. A space whose
  /// conversations have all been closed would otherwise hand back a closed
  /// one (invisible in the switcher, so a send would land nowhere the reader
  /// can see), and a thread is anchored to a message inside another
  /// conversation — it can never be the stream a space opens on.
  /// The look-up and the insert run in ONE transaction, and that is the whole
  /// point rather than hygiene. Every read path that resolves "the space's
  /// conversation" lands here — a message watch, an artifact watch, a dispatch
  /// that named no stream — and opening a space fires several of them at once.
  /// Read-then-insert without a transaction let all of them see no standing
  /// row and each insert one, so opening a PR review space minted three
  /// identical conversations named after the space, next to the named ones the
  /// reviewers had created. There is no unique index to lean on: "the standing
  /// conversation" is a predicate (active AND unanchored AND oldest), not a
  /// column.
  Future<String> ensureStandingConversation({
    required String workspaceId,
    required String spaceId,
  }) async {
    return transaction(() async {
      final existing = await listForSpace(workspaceId, spaceId);
      final standing = existing
          .where((c) => c.status == 'active' && c.anchorMessageId == null)
          .firstOrNull;
      if (standing != null) {
        return standing.id;
      }
      // Refuse a space that does not exist rather than letting the insert
      // below fail on its foreign key. `INSERT OR IGNORE` does NOT cover FK
      // violations (SQLite's conflict clause applies to UNIQUE/NOT NULL/CHECK/
      // PRIMARY KEY only), so it threw `FOREIGN KEY constraint failed` — a
      // message naming neither the column nor the id. Callers reach here by
      // passing an id positionally, and a CONVERSATION id in the space slot is
      // the mistake that actually happens, so say so.
      final spaceName = await _spaceName(spaceId);
      if (spaceName == null) {
        throw StateError(
          'Cannot open a conversation in space "$spaceId" of workspace '
          '"$workspaceId": no such space. (A conversation id passed as a space '
          'id looks exactly like this — the two are never the same value.)',
        );
      }
      final id = const Uuid().v4();
      await insertConversation(
        ConversationsTableCompanion(
          id: Value(id),
          workspaceId: Value(workspaceId),
          spaceId: Value(spaceId),
          // Untitled: the switcher shows the untitled placeholder and the
          // title model names the conversation after its first human message.
          title: const Value(''),
          status: const Value('active'),
        ),
      );
      return id;
    });
  }

  /// Live per-thread rollup for a space: one row per anchored conversation
  /// with its live reply count, newest reply and distinct senders.
  ///
  /// One grouped statement rather than a query per thread — a space with
  /// twenty threads would otherwise open twenty message watches to render
  /// twenty "N replies" rows. `readsFrom` names both tables so drift
  /// re-emits when a reply lands OR a thread is created/renamed.
  Stream<List<ThreadSummaryRow>> watchThreadSummaries(
    String workspaceId,
    String spaceId,
  ) =>
      customSelect(
        'SELECT c.id AS thread_id, '
        'c.anchor_message_id AS anchor_message_id, '
        'c.title AS title, '
        'COUNT(m.id) AS reply_count, '
        'MAX(m.created_at) AS last_reply_at, '
        'GROUP_CONCAT(DISTINCT m.sender_id) AS sender_ids '
        'FROM conversations c '
        'LEFT JOIN conversation_messages m '
        '  ON m.conversation_id = c.id AND m.reverted = 0 '
        'WHERE c.workspace_id = ? AND c.space_id = ? '
        '  AND c.anchor_message_id IS NOT NULL '
        'GROUP BY c.id, c.anchor_message_id, c.title '
        'ORDER BY MAX(m.created_at) ASC',
        variables: [
          Variable.withString(workspaceId),
          Variable.withString(spaceId),
        ],
        readsFrom: {conversationsTable, conversationMessagesTable},
      ).watch().map(
        (rows) => [
          for (final row in rows)
            ThreadSummaryRow(
              threadId: row.read<String>('thread_id'),
              anchorMessageId: row.read<String>('anchor_message_id'),
              title: row.read<String>('title'),
              replyCount: row.read<int>('reply_count'),
              lastReplyAt: row.readNullable<DateTime>('last_reply_at'),
              senderIds: (row.readNullable<String>('sender_ids') ?? '')
                  .split(',')
                  .where((s) => s.isNotEmpty)
                  .toList(growable: false),
            ),
        ],
      );

  /// The space's display name, for titling a freshly minted conversation —
  /// or null when there is NO such space (distinct from a space with an empty
  /// name, which is an empty string).
  ///
  /// Read with a raw statement because this accessor deliberately declares
  /// only [ConversationsTable] — it has no business selecting from `spaces`
  /// through the typed API.
  Future<String?> _spaceName(String spaceId) async {
    final rows = await customSelect(
      'SELECT name FROM spaces WHERE id = ?',
      variables: [Variable.withString(spaceId)],
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return rows.first.readNullable<String>('name') ?? '';
  }

  /// One conversation by id, scoped to [workspaceId] (null when not found /
  /// foreign).
  Future<ConversationsTableData?> getById(
    String workspaceId,
    String conversationId,
  ) =>
      (select(conversationsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) & t.id.equals(conversationId),
          ))
          .getSingleOrNull();

  /// Raw row by id without a workspace filter — for the sync-feed loader only.
  Future<ConversationsTableData?> getByIdUnscoped(String conversationId) =>
      (select(
        conversationsTable,
      )..where((t) => t.id.equals(conversationId))).getSingleOrNull();

  /// Inserts a conversation (ignoring conflicts on the primary key).
  Future<void> insertConversation(ConversationsTableCompanion entry) =>
      into(conversationsTable).insert(entry, mode: InsertMode.insertOrIgnore);

  /// Updates the title of a conversation, scoped to [workspaceId].
  Future<void> updateTitle(
    String workspaceId,
    String conversationId,
    String title,
  ) =>
      (update(conversationsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) & t.id.equals(conversationId),
          ))
          .write(
            ConversationsTableCompanion(
              title: Value(title),
              updatedAt: Value(DateTime.now()),
            ),
          );

  /// Updates the status of a conversation, scoped to [workspaceId].
  Future<void> updateStatus(
    String workspaceId,
    String conversationId,
    String status,
  ) =>
      (update(conversationsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) & t.id.equals(conversationId),
          ))
          .write(
            ConversationsTableCompanion(
              status: Value(status),
              updatedAt: Value(DateTime.now()),
            ),
          );
}

/// One row of [ConversationDao.watchThreadSummaries] — the storage shape,
/// mapped to the domain's `ThreadSummary` by the repository.
class ThreadSummaryRow {
  /// Creates a [ThreadSummaryRow].
  const ThreadSummaryRow({
    required this.threadId,
    required this.anchorMessageId,
    required this.title,
    required this.replyCount,
    required this.lastReplyAt,
    required this.senderIds,
  });

  /// The thread's own conversation id.
  final String threadId;

  /// The message the thread hangs off.
  final String anchorMessageId;

  /// The thread's title.
  final String title;

  /// Live (non-reverted) message count.
  final int replyCount;

  /// Newest reply, or null while the thread is empty.
  final DateTime? lastReplyAt;

  /// Distinct sender ids, in SQLite's `GROUP_CONCAT` order.
  final List<String> senderIds;
}
