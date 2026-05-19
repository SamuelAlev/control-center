import 'package:cc_domain/core/domain/services/activity_logger.dart';
import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/repositories/work_product_repository.dart';
import 'package:cc_domain/features/governance/domain/value_objects/work_product_type.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:uuid/uuid.dart';

/// Creates work products and manages their versioned revision history.
///
/// A revision write declares the base revision it edited from; if that is no
/// longer the head, the write is rejected ([ConcurrencyConflictException]) so a
/// concurrent edit is never silently clobbered. Any past revision can be
/// restored, which appends a new head revision rather than rewriting history.
class WorkProductService {
  /// Creates a [WorkProductService].
  WorkProductService({
    required WorkProductRepository repository,
    ActivityLogger? activityLogger,
  }) : _repository = repository,
       _audit = activityLogger;

  final WorkProductRepository _repository;
  final ActivityLogger? _audit;

  static const _uuid = Uuid();

  /// Creates a work product (no content yet — add the first revision next).
  Future<WorkProduct> create({
    required String workspaceId,
    required String title,
    WorkProductType artifactType = WorkProductType.document,
    String? ticketId,
    String? agentId,
    String? id,
  }) async {
    final now = DateTime.now();
    final product = WorkProduct(
      id: id ?? _uuid.v4(),
      workspaceId: workspaceId,
      title: title,
      artifactType: artifactType,
      ticketId: ticketId,
      agentId: agentId,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.upsert(product);
    _audit?.log(
      actorType: agentId != null ? 'agent' : 'user',
      actorId: agentId,
      action: 'work_product_created',
      entityType: 'work_product',
      entityId: product.id,
      workspaceId: workspaceId,
      details: title,
    );
    return product;
  }

  /// Appends a new revision to [workProductId].
  ///
  /// When [baseRevisionId] is supplied it must equal the current head, else a
  /// [ConcurrencyConflictException] is thrown (optimistic concurrency). On
  /// success the new revision becomes the head.
  Future<WorkProductRevision> addRevision({
    required String workspaceId,
    required String workProductId,
    required String content,
    String? baseRevisionId,
    String authorType = 'agent',
    String? authorId,
    String? summary,
  }) async {
    final product = await _repository.getById(workspaceId, workProductId);
    if (product == null) {
      throw NotFoundException('Work product $workProductId not found.');
    }
    if (baseRevisionId != null && baseRevisionId != product.currentRevisionId) {
      throw ConcurrencyConflictException(
        'Work product $workProductId was revised by another writer '
        '(base $baseRevisionId is no longer the head).',
      );
    }
    final revisions = await _repository.getRevisions(
      workspaceId,
      workProductId,
    );
    final nextNumber = revisions.isEmpty
        ? 1
        : revisions.first.revisionNumber + 1;
    final now = DateTime.now();
    final revision = WorkProductRevision(
      id: _uuid.v4(),
      workProductId: workProductId,
      workspaceId: workspaceId,
      revisionNumber: nextNumber,
      content: content,
      baseRevisionId: baseRevisionId ?? product.currentRevisionId,
      authorType: authorType,
      authorId: authorId,
      summary: summary,
      createdAt: now,
    );
    await _repository.addRevision(revision);
    await _repository.upsert(
      product.copyWith(currentRevisionId: revision.id, updatedAt: now),
    );
    _audit?.log(
      actorType: authorType,
      actorId: authorId,
      action: 'work_product_revised',
      entityType: 'work_product',
      entityId: workProductId,
      workspaceId: workspaceId,
      details: 'rev $nextNumber',
    );
    return revision;
  }

  /// Restores [revisionId] as a new head revision (undo), preserving history.
  Future<WorkProductRevision> restoreRevision({
    required String workspaceId,
    required String workProductId,
    required String revisionId,
    String authorType = 'user',
    String? authorId,
  }) async {
    final target = await _repository.getRevisionById(workspaceId, revisionId);
    if (target == null || target.workProductId != workProductId) {
      throw NotFoundException('Revision $revisionId not found.');
    }
    return addRevision(
      workspaceId: workspaceId,
      workProductId: workProductId,
      content: target.content,
      authorType: authorType,
      authorId: authorId,
      summary: 'Restored revision ${target.revisionNumber}',
    );
  }
}
