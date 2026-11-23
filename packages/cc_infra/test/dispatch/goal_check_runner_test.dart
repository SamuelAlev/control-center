import 'dart:io';

import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/dispatch/domain/ports/worktree_fingerprint_port.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_checks_outcome.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:cc_infra/src/dispatch/goal_check_runner.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/process/child_process.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The worktree checks run `bash -lc` for real; a Windows runner has no
/// POSIX bash on its path (`bash` there is the WSL launcher).
final String? _needsBash = Platform.isWindows ? 'needs a POSIX bash' : null;

void main() {
  late Directory root;
  late String worktree;
  late _FakeManager manager;
  late List<String> started;
  late List<int> killed;

  setUp(() {
    root = Directory.systemTemp.createTempSync('goal-check-runner-');
    worktree = p.join(root.path, 'spaces', 'space-1', 'repos', 'app');
    Directory(worktree).createSync(recursive: true);
    manager = _FakeManager();
    started = [];
    killed = [];
  });

  tearDown(() => root.deleteSync(recursive: true));

  GoalCheckRunner runner({
    HostExecutionPosture posture = HostExecutionPosture.sandboxed,
    bool withManager = true,
    EnvironmentPort? environments,
    GoalCheckProcessStarter? start,
  }) => GoalCheckRunner(
    gate: HostExecutionGate(posture: posture),
    sandboxManager: withManager ? manager : null,
    filesystem: _Filesystem(root.path),
    fingerprints: const _Fingerprints('fp-1'),
    environments: environments,
    pipeGrace: const Duration(milliseconds: 200),
    killTree: (pid, {required exited, marker}) {
      killed.add(pid);
      return ChildProcess.killTree(pid, exited: exited, marker: marker);
    },
    start:
        start ??
        (
          executable,
          arguments, {
          required workingDirectory,
          required environment,
        }) {
          started.add(executable);
          return ChildProcess.start(
            executable,
            arguments,
            workingDirectory: workingDirectory,
            environment: environment,
          );
        },
  );

  Future<GoalChecksOutcome> run(GoalCheckRunner r, List<GoalCheck> checks) =>
      r.run(
        workspaceId: 'ws-1',
        spaceId: 'space-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
        contract: GoalContract(checks: checks),
      );

  test('checks run in order in the sandbox over the worktree; a failure does '
      'not stop the rest', () async {
    final outcome = await run(runner(), [
      GoalCheck(run: 'echo one; pwd'),
      GoalCheck(run: 'echo two >&2; exit 1'),
      GoalCheck(run: 'exit 2'),
      GoalCheck(run: 'echo three'),
    ]);
    expect(outcome.status, GoalChecksStatus.ran);
    expect(outcome.fingerprint, 'fp-1');
    expect([for (final r in outcome.results) r.exitCode], [0, 1, 2, 0]);
    expect(
      [for (final r in outcome.results) r.passed],
      [true, false, false, true],
    );
    expect(outcome.anyBroken, isFalse, reason: 'exit 1 and 2 are failures');
    expect(outcome.allPassed, isFalse);
    expect(outcome.results.first.outputTail, contains('one'));
    expect(
      outcome.results.first.outputTail,
      contains(Directory(worktree).resolveSymbolicLinksSync()),
    );
    expect(outcome.results[1].outputTail, contains('two'));
    // Every check went through the sandbox, as a writable session over the
    // worktree, released at the end.
    expect(manager.argvs, hasLength(4));
    expect(manager.argvs.first, ['bash', '-lc', 'echo one; pwd']);
    expect(manager.configs.first.filesystem.allowWrite, contains(worktree));
    expect(manager.disposed, hasLength(1));
  }, skip: _needsBash);

  test('exit 126 and 127 are broken; the outcome says so', () async {
    final outcome = await run(runner(), [
      GoalCheck(run: 'definitely-not-a-command-xyz'),
      GoalCheck(run: 'exit 126'),
    ]);
    expect(outcome.results.first.exitCode, 127);
    expect(outcome.results.first.broken, isTrue);
    expect(outcome.results.last.broken, isTrue);
    expect(outcome.anyBroken, isTrue);
  }, skip: _needsBash);

  test('a spawn failure is broken', () async {
    final outcome = await run(
      runner(
        start: (e, a, {required workingDirectory, required environment}) =>
            throw const ProcessException('bash', [], 'no such file'),
      ),
      [GoalCheck(run: 'true')],
    );
    expect(outcome.results.single.broken, isTrue);
    expect(outcome.results.single.exitCode, isNull);
    expect(outcome.results.single.outputTail, contains('could not be started'));
  });

  test('a check past its timeout is ended and marked timed out', () async {
    final outcome = await run(runner(), [
      GoalCheck(run: 'sleep 30', timeoutSeconds: 1),
      GoalCheck(run: 'echo after'),
    ]);
    expect(outcome.results.first.timedOut, isTrue);
    expect(outcome.results.first.exitCode, isNull);
    expect(outcome.results.first.passed, isFalse);
    expect(killed, hasLength(1));
    expect(outcome.results.last.passed, isTrue);
  }, skip: _needsBash);

  test('only the last 6,000 characters of output are kept', () async {
    final outcome = await run(runner(), [
      GoalCheck(run: 'head -c 20000 /dev/zero | tr "\\0" a; printf END'),
    ]);
    final tail = outcome.results.single.outputTail;
    expect(tail.length, 6000);
    expect(tail, endsWith('END'));
  }, skip: _needsBash);

  test('no sandbox: nothing runs, the kind is sandbox_unavailable', () async {
    for (final r in [
      runner(posture: HostExecutionPosture.unavailable),
      runner(withManager: false),
    ]) {
      final environments = _Environments();
      final outcome = await run(
        GoalCheckRunner(
          gate: r.gate,
          sandboxManager: r.sandboxManager,
          filesystem: r.filesystem,
          fingerprints: r.fingerprints,
          environments: environments,
          start: (e, a, {required workingDirectory, required environment}) {
            started.add(e);
            throw StateError('must not start');
          },
        ),
        [
          GoalCheck(run: 'true'),
          GoalCheck(run: 'test', where: GoalCheckLocation.environment),
        ],
      );
      expect(outcome.status, GoalChecksStatus.sandboxUnavailable);
      expect(outcome.results, isEmpty);
      expect(outcome.fingerprint, 'fp-1');
      expect(outcome.allPassed, isFalse);
      expect(environments.calls, isEmpty);
    }
    expect(started, isEmpty);
    expect(GoalChecksOutcome.sandboxUnavailableKind, 'sandbox_unavailable');
  });

  test('sandbox off by the owner: checks run unconfined', () async {
    final outcome = await run(
      runner(posture: HostExecutionPosture.offByOwner, withManager: false),
      [GoalCheck(run: 'exit 0')],
    );
    expect(outcome.results.single.passed, isTrue);
    expect(manager.argvs, isEmpty);
  }, skip: _needsBash);

  test('no worktree: a worktree check is broken', () async {
    Directory(worktree).deleteSync(recursive: true);
    final outcome = await run(runner(), [GoalCheck(run: 'true')]);
    expect(outcome.results.single.broken, isTrue);
    expect(outcome.results.single.outputTail, contains('no worktree'));
    expect(started, isEmpty);
  });

  test('several worktrees: the check runs over the repos directory', () async {
    Directory(p.join(p.dirname(worktree), 'lib2')).createSync();
    final outcome = await run(runner(), [GoalCheck(run: 'ls')]);
    expect(outcome.results.single.outputTail, contains('app'));
    expect(outcome.results.single.outputTail, contains('lib2'));
  }, skip: _needsBash);

  group('environment checks', () {
    test('run as the agent, through the environment task', () async {
      final environments = _Environments(
        status: EnvironmentRunStatus.succeeded,
        exitCode: 0,
        output: 'ok',
      );
      final outcome = await run(runner(environments: environments), [
        GoalCheck(run: 'smoke', where: GoalCheckLocation.environment),
      ]);
      expect(outcome.results.single.passed, isTrue);
      expect(outcome.results.single.outputTail, 'ok');
      expect(environments.calls.single, ('space-1', 'smoke', 'agent-1'));
      expect(manager.argvs, isEmpty, reason: 'no worktree sandbox needed');
    });

    test('a failed task fails; a blocked or unknown one is broken', () async {
      expect(
        (await run(
          runner(
            environments: _Environments(
              status: EnvironmentRunStatus.failed,
              exitCode: 3,
            ),
          ),
          [GoalCheck(run: 'smoke', where: GoalCheckLocation.environment)],
        )).results.single.exitCode,
        3,
      );
      final blocked = await run(
        runner(
          environments: _Environments(status: EnvironmentRunStatus.blocked),
        ),
        [GoalCheck(run: 'smoke', where: GoalCheckLocation.environment)],
      );
      expect(blocked.results.single.broken, isTrue);
      final unknown = await run(
        runner(
          environments: _Environments(
            error: const ValidationException('task: smok is not a manual task'),
          ),
        ),
        [GoalCheck(run: 'smok', where: GoalCheckLocation.environment)],
      );
      expect(unknown.results.single.broken, isTrue);
      expect(unknown.results.single.outputTail, contains('not a manual task'));
      final none = await run(runner(), [
        GoalCheck(run: 'smoke', where: GoalCheckLocation.environment),
      ]);
      expect(none.results.single.broken, isTrue);
    });

    test('a task past the timeout is timed out', () async {
      final outcome = await run(
        runner(environments: _Environments(delay: const Duration(seconds: 5))),
        [
          GoalCheck(
            run: 'slow',
            where: GoalCheckLocation.environment,
            timeoutSeconds: 1,
          ),
        ],
      );
      expect(outcome.results.single.timedOut, isTrue);
    });
  });
}

class _FakeManager extends SandboxManager {
  _FakeManager() : super.test();

  final List<SandboxConfig> configs = [];
  final List<List<String>> argvs = [];
  final List<String> disposed = [];

  @override
  Future<SandboxWrapResult> wrap({
    required SandboxConfig config,
    required List<String> argv,
    String? workingDirectory,
  }) async {
    configs.add(config);
    argvs.add(argv);
    return SandboxWrapResult(
      executable: argv.first,
      argv: argv.sublist(1),
      environment: const {},
    );
  }

  @override
  Future<void> disposeSession(String sessionId) async =>
      disposed.add(sessionId);
}

class _Filesystem implements WorkspaceFilesystemPort {
  _Filesystem(this.root);

  final String root;

  @override
  Future<String> spaceDir(String workspaceId, String spaceId) async =>
      p.join(root, 'spaces', spaceId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Fingerprints implements WorktreeFingerprintPort {
  const _Fingerprints(this.value);

  final String? value;

  @override
  Future<String?> fingerprint({
    required String workspaceId,
    required String conversationId,
  }) async => value;
}

class _Environments implements EnvironmentPort {
  _Environments({
    this.status = EnvironmentRunStatus.succeeded,
    this.exitCode,
    this.output = '',
    this.error,
    this.delay = Duration.zero,
  });

  final EnvironmentRunStatus status;
  final int? exitCode;
  final String output;
  final Object? error;
  final Duration delay;
  final List<(String, String, String)> calls = [];

  @override
  Future<EnvironmentRun> runTask(
    String workspaceId,
    String spaceId,
    String taskId, {
    List<String> arguments = const [],
    required Principal by,
  }) async {
    calls.add((spaceId, taskId, by.id));
    if (error case final e?) {
      throw e;
    }
    await Future<void>.delayed(delay);
    return EnvironmentRun(
      id: 'run-1',
      workspaceId: workspaceId,
      spaceId: spaceId,
      kind: EnvironmentRunKind.task,
      status: status,
      startedAt: DateTime.utc(2026),
      exitCode: exitCode,
      output: output,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
