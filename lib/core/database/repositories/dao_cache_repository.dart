import 'package:control_center/core/database/daos/cache_dao.dart';
import 'package:control_center/core/domain/repositories/cache_repository.dart';

class DaoCacheRepository implements CacheRepository {
  DaoCacheRepository(this._cacheDao);

  final CacheDao _cacheDao;

  @override
  Future<String?> read(String workspaceId, String kind, String key) =>
      _cacheDao.read(workspaceId, kind, key);

  @override
  Future<void> put(
    String workspaceId,
    String kind,
    String key,
    String payload,
  ) =>
      _cacheDao.put(workspaceId, kind, key, payload);

  @override
  Future<void> deleteEntry(String workspaceId, String kind, String key) =>
      _cacheDao.deleteEntry(workspaceId, kind, key);

  @override
  Future<void> deleteKind(String workspaceId, String kind) =>
      _cacheDao.deleteKind(workspaceId, kind);

  @override
  Future<void> deleteKindWithPrefix(
    String workspaceId,
    String kind,
    String keyPrefix,
  ) =>
      _cacheDao.deleteKindWithPrefix(workspaceId, kind, keyPrefix);
}
