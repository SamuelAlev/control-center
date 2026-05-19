import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/entities/approval_comment.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_persistence/database/daos/approval_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/approval_mapper.dart';

/// Drift-backed [ApprovalRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).approvalDao` per call: approvals and their comments
/// live in their workspace's own database file, so the workspace id picks the
/// file before any SQL runs.
class DaoApprovalRepository implements ApprovalRepository {
  /// Creates a [DaoApprovalRepository] over the per-workspace databases.
  DaoApprovalRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final ApprovalMapper _mapper = const ApprovalMapper();

  ApprovalDao _dao(String workspaceId) => _dbs.of(workspaceId).approvalDao;

  @override
  Stream<List<Approval>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId).watchByWorkspace(workspaceId).map(_mapper.toDomainList);

  @override
  Stream<List<Approval>> watchByStatus(String workspaceId, String status) =>
      _dao(
        workspaceId,
      ).watchByStatus(workspaceId, status).map(_mapper.toDomainList);

  @override
  Future<Approval?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getById(workspaceId, id);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<void> upsert(Approval approval) =>
      // The approval carries its own workspace, so the file is picked from the
      // entity rather than from a parameter that could disagree with it.
      _dao(approval.workspaceId).upsert(_mapper.toCompanion(approval));

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao(workspaceId).deleteById(workspaceId, id).then((_) {});

  @override
  Stream<List<ApprovalComment>> watchComments(
    String workspaceId,
    String approvalId,
  ) => _dao(
    workspaceId,
  ).watchComments(workspaceId, approvalId).map(_mapper.commentsToDomain);

  @override
  Future<List<ApprovalComment>> getComments(
    String workspaceId,
    String approvalId,
  ) async => _mapper.commentsToDomain(
    await _dao(workspaceId).getComments(workspaceId, approvalId),
  );

  @override
  Future<void> addComment(ApprovalComment comment) =>
      // The comment carries the workspace of the approval it hangs off.
      _dao(
        comment.workspaceId,
      ).insertComment(_mapper.commentToCompanion(comment));
}
