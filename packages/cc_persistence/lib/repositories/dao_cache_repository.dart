import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// Cache repository backed by the per-workspace [CacheDao]s.
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).cacheDao` per call: cache entries live in their
/// workspace's own database file, so every read and every delete here touches
/// exactly one workspace. A server-wide retention sweep is the caller's job
/// (`DatabaseRetentionService`), not this repository's — a cache API that
/// silently fanned out would make a single-workspace delete indistinguishable
/// from a global one.
class DaoCacheRepository implements CacheRepository {
  /// Creates a [DaoCacheRepository] over the per-workspace databases.
  DaoCacheRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  CacheDao _dao(String workspaceId) => _dbs.of(workspaceId).cacheDao;

  @override
  Future<String?> read(String workspaceId, String kind, String key) =>
      _dao(workspaceId).read(workspaceId, kind, key);

  @override
  Future<void> put(
    String workspaceId,
    String kind,
    String key,
    String payload,
  ) => _dao(workspaceId).put(workspaceId, kind, key, payload);

  @override
  Future<void> deleteEntry(String workspaceId, String kind, String key) =>
      _dao(workspaceId).deleteEntry(workspaceId, kind, key);

  @override
  Future<void> deleteKind(String workspaceId, String kind) =>
      _dao(workspaceId).deleteKind(workspaceId, kind);

  @override
  Future<void> deleteKindWithPrefix(
    String workspaceId,
    String kind,
    String keyPrefix,
  ) => _dao(workspaceId).deleteKindWithPrefix(workspaceId, kind, keyPrefix);
}
