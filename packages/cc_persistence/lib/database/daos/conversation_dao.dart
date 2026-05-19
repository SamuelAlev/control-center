import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'conversation_dao.g.dart';

/// Data access object for [ConversationsTable] (the message streams inside a
/// channel). Every read is workspace-scoped (isolation invariant).
@DriftAccessor(tables: [ConversationsTable])
class ConversationDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ConversationDaoMixin {
  /// Creates a [ConversationDao].
  ConversationDao(super.attachedDatabase);

  /// Watches the conversations of a channel (main first, then most-recent),
  /// scoped to [workspaceId].
  Stream<List<ConversationsTableData>> watchForChannel(
    String workspaceId,
    String channelId,
  ) =>
      (select(conversationsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.channelId.equals(channelId),
            )
            ..orderBy([
              // `main` (kind='main') sorts before parentheses; then oldest-first.
              (t) => OrderingTerm.desc(t.kind),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

  /// Lists the conversations of a channel, scoped to [workspaceId].
  Future<List<ConversationsTableData>> listForChannel(
    String workspaceId,
    String channelId,
  ) =>
      (select(conversationsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.channelId.equals(channelId),
            )
            ..orderBy([
              (t) => OrderingTerm.desc(t.kind),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .get();

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
