import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/thread_summary.dart';
import 'package:cc_persistence/database/daos/conversation_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Drift DAO-backed [ConversationRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).conversationDao` per call: conversations live in their
/// workspace's own database file, so the workspace id picks the file before any
/// SQL runs.
class DaoConversationRepository implements ConversationRepository {
  /// Creates a [DaoConversationRepository] over the per-workspace databases.
  DaoConversationRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final _uuid = const Uuid();

  ConversationDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).conversationDao;

  Conversation _toDomain(ConversationsTableData row) => Conversation(
    id: row.id,
    workspaceId: row.workspaceId,
    spaceId: row.spaceId,
    title: row.title,
    status: ConversationStatus.fromWire(row.status),
    anchorMessageId: row.anchorMessageId,
    createdByPrincipalId: row.createdByPrincipalId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  @override
  Future<Conversation> ensure({
    required String workspaceId,
    required String spaceId,
  }) async {
    final dao = _dao(workspaceId);
    // The standing conversation mints UNTITLED (resolved by the DAO, so every
    // mint path agrees) — the title model names it from its first human
    // message. Minted only when the space has no active, unanchored
    // conversation at all.
    final id = await dao.ensureStandingConversation(
      workspaceId: workspaceId,
      spaceId: spaceId,
    );
    final row = await dao.getById(workspaceId, id);
    if (row == null) {
      throw StateError('Failed to ensure a conversation for $spaceId');
    }
    return _toDomain(row);
  }

  @override
  Future<Conversation> create({
    required String workspaceId,
    required String spaceId,
    required String title,
    String? anchorMessageId,
    String? createdByPrincipalId,
  }) async {
    final dao = _dao(workspaceId);
    final id = _uuid.v4();
    await dao.insertConversation(
      ConversationsTableCompanion(
        id: drift.Value(id),
        workspaceId: drift.Value(workspaceId),
        spaceId: drift.Value(spaceId),
        title: drift.Value(title),
        status: const drift.Value('active'),
        anchorMessageId: anchorMessageId != null
            ? drift.Value(anchorMessageId)
            : const drift.Value.absent(),
        createdByPrincipalId: createdByPrincipalId != null
            ? drift.Value(createdByPrincipalId)
            : const drift.Value.absent(),
      ),
    );
    final row = await dao.getById(workspaceId, id);
    if (row == null) {
      throw StateError('Failed to create conversation $id');
    }
    return _toDomain(row);
  }

  @override
  Future<void> rename({
    required String workspaceId,
    required String conversationId,
    required String title,
  }) => _dao(workspaceId).updateTitle(workspaceId, conversationId, title);

  @override
  Future<void> setStatus({
    required String workspaceId,
    required String conversationId,
    required ConversationStatus status,
  }) =>
      _dao(workspaceId).updateStatus(workspaceId, conversationId, status.wire);

  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async {
    final row = await _dao(workspaceId).getById(workspaceId, conversationId);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<Conversation>> listForSpace({
    required String workspaceId,
    required String spaceId,
  }) async {
    final rows = await _dao(workspaceId).listForSpace(workspaceId, spaceId);
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Stream<List<Conversation>> watchForSpace({
    required String workspaceId,
    required String spaceId,
  }) => _dao(workspaceId)
      .watchForSpace(workspaceId, spaceId)
      .map((rows) => rows.map(_toDomain).toList(growable: false));

  @override
  Stream<List<ThreadSummary>> watchThreadSummaries({
    required String workspaceId,
    required String spaceId,
  }) => _dao(workspaceId)
      .watchThreadSummaries(workspaceId, spaceId)
      .map(
        (rows) => [
          for (final row in rows)
            ThreadSummary(
              threadId: row.threadId,
              anchorMessageId: row.anchorMessageId,
              title: row.title,
              replyCount: row.replyCount,
              lastReplyAt: row.lastReplyAt,
              // Newest sender first: the avatar stack reads as "who spoke
              // last", which is what a reader scanning the row wants.
              participantIds: row.senderIds.reversed
                  .take(5)
                  .toList(growable: false),
            ),
        ],
      );
}
