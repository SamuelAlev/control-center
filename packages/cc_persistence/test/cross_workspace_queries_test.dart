import 'dart:async';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Covers [CrossWorkspaceQueries] — the ONE sanctioned way to read across
/// workspace database files.
///
/// Before the split, spanning workspaces was an ordinary `SELECT` with no
/// `WHERE workspace_id`. Now it means opening several files, and the behaviour of
/// *how* they are combined is real logic that the dashboards, startup
/// reconcilers and retention sweeps all depend on. Three properties in
/// particular are load-bearing and are pinned here:
///
///  * **Failure isolation.** One corrupt or locked workspace file must not blank
///    the dashboard for the other nine — but the failure must be reported, not
///    swallowed.
///  * **No half-populated first emission.** A merged live view emits only once
///    every workspace has produced a value, so a subscriber never sees a short
///    list that then grows (which reads as rows appearing from nowhere).
///  * **Correct global top-N.** Taking N rows from *each* file before merging is
///    what makes a global "most recent N" correct; taking fewer would drop rows
///    that outrank another workspace's.
void main() {
  // These tests deliberately open several WorkspaceDatabase instances at once —
  // that is the subject. Drift's duplicate-instance warning is about sharing one
  // executor between two databases, which never happens here.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late CrossWorkspaceQueries cross;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    cross = CrossWorkspaceQueries(dbs);
    for (final id in const ['w-1', 'w-2', 'w-3']) {
      await seedTestWorkspace(global, dbs, id);
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Future<void> seedAgent(String workspaceId, String id, String name) => dbs
      .of(workspaceId)
      .agentDao
      .upsert(
        AgentsTableCompanion.insert(
          id: id,
          name: name,
          title: 't',
          agentMdPath: '/a/$id.md',
          workspaceId: workspaceId,
          skills: '',
        ),
      );

  group('fanOut', () {
    test('reads every registered workspace', () async {
      final seen = await cross.fanOut((db) async => db.workspaceId);
      expect(seen, unorderedEquals(<String>['w-1', 'w-2', 'w-3']));
    });

    test(
      'reads the registry, so an unregistered workspace is not visited',
      () async {
        // Touching a workspace's database does not enrol it: the registry is the
        // source of truth, so a stray file is never silently adopted.
        dbs.of('w-unregistered');
        final seen = await cross.fanOut((db) async => db.workspaceId);
        expect(seen, unorderedEquals(<String>['w-1', 'w-2', 'w-3']));
      },
    );

    test('skips a failing workspace and reports it via onError', () async {
      final failures = <String, Object>{};

      final seen = await cross.fanOut<String>((db) async {
        if (db.workspaceId == 'w-2') {
          throw StateError('database is locked');
        }
        return db.workspaceId;
      }, onError: (workspaceId, error) => failures[workspaceId] = error);

      expect(
        seen,
        unorderedEquals(<String>['w-1', 'w-3']),
        reason:
            'a corrupt or locked workspace must not take the dashboard down '
            'for the others',
      );
      expect(failures.keys, <String>['w-2']);
      expect(failures['w-2'], isStateError);
    });

    test('a failure with no onError is still isolated, not rethrown', () async {
      final seen = await cross.fanOut<String>((db) async {
        if (db.workspaceId == 'w-2') {
          throw StateError('boom');
        }
        return db.workspaceId;
      });
      expect(seen, hasLength(2));
    });

    test('still visits a soft-deleted workspace', () async {
      // Its file still exists, so retention sweeps and backup must still reach
      // it. Only a hard-removed registry row drops out of the fan-out.
      for (final id in const ['w-1', 'w-2', 'w-3']) {
        await global.workspaceRegistryDao.deleteWorkspace(id);
      }
      expect(await cross.fanOut((db) async => db.workspaceId), hasLength(3));

      await global.customStatement('DELETE FROM workspaces');
      expect(await cross.fanOut((db) async => db.workspaceId), isEmpty);
    });

    test('reads real rows from each workspace file', () async {
      await seedAgent('w-1', 'a-1', 'Ada');
      await seedAgent('w-2', 'a-2', 'Grace');

      final rows = await cross.fanOut((db) => db.agentDao.getAll());
      final names = [
        for (final perWorkspace in rows)
          for (final row in perWorkspace) row.name,
      ];
      expect(names, unorderedEquals(<String>['Ada', 'Grace']));
    });
  });

  group('fanOutKeyed', () {
    test('pairs each result with its workspace id', () async {
      final byWorkspace = await cross.fanOutKeyed(
        (db) async => db.workspaceId.toUpperCase(),
      );
      expect(byWorkspace, {'w-1': 'W-1', 'w-2': 'W-2', 'w-3': 'W-3'});
    });

    test('omits a failing workspace rather than mapping it to null', () async {
      final failures = <String>[];
      final byWorkspace = await cross.fanOutKeyed<String>((db) async {
        if (db.workspaceId == 'w-3') {
          throw StateError('boom');
        }
        return db.workspaceId;
      }, onError: (workspaceId, _) => failures.add(workspaceId));
      expect(byWorkspace.keys, unorderedEquals(<String>['w-1', 'w-2']));
      expect(failures, <String>['w-3']);
    });
  });

  group('forEachWorkspace', () {
    test(
      'writes to every workspace, sequentially, and counts successes',
      () async {
        final order = <String>[];
        final ok = await cross.forEachWorkspace((db) async {
          order.add('start:${db.workspaceId}');
          await Future<void>.delayed(Duration.zero);
          order.add('end:${db.workspaceId}');
        });

        expect(ok, 3);
        // Sequential on purpose: ten concurrent maintenance write transactions
        // would spike I/O while the server is trying to serve.
        for (var i = 0; i < order.length; i += 2) {
          expect(
            order[i].replaceFirst('start:', ''),
            order[i + 1].replaceFirst('end:', ''),
          );
        }
      },
    );

    test('counts only the workspaces that succeeded', () async {
      final failures = <String>[];
      final ok = await cross.forEachWorkspace((db) async {
        if (db.workspaceId == 'w-1') {
          throw StateError('boom');
        }
      }, onError: (workspaceId, _) => failures.add(workspaceId));
      expect(ok, 2);
      expect(failures, <String>['w-1']);
    });
  });

  group('mergeStreams', () {
    test('emits only once every workspace has produced a value', () async {
      final gate = StreamController<List<String>>();
      addTearDown(gate.close);
      final emissions = <List<String>>[];

      final sub = cross
          .mergeStreams<String>(
            (db) => db.workspaceId == 'w-3'
                ? gate.stream
                : Stream.value(<String>[db.workspaceId]),
          )
          .listen(emissions.add);
      addTearDown(sub.cancel);

      await pumpEventQueue();
      expect(
        emissions,
        isEmpty,
        reason:
            'w-3 has not produced a first value, so emitting now would show a '
            'short list that then grows',
      );

      gate.add(<String>['w-3']);
      await pumpEventQueue();

      expect(emissions, hasLength(1));
      expect(emissions.single, unorderedEquals(<String>['w-1', 'w-2', 'w-3']));
    });

    test('re-emits on every later change, once primed', () async {
      final gate = StreamController<List<String>>();
      addTearDown(gate.close);
      final emissions = <List<String>>[];

      final sub = cross
          .mergeStreams<String>(
            (db) => db.workspaceId == 'w-3'
                ? gate.stream
                : Stream.value(<String>[db.workspaceId]),
          )
          .listen(emissions.add);
      addTearDown(sub.cancel);

      gate.add(<String>['first']);
      await pumpEventQueue();
      gate.add(<String>['second']);
      await pumpEventQueue();

      expect(emissions, hasLength(2));
      expect(emissions.last, contains('second'));
      expect(emissions.last, isNot(contains('first')));
    });

    test(
      're-sorts the merged list, which concatenation cannot preserve',
      () async {
        // Each workspace's own stream is ordered, but concatenating three ordered
        // lists is not ordered.
        final merged = await cross
            .mergeStreams<String>(
              (db) => Stream.value(switch (db.workspaceId) {
                'w-1' => <String>['banana', 'zebra'],
                'w-2' => <String>['apple', 'mango'],
                _ => <String>['cherry'],
              }),
              sort: (a, b) => a.compareTo(b),
            )
            .first;

        expect(merged, <String>['apple', 'banana', 'cherry', 'mango', 'zebra']);
      },
    );

    test('applies limit after sorting the merged list', () async {
      final merged = await cross
          .mergeStreams<int>(
            (db) => Stream.value(switch (db.workspaceId) {
              'w-1' => <int>[9, 3],
              'w-2' => <int>[7, 1],
              _ => <int>[5],
            }),
            sort: (a, b) => a.compareTo(b),
            limit: 3,
          )
          .first;
      expect(merged, <int>[1, 3, 5]);
    });

    test('a failing workspace stream contributes an empty list', () async {
      final merged = await cross
          .mergeStreams<String>(
            (db) => db.workspaceId == 'w-2'
                ? Stream<List<String>>.error(StateError('boom'))
                : Stream.value(<String>[db.workspaceId]),
          )
          .first;
      expect(
        merged,
        unorderedEquals(<String>['w-1', 'w-3']),
        reason:
            'one failing workspace must not kill the merged stream for every '
            'other workspace',
      );
    });

    test('yields a single empty list when no workspace exists', () async {
      for (final id in const ['w-1', 'w-2', 'w-3']) {
        await dbs.dropAndClose(id);
        await global.workspaceRegistryDao.deleteWorkspace(id);
      }
      // `allIdsIncludingDeleted` keeps soft-deleted ids, so hard-remove the rows
      // to get a genuinely empty server.
      await global.customStatement('DELETE FROM workspaces');

      expect(
        await cross.mergeStreams<String>((db) => const Stream.empty()).toList(),
        <List<String>>[<String>[]],
      );
    });

    test('merges live drift streams across workspace files', () async {
      final merged = cross.mergeStreams(
        (db) => db.agentDao.watchAll(),
        sort: (a, b) => a.name.compareTo(b.name),
      );
      final emissions = <List<String>>[];
      final sub = merged.listen(
        (rows) => emissions.add([for (final r in rows) r.name]),
      );
      addTearDown(sub.cancel);

      await pumpEventQueue();
      expect(emissions.last, isEmpty);

      await seedAgent('w-2', 'a-2', 'Grace');
      await seedAgent('w-1', 'a-1', 'Ada');
      await pumpEventQueue();

      expect(emissions.last, <String>['Ada', 'Grace']);
    });
  });

  group('topN', () {
    test('takes N from every workspace before merging', () async {
      final limitsSeen = <String, int>{};

      final top = await cross.topN<int>(
        (db, limit) async {
          limitsSeen[db.workspaceId] = limit;
          return switch (db.workspaceId) {
            // Deliberately lopsided: w-1 holds the four newest rows overall, so
            // a per-workspace limit smaller than N would drop them.
            'w-1' => <int>[100, 99, 98, 97, 96],
            'w-2' => <int>[50, 40, 30],
            _ => <int>[10],
          };
        },
        3,
        compare: (a, b) => b.compareTo(a),
      );

      expect(
        limitsSeen,
        {'w-1': 3, 'w-2': 3, 'w-3': 3},
        reason:
            'each workspace must be asked for the full N; splitting N across '
            'workspaces would miss rows that outrank another workspace',
      );
      expect(top, <int>[100, 99, 98]);
    });

    test('returns fewer than N when the workspaces hold fewer rows', () async {
      final top = await cross.topN<int>(
        (db, limit) async => db.workspaceId == 'w-1' ? <int>[1] : <int>[],
        5,
        compare: (a, b) => a.compareTo(b),
      );
      expect(top, <int>[1]);
    });

    test(
      'skips a failing workspace and still returns the global top',
      () async {
        final failures = <String>[];
        final top = await cross.topN<int>(
          (db, limit) async {
            if (db.workspaceId == 'w-2') {
              throw StateError('boom');
            }
            return db.workspaceId == 'w-1' ? <int>[5, 4] : <int>[3];
          },
          2,
          compare: (a, b) => b.compareTo(a),
          onError: (workspaceId, _) => failures.add(workspaceId),
        );
        expect(top, <int>[5, 4]);
        expect(failures, <String>['w-2']);
      },
    );
  });
}
