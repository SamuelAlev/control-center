import 'package:cc_domain/features/pr_review/domain/services/finding_fingerprint.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_run_snapshot.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// A finalized pass freezes its findings' statuses at the instant it ends. But
/// a person marks a finding fixed AFTER reading the review — that is the only
/// order this ever happens in. So the pass has to be rewritable, or `actionRate`
/// (the share of findings someone actually fixed) stays structurally zero and
/// the suppression memory never sees a dismissal, which is the state this whole
/// surface exists to leave behind.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoReviewRunSnapshotRepository repo;

  const ws = 'w-1';
  const pr = 'acme/widget#42';

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, ws);
    await seedTestWorkspace(global, dbs, 'w-2');
    repo = DaoReviewRunSnapshotRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  FindingFingerprint fp(
    String messageId, {
    String title = 'Guard the cast',
    ReviewNodeStatus status = ReviewNodeStatus.open,
  }) => FindingFingerprint(
    fingerprint: 'fp-$messageId',
    messageId: messageId,
    title: title,
    filePath: 'lib/a.dart',
    status: status,
  );

  Future<void> record({
    String id = 'snap-1',
    String prExternalId = pr,
    String workspaceId = ws,
    required List<FindingFingerprint> fingerprints,
    DateTime? finalizedAt,
  }) => repo.record(
    workspaceId,
    ReviewRunSnapshot(
      id: id,
      workspaceId: workspaceId,
      prExternalId: prExternalId,
      spaceId: 'space-1',
      finalizedAt: finalizedAt ?? DateTime.utc(2026),
      fingerprints: fingerprints,
      stats: ReviewRunStats(
        findingsTotal: fingerprints.length,
        stillOpen: fingerprints.where((f) => f.isOpen).length,
        newCount: fingerprints.length,
      ),
    ),
  );

  test('a fix recorded after the pass reaches the pass', () async {
    await record(fingerprints: [fp('m1'), fp('m2')]);

    final rewritten = await repo.applyFindingStatus(
      ws,
      pr,
      'm1',
      ReviewNodeStatus.resolved,
    );
    expect(rewritten, 1);

    final stats = await repo.statsForWorkspace(ws);
    expect(stats.findingsTotal, 2);
    expect(stats.resolved, 1);
    expect(stats.stillOpen, 1);
    // The number the whole surface exists to make producible.
    expect(stats.actionRate, 0.5);
  });

  test('only the named finding moves', () async {
    await record(fingerprints: [fp('m1'), fp('m2'), fp('m3')]);
    await repo.applyFindingStatus(ws, pr, 'm2', ReviewNodeStatus.dismissed);

    final snapshot = await repo.latestForPr(ws, pr);
    final byId = {for (final f in snapshot!.fingerprints) f.messageId: f};
    expect(byId['m1']!.status, ReviewNodeStatus.open);
    expect(byId['m2']!.status, ReviewNodeStatus.dismissed);
    expect(byId['m3']!.status, ReviewNodeStatus.open);
  });

  test('a dismissal becomes readable by the suppression loop', () async {
    // The finalizer's matcher reads dismissed titles back mechanically. Before
    // the write-back it could only ever see dismissals that predated the pass,
    // which is to say almost none.
    await record(fingerprints: [fp('m1', title: 'Prefer const here')]);
    expect(await repo.dismissedFindingTitles(ws), isEmpty);

    await repo.applyFindingStatus(ws, pr, 'm1', ReviewNodeStatus.dismissed);
    expect(await repo.dismissedFindingTitles(ws), ['Prefer const here']);
  });

  test('pressing twice does not drift the counters', () async {
    // Recomputed from the fingerprints rather than nudged by one, so a
    // double-press (or a redo) cannot inflate `resolved` past the total.
    await record(fingerprints: [fp('m1'), fp('m2')]);
    await repo.applyFindingStatus(ws, pr, 'm1', ReviewNodeStatus.resolved);
    await repo.applyFindingStatus(ws, pr, 'm1', ReviewNodeStatus.resolved);

    final stats = await repo.statsForWorkspace(ws);
    expect(stats.resolved, 1);
    expect(stats.stillOpen, 1);
  });

  test('reopening puts the counters back', () async {
    await record(fingerprints: [fp('m1'), fp('m2')]);
    await repo.applyFindingStatus(ws, pr, 'm1', ReviewNodeStatus.resolved);
    await repo.applyFindingStatus(ws, pr, 'm1', ReviewNodeStatus.open);

    final stats = await repo.statsForWorkspace(ws);
    expect(stats.resolved, 0);
    expect(stats.stillOpen, 2);
    expect(stats.actionRate, 0);
  });

  test('every pass that reported the finding is corrected', () async {
    // A re-reviewed PR reports the same finding again. Leaving the older pass
    // saying "open" would make the workspace-wide counters disagree with the
    // one decision that was actually taken.
    await record(
      id: 'snap-1',
      fingerprints: [fp('m1')],
      finalizedAt: DateTime.utc(2026),
    );
    await record(
      id: 'snap-2',
      fingerprints: [fp('m1'), fp('m2')],
      finalizedAt: DateTime.utc(2026, 2),
    );

    final rewritten = await repo.applyFindingStatus(
      ws,
      pr,
      'm1',
      ReviewNodeStatus.resolved,
    );
    expect(rewritten, 2);

    final stats = await repo.statsForWorkspace(ws);
    expect(stats.resolved, 2);
  });

  test('newCount survives, because it is a fact about the pass', () async {
    await record(fingerprints: [fp('m1'), fp('m2')]);
    await repo.applyFindingStatus(ws, pr, 'm1', ReviewNodeStatus.resolved);

    final snapshot = await repo.latestForPr(ws, pr);
    expect(snapshot!.stats.newCount, 2);
  });

  test('a finding no pass reported is not an error', () async {
    // Reviewers file findings before the pass that summarizes them ends, so a
    // status set on one of those has nothing to rewrite yet. Failing there
    // would refuse a legitimate press.
    await record(fingerprints: [fp('m1')]);
    expect(
      await repo.applyFindingStatus(ws, pr, 'unknown', ReviewNodeStatus.resolved),
      0,
    );
  });

  test('another pull request is untouched', () async {
    await record(id: 'snap-1', fingerprints: [fp('m1')]);
    await record(
      id: 'snap-2',
      prExternalId: 'acme/widget#43',
      fingerprints: [fp('m1')],
    );

    expect(
      await repo.applyFindingStatus(ws, pr, 'm1', ReviewNodeStatus.resolved),
      1,
    );
    final other = await repo.latestForPr(ws, 'acme/widget#43');
    expect(other!.fingerprints.single.status, ReviewNodeStatus.open);
  });

  test('another workspace is untouched', () async {
    await record(id: 'snap-1', fingerprints: [fp('m1')]);
    await record(id: 'snap-2', workspaceId: 'w-2', fingerprints: [fp('m1')]);

    await repo.applyFindingStatus(ws, pr, 'm1', ReviewNodeStatus.resolved);

    expect((await repo.statsForWorkspace(ws)).resolved, 1);
    expect((await repo.statsForWorkspace('w-2')).resolved, 0);
  });
}
