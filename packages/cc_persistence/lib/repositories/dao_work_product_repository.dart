import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/repositories/work_product_repository.dart';
import 'package:cc_persistence/database/daos/work_product_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/work_product_mapper.dart';

/// Drift-backed [WorkProductRepository].
///
/// Work products and their revisions live in their workspace's own database
/// file; the `workspaceId` on each method (or on the entity being written)
/// selects it before any SQL runs.
class DaoWorkProductRepository implements WorkProductRepository {
  /// Creates a [DaoWorkProductRepository] over the per-workspace databases.
  DaoWorkProductRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final WorkProductMapper _mapper = const WorkProductMapper();

  WorkProductDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).workProductDao;

  @override
  Stream<List<WorkProduct>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId).watchByWorkspace(workspaceId).map(_mapper.toDomainList);

  @override
  Future<List<WorkProduct>> forTicket(
    String workspaceId,
    String ticketId,
  ) async => _mapper.toDomainList(
    await _dao(workspaceId).forTicket(workspaceId, ticketId),
  );

  @override
  Future<WorkProduct?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getById(workspaceId, id);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<void> upsert(WorkProduct workProduct) =>
      _dao(workProduct.workspaceId).upsert(_mapper.toCompanion(workProduct));

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao(workspaceId).deleteById(workspaceId, id).then((_) {});

  @override
  Stream<List<WorkProductRevision>> watchRevisions(
    String workspaceId,
    String workProductId,
  ) => _dao(
    workspaceId,
  ).watchRevisions(workspaceId, workProductId).map(_mapper.revisionsToDomain);

  @override
  Future<List<WorkProductRevision>> getRevisions(
    String workspaceId,
    String workProductId,
  ) async => _mapper.revisionsToDomain(
    await _dao(workspaceId).getRevisions(workspaceId, workProductId),
  );

  @override
  Future<WorkProductRevision?> getRevisionById(
    String workspaceId,
    String id,
  ) async {
    final row = await _dao(workspaceId).getRevisionById(workspaceId, id);
    return row == null ? null : _mapper.revisionToDomain(row);
  }

  @override
  Future<void> addRevision(WorkProductRevision revision) => _dao(
    revision.workspaceId,
  ).insertRevision(_mapper.revisionToCompanion(revision));
}
