import 'package:cc_domain/core/domain/entities/repo_script_run.dart';
import 'package:cc_domain/core/domain/value_objects/repo_scripts.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

/// Round-trips for the per-repo lifecycle scripts: the two `repos` columns
/// (get/set, blank normalization) and the `repo_script_runs` audit table
/// (insert + prune, finish, watch) via `DaoRepoScriptRepository`.
void main() {
  late WorkspaceDatabase db;
  late DaoRepoScriptRepository repository;

  setUp(() async {
    db = WorkspaceDatabase.forTesting(
      NativeDatabase.memory(),
      workspaceId: 'ws-1',
    );
    repository = DaoRepoScriptRepository(_Manager(db));
    await db.repoDao.upsertRepo(
      ReposTableCompanion.insert(id: 'repo-1', name: 'web-app', path: '/src/w'),
    );
  });

  tearDown(() => db.close());

  test('scripts columns round-trip and blanks normalize to unset', () async {
    expect(
      await repository.getScripts('ws-1', 'repo-1'),
      const RepoScripts.empty(),
    );

    await repository.setScripts(
      'ws-1',
      'repo-1',
      RepoScripts(setup: 'pnpm install', archive: '  \n\t '),
    );

    final scripts = await repository.getScripts('ws-1', 'repo-1');
    expect(scripts.setup, 'pnpm install');
    expect(scripts.archive, isNull, reason: 'whitespace-only means unset');

    await repository.setScripts('ws-1', 'repo-1', const RepoScripts.empty());
    expect(
      await repository.getScripts('ws-1', 'repo-1'),
      const RepoScripts.empty(),
    );
  });

  test('a script id from another workspace resolves to nothing', () async {
    await repository.setScripts('ws-1', 'repo-1', RepoScripts(setup: 'x'));
    // ws-2 has its own file; reading repo-1 there must not see ws-1's scripts.
    expect(
      await repository.getScripts('ws-2', 'repo-1'),
      const RepoScripts.empty(),
    );
  });

  test('runs insert, finish and watch back the full row', () async {
    final run = RepoScriptRun(
      id: 'run-1',
      workspaceId: 'ws-1',
      spaceId: 'sp-1',
      repoId: 'repo-1',
      repoName: 'web-app',
      kind: RepoScriptKind.setup,
      status: RepoScriptRunStatus.running,
      startedAt: DateTime.utc(2026, 1, 1),
    );
    await repository.insert(run);

    await repository.finish(
      'ws-1',
      'run-1',
      status: RepoScriptRunStatus.failed,
      exitCode: 3,
      error: null,
      output: 'boom',
    );

    final rows = await repository.watchRuns('ws-1', repoId: 'repo-1').first;
    final row = rows.single;
    expect(row.status, RepoScriptRunStatus.failed);
    expect(row.exitCode, 3);
    expect(row.output, 'boom');
    expect(row.completedAt, isNotNull);
  });

  test(
    'the per-repo retention prunes finished runs but keeps running ones',
    () async {
      for (var i = 0; i < RepoScriptRunDao.retentionPerRepo + 5; i++) {
        await repository.insert(
          RepoScriptRun(
            id: 'run-$i',
            workspaceId: 'ws-1',
            spaceId: 'sp-1',
            repoId: 'repo-1',
            repoName: 'web-app',
            kind: RepoScriptKind.archive,
            status: RepoScriptRunStatus.running,
            startedAt: DateTime.utc(2026, 1, 1, 0, 0, i),
          ),
        );
      }

      final rows = await repository.watchRuns('ws-1', repoId: 'repo-1').first;
      expect(
        rows,
        hasLength(RepoScriptRunDao.retentionPerRepo + 5),
        reason:
            'running rows are never pruned out from under their finish write',
      );

      // Finishing them all, then inserting one more, prunes to the retention
      // count — the newest.
      for (var i = 0; i < rows.length; i++) {
        await repository.finish(
          'ws-1',
          'run-$i',
          status: RepoScriptRunStatus.succeeded,
        );
      }
      await repository.insert(
        RepoScriptRun(
          id: 'run-new',
          workspaceId: 'ws-1',
          spaceId: 'sp-1',
          repoId: 'repo-1',
          repoName: 'web-app',
          kind: RepoScriptKind.archive,
          status: RepoScriptRunStatus.running,
          startedAt: DateTime.utc(2026, 1, 2),
        ),
      );

      // The 25 newest finished rows survive plus the one still running.
      final pruned = await repository.watchRuns('ws-1', repoId: 'repo-1').first;
      expect(pruned, hasLength(RepoScriptRunDao.retentionPerRepo + 1));
      expect(pruned.first.id, 'run-new', reason: 'newest first');
      expect(pruned.last.startedAt.toUtc(), DateTime.utc(2026, 1, 1, 0, 0, 5));
    },
  );
}

/// Stand-in for the [WorkspaceDatabaseManager]: `of` resolves the database
/// this test owns for `ws-1` and a separate empty file for any other
/// workspace id, so a foreign workspace's read sees its OWN (empty) database
/// — the structural isolation the split provides.
class _Manager implements WorkspaceDatabaseManager {
  _Manager(this._db);

  final WorkspaceDatabase _db;
  final Map<String, WorkspaceDatabase> _others = {};

  @override
  WorkspaceDatabase of(String workspaceId) => workspaceId == 'ws-1'
      ? _db
      : _others.putIfAbsent(
          workspaceId,
          () => WorkspaceDatabase.forTesting(
            NativeDatabase.memory(),
            workspaceId: workspaceId,
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
