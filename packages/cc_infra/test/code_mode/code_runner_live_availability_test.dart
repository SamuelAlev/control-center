// Code mode's availability is live: a runner that stops launching after boot
// (binary replaced or removed, a sandbox regression) re-runs the self-test,
// and a failed re-test turns scripts off; while they are off, a read of the
// availability re-runs it, and one that passes turns them back on. A script
// cannot cause a re-test: only failures before the script is sent count.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_runner_live_availability.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

/// A self-test report that passes.
const _passing =
    '{"selftest":{"ok":true,"os":"test","build":"release",'
    '"lockdown":{"level":"full","failed":[]},'
    '"checks":[{"name":"file_read","denied":true}],'
    '"session":{"passed":true,"runs":13}}}';

void main() {
  late Directory tmp;
  late FakeRunners fakes;
  late File mode;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('codemode-live-');
    fakes = FakeRunners(tmp);
    mode = File(p.join(tmp.path, 'mode'))..writeAsStringSync('ok');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  /// A fake runner whose behaviour is read from [mode] on every start:
  /// `ok` passes its self-test, `broken` fails it, and a launch does what
  /// [launch] says.
  String runner(String launch) => fakes.script('''
m=\$(/bin/cat ${mode.path})
if [ "\$1" = "--self-test" ]; then
  if [ "\$m" = "ok" ]; then printf '%s\\n' '$_passing'; exit 0; fi
  /bin/echo "self-test crashed" >&2
  exit 1
fi
$launch''');

  CodeSandboxStart start() => CodeSandboxStart(
    code: 'return 1',
    limits: CodeModeLimits(wallClockMs: 5000),
    returnBudgetChars: 30400,
    catalog: const [],
  );

  Future<String?> launch(
    CodeSandboxProcess host, {
    CancellationToken? cancel,
  }) async {
    try {
      final session = await host.start(
        start(),
        cancel: cancel ?? CancellationToken.none,
      );
      session.events.listen((_) {});
      await session.outcome;
      return null;
    } on CodeSandboxStartException catch (e) {
      return e.errorKind;
    }
  }

  test('a launch failure re-runs the self-test; a failed re-test turns '
      'scripts off, once, with its reason; within the interval nothing '
      'turns them back on', () async {
    final host = CodeSandboxProcess(executable: runner('exit 1'));
    expect((await host.selfTest()).isAvailable, isTrue);
    final changes = <CodeRunnerAvailability>[];
    host.changes.listen(changes.add);

    mode.writeAsStringSync('broken');
    expect(await launch(host), isNotNull);
    await host.retestDone;
    expect(host.retests, 1);
    expect(host.availability, isA<CodeRunnerUnavailable>());
    expect(
      host.availability.toJson()['reason'],
      contains('self-test exited with code 1'),
    );
    expect(changes, hasLength(1));

    // Within the interval: a runner that works again, reads, a later boot
    // self-test call, more launch failures change nothing.
    mode.writeAsStringSync('ok');
    for (var i = 0; i < 5; i++) {
      expect(host.availability.isAvailable, isFalse);
    }
    expect((await host.selfTest()).isAvailable, isFalse);
    expect(await launch(host), isNotNull);
    await host.retestDone;
    expect(host.retests, 1);
    expect(host.availability.isAvailable, isFalse);
    expect(changes, hasLength(1));
    await host.dispose();
  });

  test('while a failed re-test keeps scripts off, a read re-runs the '
      'self-test: a failing one changes nothing, a passing one turns them '
      'back on; each change fires once', () async {
    final host = CodeSandboxProcess(
      executable: runner('exit 1'),
      retestInterval: Duration.zero,
    );
    expect((await host.selfTest()).isAvailable, isTrue);
    final changes = <CodeRunnerAvailability>[];
    host.changes.listen(changes.add);

    mode.writeAsStringSync('broken');
    await launch(host);
    await host.retestDone;
    expect(host.retests, 1);
    expect(changes.map((c) => c.isAvailable), [false]);

    // Still broken: the read re-tests, the failure changes nothing.
    expect(host.availability.isAvailable, isFalse);
    await host.retestDone;
    expect(host.retests, 2);
    expect(changes, hasLength(1));

    // Reads at once start one re-test, never two.
    mode.writeAsStringSync('ok');
    for (var i = 0; i < 5; i++) {
      expect(host.availability.isAvailable, isFalse);
    }
    expect(host.retests, 3);
    await host.retestDone;
    expect(host.availability.isAvailable, isTrue);
    expect(changes.map((c) => c.isAvailable), [false, true]);

    // Available again: reads start nothing; a launch failure re-tests.
    for (var i = 0; i < 5; i++) {
      expect(host.availability.isAvailable, isTrue);
    }
    expect(host.retests, 3);
    await host.dispose();
  });

  test('a read re-tests at most once per interval', () async {
    final host = CodeSandboxProcess(
      executable: runner('exit 1'),
      retestInterval: const Duration(milliseconds: 600),
    );
    expect((await host.selfTest()).isAvailable, isTrue);
    mode.writeAsStringSync('broken');
    await launch(host);
    await host.retestDone;
    expect(host.retests, 1);
    mode.writeAsStringSync('ok');
    expect(host.availability.isAvailable, isFalse);
    await host.retestDone;
    expect(host.retests, 1, reason: 'within the interval');
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(host.availability.isAvailable, isFalse);
    expect(host.retests, 2, reason: 'once the interval passed');
    await host.retestDone;
    expect(host.availability.isAvailable, isTrue);
    await host.dispose();
  });

  test('scripts that the boot self-test never allowed stay off: reads and '
      'launches re-test nothing', () async {
    mode.writeAsStringSync('broken');
    final host = CodeSandboxProcess(
      executable: runner('exit 1'),
      retestInterval: Duration.zero,
    );
    expect((await host.selfTest()).isAvailable, isFalse);
    mode.writeAsStringSync('ok');
    expect(host.availability.isAvailable, isFalse);
    expect(await launch(host), isNotNull);
    await host.retestDone;
    expect(host.retests, 0);
    expect(host.availability.isAvailable, isFalse);
    await host.dispose();
  });

  test('a passing re-test leaves code mode available, and re-tests run at '
      'most once per interval, never two at once', () async {
    final host = CodeSandboxProcess(executable: runner('exit 1'));
    expect((await host.selfTest()).isAvailable, isTrue);
    // Launches fail, the self-test passes.
    await Future.wait([launch(host), launch(host), launch(host)]);
    await host.retestDone;
    expect(host.retests, 1, reason: 'one re-test for failures together');
    expect(host.availability.isAvailable, isTrue);
    expect(await launch(host), isNotNull);
    await host.retestDone;
    expect(host.retests, 1, reason: 'within the interval');

    final eager = CodeSandboxProcess(
      executable: runner('exit 1'),
      retestInterval: Duration.zero,
    );
    expect((await eager.selfTest()).isAvailable, isTrue);
    await launch(eager);
    await eager.retestDone;
    await launch(eager);
    await eager.retestDone;
    expect(eager.retests, 2);
    expect(eager.availability.isAvailable, isTrue);
    await host.dispose();
    await eager.dispose();
  });

  test(
    'a runner of another protocol runs no script: its self-test is '
    'refused with the reinstall text, before the lockdown is tested',
    () async {
      for (final (version, says) in [
        ('cc_codemode 0.1.0 quickjs-ng 0.16.2 protocol 1', 'speaks protocol 1'),
        ('cc_codemode 9 quickjs-ng 9 protocol 3', 'speaks protocol 3'),
        ('cc_codemode 0.0.1', 'does not report its protocol'),
      ]) {
        final host = CodeSandboxProcess(
          executable: fakes.script(
            '/bin/echo "the self-test must not run" >&2; exit 1',
            version: version,
          ),
        );
        final answer = await host.selfTest();
        expect(answer.isAvailable, isFalse, reason: version);
        final reason = (answer as CodeRunnerUnavailable).reason;
        expect(reason, contains(says));
        expect(
          reason,
          contains(
            'this server speaks ${CodeSandboxProcess.protocolVersion}. '
            'Reinstall the application or server bundle.',
          ),
        );
        expect(reason, isNot(contains('must not run')));
        expect(host.availability.isAvailable, isFalse);
        await host.dispose();
      }
    },
  );

  test(
    'a re-test after a protocol refusal at launch keeps scripts off',
    () async {
      // The boot self-test passed; then the runner was replaced by one of
      // another protocol.
      final version = File(p.join(tmp.path, 'version'))..writeAsStringSync('2');
      final path = fakes.script(
        'if [ "\$1" = "--self-test" ]; then '
        "printf '%s\\n' '$_passing'; exit 0; fi\n"
        "printf '%s\\n' "
        '\'{"type":"ready","protocol":1,"engine":"x",'
        '"lockdown":{"level":"full","failed":[]}}\'; /bin/sleep 5',
        version: 'cc_codemode 0 fake protocol \$(/bin/cat ${version.path})',
      );
      final host = CodeSandboxProcess(executable: path);
      expect((await host.selfTest()).isAvailable, isTrue);
      version.writeAsStringSync('1');
      expect(await launch(host), 'protocol');
      await host.retestDone;
      expect(host.retests, 1);
      expect(host.availability.isAvailable, isFalse);
      expect(
        (host.availability as CodeRunnerUnavailable).reason,
        contains('speaks protocol 1'),
      );
      await host.dispose();
    },
  );

  test('each failure that is not the script\'s counts: no runner, a '
      'malformed or foreign ready frame, less than full lockdown', () async {
    final launches = {
      'removed': null,
      'malformed': r'''printf '%s\n' '{"type":"ready"}'; /bin/sleep 5''',
      'protocol':
          r'''printf '%s\n' '{"type":"ready","protocol":1,"engine":"x","lockdown":{"level":"full","failed":[]}}'; /bin/sleep 5''',
      'partial':
          r'''printf '%s\n' '{"type":"ready","protocol":2,"engine":"x","lockdown":{"level":"partial","failed":["seccomp"]}}'; /bin/sleep 5''',
    };
    for (final MapEntry(key: what, value: body) in launches.entries) {
      final path = runner(body ?? 'exit 0');
      final host = CodeSandboxProcess(executable: path);
      expect((await host.selfTest()).isAvailable, isTrue, reason: what);
      mode.writeAsStringSync('broken');
      if (body == null) {
        File(path).deleteSync();
      }
      expect(await launch(host), isNotNull, reason: what);
      await host.retestDone;
      expect(host.retests, 1, reason: what);
      expect(host.availability.isAvailable, isFalse, reason: what);
      mode.writeAsStringSync('ok');
      await host.dispose();
    }
  });

  test('a handshake that only times out, and a cancelled start, do not '
      'count', () async {
    final host = CodeSandboxProcess(
      executable: runner('/bin/sleep 5'),
      handshakeTimeout: const Duration(milliseconds: 300),
    );
    expect((await host.selfTest()).isAvailable, isTrue);
    mode.writeAsStringSync('broken');
    expect(await launch(host), isNotNull);
    final cancel = CancellationTokenSource();
    final cancelled = launch(host, cancel: cancel.token);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    cancel.cancel();
    expect(await cancelled, 'cancelled');
    await host.retestDone;
    expect(host.retests, 0);
    expect(host.availability.isAvailable, isTrue);
    await host.dispose();
  });

  test('scripts cannot cause a re-test: every ending a script can choose, '
      'with its own limits, leaves the runner alone', () async {
    final host = CodeSandboxProcess(executable: realRunnerPath());
    expect((await host.selfTest()).isAvailable, isTrue);
    final cases = {
      'while (true) {}': CodeModeLimits(wallClockMs: 1000, cpuMs: 30000),
      'let a = []; while (true) a.push(new Array(1e5).fill(1));':
          CodeModeLimits(heapBytes: CodeModeLimits.heap.floor),
      'throw new Error("x")': CodeModeLimits(),
      'console.log("x".repeat(1 << 20)); while (true) console.log("y".repeat(1 << 20));':
          CodeModeLimits(),
      'return undefined.x': CodeModeLimits(wallClockMs: 1000),
    };
    final statuses = <CodeExecutionStatus>{};
    for (final MapEntry(key: code, value: limits) in cases.entries) {
      final session = await host.start(
        CodeSandboxStart(
          code: code,
          limits: limits,
          catalog: const [],
          returnBudgetChars: 30400,
        ),
      );
      session.events.listen((_) {});
      statuses.add((await session.outcome).status);
    }
    expect(
      statuses,
      containsAll([
        CodeExecutionStatus.timedOut,
        CodeExecutionStatus.memoryExceeded,
        CodeExecutionStatus.failed,
        CodeExecutionStatus.outputExceeded,
      ]),
    );
    await host.retestDone;
    expect(host.retests, 0);
    expect(host.availability.isAvailable, isTrue);
    await host.dispose();
  }, timeout: const Timeout(Duration(minutes: 2)));

  group('with the real runner behind a switch', () {
    late String real;
    late String dataDir;
    late String wrapper;
    late CodeSandboxProcess process;
    late CodeExecutionService service;

    setUp(() async {
      real = realRunnerPath();
      // A data directory as an install has one: spaces, a non-ASCII name.
      dataDir = p.join(tmp.path, 'Application Support', 'Contrôle Center');
      // The real runner while [mode] says ok; otherwise a runner that
      // cannot start and says where it lives.
      wrapper = fakes.script('''
m=\$(/bin/cat ${mode.path})
if [ "\$m" = "ok" ]; then exec $real "\$@"; fi
/bin/echo "cannot open $real from \$0 in ${tmp.path}" >&2
/bin/echo "Cannot open file, path = '$dataDir/codemode' (OS Error: denied)" >&2
/bin/echo "reading file://$dataDir/x.json" >&2
printf '%s\\n' 'C:\\Users\\someone\\App Data\\cc: gone, says the runner' >&2
exit 4''');
      process = CodeSandboxProcess(
        executable: wrapper,
        retestInterval: Duration.zero,
      );
      expect((await process.selfTest()).isAvailable, isTrue);
      service = CodeExecutionService(
        sandbox: process,
        executions: MemoryExecutions(),
        store: MemoryStore(),
        serverProcessCap: 2,
      );
    });

    tearDown(() async {
      await service.dispose();
      expect(process.liveProcessCount, 0);
    });

    Future<CodeExecutionResult> run(String id) => service.execute(
      CodeExecutionRequest(
        readOnly: false,
        past: null,
        workspaceId: 'ws-1',
        runId: id,
        parentToolCallId: 'call_1',
        surface: CodeExecutionSurface.harness,
        code: 'return 1;',
        description: 'one',
        limits: CodeModeLimits(),
        tools: const [],
      ),
      callNested: (_) async => NestedCallOutcome(
        status: NestedCallStatus.completed,
        value: const {},
      ),
    );

    /// Every text of [r] a model or a run's record is given.
    String said(CodeExecutionResult r) =>
        '${r.result.text}\n${jsonEncode(r.execution.toJson())}';

    void expectNoHostPath(String text) {
      for (final path in [
        real,
        wrapper,
        tmp.path,
        p.dirname(real),
        dataDir,
        // What a pattern cut short would leave.
        'Support/', 'Center/', 'Contrôle', 'App Data', 'someone',
      ]) {
        expect(text, isNot(contains(path)), reason: text);
      }
    }

    test('lost, then restored: a run while off is refused unavailable and '
        'gets no repl, a run after has it; no text names a host '
        'path', () async {
      final changes = <CodeRunnerAvailability>[];
      process.changes.listen(changes.add);

      mode.writeAsStringSync('broken');
      final failed = await run('run-1');
      expect(failed.execution.errorKind, CodeExecutionErrorKind.start);
      expect(failed.result.text, contains('Runner said'));
      expect(failed.result.text, contains('<path>'));
      expectNoHostPath(said(failed));
      await process.retestDone;
      expect(changes.map((c) => c.isAvailable), [false]);

      // What both lanes read when a run starts: no repl while off.
      expect(service.availability.isAvailable, isFalse);
      expectNoHostPath(service.availability.toJson().toString());
      await process.retestDone;
      final off = await run('run-2');
      expect(off.execution.errorKind, CodeExecutionErrorKind.unavailable);
      expect(
        CodeExecutionErrorKind.withdrawsScripts,
        contains(off.execution.errorKind),
      );
      expectNoHostPath(said(off));
      await process.retestDone;
      expect(
        changes,
        hasLength(1),
        reason: 'a failing re-test changes nothing',
      );

      mode.writeAsStringSync('ok');
      expect(service.availability.isAvailable, isFalse);
      await process.retestDone;
      expect(service.availability.isAvailable, isTrue);
      expect(changes.map((c) => c.isAvailable), [false, true]);
      final on = await run('run-3');
      expect(
        on.execution.status,
        CodeExecutionStatus.completed,
        reason: on.result.text,
      );
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('a runner that cannot be spawned is refused without its '
        'path', () async {
      final gone = CodeSandboxProcess(
        executable: p.join(tmp.path, 'no-such-runner'),
      );
      try {
        await gone.start(
          CodeSandboxStart(
            code: 'return 1',
            limits: CodeModeLimits(),
            returnBudgetChars: 30400,
            catalog: const [],
          ),
        );
        fail('started');
      } on CodeSandboxStartException catch (e) {
        expect(e.errorKind, 'start');
        expectNoHostPath(e.message);
        expect(e.message, contains('server log'));
      }
      await gone.dispose();
    });
  });

  test('a launch failure and its verdict are each said once, in one line: '
      'a passing re-test in a line of its own, a failing one inside the '
      'reason scripts are off for', () async {
    final records = <(CcInfraLogLevel, String)>[];
    final saved = CcInfraLog.sink;
    CcInfraLog.sink = (level, message, [error, stackTrace]) =>
        records.add((level, message));
    addTearDown(() => CcInfraLog.sink = saved);
    final path = runner('exit 1');
    final host = CodeSandboxProcess(
      executable: path,
      retestInterval: Duration.zero,
    );
    expect((await host.selfTest()).isAvailable, isTrue);

    // Exits before ready; the self-test still passes.
    await launch(host);
    await host.retestDone;
    expect(host.availability.isAvailable, isTrue);
    final passed = records.where((r) => r.$2.contains('passed again'));
    expect(passed, hasLength(1));
    expect(passed.single.$1, CcInfraLogLevel.warning);

    // The runner is gone: the spawn fails (an OS error over two lines),
    // and so does the self-test.
    File(path).deleteSync();
    expect(await launch(host), 'start');
    await host.retestDone;
    final reason = host.availability.toJson()['reason'] as String;
    expect(reason, contains('re-run after a script runner failed to launch'));
    expect(reason, contains('could not be started'));
    expect(reason, isNot(matches(RegExp('[\\r\\n]'))));
    for (final (_, line) in records) {
      expect(line, isNot(matches(RegExp('[\\r\\n]'))), reason: line);
    }
    // No line of its own for the failure that turned scripts off: the
    // reason holds it.
    expect(
      records.where((r) => r.$2.contains('could not be started')),
      isEmpty,
    );
    await host.dispose();
  });

  test('a reason and a launch failure stay one line: controls, separators '
      'and secrets are taken out (review L5)', () async {
    final token = 'ghp_${'a1B2c3D4e5' * 4}';
    final records = <(CcInfraLogLevel, String)>[];
    final saved = CcInfraLog.sink;
    CcInfraLog.sink = (level, message, [error, stackTrace]) =>
        records.add((level, message));
    addTearDown(() => CcInfraLog.sink = saved);
    final dirty =
        'the runner said \x1b[31mred\x1b[0m\u0085next\x0b\x0c'
        '\u2028x token=$token';
    var pass = false;
    final health = CodeRunnerLiveAvailability(
      selfTest: () async => pass
          ? const CodeRunnerAvailability.available()
          : CodeRunnerAvailability.unavailable(dirty),
      retestInterval: Duration.zero,
    );
    final unprintable = RegExp(r'[\x00-\x1f\x7f-\x9f\u2028\u2029]');
    final reason = (await health.boot()).toJson()['reason'] as String;
    expect(reason, contains('the runner said'));
    expect(reason, isNot(matches(unprintable)));
    expect(reason, isNot(contains(token)));

    final passing = CodeRunnerLiveAvailability(
      selfTest: () async => const CodeRunnerAvailability.available(),
      retestInterval: Duration.zero,
    );
    pass = true;
    await passing.boot();
    passing.launchFailed(dirty);
    await passing.retestDone;
    final line = records.singleWhere((r) => r.$2.contains('passed again')).$2;
    expect(line, contains('the runner said'));
    expect(line, isNot(matches(unprintable)));
    expect(line, isNot(contains(token)));
    health.close();
    passing.close();
  });

  test(
    'a token split by a character that hides inside a word is redacted, '
    'in the reason and in the launch-failure line (review round 4)',
    () async {
      final records = <String>[];
      final saved = CcInfraLog.sink;
      CcInfraLog.sink = (level, message, [error, stackTrace]) =>
          records.add(message);
      addTearDown(() => CcInfraLog.sink = saved);
      for (final hidden in ['\u200B', '\u00AD', '\uFEFF', '\u2060']) {
        records.clear();
        final split = 'ghp_a1B2c3D4${hidden}e5a1B2c3D4e5a1B2c3D4e5a1B2c3D4e5';
        final failing = CodeRunnerLiveAvailability(
          selfTest: () async =>
              CodeRunnerAvailability.unavailable('token $split end'),
          retestInterval: Duration.zero,
        );
        final reason = (await failing.boot()).toJson()['reason'] as String;
        final passing = CodeRunnerLiveAvailability(
          selfTest: () async => const CodeRunnerAvailability.available(),
          retestInterval: Duration.zero,
        );
        await passing.boot();
        passing.launchFailed('token $split end');
        await passing.retestDone;
        final line = records.singleWhere((r) => r.contains('passed again'));
        for (final text in [reason, line]) {
          expect(text, isNot(contains('a1B2c3D4')), reason: text);
          expect(text, contains('token '));
          expect(text, contains(' end'));
        }
        failing.close();
        passing.close();
      }
    },
  );
}
