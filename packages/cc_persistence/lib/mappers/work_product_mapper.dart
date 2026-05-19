import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/value_objects/work_product_type.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between [WorkProduct] / [WorkProductRevision] domain entities and their
/// table rows.
class WorkProductMapper {
  /// Creates a [WorkProductMapper].
  const WorkProductMapper();

  /// Work product to domain.
  WorkProduct toDomain(WorkProductsTableData row) => WorkProduct(
    id: row.id,
    workspaceId: row.workspaceId,
    title: row.title,
    artifactType: WorkProductType.fromStorage(row.artifactType),
    ticketId: row.ticketId,
    agentId: row.agentId,
    currentRevisionId: row.currentRevisionId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  /// Work product list to domain.
  List<WorkProduct> toDomainList(List<WorkProductsTableData> rows) =>
      rows.map(toDomain).toList(growable: false);

  /// Work product to companion.
  WorkProductsTableCompanion toCompanion(WorkProduct w) =>
      WorkProductsTableCompanion(
        id: Value(w.id),
        workspaceId: Value(w.workspaceId),
        ticketId: Value(w.ticketId),
        agentId: Value(w.agentId),
        title: Value(w.title),
        artifactType: Value(w.artifactType.name),
        currentRevisionId: Value(w.currentRevisionId),
        createdAt: Value(w.createdAt),
        updatedAt: Value(w.updatedAt),
      );

  /// Revision to domain.
  WorkProductRevision revisionToDomain(WorkProductRevisionsTableData row) =>
      WorkProductRevision(
        id: row.id,
        workProductId: row.workProductId,
        workspaceId: row.workspaceId,
        revisionNumber: row.revisionNumber,
        content: row.content,
        baseRevisionId: row.baseRevisionId,
        authorType: row.authorType,
        authorId: row.authorId,
        summary: row.summary,
        createdAt: row.createdAt,
      );

  /// Revision list to domain.
  List<WorkProductRevision> revisionsToDomain(
    List<WorkProductRevisionsTableData> rows,
  ) => rows.map(revisionToDomain).toList(growable: false);

  /// Revision to companion.
  WorkProductRevisionsTableCompanion revisionToCompanion(
    WorkProductRevision r,
  ) => WorkProductRevisionsTableCompanion(
    id: Value(r.id),
    workProductId: Value(r.workProductId),
    workspaceId: Value(r.workspaceId),
    revisionNumber: Value(r.revisionNumber),
    content: Value(r.content),
    baseRevisionId: Value(r.baseRevisionId),
    authorType: Value(r.authorType),
    authorId: Value(r.authorId),
    summary: Value(r.summary),
    createdAt: Value(r.createdAt),
  );
}
