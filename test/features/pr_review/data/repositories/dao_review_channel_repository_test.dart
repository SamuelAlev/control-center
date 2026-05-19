import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/repositories/dao_review_channel_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DaoReviewChannelRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = DaoReviewChannelRepository(db.reviewChannelDao);
  });

  tearDown(() async {
    await db.close();
  });

  // Seed FK dependencies
  Future<void> seedWorkspace(String id) => db
      .into(db.workspacesTable)
      .insert(WorkspacesTableCompanion.insert(id: id, name: 'WS $id'));

  Future<void> seedChannel(String id) => db
      .into(db.channelsTable)
      .insert(ChannelsTableCompanion.insert(id: id, name: 'Ch $id'));

  // ---- create ----

  test('creates a review channel association', () async {
    await seedWorkspace('ws1');
    await seedChannel('ch1');

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
    await seedWorkspace('ws1');
    await seedChannel('ch1');
    await seedChannel('ch2');

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
    await seedWorkspace('ws1');
    await seedChannel('ch1');

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
    await seedWorkspace('ws1');
    await seedChannel('ch1');

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

  test('watchByPr scoped to workspace', () async {
    await seedWorkspace('ws-a');
    await seedWorkspace('ws-b');
    await seedChannel('ch-a');
    await seedChannel('ch-b');

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
    await seedWorkspace('ws1');
    await seedChannel('ch1');

    await repo.create(
      channelId: 'ch1',
      workspaceId: 'ws1',
      prNodeId: 'PR_1',
      prNumber: 1,
      repoFullName: 'o/r',
    );

    final emitted = await repo.watchByChannel('ch1').first;
    expect(emitted, isNotNull);
    expect(emitted!.channelId, 'ch1');
  });

  test('watchByChannel returns null for unknown channel', () async {
    await seedWorkspace('ws1');
    await seedChannel('ch1');

    await repo.create(
      channelId: 'ch1',
      workspaceId: 'ws1',
      prNodeId: 'PR_1',
      prNumber: 1,
      repoFullName: 'o/r',
    );

    final emitted = await repo.watchByChannel('ch-unknown').first;
    expect(emitted, isNull);
  });

  // ---- watchByWorkspace ----

  test('watchByWorkspace returns all associations in workspace', () async {
    await seedWorkspace('ws1');
    await seedChannel('ch1');
    await seedChannel('ch2');

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
    await seedWorkspace('ws1');

    final emitted = await repo.watchByWorkspace('ws1').first;
    expect(emitted, isEmpty);
  });

  // ---- updateStatus ----

  test('updateStatus updates the status', () async {
    await seedWorkspace('ws1');
    await seedChannel('ch1');

    final assoc = await repo.create(
      channelId: 'ch1',
      workspaceId: 'ws1',
      prNodeId: 'PR_1',
      prNumber: 1,
      repoFullName: 'o/r',
    );

    await repo.updateStatus(assoc.id, ReviewChannelStatus.completed);

    final updated = await repo.watchByPr('ws1', 'PR_1').first;
    expect(updated!.status, ReviewChannelStatus.completed);
  });

  test('updateStatus to in_progress', () async {
    await seedWorkspace('ws1');
    await seedChannel('ch1');

    final assoc = await repo.create(
      channelId: 'ch1',
      workspaceId: 'ws1',
      prNodeId: 'PR_1',
      prNumber: 1,
      repoFullName: 'o/r',
    );
    expect(assoc.status, ReviewChannelStatus.requested);

    await repo.updateStatus(assoc.id, ReviewChannelStatus.inProgress);
    final updated = await repo.watchByPr('ws1', 'PR_1').first;
    expect(updated!.status, ReviewChannelStatus.inProgress);
  });
}
