import 'package:cc_domain/features/governance/domain/entities/work_product.dart';

/// Repository for work products and their versioned revisions. Every method is
/// workspace-scoped — `workspaceId` is required and never optional.
abstract interface class WorkProductRepository {
  /// Watches all work products for [workspaceId].
  Stream<List<WorkProduct>> watchByWorkspace(String workspaceId);

  /// Returns the work products attached to [ticketId] within [workspaceId].
  Future<List<WorkProduct>> forTicket(String workspaceId, String ticketId);

  /// Returns a single work product by [id] within [workspaceId], or null.
  Future<WorkProduct?> getById(String workspaceId, String id);

  /// Inserts or updates a work product.
  Future<void> upsert(WorkProduct workProduct);

  /// Deletes a work product by [id] within [workspaceId].
  Future<void> delete(String workspaceId, String id);

  /// Watches the revision history of [workProductId] within [workspaceId],
  /// newest first.
  Stream<List<WorkProductRevision>> watchRevisions(
    String workspaceId,
    String workProductId,
  );

  /// Returns the revision history of [workProductId] within [workspaceId],
  /// newest first.
  Future<List<WorkProductRevision>> getRevisions(
    String workspaceId,
    String workProductId,
  );

  /// Returns a single revision by [id] within [workspaceId], or null.
  Future<WorkProductRevision?> getRevisionById(String workspaceId, String id);

  /// Inserts a new revision.
  Future<void> addRevision(WorkProductRevision revision);
}
