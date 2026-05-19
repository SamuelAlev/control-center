import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/repositories/work_product_repository.dart';
import 'package:cc_domain/features/governance/domain/services/work_product_service.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWorkProductRepo implements WorkProductRepository {
  final Map<String, WorkProduct> products = {};
  final List<WorkProductRevision> revisions = [];

  @override
  Future<void> upsert(WorkProduct workProduct) async =>
      products[workProduct.id] = workProduct;

  @override
  Future<WorkProduct?> getById(String workspaceId, String id) async {
    final p = products[id];
    return (p != null && p.workspaceId == workspaceId) ? p : null;
  }

  @override
  Future<void> addRevision(WorkProductRevision revision) async =>
      revisions.add(revision);

  @override
  Future<List<WorkProductRevision>> getRevisions(
    String workspaceId,
    String workProductId,
  ) async {
    final list =
        revisions
            .where(
              (r) =>
                  r.workspaceId == workspaceId &&
                  r.workProductId == workProductId,
            )
            .toList()
          ..sort((a, b) => b.revisionNumber.compareTo(a.revisionNumber));
    return list;
  }

  @override
  Future<WorkProductRevision?> getRevisionById(
    String workspaceId,
    String id,
  ) async => revisions
      .where((r) => r.workspaceId == workspaceId && r.id == id)
      .firstOrNull;

  @override
  Stream<List<WorkProductRevision>> watchRevisions(
    String workspaceId,
    String workProductId,
  ) => Stream.value(const []);

  @override
  Future<List<WorkProduct>> forTicket(
    String workspaceId,
    String ticketId,
  ) async => products.values
      .where((p) => p.workspaceId == workspaceId && p.ticketId == ticketId)
      .toList();

  @override
  Stream<List<WorkProduct>> watchByWorkspace(String workspaceId) =>
      Stream.value(products.values.toList());

  @override
  Future<void> delete(String workspaceId, String id) async =>
      products.remove(id);
}

void main() {
  late _FakeWorkProductRepo repo;
  late WorkProductService svc;

  setUp(() {
    repo = _FakeWorkProductRepo();
    svc = WorkProductService(repository: repo);
  });

  test('revisions increment and the head advances', () async {
    final p = await svc.create(workspaceId: 'ws1', title: 'Plan');
    expect(p.hasContent, isFalse);

    final r1 = await svc.addRevision(
      workspaceId: 'ws1',
      workProductId: p.id,
      content: 'v1',
    );
    expect(r1.revisionNumber, 1);

    final r2 = await svc.addRevision(
      workspaceId: 'ws1',
      workProductId: p.id,
      content: 'v2',
      baseRevisionId: r1.id,
    );
    expect(r2.revisionNumber, 2);

    final head = await repo.getById('ws1', p.id);
    expect(head!.currentRevisionId, r2.id);
  });

  test(
    'a write against a stale base is rejected (optimistic concurrency)',
    () async {
      final p = await svc.create(workspaceId: 'ws1', title: 'Plan');
      final r1 = await svc.addRevision(
        workspaceId: 'ws1',
        workProductId: p.id,
        content: 'v1',
      );
      // r2 advances the head past r1.
      await svc.addRevision(
        workspaceId: 'ws1',
        workProductId: p.id,
        content: 'v2',
        baseRevisionId: r1.id,
      );
      // A second writer still thinks r1 is the head → conflict.
      expect(
        () => svc.addRevision(
          workspaceId: 'ws1',
          workProductId: p.id,
          content: 'conflicting',
          baseRevisionId: r1.id,
        ),
        throwsA(isA<ConcurrencyConflictException>()),
      );
    },
  );

  test('restoring a revision appends a new head preserving history', () async {
    final p = await svc.create(workspaceId: 'ws1', title: 'Plan');
    final r1 = await svc.addRevision(
      workspaceId: 'ws1',
      workProductId: p.id,
      content: 'original',
    );
    await svc.addRevision(
      workspaceId: 'ws1',
      workProductId: p.id,
      content: 'edited',
      baseRevisionId: r1.id,
    );
    final restored = await svc.restoreRevision(
      workspaceId: 'ws1',
      workProductId: p.id,
      revisionId: r1.id,
    );
    expect(restored.revisionNumber, 3);
    expect(restored.content, 'original');
    final head = await repo.getById('ws1', p.id);
    expect(head!.currentRevisionId, restored.id);
  });
}
