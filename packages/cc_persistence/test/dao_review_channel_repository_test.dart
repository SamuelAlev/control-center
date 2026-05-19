import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoReviewChannelRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    // A workspace is a database FILE now, so there is no `workspaces` row to
    // seed inside it; registering it is what makes it addressable.
    for (final workspaceId in ['ws1', 'ws-a', 'ws-b']) {
      await seedTestWorkspace(global, dbs, workspaceId);
    }
    repo = DaoReviewChannelRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  /// Inserts the parent channel row into [workspaceId]'s own database,
  /// satisfying the `review_channels.channel_id` → `channels` FK.
  Future<void> seedChannel(String workspaceId, String id) {
    final db = dbs.of(workspaceId);
    return db
        .into(db.channelsTable)
        .insert(
          ChannelsTableCompanion.insert(
            id: id,
            name: 'Ch $id',
            workspaceId: Value(workspaceId),
          ),
        );
  }

  // ---- create ----

  test('creates a review channel association', () async {
    await seedChannel('ws1', 'ch1');

    final assoc = await repo.create(
      channelId: 'ch1',
      workspaceId: 'ws1',
      prNodeId: 'PR_123',
      prNumber: 42,
      repoFullName: 'owner/repo',
    );

    expect(assoc.id, isNotEmpty);
    expect(assoc.channelId, 'ch1');
    expect(assoc.workspaceId, 'ws1');
    expect(assoc.prNodeId, 'PR_123');
    expect(assoc.prNumber, 42);
    expect(assoc.repoFullName, 'owner/repo');
    expect(assoc.status, ReviewChannelStatus.requested);
    expect(assoc.createdAt, isNotNull);
  });

  test('creates with unique IDs', () async {
    await seedChannel('ws1', 'ch1');
    await seedChannel('ws1', 'ch2');

    final a1 = await repo.create(
      channelId: 'ch1',
      workspaceId: 'ws1',
      prNodeId: 'PR_1',
      prNumber: 1,
      repoFullName: 'a/b',
    );
    final a2 = await repo.create(
      channelId: 'ch2',
      workspaceId: 'ws1',
      prNodeId: 'PR_2',
      prNumber: 2,
      repoFullName: 'a/b',
    );

    expect(a1.id, isNot(a2.id));
  });

  // ---- watchByPr ----

  test('watchByPr returns association for matching PR', () async {
    await seedChannel('ws1', 'ch1');

    await repo.create(
      channelId: 'ch1',
      workspaceId: 'ws1',
      prNodeId: 'PR_X',
      prNumber: 1,
      repoFullName: 'o/r',
    );

    final stream = repo.watchByPr('ws1', 'PR_X');
    final emitted = await stream.first;

    expect(emitted, isNotNull);
    expect(emitted!.prNodeId, 'PR_X');
  });

  test('watchByPr returns null for non-matching PR', () async {
    await seedChannel('ws1', 'ch1');

    await repo.create(
      channelId: 'ch1',
      workspaceId: 'ws1',
      prNodeId: 'PR_X',
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
    await seedChannel('ws-a', 'ch-a');
    await seedChannel('ws-b', 'ch-b');

    await repo.create(
      channelId: 'ch-a',
      workspaceId: 'ws-a',
      prNodeId: 'PR_COMMON',
      prNumber: 1,
      repoFullName: 'o/r',
    );
    await repo.create(
      channelId: 'ch-b',
      workspaceId: 'ws-b',
      prNodeId: 'PR_COMMON',
      prNumber: 1,
      repoFullName: 'o/r',
    );

    final inA = await repo.watchByPr('ws-a', 'PR_COMMON').first;
    final inB = await repo.watchByPr('ws-b', 'PR_COMMON').first;

    expect(inA, isNotNull);
    expect(inB, isNotNull);
    expect(inA!.channelId, 'ch-a');
    expect(inB!.channelId, 'ch-b');
  });

  // ---- watchByChannel ----

  test('watchByChannel returns association for matching channel', () async {
    await seedChannel('ws1', 'ch1');

    await repo.create(
      channelId: 'ch1',
      workspaceId: 'ws1',
      prNodeId: 'PR_1',
      prNumber: 1,
      repoFullName: 'o/r',
    );

    final emitted = await repo.watchByChannel('ws1', 'ch1').first;
    expect(emitted, isNotNull);
    expect(emitted!.channelId, 'ch1');
  });

  test('watchByChannel returns null for unknown channel', () async {
    await seedChannel('ws1', 'ch1');

    await repo.create(
      channelId: 'ch1',
      workspaceId: 'ws1',
      prNodeId: 'PR_1',
      prNumber: 1,
      repoFullName: 'o/r',
    );

    final emitted = await repo.watchByChannel('ws1', 'ch-unknown').first;
    expect(emitted, isNull);
  });

  // ---- watchByWorkspace ----

  test('watchByWorkspace returns all associations in workspace', () async {
    await seedChannel('ws1', 'ch1');
    await seedChannel('ws1', 'ch2');

    await repo.create(
      channelId: 'ch1',
      workspaceId: 'ws1',
      prNodeId: 'PR_1',
      prNumber: 1,
      repoFullName: 'o/r',
    );
    await repo.create(
      channelId: 'ch2',
      workspaceId: 'ws1',
      prNodeId: 'PR_2',
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
    await seedChannel('ws1', 'ch1');

    final assoc = await repo.create(
      channelId: 'ch1',
      workspaceId: 'ws1',
      prNodeId: 'PR_1',
      prNumber: 1,
      repoFullName: 'o/r',
    );

    await repo.updateStatus('ws1', assoc.id, ReviewChannelStatus.completed);

    final updated = await repo.watchByPr('ws1', 'PR_1').first;
    expect(updated!.status, ReviewChannelStatus.completed);
  });

  test('updateStatus to in_progress', () async {
    await seedChannel('ws1', 'ch1');

    final assoc = await repo.create(
      channelId: 'ch1',
      workspaceId: 'ws1',
      prNodeId: 'PR_1',
      prNumber: 1,
      repoFullName: 'o/r',
    );
    expect(assoc.status, ReviewChannelStatus.requested);

    await repo.updateStatus('ws1', assoc.id, ReviewChannelStatus.inProgress);
    final updated = await repo.watchByPr('ws1', 'PR_1').first;
    expect(updated!.status, ReviewChannelStatus.inProgress);
  });
}
