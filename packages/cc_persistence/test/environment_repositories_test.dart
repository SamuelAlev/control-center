import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_lease.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Round trips and isolation for the environment repositories, against real
/// per-workspace databases so a row in one workspace really is in another file.
void main() {
  final at = DateTime.utc(2026, 3, 4, 5, 6, 7);

  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  setUp(() {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  group('DaoEnvironmentDefinitionRepository', () {
    late DaoEnvironmentDefinitionRepository repository;

    setUp(() => repository = DaoEnvironmentDefinitionRepository(dbs));

    EnvironmentDefinitionRecord record({
      String id = 'def-1',
      String workspaceId = 'ws-1',
      String name = 'Shop',
    }) => EnvironmentDefinitionRecord(
      id: id,
      workspaceId: workspaceId,
      name: name,
      definitionJson: '{"contract":1}',
      sourceRepoId: 'repo-1',
      sourcePath: '.cc/environment.json',
      approvedBlobHash: 'abc123',
      overridesJson: '{"policy":{"maxRunning":2}}',
      createdBy: 'user-1',
      createdAt: at,
      updatedAt: at,
    );

    test('round-trips every field', () async {
      await repository.save(record());

      final read = (await repository.get('ws-1', 'def-1'))!;
      expect(read, record());
      expect(read.createdBy, 'user-1');
      expect(read.createdAt, at);
    });

    test('save replaces by id', () async {
      await repository.save(record());
      await repository.save(record(name: 'Renamed'));

      final rows = await repository.list('ws-1');
      expect(rows.single.name, 'Renamed');
    });

    test('lists by name and deletes one', () async {
      await repository.save(record(id: 'def-2', name: 'Tool'));
      await repository.save(record(id: 'def-1', name: 'Acme'));
      expect((await repository.list('ws-1')).map((r) => r.id), [
        'def-1',
        'def-2',
      ]);

      await repository.delete('ws-1', 'def-1');
      expect(await repository.get('ws-1', 'def-1'), isNull);
      expect((await repository.list('ws-1')).single.id, 'def-2');
    });

    test('a row in one workspace is invisible through another', () async {
      await repository.save(record());

      expect(await repository.get('ws-2', 'def-1'), isNull);
      expect(await repository.list('ws-2'), isEmpty);

      await repository.delete('ws-2', 'def-1');
      expect(await repository.get('ws-1', 'def-1'), isNotNull);
    });
  });

  group('DaoSpaceEnvironmentRepository', () {
    late DaoSpaceEnvironmentRepository repository;

    setUp(() => repository = DaoSpaceEnvironmentRepository(dbs));

    SpaceEnvironment environment({
      String id = 'env-1',
      String workspaceId = 'ws-1',
      String spaceId = 'space-1',
      String definitionId = 'def-1',
    }) => SpaceEnvironment(
      id: id,
      workspaceId: workspaceId,
      spaceId: spaceId,
      definitionId: definitionId,
      name: 'shop-main',
      status: EnvironmentStatus.degraded,
      ports: const {'web': 42000, 'postgres.5432': 42001},
      endpoints: [
        EnvironmentEndpoint(
          role: 'web',
          url: 'https://shop-main.test',
          primary: true,
        ),
      ],
      components: [
        EnvironmentComponentState(
          id: 'stack',
          kind: 'compose',
          state: 'running',
          label: 'Stack',
          detail: 'one service down',
          restarts: 2,
          services: const [
            {'name': 'db', 'state': 'running'},
          ],
          sessionId: 'session-1',
          lastRunAt: at,
          lastExitCode: 1,
        ),
      ],
      options: const {
        'seed': true,
        'mode': ['a', 'b'],
      },
      warnings: const ['Port 42002 was busy'],
      lastError: const EnvironmentError(
        code: 'compose_failed',
        message: 'A service exited',
        hint: 'Read the logs',
        command: 'docker compose logs',
        exitCode: 3,
      ),
      needsRecreate: true,
      placement: 'rig',
      rigId: 'rig-1',
      createdBy: 'user-1',
      createdAt: at,
      lastUsedAt: at.add(const Duration(minutes: 1)),
    );

    test('round-trips every field', () async {
      await repository.save(environment());

      final read = (await repository.get('ws-1', 'env-1'))!;
      expect(read, environment());
      expect(read.options, environment().options);
      expect(read.createdBy, 'user-1');
      expect(read.createdAt, at);
      expect(read.lastError!.exitCode, 3);
    });

    test('a minimal environment reads back with its defaults', () async {
      final minimal = SpaceEnvironment(
        id: 'env-1',
        workspaceId: 'ws-1',
        spaceId: 'space-1',
        definitionId: 'def-1',
        name: 'shop-main',
        status: EnvironmentStatus.creating,
        createdBy: 'user-1',
        createdAt: at,
        lastUsedAt: at,
      );
      await repository.save(minimal);

      final read = (await repository.get('ws-1', 'env-1'))!;
      expect(read, minimal);
      expect(read.lastError, isNull);
      expect(read.placement, 'host');
    });

    test('save updates by id and clears a stale error', () async {
      await repository.save(environment());
      await repository.save(
        environment().copyWith(
          status: EnvironmentStatus.ready,
          clearLastError: true,
        ),
      );

      final read = (await repository.list('ws-1')).single;
      expect(read.status, EnvironmentStatus.ready);
      expect(read.lastError, isNull);
    });

    test('a second id for one space and definition is refused', () async {
      await repository.save(environment());

      await expectLater(
        repository.save(environment(id: 'env-2')),
        throwsA(anything),
      );
      expect((await repository.list('ws-1')).single.id, 'env-1');
    });

    test('forSpace returns only that space', () async {
      await repository.save(environment());
      await repository.save(environment(id: 'env-2', definitionId: 'def-2'));
      await repository.save(environment(id: 'env-3', spaceId: 'space-2'));

      final rows = await repository.forSpace('ws-1', 'space-1');
      expect(rows.map((row) => row.id), ['env-1', 'env-2']);
    });

    test('unreadable JSON does not hide the row', () async {
      await repository.save(environment());
      await dbs
          .of('ws-1')
          .customStatement(
            "UPDATE space_environments SET ports_json = 'nope', "
            "components_json = '[{\"id\": 1}]', last_error_json = '{'",
          );

      final read = (await repository.list('ws-1')).single;
      expect(read.ports, isEmpty);
      expect(read.components, isEmpty);
      expect(read.lastError, isNull);
      expect(read.endpoints, hasLength(1));
    });

    test('delete removes one row', () async {
      await repository.save(environment());
      await repository.delete('ws-1', 'env-1');
      expect(await repository.get('ws-1', 'env-1'), isNull);
    });

    test('a row in one workspace is invisible through another', () async {
      await repository.save(environment());

      expect(await repository.get('ws-2', 'env-1'), isNull);
      expect(await repository.list('ws-2'), isEmpty);
      expect(await repository.forSpace('ws-2', 'space-1'), isEmpty);

      await repository.delete('ws-2', 'env-1');
      expect(await repository.get('ws-1', 'env-1'), isNotNull);
    });

    test('the same space and definition may exist in two workspaces', () async {
      await repository.save(environment());
      await repository.save(environment(workspaceId: 'ws-2'));

      expect((await repository.get('ws-2', 'env-1'))!.workspaceId, 'ws-2');
      expect((await repository.get('ws-1', 'env-1'))!.workspaceId, 'ws-1');
    });
  });

  group('DaoEnvironmentRunRepository', () {
    late DaoEnvironmentRunRepository repository;

    setUp(() => repository = DaoEnvironmentRunRepository(dbs));

    EnvironmentRun run({
      String id = 'run-1',
      String workspaceId = 'ws-1',
      String? spaceId = 'space-1',
      String? definitionId = 'def-1',
      EnvironmentRunStatus status = EnvironmentRunStatus.running,
      DateTime? startedAt,
      String output = '',
    }) => EnvironmentRun(
      id: id,
      workspaceId: workspaceId,
      spaceId: spaceId,
      environmentId: 'env-1',
      definitionId: definitionId,
      repoId: 'repo-1',
      kind: EnvironmentRunKind.task,
      label: 'setup',
      status: status,
      startedAt: startedAt ?? at,
      output: output,
    );

    test('round-trips every field', () async {
      await repository.start(run(output: 'hello'));

      final read = (await repository.get('ws-1', 'run-1'))!;
      expect(read, run(output: 'hello'));
      expect(read.spaceId, 'space-1');
      expect(read.environmentId, 'env-1');
      expect(read.definitionId, 'def-1');
      expect(read.repoId, 'repo-1');
      expect(read.kind, EnvironmentRunKind.task);
      expect(read.label, 'setup');
      expect(read.startedAt, at);
    });

    test('every status survives storage', () async {
      for (final status in EnvironmentRunStatus.values) {
        await repository.start(run(id: status.name, status: status));
        expect((await repository.get('ws-1', status.name))!.status, status);
      }
    });

    test('a test run needs no space or definition', () async {
      await repository.start(run(spaceId: null, definitionId: null));

      final read = (await repository.get('ws-1', 'run-1'))!;
      expect(read.spaceId, isNull);
      expect(read.definitionId, isNull);
    });

    test('finish records the outcome', () async {
      await repository.start(run());
      await repository.finish(
        'ws-1',
        'run-1',
        status: EnvironmentRunStatus.timedOut,
        completedAt: at.add(const Duration(minutes: 5)),
        exitCode: 124,
        error: 'Deadline passed',
        output: 'tail',
      );

      final read = (await repository.get('ws-1', 'run-1'))!;
      expect(read.status, EnvironmentRunStatus.timedOut);
      expect(read.completedAt, at.add(const Duration(minutes: 5)));
      expect(read.exitCode, 124);
      expect(read.error, 'Deadline passed');
      expect(read.output, 'tail');
    });

    test('finish without output keeps the stored tail', () async {
      await repository.start(run());
      await repository.updateOutput('ws-1', 'run-1', 'live tail');
      await repository.finish(
        'ws-1',
        'run-1',
        status: EnvironmentRunStatus.succeeded,
        completedAt: at,
      );

      expect((await repository.get('ws-1', 'run-1'))!.output, 'live tail');
    });

    group('output cap', () {
      const cap = EnvironmentDao.maxOutputChars;
      final long = '${'x' * 10}${'y' * cap}';

      test('applies on start, update and finish, keeping the tail', () async {
        await repository.start(run(output: long));
        expect((await repository.get('ws-1', 'run-1'))!.output, 'y' * cap);

        await repository.updateOutput('ws-1', 'run-1', 'short');
        expect((await repository.get('ws-1', 'run-1'))!.output, 'short');

        await repository.updateOutput('ws-1', 'run-1', long);
        expect((await repository.get('ws-1', 'run-1'))!.output, 'y' * cap);

        await repository.finish(
          'ws-1',
          'run-1',
          status: EnvironmentRunStatus.failed,
          completedAt: at,
          output: '$long!',
        );
        final finished = (await repository.get('ws-1', 'run-1'))!.output;
        expect(finished, hasLength(cap));
        expect(finished, endsWith('!'));
      });

      test('output at the cap is untouched', () {
        final exact = 'y' * cap;
        expect(EnvironmentDao.capOutput(exact), exact);
      });

      test('the cut never splits a surrogate pair', () {
        // The cap lands on the low half of the emoji.
        final output = '\u{1F600}${'y' * (cap - 1)}';
        expect(output.length, cap + 1);
        expect(EnvironmentDao.capOutput(output), 'y' * (cap - 1));
      });
    });

    group('retention', () {
      const keep = EnvironmentDao.retentionPerDefinition;

      Future<void> fill(int count, {String? definitionId = 'def-1'}) async {
        for (var i = 0; i < count; i++) {
          await repository.start(
            run(
              id: '$definitionId-$i',
              definitionId: definitionId,
              status: EnvironmentRunStatus.succeeded,
              startedAt: at.add(Duration(seconds: i)),
            ),
          );
        }
      }

      test('prunes finished runs to the newest', () async {
        await fill(keep + 5);

        final rows = await repository.forDefinition(
          'ws-1',
          'def-1',
          limit: keep * 2,
        );
        expect(rows, hasLength(keep));
        expect(rows.first.id, 'def-1-${keep + 4}');
        expect(rows.last.id, 'def-1-5');
      });

      test('never prunes a running row', () async {
        await repository.start(
          run(id: 'live', startedAt: at.subtract(const Duration(days: 1))),
        );
        await fill(keep + 5);

        expect(await repository.get('ws-1', 'live'), isNotNull);
      });

      test('a busy definition leaves others alone', () async {
        await fill(1, definitionId: 'def-2');
        await fill(keep + 5);

        expect(await repository.forDefinition('ws-1', 'def-2'), hasLength(1));
      });

      test('runs without a definition have their own allowance', () async {
        await fill(1);
        await fill(keep + 5, definitionId: null);

        expect(await repository.forDefinition('ws-1', 'def-1'), hasLength(1));
        final rows = await dbs
            .of('ws-1')
            .customSelect(
              'SELECT id FROM environment_runs WHERE definition_id IS NULL',
            )
            .get();
        expect(rows, hasLength(keep));
      });
    });

    test('lists newest first, honouring the limit', () async {
      await repository.start(run(id: 'old'));
      await repository.start(
        run(id: 'new', startedAt: at.add(const Duration(hours: 1))),
      );
      await repository.start(
        run(id: 'other', spaceId: 'space-2', definitionId: 'def-2'),
      );

      expect((await repository.forSpace('ws-1', 'space-1')).map((r) => r.id), [
        'new',
        'old',
      ]);
      expect(
        (await repository.forDefinition('ws-1', 'def-1', limit: 1)).single.id,
        'new',
      );
    });

    test('runs sharing a second keep their insertion order', () async {
      await repository.start(run(id: 'z-first'));
      await repository.start(run(id: 'a-second'));

      expect((await repository.forSpace('ws-1', 'space-1')).map((r) => r.id), [
        'a-second',
        'z-first',
      ]);
    });

    test('failInterrupted closes only running rows', () async {
      await repository.start(run(id: 'live', output: 'partial'));
      await repository.start(
        run(id: 'done', status: EnvironmentRunStatus.succeeded),
      );
      final now = at.add(const Duration(hours: 1));

      await repository.failInterrupted('ws-1', now);

      final live = (await repository.get('ws-1', 'live'))!;
      expect(live.status, EnvironmentRunStatus.failed);
      expect(live.completedAt, now);
      expect(live.error, DaoEnvironmentRunRepository.interruptedError);
      expect(live.output, 'partial');
      final done = (await repository.get('ws-1', 'done'))!;
      expect(done.status, EnvironmentRunStatus.succeeded);
      expect(done.completedAt, isNull);
    });

    test('a row in one workspace is invisible through another', () async {
      await repository.start(run());

      expect(await repository.get('ws-2', 'run-1'), isNull);
      expect(await repository.forSpace('ws-2', 'space-1'), isEmpty);
      expect(await repository.forDefinition('ws-2', 'def-1'), isEmpty);

      await repository.updateOutput('ws-2', 'run-1', 'leak');
      await repository.finish(
        'ws-2',
        'run-1',
        status: EnvironmentRunStatus.failed,
        completedAt: at,
      );
      await repository.failInterrupted('ws-2', at);

      final read = (await repository.get('ws-1', 'run-1'))!;
      expect(read.status, EnvironmentRunStatus.running);
      expect(read.output, isEmpty);
    });
  });

  group('DaoEnvironmentLeaseRepository', () {
    late DaoEnvironmentLeaseRepository repository;

    setUp(
      () => repository = DaoEnvironmentLeaseRepository(
        global.environmentLeaseDao,
      ),
    );

    EnvironmentLease lease({
      int block = 0,
      String workspaceId = 'ws-1',
      String spaceId = 'space-1',
      String definitionId = 'def-1',
      String? poolKey,
      int? poolSlot,
    }) => EnvironmentLease(
      block: block,
      firstPort: 42000 + block * 32,
      size: 32,
      workspaceId: workspaceId,
      spaceId: spaceId,
      definitionId: definitionId,
      createdAt: at,
      poolKey: poolKey,
      poolSlot: poolSlot,
    );

    test('round-trips every field', () async {
      final taken = lease(block: 2, poolKey: 'tool', poolSlot: 1);
      expect(await repository.tryInsert(taken), isTrue);

      final read = (await repository.forSpace('ws-1', 'space-1', 'def-1'))!;
      expect(read, taken);
      expect(read.createdAt, at);
      expect(await repository.all(), [taken]);
    });

    test('block zero is an ordinary block', () async {
      expect(await repository.tryInsert(lease()), isTrue);
      expect((await repository.all()).single.block, 0);
    });

    test('a taken block refuses, across workspaces too', () async {
      expect(await repository.tryInsert(lease()), isTrue);

      expect(await repository.tryInsert(lease(spaceId: 'space-2')), isFalse);
      expect(await repository.tryInsert(lease(workspaceId: 'ws-2')), isFalse);
      expect((await repository.all()).single.spaceId, 'space-1');
    });

    test('a refusal is not hidden by an earlier success', () async {
      // An ignored insert leaves last_insert_rowid at the previous row, so a
      // check on the rowid would read this as a success.
      expect(await repository.tryInsert(lease(block: 7)), isTrue);
      expect(
        await repository.tryInsert(lease(block: 7, spaceId: 'space-2')),
        isFalse,
      );
    });

    test('a taken pool slot refuses on a free block', () async {
      expect(
        await repository.tryInsert(lease(poolKey: 'tool', poolSlot: 1)),
        isTrue,
      );

      expect(
        await repository.tryInsert(
          lease(block: 1, spaceId: 'space-2', poolKey: 'tool', poolSlot: 1),
        ),
        isFalse,
      );
      expect(
        await repository.tryInsert(
          lease(block: 1, spaceId: 'space-2', poolKey: 'tool', poolSlot: 2),
        ),
        isTrue,
      );
      expect(
        await repository.tryInsert(
          lease(block: 2, spaceId: 'space-3', poolKey: 'shop', poolSlot: 1),
        ),
        isTrue,
      );
    });

    test('leases outside a pool never collide on the slot', () async {
      expect(await repository.tryInsert(lease()), isTrue);
      expect(
        await repository.tryInsert(lease(block: 1, spaceId: 'space-2')),
        isTrue,
      );
    });

    test('a holder has one lease per definition', () async {
      expect(await repository.tryInsert(lease()), isTrue);

      expect(await repository.tryInsert(lease(block: 1)), isFalse);
      expect(
        await repository.tryInsert(lease(block: 1, definitionId: 'def-2')),
        isTrue,
      );
      expect(
        await repository.tryInsert(lease(block: 2, workspaceId: 'ws-2')),
        isTrue,
      );
    });

    test('release frees the block and the slot', () async {
      await repository.tryInsert(lease(poolKey: 'tool', poolSlot: 1));
      await repository.release('ws-1', 'space-1', 'def-1');

      expect(await repository.forSpace('ws-1', 'space-1', 'def-1'), isNull);
      expect(
        await repository.tryInsert(
          lease(spaceId: 'space-2', poolKey: 'tool', poolSlot: 1),
        ),
        isTrue,
      );
    });

    test('releaseSpace drops only that space', () async {
      await repository.tryInsert(lease());
      await repository.tryInsert(lease(block: 1, definitionId: 'def-2'));
      await repository.tryInsert(lease(block: 2, spaceId: 'space-2'));

      await repository.releaseSpace('ws-1', 'space-1');

      expect((await repository.all()).single.spaceId, 'space-2');
    });

    test('a holder is named by its workspace', () async {
      await repository.tryInsert(lease());

      expect(await repository.forSpace('ws-2', 'space-1', 'def-1'), isNull);
      await repository.release('ws-2', 'space-1', 'def-1');
      await repository.releaseSpace('ws-2', 'space-1');

      expect(await repository.all(), hasLength(1));
    });
  });
}
