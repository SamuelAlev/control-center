import 'package:cc_persistence/database/tables/work_product_revisions_table.dart';
import 'package:cc_persistence/database/tables/work_products_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'work_product_dao.g.dart';

/// Data access for work products and their versioned revisions. Every read
/// filters by `workspaceId`.
@DriftAccessor(tables: [WorkProductsTable, WorkProductRevisionsTable])
class WorkProductDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$WorkProductDaoMixin {
  /// Creates a [WorkProductDao].
  WorkProductDao(super.db);

  // ── Work products ──

  /// Watches all work products for [workspaceId], newest first.
  Stream<List<WorkProductsTableData>> watchByWorkspace(String workspaceId) =>
      (select(workProductsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  /// Returns the work products attached to [ticketId] within [workspaceId].
  Future<List<WorkProductsTableData>> forTicket(
    String workspaceId,
    String ticketId,
  ) =>
      (select(workProductsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.ticketId.equals(ticketId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  /// Returns a single work product by [id] within [workspaceId], or null.
  Future<WorkProductsTableData?> getById(String workspaceId, String id) =>
      (select(workProductsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// Inserts or updates a work product.
  Future<void> upsert(WorkProductsTableCompanion entry) =>
      into(workProductsTable).insertOnConflictUpdate(entry);

  /// Deletes a work product by [id] within [workspaceId]. Returns rows deleted.
  Future<int> deleteById(String workspaceId, String id) => (delete(
    workProductsTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();

  // ── Revisions ──

  /// Watches the revision history of [workProductId] within [workspaceId],
  /// newest first.
  Stream<List<WorkProductRevisionsTableData>> watchRevisions(
    String workspaceId,
    String workProductId,
  ) =>
      (select(workProductRevisionsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.workProductId.equals(workProductId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.revisionNumber)]))
          .watch();

  /// Returns the revision history of [workProductId] within [workspaceId],
  /// newest first.
  Future<List<WorkProductRevisionsTableData>> getRevisions(
    String workspaceId,
    String workProductId,
  ) =>
      (select(workProductRevisionsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.workProductId.equals(workProductId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.revisionNumber)]))
          .get();

  /// Returns a single revision by [id] within [workspaceId], or null.
  Future<WorkProductRevisionsTableData?> getRevisionById(
    String workspaceId,
    String id,
  ) =>
      (select(workProductRevisionsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// Inserts a new revision.
  Future<void> insertRevision(WorkProductRevisionsTableCompanion entry) =>
      into(workProductRevisionsTable).insert(entry);
}
