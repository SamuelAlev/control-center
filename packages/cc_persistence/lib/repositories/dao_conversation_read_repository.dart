import 'package:cc_domain/core/domain/value_objects/feed_position.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_read_repository.dart';
import 'package:cc_persistence/database/daos/messaging_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// [ConversationReadRepository] backed by the per-workspace [MessagingDao]s.
///
/// The cursor rows live in their workspace's own database file, so the
/// workspace id picks the file before any SQL runs and a foreign conversation
/// id resolves to nothing.
class DaoConversationReadRepository implements ConversationReadRepository {
  /// Creates a [DaoConversationReadRepository] over the per-workspace
  /// databases.
  DaoConversationReadRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  MessagingDao _dao(String workspaceId) => _dbs.of(workspaceId).messagingDao;

  @override
  Future<void> markConversationRead(
    String workspaceId,
    String conversationId,
    String userId,
  ) => _dao(workspaceId).markConversationRead(conversationId, userId);

  @override
  Stream<Map<String, FeedPosition>> watchUserConversationReads(
    String workspaceId,
    String userId,
  ) => _dao(workspaceId).watchUserConversationReads(workspaceId, userId);
}
