import 'dart:io';

import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_command.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_template.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/environments/environment_contract.dart';
import 'package:cc_infra/src/environments/environment_task_runner.dart';
import 'package:test/test.dart';

import 'helpers/environment_fakes.dart';

void main() {
  late Directory dir;
  late InMemoryRuns runs;
  late EnvironmentTaskRunner subject;

  setUp(() {
    dir = tempDir(addTearDown);
    Directory('${dir.path}/packages/ui').createSync(recursive: true);
    runs = InMemoryRuns();
    subject = EnvironmentTaskRunner(
      runs: runs,
      runner: EnvironmentCommandRunner(
        killGrace: const Duration(milliseconds: 100),
        drainGrace: const Duration(milliseconds: 100),
      ),
      flushInterval: const Duration(milliseconds: 20),
      maxOutputChars: 200,
    );
  });

  EnvironmentContract contract() => EnvironmentContract(
    EnvironmentContractInput(
      name: 'fix-login',
      id: 'env-1',
      stateDir: '${dir.path}/state',
      home: dir.path,
      branch: 'fix-login',
      spaceId: 'space-1',
      spaceName: 'Fix login',
      spaceKind: 'space',
      repos: [
        EnvironmentContractRepo(
          role: 'app',
          repoId: 'repo-1',
          name: 'Shop',
          slug: 'shop',
          path: dir.path,
          sourcePath: '/src/shop',
        ),
      ],
      ports: const {'web': 42000},
      compose: const {'COMPOSE_PROJECT_NAME': 'cc-env-1'},
    ),
  );

  TaskEnvironmentComponent task(
    EnvironmentCommand command, {
    EnvironmentCwd? cwd,
    int? timeout,
    List<String> ports = const [],
  }) => TaskEnvironmentComponent(
    id: 'migrate',
    command: command,
    when: const {EnvironmentTaskTrigger.manual},
    cwd: cwd,
    timeoutSeconds: timeout,
    ports: ports,
  );

  Future<EnvironmentTaskOutcome> run(
    TaskEnvironmentComponent task, {
    List<String> arguments = const [],
  }) => subject.runInEnvironment(
    task: task,
    contract: contract(),
    workspaceId: 'ws',
    definitionId: 'def',
    environmentId: 'env-1',
    arguments: arguments,
  );

  test('runs with the contract, in the right directory', () async {
    final outcome = await run(
      task(
        ShellEnvironmentCommand(
          r'echo "$PWD $CC_ENV_NAME $COMPOSE_PROJECT_NAME $PORT"',
        ),
        cwd: const EnvironmentCwd(path: 'packages/ui'),
        ports: const ['web'],
      ),
    );
    expect(outcome.succeeded, isTrue);
    expect(
      outcome.run.output,
      '${dir.path}/packages/ui fix-login cc-env-1 42000',
    );
  });

  test('extra arguments arrive as "\$@"', () async {
    final outcome = await run(
      task(ShellEnvironmentCommand(r'printf "%s," "$@"')),
      arguments: ['--grep', 'a b'],
    );
    expect(outcome.run.output, '--grep,a b,');
  });

  test('records a running row, then the result', () async {
    final outcome = await run(task(ShellEnvironmentCommand('echo done')));
    final stored = runs.runs[outcome.run.id]!;
    expect(stored.status, EnvironmentRunStatus.succeeded);
    expect(stored.label, 'migrate');
    expect(stored.kind, EnvironmentRunKind.task);
    expect(stored.spaceId, 'space-1');
    expect(stored.environmentId, 'env-1');
    expect(stored.definitionId, 'def');
    expect(stored.exitCode, 0);
    expect(stored.output, 'done');
    expect(stored.completedAt, isNotNull);
  });

  test('a failure carries the structured error and the stderr tail', () async {
    final outcome = await run(
      task(
        ShellEnvironmentCommand(r'''
echo oops >&2
echo '{"type":"error","code":"db.down","message":"No database"}' >&2
exit 2
'''),
      ),
    );
    expect(outcome.succeeded, isFalse);
    expect(outcome.error?.code, 'db.down');
    expect(outcome.run.status, EnvironmentRunStatus.failed);
    expect(outcome.run.exitCode, 2);
    expect(outcome.run.error, 'No database');
    expect(outcome.run.output, contains('[stderr] oops'));
  });

  test('a deadline is recorded as timedOut', () async {
    final outcome = await run(
      task(ShellEnvironmentCommand('exec sleep 30'), timeout: 1),
    );
    expect(outcome.run.status, EnvironmentRunStatus.timedOut);
    expect(outcome.run.exitCode, environmentTimeoutExitCode);
  });

  test('a bad placeholder still finishes the row', () async {
    final outcome = await run(
      task(ArgvEnvironmentCommand([EnvironmentArgvItem.plain('{port.nope}')])),
    );
    expect(outcome.run.status, EnvironmentRunStatus.failed);
    expect(outcome.run.error, contains('port.nope'));
    expect(runs.runs[outcome.run.id]!.status, EnvironmentRunStatus.failed);
  });

  test('a missing role still finishes the row', () async {
    final outcome = await run(
      task(
        ShellEnvironmentCommand('true'),
        cwd: const EnvironmentCwd(role: 'nope'),
      ),
    );
    expect(outcome.run.status, EnvironmentRunStatus.failed);
  });

  test('the tail is throttled and bounded', () async {
    final outcome = await run(
      task(
        ShellEnvironmentCommand(
          r'for i in $(seq 1 200); do echo "line-$i"; sleep 0.001; done',
        ),
      ),
    );
    expect(outcome.run.output, startsWith('[…output truncated…]'));
    expect(outcome.run.output, endsWith('line-200'));
    expect(runs.outputWrites.length, lessThan(100));
    expect(runs.outputWrites, isNotEmpty);
  });

  test('progress lands in the tail', () async {
    final outcome = await run(
      task(
        ShellEnvironmentCommand(
          r'''echo '{"type":"step","label":"Migrate"}' >&2''',
        ),
      ),
    );
    expect(outcome.run.output, '[step] Migrate');
  });

  test('output is redacted', () async {
    final outcome = await run(
      task(ShellEnvironmentCommand('echo --token=hunter2')),
    );
    expect(outcome.run.output, isNot(contains('hunter2')));
  });

  group('runInWorktree', () {
    test('sees only what it is given, and records the repo', () async {
      final outcome = await subject.runInWorktree(
        task: TaskEnvironmentComponent(
          id: 'deps',
          when: const {EnvironmentTaskTrigger.provision},
          command: ShellEnvironmentCommand(
            r'echo "[$CC_REPO_NAME][$CC_ENV_NAME]"',
          ),
        ),
        workspaceId: 'ws',
        workingDirectory: dir.path,
        variables: worktreeTaskVariables(
          worktreePath: dir.path,
          sourcePath: '/src/shop',
          repoName: 'Shop',
        ),
        repoId: 'repo-1',
      );
      expect(outcome.run.output, '[Shop][]');
      expect(outcome.run.repoId, 'repo-1');
      expect(outcome.run.environmentId, isNull);
    });

    test('expands the placeholders it has', () async {
      final outcome = await subject.runInWorktree(
        task: TaskEnvironmentComponent(
          id: 'deps',
          when: const {EnvironmentTaskTrigger.provision},
          command: ArgvEnvironmentCommand([
            EnvironmentArgvItem.plain('/bin/echo'),
            EnvironmentArgvItem.plain('{repo.app}'),
          ]),
        ),
        workspaceId: 'ws',
        workingDirectory: dir.path,
        variables: const {},
        values: const EnvironmentValues({'repo.app': '/w'}),
      );
      expect(outcome.run.output, '/w');
    });
  });
}
