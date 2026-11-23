// The process host against fake runners that speak the protocol badly. Each
// hostile frame must end the script as sandbox_error and leave no process.
// Fake runners are /bin/sh scripts (FakeRunners), which Windows cannot exec.
@TestOn('!windows')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

void main() {
  late Directory tmp;
  late FakeRunners fakes;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('codemode-fake-');
    fakes = FakeRunners(tmp);
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  CodeSandboxStart start({int wallMs = 5000, int maxCalls = 1}) =>
      CodeSandboxStart(
        code: 'return 1',
        limits: CodeModeLimits(wallClockMs: wallMs, maxNestedCalls: maxCalls),
        returnBudgetChars: 30400,
        catalog: const [],
      );

  /// Runs a fake that has read init and exec, then does [after].
  String afterExec(String after) => fakes.script('''
printf '%s\\n' '$fakeReadyFull'
read -r init
read -r exec
$after''');

  Future<CodeSandboxOutcome> drive(
    CodeSandboxProcess host, {
    CodeSandboxStart? request,
    void Function(CodeSandboxEvent event, CodeSandboxSession session)? onEvent,
  }) async {
    final session = await host.start(request ?? start());
    session.events.listen((e) => onEvent?.call(e, session));
    return session.outcome;
  }

  Future<void> expectGone(CodeSandboxProcess host) async {
    expect(host.liveProcessCount, 0);
    final pid = fakes.lastPid();
    expect(pid, isNotNull);
    expect(processAlive(pid!), isFalse, reason: 'runner $pid still alive');
  }

  test('a ready frame with partial lockdown is refused before any script '
      'is sent', () async {
    final received = p.join(tmp.path, 'received');
    final path = fakes.script('''
printf '%s\\n' '{"type":"ready","protocol":2,"engine":"fake","lockdown":{"level":"partial","failed":["seccomp"]}}'
if read -r line; then echo "\$line" > $received; fi
exec /bin/sleep 30''');
    final host = CodeSandboxProcess(executable: path);
    await expectLater(
      host.start(start()),
      throwsA(
        isA<CodeSandboxStartException>()
            .having((e) => e.errorKind, 'errorKind', 'lockdown')
            .having((e) => e.message, 'message', contains('seccomp')),
      ),
    );
    expect(File(received).existsSync(), isFalse);
    await expectGone(host);
  });

  test('a runner speaking another protocol version is refused', () async {
    final path = fakes.script('''
printf '%s\\n' '{"type":"ready","protocol":1,"engine":"fake","lockdown":{"level":"full"}}'
exec /bin/sleep 30''');
    final host = CodeSandboxProcess(executable: path);
    await expectLater(
      host.start(start()),
      throwsA(
        isA<CodeSandboxStartException>().having(
          (e) => e.errorKind,
          'errorKind',
          'protocol',
        ),
      ),
    );
    await expectGone(host);
  });

  test('garbage before ready fails the start', () async {
    final path = fakes.script('''
printf 'hello\\n'
exec /bin/sleep 30''');
    final host = CodeSandboxProcess(executable: path);
    await expectLater(
      host.start(start()),
      throwsA(isA<CodeSandboxStartException>()),
    );
    await expectGone(host);
  });

  test('a runner that exits before ready fails the start at once, saying why '
      'and with its stderr', () async {
    final path = fakes.script(r'''
printf 'setup failed: no seccomp\n' >&2
exit 4''');
    final host = CodeSandboxProcess(executable: path);
    final clock = Stopwatch()..start();
    await expectLater(
      host.start(start()),
      throwsA(
        isA<CodeSandboxStartException>()
            .having((e) => e.errorKind, 'errorKind', 'start')
            .having((e) => e.message, 'message', contains('set up'))
            .having((e) => e.message, 'message', contains('no seccomp')),
      ),
    );
    expect(clock.elapsed, lessThan(const Duration(seconds: 3)));
    await expectGone(host);
  });

  test('a runner that never says ready is killed after the timeout', () async {
    final path = fakes.script('exec /bin/sleep 30');
    final host = CodeSandboxProcess(
      executable: path,
      handshakeTimeout: const Duration(milliseconds: 500),
    );
    await expectLater(
      host.start(start()),
      throwsA(
        isA<CodeSandboxStartException>().having(
          (e) => e.message,
          'message',
          contains('ready'),
        ),
      ),
    );
    await expectGone(host);
  });

  test('init and exec carry the limits, catalog and store', () async {
    final got = p.join(tmp.path, 'got');
    final path = fakes.script('''
printf '%s\\n' '$fakeReadyFull'
read -r init
read -r exec
printf "%s\\n" "\$init" > $got
printf "%s\\n" "\$exec" >> $got
printf '%s\\n' '{"type":"done","ok":true,"value":7,"stats":{"cpu_ms":1,"peak_heap_bytes":2,"calls":0,"output_chars":0,"output_items":0}}'
''');
    final host = CodeSandboxProcess(executable: path);
    final outcome = await drive(
      host,
      request: CodeSandboxStart(
        code: 'return 7',
        limits: CodeModeLimits(maxNestedCalls: 3),
        returnBudgetChars: 30400,
        catalog: const [
          {'id': 'read', 'name': 'read', 'namespace': 'builtin'},
        ],
        store: const {'k': '[1,2]'},
      ),
    );
    expect(outcome.status, CodeExecutionStatus.completed);
    expect(outcome.returnValue?.text, '7');
    final lines = File(got).readAsLinesSync();
    final init = jsonDecode(lines[0]) as Map<String, dynamic>;
    expect(init['type'], 'init');
    final limits = init['limits'] as Map<String, dynamic>;
    expect(limits['max_calls'], 3 + CodeSandboxProcess.hostCallAllowance);
    expect(limits['stack_bytes'], CodeModeLimits.stackBytes);
    expect(init['catalog'], hasLength(1));
    expect(init['store'], {
      'k': [1, 2],
    });
    expect(jsonDecode(lines[1]), {'type': 'exec', 'code': 'return 7'});
    await expectGone(host);
  });

  test('an oversized frame ends the script as sandbox_error', () async {
    final path = afterExec('''
/usr/bin/head -c 9000000 /dev/zero | /usr/bin/tr '\\0' 'a'
exec /bin/sleep 30''');
    final host = CodeSandboxProcess(executable: path);
    final outcome = await drive(host);
    expect(outcome.status, CodeExecutionStatus.sandboxError);
    expect(outcome.errorKind, 'frame_too_large');
    await expectGone(host);
  });

  test('an unknown frame type ends the script as sandbox_error', () async {
    final path = afterExec('''
printf '%s\\n' '{"type":"bogus"}'
exec /bin/sleep 30''');
    final host = CodeSandboxProcess(executable: path);
    final outcome = await drive(host);
    expect(outcome.status, CodeExecutionStatus.sandboxError);
    expect(outcome.detail, contains('unknown frame type'));
    await expectGone(host);
  });

  test('garbage on stdout ends the script as sandbox_error', () async {
    final path = afterExec('''
printf 'not json at all\\n'
exec /bin/sleep 30''');
    final host = CodeSandboxProcess(executable: path);
    final outcome = await drive(host);
    expect(outcome.status, CodeExecutionStatus.sandboxError);
    await expectGone(host);
  });

  test('a mistyped field ends the script as sandbox_error', () async {
    final path = afterExec('''
printf '%s\\n' '{"type":"call","id":"1","target":"tool","name":"x","args":{}}'
exec /bin/sleep 30''');
    final host = CodeSandboxProcess(executable: path);
    final outcome = await drive(host);
    expect(outcome.status, CodeExecutionStatus.sandboxError);
    await expectGone(host);
  });

  test('a reply-less flood of calls ends at the call cap', () async {
    final path = afterExec(r'''
i=1
while [ $i -le 1100 ]; do
  printf '{"type":"call","id":%d,"target":"host","name":"searchTools","args":{"query":"x"}}\n' $i
  i=$((i+1))
done
exec /bin/sleep 30''');
    final host = CodeSandboxProcess(executable: path);
    var calls = 0;
    final outcome = await drive(
      host,
      onEvent: (e, _) {
        if (e is CodeSandboxCall) {
          calls++;
        }
      },
    );
    expect(outcome.status, CodeExecutionStatus.sandboxError);
    expect(outcome.errorKind, 'call_cap');
    expect(calls, 1 + CodeSandboxProcess.hostCallAllowance);
    await expectGone(host);
  });

  test('a repeated call id ends the script as sandbox_error', () async {
    final path = afterExec('''
printf '%s\\n' '{"type":"call","id":1,"target":"tool","name":"x","args":{}}'
printf '%s\\n' '{"type":"call","id":1,"target":"tool","name":"x","args":{}}'
exec /bin/sleep 30''');
    final host = CodeSandboxProcess(executable: path);
    final outcome = await drive(host);
    expect(outcome.status, CodeExecutionStatus.sandboxError);
    expect(outcome.detail, contains('reused call id 1'));
    await expectGone(host);
  });

  test('call arguments over the cap end the script as sandbox_error', () async {
    final path = afterExec('''
printf '%s' '{"type":"call","id":1,"target":"tool","name":"x","args":{"a":"'
/usr/bin/head -c 1200000 /dev/zero | /usr/bin/tr '\\0' 'a'
printf '%s\\n' '"}}'
exec /bin/sleep 30''');
    final host = CodeSandboxProcess(executable: path);
    final outcome = await drive(host);
    expect(outcome.status, CodeExecutionStatus.sandboxError);
    expect(outcome.detail, contains('call arguments'));
    await expectGone(host);
  });

  test('a frame after done ends the script as sandbox_error', () async {
    final path = afterExec('''
printf '%s\\n' '{"type":"done","ok":true,"stats":{"cpu_ms":0,"peak_heap_bytes":0,"calls":0,"output_chars":0,"output_items":0}}'
printf '%s\\n' '{"type":"output","kind":"text","text":"late"}'
exec /bin/sleep 30''');
    final host = CodeSandboxProcess(executable: path);
    final outcome = await drive(host);
    expect(outcome.status, CodeExecutionStatus.sandboxError);
    expect(outcome.detail, contains('after done'));
    await expectGone(host);
  });

  test('a runner that exits without done ends as sandbox_error', () async {
    final path = afterExec('''
printf '%s\\n' '{"type":"output","kind":"text","text":"partial"}'
exit 0''');
    final host = CodeSandboxProcess(executable: path);
    final outputs = <CodeSandboxEvent>[];
    final outcome = await drive(host, onEvent: (e, _) => outputs.add(e));
    expect(outcome.status, CodeExecutionStatus.sandboxError);
    expect(outcome.errorKind, 'exited');
    expect(outputs, hasLength(1));
    await expectGone(host);
  });

  test('a runner that ignores cancel is killed at the deadline', () async {
    final path = afterExec('exec /bin/sleep 30');
    final host = CodeSandboxProcess(executable: path);
    final clock = Stopwatch()..start();
    final outcome = await drive(host, request: start(wallMs: 1000));
    expect(outcome.status, CodeExecutionStatus.timedOut);
    expect(outcome.errorKind, 'deadline');
    expect(clock.elapsed, lessThan(const Duration(seconds: 5)));
    await expectGone(host);
  });

  group('while the host has stopped reading stdout for backpressure', () {
    // More unanswered call arguments than the host buffers: it pauses its
    // stdout subscription after about 64 MiB, and nobody replies.
    late String flood;
    const frames = 80;
    final args = 'a' * 1000000;

    setUp(() {
      final sink = File(
        p.join(tmp.path, 'flood'),
      ).openSync(mode: FileMode.write);
      for (var i = 1; i <= frames; i++) {
        sink.writeStringSync(
          '${jsonEncode({
            'type': 'call',
            'id': i,
            'target': 'host',
            'name': 'searchTools',
            'args': {'query': args},
          })}\n',
        );
      }
      sink.closeSync();
      flood = afterExec(
        '/bin/cat ${p.join(tmp.path, 'flood')}\n'
        'exec /bin/sleep 30',
      );
    });

    Future<(CodeSandboxSession, Future<int>)> paused(
      CodeSandboxProcess host,
      int wallMs,
    ) async {
      final session = await host.start(start(wallMs: wallMs));
      var calls = 0;
      final stopped = Completer<int>();
      session.events.listen((e) {
        if (e is CodeSandboxCall) {
          calls++;
        }
      });
      // Reading stops short of the flood and stays stopped.
      unawaited(() async {
        var last = -1;
        while (calls != last || calls == 0) {
          last = calls;
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
        stopped.complete(calls);
      }());
      return (session, stopped.future);
    }

    test('the wall-clock deadline still kills the runner', () async {
      final host = CodeSandboxProcess(executable: flood);
      final clock = Stopwatch()..start();
      final (session, stopped) = await paused(host, 3000);
      final read = await stopped;
      expect(read, lessThan(frames), reason: 'the host paused reading');
      final outcome = await session.outcome;
      expect(outcome.status, CodeExecutionStatus.timedOut);
      expect(outcome.errorKind, 'deadline');
      // The deadline, the kill grace and the drain grace, with a margin.
      expect(clock.elapsed, lessThan(const Duration(seconds: 8)));
      await expectGone(host);
    });

    test('terminate still ends the session', () async {
      final host = CodeSandboxProcess(executable: flood);
      final (session, stopped) = await paused(host, 60000);
      expect(await stopped, lessThan(frames));
      final clock = Stopwatch()..start();
      session.terminate();
      final outcome = await session.outcome;
      expect(outcome.status, CodeExecutionStatus.sandboxError);
      expect(outcome.errorKind, CodeExecutionErrorKind.unresponsive);
      expect(clock.elapsed, lessThan(const Duration(seconds: 5)));
      await expectGone(host);
    });
  });

  test('a held deadline does not expire, and resumes on release', () async {
    final path = afterExec('exec /bin/sleep 30');
    final host = CodeSandboxProcess(executable: path);
    final session = await host.start(start(wallMs: 1000));
    session.events.listen((_) {});
    final hold = session.holdDeadline();
    final inner = session.holdDeadline();
    var ended = false;
    unawaited(session.outcome.then((_) => ended = true));
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    expect(ended, isFalse);
    hold.release();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(ended, isFalse, reason: 'an inner hold is still active');
    inner.release();
    final outcome = await session.outcome;
    expect(outcome.status, CodeExecutionStatus.timedOut);
    await expectGone(host);
  });

  test('replies carry credit for held time and refuse undeliverable '
      'payloads', () async {
    final got = p.join(tmp.path, 'got');
    final path = afterExec('''
printf '%s\\n' '{"type":"call","id":1,"target":"tool","name":"x","args":{}}'
read -r r1
printf "%s\\n" "\$r1" > $got
printf '%s\\n' '{"type":"done","ok":true,"stats":{"cpu_ms":0,"peak_heap_bytes":0,"calls":1,"output_chars":0,"output_items":0}}'
''');
    final host = CodeSandboxProcess(executable: path);
    final outcome = await drive(
      host,
      onEvent: (e, session) async {
        if (e is CodeSandboxCall) {
          final hold = session.holdDeadline();
          await Future<void>.delayed(const Duration(milliseconds: 200));
          hold.release();
          Object deep = 1;
          for (var i = 0; i < 200; i++) {
            deep = [deep];
          }
          session.reply(CodeSandboxReply.value(e.id, deep));
        }
      },
    );
    expect(outcome.status, CodeExecutionStatus.completed);
    final frame = jsonDecode(File(got).readAsStringSync()) as Map;
    expect(frame['type'], 'result');
    expect(frame['id'], 1);
    expect(frame['ok'], isFalse);
    expect((frame['payload'] as Map)['message'], contains('nested'));
    expect(frame['credit_ms'], greaterThanOrEqualTo(150));
    await expectGone(host);
  });

  test('cancel stops a runner that ignores it within the grace', () async {
    final path = afterExec('exec /bin/sleep 30');
    final host = CodeSandboxProcess(executable: path);
    final session = await host.start(start());
    session.events.listen((_) {});
    session.cancel();
    final outcome = await session.outcome;
    expect(outcome.status, CodeExecutionStatus.cancelled);
    await expectGone(host);
  });

  test('dispose kills every live runner', () async {
    final path = afterExec('exec /bin/sleep 30');
    final host = CodeSandboxProcess(executable: path);
    final session = await host.start(start(wallMs: 60000));
    session.events.listen((_) {});
    await host.dispose();
    final outcome = await session.outcome;
    expect(outcome.status, CodeExecutionStatus.cancelled);
    expect(outcome.errorKind, 'shutdown');
    await expectGone(host);
    await expectLater(
      host.start(start()),
      throwsA(isA<CodeSandboxStartException>()),
    );
  });

  test(
    'self-test of a fake that reports less than full is unavailable',
    () async {
      final path = fakes.script(r'''
printf '%s\n' '{"selftest":{"ok":false,"lockdown":{"level":"partial","failed":["seccomp"]},"checks":[{"name":"network","denied":false}]}}'
exit 1''');
      final host = CodeSandboxProcess(executable: path);
      final availability = await host.selfTest();
      expect(availability.isAvailable, isFalse);
      expect(availability.toJson()['reason'], contains('seccomp'));
      expect(host.availability, availability);
    },
  );

  test(
    'a control that was not applied is named with what the runner said',
    () async {
      // The Windows runner's `runner_access` control says which command
      // grants the access; the operator has to be able to read it.
      final path = fakes.script(r'''
printf '%s\n' '{"selftest":{"ok":false,"os":"windows","lockdown":{"level":"none","controls":[{"name":"job_object","required":true,"status":"applied"},{"name":"runner_access","required":true,"status":"failed","detail":"run\n\"cc_codemode.exe\" --grant-runner-access\u202e as an administrator"}],"failed":["runner_access"]},"checks":[]}}'
exit 3''');
      final host = CodeSandboxProcess(executable: path);
      final availability = await host.selfTest();
      expect(availability.isAvailable, isFalse);
      final reason = availability.toJson()['reason'] as String;
      expect(
        reason,
        contains(
          'controls not applied: runner_access (run "cc_codemode.exe" '
          '--grant-runner-access',
        ),
      );
      // One line, and no bidirectional override from the runner's text.
      expect(reason, isNot(contains('\n')));
      expect(reason, isNot(contains('\u202e')));
      expect(reason, isNot(contains('job_object')));
    },
  );

  test(
    'self-test of a fake whose test sessions die is unavailable and says how',
    () async {
      final path = fakes.script(r'''
printf '%s\n' '{"selftest":{"ok":false,"os":"linux","lockdown":{"level":"full","failed":[]},"checks":[{"name":"file_read","denied":true},{"name":"process","denied":true}],"session":{"passed":false,"runs":3,"detail":"run 3 of 8: stdout closed before done: killed by signal 31 (SIGSYS: a system call outside the seccomp allowlist)"}}}'
exit 1''');
      final host = CodeSandboxProcess(executable: path);
      final availability = await host.selfTest();
      expect(availability.isAvailable, isFalse);
      final reason = availability.toJson()['reason'] as String;
      expect(reason, startsWith('The code mode runner cannot run scripts'));
      expect(
        reason,
        contains(
          'a test script could not run under the lockdown: run 3 of 8: '
          'stdout closed before done: killed by signal 31',
        ),
      );
      expect(reason, isNot(contains('lockdown level')));
    },
  );

  test('self-test without a session result is unavailable', () async {
    final path = fakes.script(r'''
printf '%s\n' '{"selftest":{"ok":true,"os":"linux","lockdown":{"level":"full","failed":[]},"checks":[{"name":"file_read","denied":true}]}}'
exit 0''');
    final host = CodeSandboxProcess(executable: path);
    final availability = await host.selfTest();
    expect(availability.isAvailable, isFalse);
    expect(
      availability.toJson()['reason'],
      contains('no session result was reported'),
    );
  });
}
