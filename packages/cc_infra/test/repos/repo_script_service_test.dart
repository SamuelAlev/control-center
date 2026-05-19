@TestOn('!windows')
library;

import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show RepoScriptException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/repo_script_run.dart';
import 'package:cc_domain/core/domain/ports/repo_isolation_port.dart';
import 'package:cc_domain/core/domain/ports/repo_script_port.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_script_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/core/domain/value_objects/repo_scripts.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/repos/repo_script_service.dart';
import 'package:test/test.dart';

/// The server-side executor for per-repo lifecycle scripts: cwd + env contract
/// (`CC_WORKSPACE_PATH` / `CC_ROOT_PATH` / …), bounded output capture, the
/// timeout kill ladder, and the failure asymmetry — setup THROWS (the space
/// provisioning fails), archive NEVER does (the GC must not be blocked).
///
/// POSIX-only: every run ends in `bash -lc`, and on the GitHub Windows runner
/// the PATH `bash` is the WSL stub with no distro installed (exit 1, UTF-16
/// "Windows Subsystem for Linux has no installed distributions").
void main() {
  late Directory root;
  late Directory worktree;
  late _FakeScripts scripts;
  late _RecordingRuns runs;
  late RepoScriptService service;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc_repo_scripts');
    worktree = Directory('${root.path}/wt')..createSync();
    scripts = _FakeScripts();
    runs = _RecordingRuns();
    service = RepoScriptService(
      scripts: scripts,
      runs: runs,
      setupTimeout: const Duration(seconds: 20),
      archiveTimeout: const Duration(seconds: 20),
    );
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  RepoScriptContext ctx() => RepoScriptContext(
    workspaceId: 'ws-1',
    spaceId: 'sp-1',
    repoId: 'repo-1',
    worktreePath: worktree.path,
    sourcePath: '/src/web-app',
  );

  test('unset scripts produce no run rows and spawn nothing', () async {
    await service.runSetup(ctx());
    await service.runArchive(ctx());

    expect(runs.inserted, isEmpty);
  });

  test(
    'a successful setup records a succeeded run and returns normally',
    () async {
      scripts.map['repo-1'] = RepoScripts(setup: 'echo hello; echo oops >&2');

      await service.runSetup(ctx());

      final run = runs.inserted.single;
      expect(run.kind, RepoScriptKind.setup);
      expect(run.repoName, 'web-app', reason: 'falls back to source basename');
      final finished = runs.finished[run.id]!;
      expect(finished.status, RepoScriptRunStatus.succeeded);
      expect(finished.exitCode, 0);
      expect(finished.output, contains('hello'));
      expect(finished.output, contains('[stderr] oops'));
    },
  );

  test(
    'a failing setup throws RepoScriptException with the output tail',
    () async {
      scripts.map['repo-1'] = RepoScripts(setup: 'echo boom >&2; exit 3');

      await expectLater(
        service.runSetup(ctx()),
        throwsA(
          isA<RepoScriptException>()
              .having((e) => e.message, 'message', contains('exited 3'))
              .having((e) => e.outputTail, 'tail', contains('boom')),
        ),
      );
      expect(runs.finished.values.single.status, RepoScriptRunStatus.failed);
      expect(runs.finished.values.single.exitCode, 3);
    },
  );

  test('a failing archive records the failure but never throws', () async {
    scripts.map['repo-1'] = RepoScripts(archive: 'exit 9');

    await service.runArchive(ctx());

    expect(runs.finished.values.single.status, RepoScriptRunStatus.failed);
    expect(runs.finished.values.single.exitCode, 9);
  });

  test('a hung script is killed and reported as timed out', () async {
    final slow = RepoScriptService(
      scripts: scripts,
      runs: runs,
      setupTimeout: const Duration(milliseconds: 400),
      archiveTimeout: const Duration(seconds: 20),
    );
    scripts.map['repo-1'] = RepoScripts(setup: 'sleep 30');

    final sw = Stopwatch()..start();
    await expectLater(
      slow.runSetup(ctx()),
      throwsA(isA<RepoScriptException>()),
    );
    sw.stop();

    expect(sw.elapsed.inSeconds, lessThan(10), reason: 'must not wait 30s');
    expect(runs.finished.values.single.status, RepoScriptRunStatus.timedOut);
    expect(runs.finished.values.single.error, contains('timed out'));
  });

  test('the script runs in the worktree with the CC_* environment', () async {
    scripts.map['repo-1'] = RepoScripts(
      setup: '''
pwd > "\$CC_WORKSPACE_PATH/probe.txt"
echo "\$CC_WORKSPACE_PATH|\$CC_ROOT_PATH|\$CC_REPO_NAME|\$CC_SPACE_ID" >> "\$CC_WORKSPACE_PATH/probe.txt"
''',
    );

    await service.runSetup(ctx());

    // `pwd` resolves symlinks (macOS `/var` → `/private/var`), so compare it
    // against the resolved worktree path; the env var carries it verbatim.
    final resolvedWorktree = worktree.resolveSymbolicLinksSync();
    final lines = File('${worktree.path}/probe.txt').readAsLinesSync();
    expect(lines[0], resolvedWorktree, reason: 'cwd is the worktree');
    expect(lines[1].split('|'), [
      worktree.path,
      '/src/web-app',
      'web-app',
      'sp-1',
    ]);
  });

  group('runTest (the dialog\'s Test button)', () {
    late Directory cloneDir;
    late _FakeIsolation isolation;
    late _TestRuns testRuns;

    RepoScriptService testService({bool withBackend = true}) =>
        RepoScriptService(
          scripts: scripts,
          runs: testRuns,
          repos: _FakeRepos(),
          repoIsolation: withBackend ? isolation : null,
          testCloneParentDir: withBackend
              ? (workspaceId) async => cloneDir.path
              : null,
          setupTimeout: const Duration(seconds: 20),
          archiveTimeout: const Duration(seconds: 20),
        );

    setUp(() {
      cloneDir = Directory('${root.path}/clone')..createSync();
      isolation = _FakeIsolation(cloneDir.path);
      testRuns = _TestRuns();
    });

    /// Starts a test run and settles the background clone+execute task.
    Future<RepoScriptRun> runToCompletion(
      RepoScriptService svc,
      String body, {
      RepoScriptKind kind = RepoScriptKind.setup,
    }) async {
      final runId = await svc.runTest(
        workspaceId: 'ws-1',
        repoId: 'repo-1',
        kind: kind,
        body: body,
      );
      for (var i = 0; i < 100 && !testRuns.finished.containsKey(runId); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(testRuns.finished, contains(runId), reason: 'run must settle');
      return testRuns.rows[runId]!;
    }

    test('a successful draft records a kind-test run in the clone', () async {
      final run = await runToCompletion(testService(), 'echo hello-from-test');

      expect(run.kind, RepoScriptKind.test);
      expect(run.status, RepoScriptRunStatus.succeeded);
      expect(run.exitCode, 0);
      expect(run.spaceId, isNull, reason: 'a test belongs to no space');
      expect(run.output, contains('hello-from-test'));
      expect(isolation.provisions, 1);
      expect(
        isolation.lastPristine,
        isTrue,
        reason: 'the clone is a clean tree, like a fresh worktree',
      );
      expect(isolation.destroys, 1, reason: 'the clone is destroyed after');
    });

    test('a failing draft records a failed row and never throws', () async {
      final run = await runToCompletion(testService(), 'echo boom >&2; exit 3');

      expect(run.status, RepoScriptRunStatus.failed);
      expect(run.exitCode, 3);
      expect(run.output, contains('[stderr] boom'));
      expect(isolation.destroys, 1, reason: 'teardown even on failure');
    });

    test(
      'the test env: CC_SCRIPT_TEST set, space vars absent, clone as cwd',
      () async {
        final run = await runToCompletion(
          testService(),
          'echo "test=\$CC_SCRIPT_TEST space=[\$CC_SPACE_ID] '
          'cwd=\$PWD root=[\$CC_ROOT_PATH]"',
        );

        expect(run.output, contains('test=1'));
        expect(run.output, contains('space=[]'));
        // `pwd` resolves symlinks (macOS `/var` → `/private/var`), the same
        // caveat as the worktree env test above.
        expect(
          run.output,
          contains('cwd=${cloneDir.resolveSymbolicLinksSync()}'),
        );
        expect(run.output, contains('root=[/src/web-app]'));
      },
    );

    test(
      'a blank body is refused with a failed row, no clone provisioned',
      () async {
        final svc = testService();
        final runId = await svc.runTest(
          workspaceId: 'ws-1',
          repoId: 'repo-1',
          kind: RepoScriptKind.archive,
          body: '   ',
        );

        final row = testRuns.rows[runId]!;
        expect(row.status, RepoScriptRunStatus.failed);
        expect(row.error, contains('empty script body'));
        expect(isolation.provisions, 0);
      },
    );

    test(
      'no isolation backend wired: honest failed row, never a throw',
      () async {
        final runId = await testService(withBackend: false).runTest(
          workspaceId: 'ws-1',
          repoId: 'repo-1',
          kind: RepoScriptKind.setup,
          body: 'echo never-runs',
        );

        final row = testRuns.rows[runId]!;
        expect(row.status, RepoScriptRunStatus.failed);
        expect(row.error, contains('unavailable'));
      },
    );

    test(
      'a clone provision failure closes the row and still never throws',
      () async {
        isolation.provisionError = Exception('cow_unavailable');
        final run = await runToCompletion(testService(), 'echo never-runs');

        expect(run.status, RepoScriptRunStatus.failed);
        expect(run.error, contains('cow_unavailable'));
      },
    );

    test('the draft runs, not the stored script', () async {
      scripts.map['repo-1'] = RepoScripts(setup: 'echo stored-body');
      final run = await runToCompletion(
        testService(),
        'echo draft-body',
        kind: RepoScriptKind.setup,
      );

      expect(run.output, contains('draft-body'));
      expect(run.output, isNot(contains('stored-body')));
    });
  });
}

class _FakeScripts implements RepoScriptRepository {
  final Map<String, RepoScripts> map = {};

  @override
  Future<RepoScripts> getScripts(String workspaceId, String repoId) async =>
      map[repoId] ?? const RepoScripts.empty();

  @override
  Future<void> setScripts(
    String workspaceId,
    String repoId,
    RepoScripts scripts,
  ) async {
    map[repoId] = scripts;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingRuns implements RepoScriptRunRecorder {
  final List<RepoScriptRun> inserted = [];
  final Map<String, _Finish> finished = {};

  @override
  Future<void> insert(RepoScriptRun run) async {
    inserted.add(run);
  }

  @override
  Future<void> updateOutput(String workspaceId, String runId, String output) =>
      Future.value();

  @override
  Future<void> finish(
    String workspaceId,
    String runId, {
    required RepoScriptRunStatus status,
    int? exitCode,
    String? error,
    String? output,
  }) async {
    finished[runId] = _Finish(
      status: status,
      exitCode: exitCode,
      error: error,
      output: output,
    );
  }
}

class _Finish {
  const _Finish({required this.status, this.exitCode, this.error, this.output});

  final RepoScriptRunStatus status;
  final int? exitCode;
  final String? error;
  final String? output;
}

/// Run recorder for the test-run group: keeps the merged row so assertions
/// read one object instead of insert + finish halves.
class _TestRuns implements RepoScriptRunRecorder {
  final Map<String, RepoScriptRun> rows = {};
  final Map<String, _Finish> finished = {};

  @override
  Future<void> insert(RepoScriptRun run) async {
    rows[run.id] = run;
  }

  @override
  Future<void> updateOutput(
    String workspaceId,
    String runId,
    String output,
  ) async {}

  @override
  Future<void> finish(
    String workspaceId,
    String runId, {
    required RepoScriptRunStatus status,
    int? exitCode,
    String? error,
    String? output,
  }) async {
    finished[runId] = _Finish(
      status: status,
      exitCode: exitCode,
      error: error,
      output: output,
    );
    final old = rows[runId]!;
    rows[runId] = RepoScriptRun(
      id: runId,
      workspaceId: old.workspaceId,
      spaceId: old.spaceId,
      repoId: old.repoId,
      repoName: old.repoName,
      kind: old.kind,
      status: status,
      startedAt: old.startedAt,
      completedAt: DateTime.now(),
      exitCode: exitCode,
      error: error,
      output: output ?? '',
    );
  }
}

/// The one repo row `runTest` resolves: id/name/path, matching the contexts
/// used above (`/src/web-app`, name `web-app`).
class _FakeRepos implements RepoRepository {
  @override
  Future<Repo?> getById(String workspaceId, String id) async => Repo(
    id: 'repo-1',
    name: 'web-app',
    path: '/src/web-app',
    remoteOwner: 'acme',
    remoteName: 'web-app',
    createdAt: DateTime.utc(2026, 8, 29),
    updatedAt: DateTime.utc(2026, 8, 29),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeIsolation implements RepoIsolationPort {
  _FakeIsolation(this.clonePath);

  final String clonePath;
  int provisions = 0;
  int destroys = 0;
  bool? lastPristine;
  Object? provisionError;

  @override
  bool get isCowAvailable => true;

  @override
  Future<RepoIsolationResult> provision({
    required String sourcePath,
    required String destParentDir,
    required String name,
    required String branch,
    String baseRef = '',
    String? authUrl,
    String? headRef,
    bool pristine = false,
    CancellationToken? cancel,
  }) async {
    provisions++;
    lastPristine = pristine;
    if (provisionError != null) {
      throw provisionError!;
    }
    return RepoIsolationResult(
      path: clonePath,
      backend: RepoIsolationBackend.rift,
    );
  }

  @override
  Future<void> destroy({
    required String path,
    required String sourcePath,
    required RepoIsolationBackend backend,
    String? branch,
  }) async {
    destroys++;
  }
}
