import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoReviewSpaceRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    // A workspace is a database FILE now, so there is no `workspaces` row to
    // seed inside it; registering it is what makes it addressable.
    for (final workspaceId in ['ws1', 'ws-a', 'ws-b']) {
      await seedTestWorkspace(global, dbs, workspaceId);
    }
    repo = DaoReviewSpaceRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  /// Inserts the parent space row into [workspaceId]'s own database,
  /// satisfying the `review_spaces.space_id` → `spaces` FK.
  Future<void> seedSpace(String workspaceId, String id) {
    final db = dbs.of(workspaceId);
    return db
        .into(db.spacesTable)
        .insert(
          SpacesTableCompanion.insert(
            id: id,
            name: 'Ch $id',
            workspaceId: Value(workspaceId),
          ),
        );
  }

  // ---- create ----

  test('creates a review space association', () async {
    await seedSpace('ws1', 'ch1');

    final assoc = await repo.create(
      spaceId: 'ch1',
      workspaceId: 'ws1',
      prExternalId: 'PR_123',
      prNumber: 42,
      repoFullName: 'owner/repo',
    );

    expect(assoc.id, isNotEmpty);
    expect(assoc.spaceId, 'ch1');
    expect(assoc.workspaceId, 'ws1');
    expect(assoc.prExternalId, 'PR_123');
    expect(assoc.prNumber, 42);
    expect(assoc.repoFullName, 'owner/repo');
    expect(assoc.status, ReviewSpaceStatus.requested);
    expect(assoc.createdAt, isNotNull);
  });

  test('creates with unique IDs', () async {
    await seedSpace('ws1', 'ch1');
    await seedSpace('ws1', 'ch2');

    final a1 = await repo.create(
      spaceId: 'ch1',
      workspaceId: 'ws1',
      prExternalId: 'PR_1',
      prNumber: 1,
      repoFullName: 'a/b',
    );
    final a2 = await repo.create(
      spaceId: 'ch2',
      workspaceId: 'ws1',
      prExternalId: 'PR_2',
      prNumber: 2,
      repoFullName: 'a/b',
    );

    expect(a1.id, isNot(a2.id));
  });

  // ---- watchByPr ----

  test('watchByPr returns association for matching PR', () async {
    await seedSpace('ws1', 'ch1');

    await repo.create(
      spaceId: 'ch1',
      workspaceId: 'ws1',
      prExternalId: 'PR_X',
      prNumber: 1,
      repoFullName: 'o/r',
    );

    final stream = repo.watchByPr('ws1', 'PR_X');
    final emitted = await stream.first;

    expect(emitted, isNotNull);
    expect(emitted!.prExternalId, 'PR_X');
  });

  test('watchByPr returns null for non-matching PR', () async {
    await seedSpace('ws1', 'ch1');

    await repo.create(
      spaceId: 'ch1',
      workspaceId: 'ws1',
      prExternalId: 'PR_X',
      prNumber: 1,
      repoFullName: 'o/r',
    );

    final stream = repo.watchByPr('ws1', 'PR_Y'); // different PR
    final emitted = await stream.first;

    expect(emitted, isNull);
  });

  /// The same upstream PR can be linked into two workspaces. `ws-a` and `ws-b`
  /// are separate database files now, so this proves the repository ROUTES on
  /// its `workspaceId` argument as well as the DAO's `WHERE workspace_id = ?`.
  test('watchByPr scoped to workspace', () async {
    await seedSpace('ws-a', 'ch-a');
    await seedSpace('ws-b', 'ch-b');

    await repo.create(
      spaceId: 'ch-a',
      workspaceId: 'ws-a',
      prExternalId: 'PR_COMMON',
      prNumber: 1,
      repoFullName: 'o/r',
    );
    await repo.create(
      spaceId: 'ch-b',
      workspaceId: 'ws-b',
      prExternalId: 'PR_COMMON',
      prNumber: 1,
      repoFullName: 'o/r',
    );

    final inA = await repo.watchByPr('ws-a', 'PR_COMMON').first;
    final inB = await repo.watchByPr('ws-b', 'PR_COMMON').first;

    expect(inA, isNotNull);
    expect(inB, isNotNull);
    expect(inA!.spaceId, 'ch-a');
    expect(inB!.spaceId, 'ch-b');
  });

  // ---- watchBySpace ----

  test('watchBySpace returns association for matching space', () async {
    await seedSpace('ws1', 'ch1');

    await repo.create(
      spaceId: 'ch1',
      workspaceId: 'ws1',
      prExternalId: 'PR_1',
      prNumber: 1,
      repoFullName: 'o/r',
    );

    final emitted = await repo.watchBySpace('ws1', 'ch1').first;
    expect(emitted, isNotNull);
    expect(emitted!.spaceId, 'ch1');
  });

  test('watchBySpace returns null for unknown space', () async {
    await seedSpace('ws1', 'ch1');

    await repo.create(
      spaceId: 'ch1',
      workspaceId: 'ws1',
      prExternalId: 'PR_1',
      prNumber: 1,
      repoFullName: 'o/r',
    );

    final emitted = await repo.watchBySpace('ws1', 'ch-unknown').first;
    expect(emitted, isNull);
  });

  // ---- watchByWorkspace ----

  test('watchByWorkspace returns all associations in workspace', () async {
    await seedSpace('ws1', 'ch1');
    await seedSpace('ws1', 'ch2');

    await repo.create(
      spaceId: 'ch1',
      workspaceId: 'ws1',
      prExternalId: 'PR_1',
      prNumber: 1,
      repoFullName: 'o/r',
    );
    await repo.create(
      spaceId: 'ch2',
      workspaceId: 'ws1',
      prExternalId: 'PR_2',
      prNumber: 2,
      repoFullName: 'o/r',
    );

    final emitted = await repo.watchByWorkspace('ws1').first;
    expect(emitted.length, 2);
  });

  test('watchByWorkspace returns empty for empty workspace', () async {
    final emitted = await repo.watchByWorkspace('ws1').first;
    expect(emitted, isEmpty);
  });

  // ---- updateStatus ----

  test('updateStatus updates the status', () async {
    await seedSpace('ws1', 'ch1');

    final assoc = await repo.create(
      spaceId: 'ch1',
      workspaceId: 'ws1',
      prExternalId: 'PR_1',
      prNumber: 1,
      repoFullName: 'o/r',
    );

    await repo.updateStatus('ws1', assoc.id, ReviewSpaceStatus.completed);

    final updated = await repo.watchByPr('ws1', 'PR_1').first;
    expect(updated!.status, ReviewSpaceStatus.completed);
  });

  test('updateStatus to in_progress', () async {
    await seedSpace('ws1', 'ch1');

    final assoc = await repo.create(
      spaceId: 'ch1',
      workspaceId: 'ws1',
      prExternalId: 'PR_1',
      prNumber: 1,
      repoFullName: 'o/r',
    );
    expect(assoc.status, ReviewSpaceStatus.requested);

    await repo.updateStatus('ws1', assoc.id, ReviewSpaceStatus.inProgress);
    final updated = await repo.watchByPr('ws1', 'PR_1').first;
    expect(updated!.status, ReviewSpaceStatus.inProgress);
  });
}
