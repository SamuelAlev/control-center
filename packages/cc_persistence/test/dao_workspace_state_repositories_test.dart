import 'package:cc_domain/core/domain/value_objects/editor_layout_cache_kinds.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_takeover.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_divergence_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/agent_pull_request_requester_repository.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/seed_platform.dart';
import 'helpers/test_database.dart';

/// The workspace tables that took over durable state from the `caches`
/// table: each keeps what it holds for as long as its owner row exists, and
/// goes with that row.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    await seedTestWorkspace(global, dbs, 'ws-2');
    for (final ws in ['ws-1', 'ws-2']) {
      final db = dbs.of(ws);
      await db
          .into(db.spacesTable)
          .insert(
            SpacesTableCompanion.insert(
              workspaceId: 'test-workspace',
              id: 'sp-1',
              name: 'General',
            ),
          );
      await seedAgent(db, 'agent-1');
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  SpaceTakeover takeover(String userId) => SpaceTakeover(
    spaceId: 'sp-1',
    userId: userId,
    displayName: userId,
    since: DateTime(2026, 6, 1),
  );

  group('space take-overs', () {
    test('a claim race has one winner', () async {
      final repo = DaoSpaceTakeoverRepository(dbs);

      final results = await Future.wait([
        for (var i = 0; i < 6; i++) repo.claim('ws-1', takeover('u-$i')),
      ]);

      expect(results.where((won) => won), hasLength(1));
      final winner = results.indexOf(true);
      expect((await repo.get('ws-1', 'sp-1'))?.userId, 'u-$winner');
    });

    test('a claim in one workspace does not hold the other', () async {
      final repo = DaoSpaceTakeoverRepository(dbs);
      expect(await repo.claim('ws-1', takeover('u-1')), isTrue);

      expect(await repo.claim('ws-2', takeover('u-2')), isTrue);
    });

    test('records the held runs and is released', () async {
      final repo = DaoSpaceTakeoverRepository(dbs);
      await repo.claim('ws-1', takeover('u-1'));

      await repo.recordHeldRuns(
        'ws-1',
        'sp-1',
        paused: const ['r-1'],
        stopped: const ['r-2'],
      );
      final held = await repo.get('ws-1', 'sp-1');
      expect(held?.pausedRunIds, ['r-1']);
      expect(held?.stoppedRunIds, ['r-2']);

      await repo.release('ws-1', 'sp-1');
      expect(await repo.get('ws-1', 'sp-1'), isNull);
      expect(await repo.claim('ws-1', takeover('u-2')), isTrue);
    });

    test('goes with its space', () async {
      final repo = DaoSpaceTakeoverRepository(dbs);
      await repo.claim('ws-1', takeover('u-1'));
      final checkers = DaoSpaceCheckerRepository(dbs);
      await checkers.setChecker('ws-1', 'sp-1', 'agent-1');

      final db = dbs.of('ws-1');
      await (db.delete(db.spacesTable)..where((t) => t.id.equals('sp-1'))).go();

      expect(await repo.get('ws-1', 'sp-1'), isNull);
      expect(await checkers.checkerOf('ws-1', 'sp-1'), isNull);
    });
  });

  test('a space checker is set, read and cleared per workspace', () async {
    final repo = DaoSpaceCheckerRepository(dbs);
    await repo.setChecker('ws-1', 'sp-1', 'agent-1');

    expect(await repo.checkerOf('ws-1', 'sp-1'), 'agent-1');
    expect(await repo.checkerOf('ws-2', 'sp-1'), isNull);

    await repo.clearChecker('ws-1', 'sp-1');
    expect(await repo.checkerOf('ws-1', 'sp-1'), isNull);
  });

  test('an escalation tier is remembered until the approval goes', () async {
    final db = dbs.of('ws-1');
    await db.customStatement(
      "INSERT INTO approvals (id, workspace_id, title) VALUES ('ap-1', "
      "'ws-1', 'Ship it')",
    );
    final repo = DaoApprovalEscalationRepository(dbs);
    expect(await repo.tierOf('ws-1', 'ap-1'), 0);

    await repo.recordTier('ws-1', 'ap-1', 2);
    expect(await repo.tierOf('ws-1', 'ap-1'), 2);

    await db.customStatement("DELETE FROM approvals WHERE id = 'ap-1'");
    expect(await repo.tierOf('ws-1', 'ap-1'), 0);
  });

  test("an editor layout is one person's, per surface", () async {
    final repo = DaoEditorLayoutRepository(dbs);
    await repo.write(
      'ws-1',
      userId: 'u-1',
      surface: EditorLayoutSurface.space,
      target: 'sp-1',
      layout: '{"a":1}',
    );

    expect(
      await repo.read(
        'ws-1',
        userId: 'u-1',
        surface: EditorLayoutSurface.space,
        target: 'sp-1',
      ),
      '{"a":1}',
    );
    expect(
      await repo.read(
        'ws-1',
        userId: 'u-2',
        surface: EditorLayoutSurface.space,
        target: 'sp-1',
      ),
      isNull,
    );
    expect(
      await repo.read(
        'ws-1',
        userId: 'u-1',
        surface: EditorLayoutSurface.pullRequest,
        target: 'sp-1',
      ),
      isNull,
    );
  });

  test('a plan divergence is recorded and resumed', () async {
    await dbs
        .of('ws-1')
        .customStatement(
          'INSERT INTO orchestrations (id, workspace_id, proposal_json) '
          "VALUES ('o-1', 'ws-1', '{}')",
        );
    final repo = DaoPlanDivergenceRepository(dbs);
    await repo.record(
      'ws-1',
      'o-1',
      PlanDivergence(
        nodeKey: 'n-1',
        reasons: const ['scope'],
        at: DateTime(2026, 6, 1),
        held: true,
      ),
    );

    await repo.markResumed('ws-1', 'o-1', 'n-1');

    final markers = await repo.forOrchestration('ws-1', 'o-1');
    expect(markers['n-1']?.held, isFalse);
    expect(markers['n-1']?.reasons, ['scope']);
  });

  group('agent pull request requesters', () {
    late DaoAgentPullRequestRequesterRepository repo;

    setUp(() async {
      repo = DaoAgentPullRequestRequesterRepository(global);
      for (final user in ['u-1', 'u-2']) {
        await seedUser(global, user);
      }
    });

    test('promoting moves a pending record to its number', () async {
      await repo.add(AgentPullRequestRecordState.pending, 'o/r@b', {'u-1'});

      await repo.promote('o/r@b', 'o/r#1');

      expect(await repo.requesters(openedKey: 'o/r#1'), {'u-1'});
      expect(await repo.requesters(pendingKey: 'o/r@b'), isEmpty);
    });

    test('one read answers for the number and the head branch', () async {
      await repo.add(AgentPullRequestRecordState.opened, 'o/r#1', {'u-1'});
      await repo.add(AgentPullRequestRecordState.pending, 'o/r@b', {'u-2'});

      expect(await repo.requesters(openedKey: 'o/r#1', pendingKey: 'o/r@b'), {
        'u-1',
        'u-2',
      });
      expect(await repo.requesters(openedKey: '', pendingKey: null), isEmpty);
    });

    test('a prefix match is literal', () async {
      await repo.add(AgentPullRequestRecordState.pending, 'o/r_x@b', {'u-1'});
      await repo.add(AgentPullRequestRecordState.pending, 'o/rax@b', {'u-2'});

      final rows = await repo.pendingWithPrefix('o/r_');
      expect(rows.map((r) => r.key), ['o/r_x@b']);
    });

    test('a record names a user the server knows', () async {
      await expectLater(
        repo.add(AgentPullRequestRecordState.opened, 'o/r#1', {'nobody'}),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  test('a pending PR reply is taken once', () async {
    await seedRunLog(dbs.of('ws-1'), 'r-1');
    final repo = DaoPendingPrReplyRepository(dbs);
    await repo.save('ws-1', 'r-1', {'comment_id': 7});

    final taken = await Future.wait([
      repo.take('ws-1', 'r-1'),
      repo.take('ws-1', 'r-1'),
    ]);

    expect(taken.whereType<Map<String, dynamic>>(), hasLength(1));
    expect(taken.whereType<Map<String, dynamic>>().single, {'comment_id': 7});
  });

  test('a code owner set grows and is kept per pull request', () async {
    final repo = DaoPrCodeOwnerRepository(dbs);
    await repo.addAndList(
      'ws-1',
      repoKey: 'o/r',
      prNumber: 1,
      identities: {'@a'},
    );

    expect(
      await repo.addAndList(
        'ws-1',
        repoKey: 'o/r',
        prNumber: 1,
        identities: {'@b'},
      ),
      {'@a', '@b'},
    );
    expect(
      await repo.addAndList(
        'ws-1',
        repoKey: 'o/r',
        prNumber: 2,
        identities: const {},
      ),
      isEmpty,
    );
  });
}
