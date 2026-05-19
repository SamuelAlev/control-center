import 'package:cc_domain/features/sandboxing/domain/entities/sandbox_exec_grant.dart';
import 'package:cc_domain/features/sandboxing/domain/repositories/sandbox_exec_grant_repository.dart';
import 'package:cc_persistence/database/daos/sandbox_exec_grant_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/sandbox_exec_grant_mapper.dart';

/// Drift-backed [SandboxExecGrantRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).sandboxExecGrantDao` per call — grants live in their
/// workspace's own database file, so the workspace id picks the file before any
/// SQL runs. Caching a resolved DAO in a field would pin the first workspace
/// seen and answer every later call from its file.
class DaoSandboxExecGrantRepository implements SandboxExecGrantRepository {
  /// Creates a [DaoSandboxExecGrantRepository] over the per-workspace databases.
  DaoSandboxExecGrantRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final SandboxExecGrantMapper _mapper = const SandboxExecGrantMapper();

  SandboxExecGrantDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).sandboxExecGrantDao;

  @override
  Future<List<SandboxExecGrant>> grants(String workspaceId) async =>
      (await _dao(workspaceId).grants(workspaceId))
          .map(_mapper.fromRow)
          .toList();

  @override
  Stream<List<SandboxExecGrant>> watchGrants(String workspaceId) =>
      _dao(workspaceId)
          .watchGrants(workspaceId)
          .map((rows) => rows.map(_mapper.fromRow).toList());

  @override
  Future<SandboxExecGrant?> decisionFor(
    String workspaceId,
    String path,
  ) async {
    // Resolved in memory rather than with a SQL prefix match: the grant set per
    // workspace is a handful of rows, and "most specific wins" means picking the
    // LONGEST covering path, which a `LIKE` cannot express. A narrower later
    // decision therefore overrides a broader earlier one.
    final rows = await _dao(workspaceId).grants(workspaceId);
    SandboxExecGrant? best;
    for (final row in rows) {
      final grant = _mapper.fromRow(row);
      if (!grant.covers(path)) {
        continue;
      }
      if (best == null || grant.path.length > best.path.length) {
        best = grant;
      }
    }
    return best;
  }

  @override
  Future<void> upsert(SandboxExecGrant grant) async {
    // The grant carries its own workspace, so the file is picked from the entity
    // rather than from a second parameter that could disagree with it.
    final dao = _dao(grant.workspaceId);
    // The table's unique key is (workspaceId, path), but the PK is `id`, so a
    // re-answer with a fresh id would collide on the unique key rather than
    // replace. Drop any existing decision on the same path first.
    final existing = await dao.byPath(grant.workspaceId, grant.path);
    if (existing != null && existing.id != grant.id) {
      await dao.revoke(grant.workspaceId, existing.id);
    }
    await dao.upsert(_mapper.toCompanion(grant));
  }

  @override
  Future<void> revoke(String workspaceId, String id) =>
      _dao(workspaceId).revoke(workspaceId, id);
}
