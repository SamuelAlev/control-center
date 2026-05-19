import 'package:cc_domain/features/messaging/domain/repositories/channel_read_repository.dart';
import 'package:cc_persistence/database/daos/messaging_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// [ChannelReadRepository] backed by the per-workspace [MessagingDao]s.
///
/// Thin pass-through over the DAO's read-cursor column on
/// `channel_participants`. The DAO owns the SQL; this class exists so consumers
/// depend on the domain port, not the Drift DAO. It holds the
/// [WorkspaceDatabaseManager] and resolves `_dbs.of(workspaceId).messagingDao`
/// per call: the cursor row lives in its workspace's own database file, so the
/// workspace id picks the file before any SQL runs.
class DaoChannelReadRepository implements ChannelReadRepository {
  /// Creates a [DaoChannelReadRepository] over the per-workspace databases.
  DaoChannelReadRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  MessagingDao _dao(String workspaceId) => _dbs.of(workspaceId).messagingDao;

  // The cursor row is keyed by (channelId, userId) within the workspace's own
  // database file, so a foreign channel id resolves to nothing rather than to
  // another workspace's cursor.
  @override
  Future<void> markChannelRead(
    String workspaceId,
    String channelId,
    String userId,
  ) => _dao(workspaceId).markChannelRead(channelId, userId);

  @override
  Stream<DateTime?> watchUserLastReadAt(
    String workspaceId,
    String channelId,
    String userId,
  ) => _dao(workspaceId).watchUserLastReadAt(channelId, userId);
}
