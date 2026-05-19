import 'package:cc_domain/features/messaging/domain/repositories/space_read_repository.dart';
import 'package:cc_persistence/database/daos/messaging_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// [SpaceReadRepository] backed by the per-workspace [MessagingDao]s.
///
/// Thin pass-through over the DAO's read-cursor column on
/// `space_participants`. The DAO owns the SQL; this class exists so consumers
/// depend on the domain port, not the Drift DAO. It holds the
/// [WorkspaceDatabaseManager] and resolves `_dbs.of(workspaceId).messagingDao`
/// per call: the cursor row lives in its workspace's own database file, so the
/// workspace id picks the file before any SQL runs.
class DaoSpaceReadRepository implements SpaceReadRepository {
  /// Creates a [DaoSpaceReadRepository] over the per-workspace databases.
  DaoSpaceReadRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  MessagingDao _dao(String workspaceId) => _dbs.of(workspaceId).messagingDao;

  // The cursor row is keyed by (spaceId, userId) within the workspace's own
  // database file, so a foreign space id resolves to nothing rather than to
  // another workspace's cursor.
  @override
  Future<void> markSpaceRead(
    String workspaceId,
    String spaceId,
    String userId,
  ) => _dao(workspaceId).markSpaceRead(spaceId, userId);

  @override
  Stream<DateTime?> watchUserLastReadAt(
    String workspaceId,
    String spaceId,
    String userId,
  ) => _dao(workspaceId).watchUserLastReadAt(spaceId, userId);
}
