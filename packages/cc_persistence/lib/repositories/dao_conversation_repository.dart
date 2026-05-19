import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_kind.dart';
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
    channelId: row.channelId,
    title: row.title,
    kind: ConversationKind.fromWire(row.kind),
    status: ConversationStatus.fromWire(row.status),
    createdByPrincipalId: row.createdByPrincipalId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  @override
  Future<Conversation> ensureMain({
    required String workspaceId,
    required String channelId,
  }) async {
    final dao = _dao(workspaceId);
    // The `main` conversation's id equals the channel id (documented invariant).
    await dao.insertConversation(
      ConversationsTableCompanion(
        id: drift.Value(channelId),
        workspaceId: drift.Value(workspaceId),
        channelId: drift.Value(channelId),
        title: const drift.Value('Main'),
        kind: const drift.Value('main'),
        status: const drift.Value('active'),
      ),
    );
    final row = await dao.getById(workspaceId, channelId);
    if (row == null) {
      throw StateError('Failed to ensure main conversation for $channelId');
    }
    return _toDomain(row);
  }

  @override
  Future<Conversation> create({
    required String workspaceId,
    required String channelId,
    required String title,
    required Conversation conversation,
  }) async {
    final dao = _dao(workspaceId);
    final id = conversation.id.isNotEmpty ? conversation.id : _uuid.v4();
    await dao.insertConversation(
      ConversationsTableCompanion(
        id: drift.Value(id),
        workspaceId: drift.Value(workspaceId),
        channelId: drift.Value(channelId),
        title: drift.Value(title),
        kind: drift.Value(conversation.kind.wire),
        status: drift.Value(conversation.status.wire),
        createdByPrincipalId: conversation.createdByPrincipalId != null
            ? drift.Value(conversation.createdByPrincipalId)
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
  Future<List<Conversation>> listForChannel({
    required String workspaceId,
    required String channelId,
  }) async {
    final rows = await _dao(workspaceId).listForChannel(workspaceId, channelId);
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Stream<List<Conversation>> watchForChannel({
    required String workspaceId,
    required String channelId,
  }) => _dao(workspaceId)
      .watchForChannel(workspaceId, channelId)
      .map((rows) => rows.map(_toDomain).toList(growable: false));
}
