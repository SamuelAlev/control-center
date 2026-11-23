import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/environments/domain/value_objects/environment_command.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_template.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:test/test.dart';

import 'helpers/environment_fakes.dart';

/// Why a test that spawns `bash`, `/bin/echo` or `/bin/cat`, or signals the
/// process it started, does not run on Windows.
final String _pathSep = Platform.isWindows ? ';' : ':';

final String? _posix = Platform.isWindows
    ? 'spawns POSIX tools (bash, /bin/echo) and signals them'
    : null;

void main() {
  late Directory dir;
  late EnvironmentCommandRunner runner;

  setUp(() {
    dir = tempDir(addTearDown);
    runner = EnvironmentCommandRunner(
      killGrace: const Duration(milliseconds: 200),
      drainGrace: const Duration(milliseconds: 300),
    );
  });

  EnvironmentCommand argv(List<String> items) => ArgvEnvironmentCommand([
    for (final item in items) EnvironmentArgvItem.plain(item),
  ]);

  group('argv', () {
    test('goes to the process with no shell in between', () async {
      final result = await runner.run(
        argv(['/bin/echo', r'$HOME; touch pwned', '`id`']),
        workingDirectory: dir.path,
      );
      expect(result.stdout, r'$HOME; touch pwned `id`');
      expect(File('${dir.path}/pwned').existsSync(), isFalse);
    }, skip: _posix);

    test('expands placeholders and conditions', () async {
      final result = await runner.run(
        ArgvEnvironmentCommand([
          EnvironmentArgvItem.plain('/bin/echo'),
          EnvironmentArgvItem.plain('{name}'),
          EnvironmentArgvItem.conditional(
            condition: 'opt.extra',
            args: ['--extra'],
          ),
        ]),
        values: const EnvironmentValues({'name': 'shop', 'opt.extra': 'false'}),
      );
      expect(result.stdout, 'shop');
    }, skip: _posix);

    test('appends extra arguments', () async {
      final result = await runner.run(
        argv(['/bin/echo', 'a']),
        arguments: ['b c'],
      );
      expect(result.stdout, 'a b c');
    }, skip: _posix);

    test('runArgv takes braces literally', () async {
      final result = await runner.runArgv(['/bin/echo', '{name}']);
      expect(result.stdout, '{name}');
    }, skip: _posix);

    test('fails before running on an unknown placeholder', () {
      expect(
        () => runner.run(argv(['/bin/echo', '{nope}'])),
        throwsA(isA<EnvironmentTemplateException>()),
      );
    });

    test('reports a missing binary as a result', () async {
      final runner = EnvironmentCommandRunner(
        binaryResolver: (_) async => null,
      );
      final result = await runner.run(argv(['acme-no-such-tool']));
      expect(result.exitCode, environmentSpawnFailureExitCode);
      expect(result.error?.code, 'command-not-found');
      expect(result.error?.message, contains('acme-no-such-tool'));
    });
  });

  group('shell', () {
    test('runs as bash -lc with "\$@" working', () async {
      final result = await runner.run(
        ShellEnvironmentCommand(r'printf "%s|" "$@"'),
        arguments: ['a b', 'c'],
      );
      expect(result.stdout, 'a b|c|');
    });

    test('never expands placeholders in the body', () async {
      final result = await runner.run(
        ShellEnvironmentCommand('echo "{name}"'),
        values: const EnvironmentValues({'name': 'shop'}),
      );
      expect(result.stdout, '{name}');
    });
  }, skip: _posix);

  test('stdin is closed, so a reader gets end of file', () async {
    final result = await runner.run(
      argv(['/bin/cat']),
      timeout: const Duration(seconds: 5),
    );
    expect(result.exitCode, 0);
    expect(result.timedOut, isFalse);
  }, skip: _posix);

  group('deadline', () {
    test('SIGTERM, synthetic exit 124', () async {
      final result = await runner.run(
        ShellEnvironmentCommand('exec sleep 30'),
        timeout: const Duration(milliseconds: 200),
      );
      expect(result.exitCode, environmentTimeoutExitCode);
      expect(result.timedOut, isTrue);
      expect(result.error?.code, 'timeout');
    });

    test('SIGKILL for a process ignoring SIGTERM', () async {
      final watch = Stopwatch()..start();
      final result = await runner.run(
        ShellEnvironmentCommand(
          "trap '' TERM; echo armed; while true; do sleep 0.05; done",
        ),
        timeout: const Duration(milliseconds: 400),
      );
      expect(result.exitCode, environmentTimeoutExitCode);
      expect(result.stdout, contains('armed'));
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('takes the children down too', () async {
      final marker = '${dir.path}/survived';
      // The deadline must find the child already started: a shell that only
      // forks it while the deadline is reading the process table (a loaded
      // CI runner can take 200 ms to start one) leaves a child that was not
      // there to be signalled, which says nothing about the ladder.
      final result = await runner.run(
        ShellEnvironmentCommand(
          '(sleep 2; touch "$marker") & echo started; wait',
        ),
        timeout: const Duration(seconds: 1),
      );
      expect(result.timedOut, isTrue);
      expect(result.stdout, contains('started'));
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      expect(File(marker).existsSync(), isFalse);
    });
  }, skip: _posix);

  test('cancel uses the same ladder and keeps the real exit code', () async {
    final handle = runner.startArgv(['/bin/sleep', '30']);
    Timer(const Duration(milliseconds: 100), handle.cancel);
    final result = await handle.result;
    expect(result.cancelled, isTrue);
    expect(result.timedOut, isFalse);
    expect(result.exitCode, isNot(0));
    expect(result.exitCode, isNot(environmentTimeoutExitCode));
  }, skip: _posix);

  test('the exit is the last thing a command says', () async {
    final events = <EnvironmentCommandEvent>[];
    await runner.run(
      ShellEnvironmentCommand('echo out; echo err >&2; exit 4'),
      onEvent: events.add,
    );
    expect(events.whereType<EnvironmentCommandExit>(), hasLength(1));
    final exit = events.last;
    expect(exit, isA<EnvironmentCommandExit>());
    expect((exit as EnvironmentCommandExit).exitCode, 4);
    expect(exit.succeeded, isFalse);
  }, skip: _posix);

  test('a daemon holding stdout open does not fail the command', () async {
    final watch = Stopwatch()..start();
    final result = await runner.run(
      ShellEnvironmentCommand('sleep 2 & echo started; exit 0'),
    );
    expect(result.exitCode, 0);
    expect(result.error, isNull);
    expect(result.stdout, contains('started'));
    expect(watch.elapsed, lessThan(const Duration(milliseconds: 1500)));
  }, skip: _posix);

  group('stderr', () {
    test('streams progress and lines apart', () async {
      final events = <EnvironmentCommandEvent>[];
      final result = await runner.run(
        ShellEnvironmentCommand(r'''
echo out
echo '{"type":"step","label":"Pull","state":"running"}' >&2
echo plain >&2
echo '{"type":"note","message":"Left a hosts line"}' >&2
'''),
        onEvent: events.add,
      );
      final progress = events.whereType<EnvironmentCommandProgress>().toList();
      expect(progress.map((e) => e.progress.type), ['step', 'note']);
      expect(progress.first.progress.label, 'Pull');
      expect(progress.last.progress.label, 'Left a hosts line');
      final lines = events.whereType<EnvironmentCommandOutput>().toList();
      expect(lines.map((e) => (e.line, e.isStderr)), [
        ('out', false),
        ('plain', true),
      ]);
      expect(result.stderr, 'plain');
    });

    test('a final error line becomes the error', () async {
      final result = await runner.run(
        ShellEnvironmentCommand(r'''
echo noise >&2
echo '{"type":"error","code":"env.broken","message":"It broke","hint":"Fix it","command":"tool repair"}' >&2
exit 7
'''),
      );
      expect(
        result.error,
        const EnvironmentError(
          code: 'env.broken',
          message: 'It broke',
          hint: 'Fix it',
          command: 'tool repair',
          exitCode: 7,
          output: 'noise',
        ),
      );
    });

    test(
      'the error keeps the end of the output beside the tool\'s words',
      () async {
        final long = 'x' * 400;
        final result = await runner.run(
          ShellEnvironmentCommand('''
for i in \$(seq 1 30); do echo "pull \$i" >&2; done
echo "$long" >&2
echo '{"type":"log","stream":"stderr","line":"denied: the token has expired"}' >&2
echo '{"type":"error","code":"compose.up","message":"The stack did not start"}' >&2
exit 1
'''),
        );
        final output = result.error!.output!.split('\n');
        expect(result.error?.message, 'The stack did not start');
        expect(output, hasLength(EnvironmentCommandRunner.errorOutputLines));
        expect(output.first, 'pull 21');
        expect(output[output.length - 2], '${'x' * 300}…');
        expect(output.last, 'denied: the token has expired');
      },
    );

    test('a line the tool wrapped in JSON is still a line', () async {
      final events = <EnvironmentCommandEvent>[];
      final result = await runner.run(
        ShellEnvironmentCommand(r'''
echo '{"type":"log","stream":"stdout","line":"Container db  Started"}' >&2
echo '{"type":"log","stream":"stderr"}' >&2
'''),
        onEvent: events.add,
      );
      expect(events.whereType<EnvironmentCommandProgress>(), isEmpty);
      expect(events.whereType<EnvironmentCommandOutput>().map((e) => e.line), [
        'Container db  Started',
        '{"type":"log","stream":"stderr"}',
      ]);
      expect(result.stderr, startsWith('Container db  Started'));
    });

    test('the tool\'s verdict reads as a line of the log', () async {
      final events = <EnvironmentCommandEvent>[];
      await runner.run(
        ShellEnvironmentCommand(r'''
echo '{"type":"error","code":"env.broken","message":"It broke","hint":"Fix it"}' >&2
exit 7
'''),
        onEvent: events.add,
      );
      expect(events.whereType<EnvironmentCommandOutput>().map((e) => e.line), [
        '[error] It broke',
      ]);
    });

    test('a step keeps the id its tool gave it, number or word', () async {
      final events = <EnvironmentCommandEvent>[];
      await runner.run(
        ShellEnvironmentCommand(r'''
echo '{"type":"step","id":1,"label":"Pulling images","state":"running"}' >&2
echo '{"type":"step","id":"db","label":"Database","state":"succeeded"}' >&2
'''),
        onEvent: events.add,
      );
      final steps = events.whereType<EnvironmentCommandProgress>().toList();
      expect(steps.map((e) => e.progress.id), ['1', 'db']);
      expect(steps.map((e) => e.progress.stepState), [
        EnvironmentStepState.running,
        EnvironmentStepState.done,
      ]);
    });

    test('an error line that is not last is plain output', () async {
      final result = await runner.run(
        ShellEnvironmentCommand(r'''
echo '{"type":"error","message":"Old news"}' >&2
echo the real reason >&2
exit 1
'''),
      );
      expect(result.error?.code, 'command-failed');
      expect(result.error?.message, contains('the real reason'));
    });

    test('no error on exit 0, whatever stderr says', () async {
      final result = await runner.run(
        ShellEnvironmentCommand(
          r'''echo '{"type":"error","message":"Eh"}' >&2''',
        ),
      );
      expect(result.error, isNull);
    });

    test('without an error line, quotes the last 20 lines', () async {
      final result = await runner.run(
        ShellEnvironmentCommand(
          r'for i in $(seq 1 30); do echo "line-$i" >&2; done; exit 1',
        ),
      );
      final lines = result.error!.message.split('\n');
      expect(lines, hasLength(20));
      expect(lines.first, 'line-11');
      expect(lines.last, 'line-30');
    });

    for (final (code, name) in const [
      (3, 'input-required'),
      (4, 'auth-required'),
      (5, 'dependency-unavailable'),
    ]) {
      test('exit $code carries the command to retry', () async {
        final result = await runner.run(ShellEnvironmentCommand('exit $code'));
        expect(result.error?.code, name);
        expect(result.error?.exitCode, code);
        expect(result.error?.command, contains('exit $code'));
      });
    }

    test('a tool\'s own command wins over the fallback', () async {
      final result = await runner.run(
        ShellEnvironmentCommand(r'''
echo '{"type":"error","code":"hosts","message":"Needs sudo","command":"sudo tool hosts"}' >&2
exit 3
'''),
      );
      expect(result.error?.command, 'sudo tool hosts');
      expect(result.error?.blocker, EnvironmentBlocker.input);
    });
  }, skip: _posix);

  test('keeps raw stdout for parsing only', () async {
    final result = await runner.run(
      ShellEnvironmentCommand(
        r'''echo '{"auth":"Authorization: Bearer abc"}' ''',
      ),
    );
    expect(jsonDecode(result.rawStdout), {'auth': 'Authorization: Bearer abc'});
    expect(result.stdout, isNot(contains('abc')));
  }, skip: _posix);

  test('redacts stdout, stderr, events and errors', () async {
    const secret = 'ghp_abcdefghijklmnopqrstuvwxyz0123456789';
    final seen = <String>[];
    final result = await runner.run(
      ShellEnvironmentCommand(
        'echo $secret; echo --token=hunter2 >&2; '
        '''echo '{"type":"error","message":"bad $secret"}' >&2; exit 1''',
      ),
      onEvent: (event) {
        if (event is EnvironmentCommandOutput) {
          seen.add(event.line);
        }
      },
    );
    expect(result.stdout, isNot(contains(secret)));
    expect(result.stderr, isNot(contains('hunter2')));
    expect(seen.join('\n'), isNot(contains(secret)));
    expect(result.error?.message, isNot(contains(secret)));
  }, skip: _posix);

  group('environment', () {
    test('caller variables reach the process', () async {
      final result = await runner.run(
        ShellEnvironmentCommand(r'echo "$CC_ENV_NAME"'),
        environment: const {'CC_ENV_NAME': 'shop'},
      );
      expect(result.stdout, 'shop');
    }, skip: _posix);

    test('caller NODE_OPTIONS survives sanitizing', () {
      final variables = environmentProcessVariables(const {
        'NODE_OPTIONS': '--max-old-space-size=4096',
      });
      expect(variables['NODE_OPTIONS'], '--max-old-space-size=4096');
    });

    test('a resolved binary adds its directory to the end of PATH', () {
      final variables = environmentProcessVariables(const {
        'PATH': '/usr/bin',
      }, executable: '/opt/acme/bin/tool');
      expect(variables['PATH'], ['/usr/bin', '/opt/acme/bin'].join(_pathSep));
    });

    test('a directory already on PATH is left alone', () {
      final path = ['/opt/acme/bin', '/usr/bin'].join(_pathSep);
      final variables = environmentProcessVariables({
        'PATH': path,
      }, executable: '/opt/acme/bin/tool');
      expect(variables['PATH'], path);
    });

    test('the process does not inherit past the sanitizer', () async {
      Map<String, String>? seen;
      final runner = EnvironmentCommandRunner(
        starter: (executable, arguments, {workingDirectory, environment}) {
          seen = environment;
          return Process.start('/bin/echo', const []);
        },
        binaryResolver: (name) async => '/usr/bin/$name',
      );
      await runner.runArgv(['true']);
      expect(seen!.keys, isNot(contains('DYLD_INSERT_LIBRARIES')));
      expect(seen!.keys, isNot(contains('LD_PRELOAD')));
    });
  });

  test('environmentCommandLine quotes what a shell would split', () {
    expect(
      environmentCommandLine(['tool', 'a b', "it's", '--x=1']),
      r"tool 'a b' 'it'\''s' --x=1",
    );
  });
}
