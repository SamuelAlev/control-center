import 'package:cc_persistence/database/tables/approval_comments_table.dart';
import 'package:cc_persistence/database/tables/approvals_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'approval_dao.g.dart';

/// Data access for board approvals and their comment history. Every read
/// filters by `workspaceId`.
@DriftAccessor(tables: [ApprovalsTable, ApprovalCommentsTable])
class ApprovalDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ApprovalDaoMixin {
  /// Creates an [ApprovalDao].
  ApprovalDao(super.db);

  // ── Approvals ──

  /// Watches all approvals for [workspaceId], newest first.
  Stream<List<ApprovalsTableData>> watchByWorkspace(String workspaceId) =>
      (select(approvalsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Watches approvals for [workspaceId] in a given [status], newest first.
  Stream<List<ApprovalsTableData>> watchByStatus(
    String workspaceId,
    String status,
  ) =>
      (select(approvalsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) & t.status.equals(status),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Returns a single approval by [id] within [workspaceId], or null.
  Future<ApprovalsTableData?> getById(String workspaceId, String id) =>
      (select(approvalsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// Inserts or updates an approval.
  Future<void> upsert(ApprovalsTableCompanion entry) =>
      into(approvalsTable).insertOnConflictUpdate(entry);

  /// Deletes an approval by [id] within [workspaceId]. Returns rows deleted.
  Future<int> deleteById(String workspaceId, String id) => (delete(
    approvalsTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();

  // ── Approval comments ──

  /// Watches the comment thread for [approvalId] within [workspaceId], oldest
  /// first. Scoping by workspace keeps a foreign approval's thread hidden.
  Stream<List<ApprovalCommentsTableData>> watchComments(
    String workspaceId,
    String approvalId,
  ) =>
      (select(approvalCommentsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.approvalId.equals(approvalId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  /// Returns the comment thread for [approvalId] within [workspaceId].
  Future<List<ApprovalCommentsTableData>> getComments(
    String workspaceId,
    String approvalId,
  ) =>
      (select(approvalCommentsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.approvalId.equals(approvalId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// Inserts a new approval comment.
  Future<void> insertComment(ApprovalCommentsTableCompanion entry) =>
      into(approvalCommentsTable).insert(entry);
}
