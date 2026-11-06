import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/environments/domain/value_objects/environment_command.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_template.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:test/test.dart';

import 'helpers/environment_fakes.dart';

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
    });

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
    });

    test('appends extra arguments', () async {
      final result = await runner.run(
        argv(['/bin/echo', 'a']),
        arguments: ['b c'],
      );
      expect(result.stdout, 'a b c');
    });

    test('runArgv takes braces literally', () async {
      final result = await runner.runArgv(['/bin/echo', '{name}']);
      expect(result.stdout, '{name}');
    });

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
  });

  test('stdin is closed, so a reader gets end of file', () async {
    final result = await runner.run(
      argv(['/bin/cat']),
      timeout: const Duration(seconds: 5),
    );
    expect(result.exitCode, 0);
    expect(result.timedOut, isFalse);
  });

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
      await runner.run(
        ShellEnvironmentCommand('(sleep 1; touch "$marker") & wait'),
        timeout: const Duration(milliseconds: 200),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(File(marker).existsSync(), isFalse);
    });
  });

  test('cancel uses the same ladder and keeps the real exit code', () async {
    final handle = runner.startArgv(['/bin/sleep', '30']);
    Timer(const Duration(milliseconds: 100), handle.cancel);
    final result = await handle.result;
    expect(result.cancelled, isTrue);
    expect(result.timedOut, isFalse);
    expect(result.exitCode, isNot(0));
    expect(result.exitCode, isNot(environmentTimeoutExitCode));
  });

  test('a daemon holding stdout open does not fail the command', () async {
    final watch = Stopwatch()..start();
    final result = await runner.run(
      ShellEnvironmentCommand('sleep 2 & echo started; exit 0'),
    );
    expect(result.exitCode, 0);
    expect(result.error, isNull);
    expect(result.stdout, contains('started'));
    expect(watch.elapsed, lessThan(const Duration(milliseconds: 1500)));
  });

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
        ),
      );
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
      (3, 'host-setup-required'),
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
      expect(result.error?.needsHostSetup, isTrue);
    });
  });

  test('keeps raw stdout for parsing only', () async {
    final result = await runner.run(
      ShellEnvironmentCommand(
        r'''echo '{"auth":"Authorization: Bearer abc"}' ''',
      ),
    );
    expect(jsonDecode(result.rawStdout), {'auth': 'Authorization: Bearer abc'});
    expect(result.stdout, isNot(contains('abc')));
  });

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
  });

  group('environment', () {
    test('caller variables reach the process', () async {
      final result = await runner.run(
        ShellEnvironmentCommand(r'echo "$CC_ENV_NAME"'),
        environment: const {'CC_ENV_NAME': 'shop'},
      );
      expect(result.stdout, 'shop');
    });

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
      expect(variables['PATH'], '/usr/bin:/opt/acme/bin');
    });

    test('a directory already on PATH is left alone', () {
      final variables = environmentProcessVariables(const {
        'PATH': '/opt/acme/bin:/usr/bin',
      }, executable: '/opt/acme/bin/tool');
      expect(variables['PATH'], '/opt/acme/bin:/usr/bin');
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
