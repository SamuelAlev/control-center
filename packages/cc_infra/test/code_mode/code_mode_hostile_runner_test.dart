// What a hostile or broken runner can make the host do, against the real
// CodeSandboxProcess and CodeExecutionService. Fake runners are /bin/sh
// scripts that cat pre-generated frames; the tests that need a real script
// use the real runner (CC_CODEMODE_RUNNER).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart' show TokenEstimator;
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:cc_infra/src/code_mode/runner_frames.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

/// Reports the runner available without a self-test, so the service admits
/// scripts to a fake runner.
class AvailableSandbox implements CodeSandboxPort {
  AvailableSandbox(this.inner);

  final CodeSandboxPort inner;

  @override
  CodeRunnerAvailability get availability =>
      const CodeRunnerAvailability.available();

  @override
  Future<CodeRunnerAvailability> selfTest() async => availability;

  @override
  Future<CodeSandboxSession> start(
    CodeSandboxStart request, {
    CancellationToken cancel = CancellationToken.none,
  }) => inner.start(request, cancel: cancel);

  @override
  Future<void> dispose() => inner.dispose();
}

/// A session whose runner never reports an outcome, even when killed.
class _SilentSession implements CodeSandboxSession {
  int terminations = 0;
  // Never closed: this runner never ends its events.
  // ignore: close_sinks
  final _events = StreamController<CodeSandboxEvent>();
  final _outcome = Completer<CodeSandboxOutcome>();

  @override
  CodeRunnerHandshake get handshake => const CodeRunnerHandshake(
    protocol: 1,
    engine: 'fake 1',
    lockdown: CodeRunnerLockdown(level: CodeRunnerLockdown.fullLevel),
  );

  @override
  Stream<CodeSandboxEvent> get events => _events.stream;

  @override
  void reply(CodeSandboxReply reply) {}

  @override
  CodeSandboxDeadlineHold holdDeadline() => throw UnimplementedError();

  @override
  void cancel() {}

  @override
  void terminate() => terminations++;

  @override
  bool get ended => false;

  @override
  Future<CodeSandboxOutcome> get outcome => _outcome.future;
}

class _SilentSandbox implements CodeSandboxPort {
  final session = _SilentSession();

  @override
  CodeRunnerAvailability get availability =>
      const CodeRunnerAvailability.available();

  @override
  Future<CodeRunnerAvailability> selfTest() async => availability;

  @override
  Future<CodeSandboxSession> start(
    CodeSandboxStart request, {
    CancellationToken cancel = CancellationToken.none,
  }) async => session;

  @override
  Future<void> dispose() async {}
}

final _tools = [
  ScriptToolDescriptor(
    name: 'read',
    namespace: ScriptToolNamespace.builtin,
    description: 'Read a file.',
    inputSchema: const {'type': 'object'},
  ),
  ScriptToolDescriptor(
    name: 'ask_user',
    namespace: ScriptToolNamespace.controlCenter,
    description: 'Ask the person a question.',
    inputSchema: const {'type': 'object'},
  ),
];

const _doneOk =
    '{"type":"done","ok":true,"stats":{"cpu_ms":1,"peak_heap_bytes":1,'
    '"calls":0,"output_chars":0,"output_items":0}}';

void main() {
  late Directory tmp;
  late FakeRunners fakes;
  late MemoryExecutions executions;
  late MemoryStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('codemode-hostile-');
    fakes = FakeRunners(tmp);
    executions = MemoryExecutions();
    store = MemoryStore();
  });

  tearDown(() async => tmp.delete(recursive: true));

  String frameFile(String name, String content) {
    final file = File(p.join(tmp.path, name))..writeAsStringSync(content);
    return file.path;
  }

  /// A fake runner that has read init and exec, then runs [body].
  String afterExec(String body) => fakes.script('''
printf '%s\\n' '$fakeReadyFull'
read -r init
read -r exec
$body''');

  CodeExecutionService serviceOver(
    CodeSandboxPort sandbox, {
    int cap = 1,
    Duration outcomeGrace = const Duration(seconds: 15),
  }) => CodeExecutionService(
    sandbox: sandbox,
    executions: executions,
    store: store,
    serverProcessCap: cap,
    outcomeGrace: outcomeGrace,
  );

  CodeExecutionRequest request({
    String code = 'return 1',
    String workspaceId = 'ws-1',
    String runId = 'run-1',
    String description = 'x',
    CodeModeLimits? limits,
    CodeExecutionSurface surface = CodeExecutionSurface.harness,
  }) => CodeExecutionRequest(
    readOnly: false,
    past: null,
    workspaceId: workspaceId,
    runId: runId,
    parentToolCallId: 'call_1',
    surface: surface,
    code: code,
    description: description,
    limits: limits ?? CodeModeLimits(wallClockMs: 20000),
    tools: _tools,
    conversationId: 'conv-1',
    agentId: 'agent-1',
  );

  Future<NestedCallOutcome> noCalls(NestedCallRequest r) async =>
      NestedCallOutcome(status: NestedCallStatus.failed, errorMessage: 'no');

  test('H1: a done frame nested past any depth the runner can write ends '
      'the script as a protocol violation; slot, run, process and dispose '
      'all come back', () async {
    const depth = 200000;
    final done =
        '{"type":"done","ok":true,"value":${'[' * depth}${']' * depth},'
        '"stats":{"cpu_ms":1,"peak_heap_bytes":1,"calls":0,'
        '"output_chars":0}}\n';
    final file = frameFile('done', done);
    // Like the real runner: exit 0 once the host closes stdin.
    final path = afterExec('/bin/cat $file\nread -r x\nexit 0');
    final process = CodeSandboxProcess(executable: path);
    final service = serviceOver(AvailableSandbox(process));
    final uncaught = <Object>[];
    final result = await runZonedGuarded(
      () => service
          .execute(request(), callNested: noCalls)
          .timeout(const Duration(seconds: 10)),
      (e, st) => uncaught.add(e),
    )!;
    expect(uncaught, isEmpty);
    expect(result.execution.status, CodeExecutionStatus.sandboxError);
    expect(result.execution.errorKind, 'protocol');
    expect(service.slotsInUse, 0);
    expect(service.activeRuns, 0);
    expect(process.liveProcessCount, 0);
    // The run is free for its next script.
    final next = await service.execute(
      request(limits: CodeModeLimits(wallClockMs: 1000)),
      callNested: noCalls,
    );
    expect(next.execution.errorKind, isNot('run_busy'));
    await service.dispose().timeout(const Duration(seconds: 5));
  }, timeout: const Timeout(Duration(seconds: 60)));

  group('H2: store frames are counted by the host', () {
    test('values past the store total end the script as store_overrun, and '
        'nothing is committed', () async {
      final value = 'v' * (250 * 1024);
      final frames = StringBuffer();
      for (var i = 0; i < 8; i++) {
        frames.writeln('{"type":"store","key":"k$i","value":"$value"}');
      }
      final file = frameFile('store', frames.toString());
      final path = afterExec(
        "/bin/cat $file\nprintf '%s\\n' '$_doneOk'\nread -r x",
      );
      final service = serviceOver(
        AvailableSandbox(CodeSandboxProcess(executable: path)),
      );
      final r = await service.execute(request(), callNested: noCalls);
      expect(r.execution.status, CodeExecutionStatus.sandboxError);
      expect(r.execution.errorKind, 'store_overrun');
      expect(store.commits, 0);
      await service.dispose();
    });

    test('more store operations than the runner allows end the script as '
        'store_overrun', () async {
      final frames = StringBuffer();
      for (var i = 0; i <= CodeModeLimits.maxStoreFrames; i++) {
        frames.writeln('{"type":"store","key":"k","value":$i}');
      }
      final file = frameFile('ops', frames.toString());
      final path = afterExec(
        "/bin/cat $file\nprintf '%s\\n' '$_doneOk'\nread -r x",
      );
      final service = serviceOver(
        AvailableSandbox(CodeSandboxProcess(executable: path)),
      );
      final r = await service.execute(request(), callNested: noCalls);
      expect(r.execution.errorKind, 'store_overrun');
      expect(store.commits, 0);
      await service.dispose();
    });

    test('overwrites of one key are held once: a full allowance of 250 KiB '
        'writes commits one value and does not grow the server', () async {
      final value = 'v' * (250 * 1024);
      final frame = '{"type":"store","key":"k","value":"$value"}\n';
      final file = frameFile('same', frame * 100);
      const rounds = CodeModeLimits.maxStoreFrames ~/ 100;
      final path = afterExec('''
i=0
while [ \$i -lt $rounds ]; do /bin/cat $file; i=\$((i+1)); done
printf '%s\\n' '$_doneOk'
read -r x
exit 0''');
      final service = serviceOver(
        AvailableSandbox(CodeSandboxProcess(executable: path)),
      );
      final before = ProcessInfo.currentRss;
      var peak = before;
      final sampler = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (ProcessInfo.currentRss > peak) {
          peak = ProcessInfo.currentRss;
        }
      });
      final r = await service.execute(
        request(limits: CodeModeLimits(wallClockMs: 60000)),
        callNested: noCalls,
      );
      sampler.cancel();
      expect(
        r.execution.status,
        CodeExecutionStatus.completed,
        reason: '${r.execution.errorKind}: ${r.result.text}',
      );
      expect(store.commits, 1);
      expect(store.values['conv-1|agent-1']!.keys, ['k']);
      // 2000 writes of 250 KiB is 500 MiB; held one per key it is 250 KiB.
      expect(peak - before, lessThan(256 * 1024 * 1024));
      await service.dispose();
    }, timeout: const Timeout(Duration(seconds: 120)));
  });

  test('H3: what reaches the model stays inside its budget, notes '
      'included', () async {
    final key = 'k' * 600; // over the 512-byte key cap
    final frame = '{"type":"store","key":"$key","value":1}\n';
    final file = frameFile('bad', frame * 1000);
    final path = afterExec('''
i=0
while [ \$i -lt 20 ]; do /bin/cat $file; i=\$((i+1)); done
printf '%s\\n' '$_doneOk'
read -r x''');
    final service = serviceOver(
      AvailableSandbox(CodeSandboxProcess(executable: path)),
    );
    final r = await service.execute(
      request(limits: CodeModeLimits(maxOutputTokens: 100)),
      callNested: noCalls,
    );
    // The first bad key ends the script; no note per frame is collected.
    expect(r.execution.status, CodeExecutionStatus.sandboxError);
    expect(r.execution.errorKind, 'protocol');
    expect(r.result.text.length, lessThan(2000));
    await service.dispose();
  });

  test('notes that arrive after the output spent its budget stay inside the '
      'budget with it: the output is cut to make room, not the budget '
      'stretched', () async {
    // Text that alone fills the budget many times, then store writes the
    // host lets through (inside its measuring slack) that the rules refuse,
    // each a note.
    final frames = StringBuffer()
      ..writeln(
        jsonEncode({'type': 'output', 'kind': 'text', 'text': 'word ' * 20000}),
      );
    final over = 'v' * (CodeModeLimits.maxStoreValueBytes + 100);
    for (var i = 0; i < 4; i++) {
      frames.writeln(
        jsonEncode({'type': 'store', 'key': 'key-$i', 'value': over}),
      );
    }
    frames.writeln(_doneOk);
    final file = frameFile('late-notes', frames.toString());
    final path = afterExec('/bin/cat $file\nread -r x\nexit 0');
    final service = serviceOver(
      AvailableSandbox(CodeSandboxProcess(executable: path)),
    );
    const budget = 600;
    final r = await service.execute(
      request(limits: CodeModeLimits(maxOutputTokens: budget)),
      callNested: noCalls,
    );
    expect(
      r.execution.status,
      CodeExecutionStatus.completed,
      reason: '${r.execution.errorKind}: ${r.result.text}',
    );
    expect(r.result.text, contains('Not saved: store("key-0")'));
    expect(r.result.truncated, isTrue);
    // The output section and the notes share the budget; only the first
    // line is bounded on its own.
    const tokens = TokenEstimator.instance;
    final text = r.result.text;
    final notes = text.substring(text.indexOf('Note: '));
    expect(tokens.estimate(notes), lessThanOrEqualTo(budget ~/ 2));
    expect(
      tokens.estimate(text),
      lessThanOrEqualTo(budget + tokens.estimate(text.split('\n').first) + 2),
    );
    expect(store.commits, 0, reason: 'nothing valid was stored');
    await service.dispose();
  });

  test('H4: a runner that stops reading stdin ends as stdin_stalled before '
      'the host buffers more than its budget', () async {
    final calls = StringBuffer();
    for (var i = 1; i <= 120; i++) {
      calls.writeln(
        '{"type":"call","id":$i,"target":"tool","name":"read","args":{}}',
      );
    }
    final file = frameFile('calls', calls.toString());
    // Never reads stdin again: replies pile up behind a full pipe.
    final path = afterExec('/bin/cat $file\nexec /bin/sleep 60');
    final process = CodeSandboxProcess(executable: path);
    final service = serviceOver(AvailableSandbox(process));
    final big = 'x' * (3 * 1024 * 1024);
    var answered = 0;
    final r = await service.execute(
      request(
        limits: CodeModeLimits(
          wallClockMs: 30000,
          maxNestedCalls: 200,
          maxInFlightCalls: 8,
        ),
      ),
      callNested: (_) async {
        answered++;
        return NestedCallOutcome(
          status: NestedCallStatus.completed,
          value: big,
          gateDecision: NestedCallGateDecision.allowed,
          resultBytes: big.length,
        );
      },
    );
    expect(
      r.execution.errorKind,
      'stdin_stalled',
      reason: '${r.execution.status.wire}: ${r.result.text}',
    );
    expect(r.execution.status, CodeExecutionStatus.sandboxError);
    // 64 MiB of 3 MiB replies is 21 of them; the calls in flight then
    // finish, and no queued call starts once the runner is killed.
    expect(
      answered,
      lessThanOrEqualTo(
        CodeSandboxProcess.stdinBacklogBudgetBytes ~/ big.length + 1 + 8,
      ),
    );
    expect(process.liveProcessCount, 0);
    await service.dispose();
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('H5: a call frame with deeply nested arguments is a protocol '
      'violation, not an uncaught error', () async {
    const depth = 300000;
    final frame =
        '{"type":"call","id":1,"target":"tool","name":"read","args":{"a":'
        '${'[' * depth}${']' * depth}}}\n';
    final file = frameFile('deepcall', frame);
    final path = afterExec('/bin/cat $file\nexec /bin/sleep 60');
    final process = CodeSandboxProcess(executable: path);
    final uncaught = <Object>[];
    final outcome = await runZonedGuarded(() async {
      final session = await process.start(
        CodeSandboxStart(
          code: 'x',
          limits: CodeModeLimits(wallClockMs: 30000),
          returnBudgetChars: 30400,
          catalog: const [],
        ),
      );
      session.events.listen((_) {});
      return session.outcome.timeout(const Duration(seconds: 10));
    }, (e, st) => uncaught.add(e))!;
    expect(uncaught, isEmpty);
    expect(outcome.status, CodeExecutionStatus.sandboxError);
    expect(outcome.errorKind, 'protocol');
    expect(outcome.detail, contains('nested'));
    expect(process.liveProcessCount, 0);
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('H6: a script cannot choose the stored error kind: a 3 MiB '
      'Error.name is script_error, its name kept capped apart', () async {
    final process = CodeSandboxProcess(executable: realRunnerPath());
    expect((await process.selfTest()).isAvailable, isTrue);
    final service = serviceOver(process);
    final r = await service.execute(
      request(
        code:
            "const e = new Error('x'); e.name = 'N'.repeat(3 * 1024 * 1024); "
            'throw e;',
      ),
      callNested: noCalls,
    );
    final saved = executions.rows.values.single;
    expect(r.execution.status, CodeExecutionStatus.failed);
    expect(saved.execution.errorKind, CodeExecutionErrorKind.scriptError);
    expect(
      saved.payload!.errorName!.length,
      lessThanOrEqualTo(CodeExecutionPayload.maxErrorNameChars),
    );
    expect(jsonEncode(saved.execution.toJson()).length, lessThan(4096));
    await service.dispose();
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('H7: a refused script is not recorded, and a description is one '
      'bounded line', () async {
    final service = serviceOver(
      AvailableSandbox(CodeSandboxProcess(executable: '/nonexistent')),
    );
    final results = await Future.wait([
      for (var i = 0; i < 5; i++)
        service.execute(
          request(
            code: 'x' * (300 * 1024),
            description: 'D\n' * (1024 * 1024),
            surface: CodeExecutionSurface.mcp,
          ),
          callNested: noCalls,
        ),
    ]);
    expect(executions.rows, isEmpty);
    expect(executions.begins, isEmpty);
    expect(results.map((r) => r.execution.errorKind).toSet(), {
      'source_too_large',
      'run_busy',
    });
    for (final r in results) {
      expect(r.execution.status, CodeExecutionStatus.refused);
      expect(
        r.execution.description.length,
        lessThanOrEqualTo(CodeExecution.maxDescriptionChars),
      );
      expect(r.execution.description, isNot(contains('\n')));
    }
    await service.dispose();
  });

  test('a runner that never reports an outcome is terminated past its '
      'deadline and the script ends as unresponsive', () async {
    final silent = _SilentSandbox();
    final service = serviceOver(
      silent,
      outcomeGrace: const Duration(milliseconds: 300),
    );
    final clock = Stopwatch()..start();
    final r = await service
        .execute(
          request(limits: CodeModeLimits(wallClockMs: 1000)),
          callNested: noCalls,
        )
        .timeout(const Duration(seconds: 10));
    expect(r.execution.status, CodeExecutionStatus.sandboxError);
    expect(r.execution.errorKind, CodeExecutionErrorKind.unresponsive);
    expect(silent.session.terminations, 1);
    expect(clock.elapsed, lessThan(const Duration(seconds: 5)));
    expect(service.slotsInUse, 0);
    expect(service.activeRuns, 0);
    expect(
      executions.rows.values.single.execution.status,
      CodeExecutionStatus.sandboxError,
    );
    await service.dispose();
  });

  group('hostile fields', () {
    Future<CodeSandboxOutcome> drive(String body) async {
      final process = CodeSandboxProcess(
        executable: afterExec('$body\nexec /bin/sleep 30'),
      );
      final session = await process.start(
        CodeSandboxStart(
          code: 'x',
          limits: CodeModeLimits(wallClockMs: 10000),
          returnBudgetChars: 30400,
          catalog: const [],
        ),
      );
      session.events.listen((_) {});
      final outcome = await session.outcome;
      expect(process.liveProcessCount, 0);
      return outcome;
    }

    test('a call name over the cap is a protocol violation', () async {
      final name = 'n' * (CodeModeLimits.maxCallNameBytes + 1);
      final outcome = await drive(
        "printf '%s\\n' "
        '\'{"type":"call","id":1,"target":"tool","name":"$name","args":{}}\'',
      );
      expect(outcome.errorKind, 'protocol');
      expect(outcome.detail, contains('${CodeModeLimits.maxCallNameBytes}'));
    });

    for (final (what, mediaType, data) in [
      ('a type no image has', 'text/html', base64Encode([1, 2, 3])),
      ('data that is not base64', 'image/png', 'not base64!'),
      ('bytes that are not the type', 'image/png', base64Encode([1, 2, 3])),
    ]) {
      test('an image with $what is a protocol violation', () async {
        final outcome = await drive(
          "printf '%s\\n' "
          '\'{"type":"output","kind":"image","image":{"type":"image",'
          '"mediaType":"$mediaType","data":"$data"}}\'',
        );
        expect(outcome.status, CodeExecutionStatus.sandboxError);
        expect(outcome.errorKind, 'protocol');
        expect(outcome.detail, contains('image'));
      });
    }

    test('imageProblem accepts each allowed type by its magic bytes', () {
      final png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0];
      final jpeg = [0xFF, 0xD8, 0xFF, 0xE0, 0];
      final gif = ascii.encode('GIF89a..');
      final webp = [
        ...ascii.encode('RIFF'),
        0,
        0,
        0,
        0,
        ...ascii.encode('WEBP'),
      ];
      expect(imageProblem('image/png', base64Encode(png)), isNull);
      expect(imageProblem('image/jpeg', base64Encode(jpeg)), isNull);
      expect(imageProblem('image/gif', base64Encode(gif)), isNull);
      expect(imageProblem('image/webp', base64Encode(webp)), isNull);
      expect(imageProblem('image/png', base64Encode(jpeg)), isNotNull);
      expect(imageProblem('image/svg+xml', base64Encode(png)), isNotNull);
    });

    test('a runner that fails internally (exit 4) says so, and is not '
        'mistaken for a lockdown kill', () async {
      final process = CodeSandboxProcess(
        executable: afterExec(
          "printf 'cc_codemode: internal error: boom\\n' >&2\nexit 4",
        ),
      );
      final session = await process.start(
        CodeSandboxStart(
          code: 'x',
          limits: CodeModeLimits(wallClockMs: 10000),
          returnBudgetChars: 30400,
          catalog: const [],
        ),
      );
      session.events.listen((_) {});
      final outcome = await session.outcome;
      expect(outcome.status, CodeExecutionStatus.sandboxError);
      expect(outcome.errorKind, CodeExecutionErrorKind.internal);
      expect(outcome.detail, contains('failed internally'));
      expect(outcome.detail, contains('internal error: boom'));
    });

    test('a token the runner wrote on stderr, whole or split by a '
        'zero-width character, reaches neither the result nor the record '
        '(smoke 4)', () async {
      const whole = 'ghp_Q7w2E9r4T6y1U3i5O8p0A2s4D6f8G1h3J5k7';
      // The same shape, split after eight characters by U+200B (UTF-8).
      final process = CodeSandboxProcess(
        executable: afterExec(
          "printf 'leaked $whole here\\n' >&2\n"
          r"printf 'split ghp_Z9x8C7v6\342\200\213B5n4M3l2K1j0H9g8F7d6S5a4Q3w2E1 here\n' >&2"
          '\nexit 3',
        ),
      );
      final service = serviceOver(AvailableSandbox(process));
      final r = await service
          .execute(request(), callNested: noCalls)
          .timeout(const Duration(seconds: 20));
      final saved = executions.rows.values.single;
      final texts = [
        r.result.text,
        jsonEncode(saved.execution.toJson()),
        '${saved.payload?.output} ${saved.payload?.console}',
      ];
      expect(r.result.text, contains('Runner said'));
      expect(r.result.text, contains('REDACTED'));
      for (final text in texts) {
        expect(text, isNot(contains('Q7w2E9r4')), reason: text);
        expect(text, isNot(contains('Z9x8C7v6')), reason: text);
        expect(text, isNot(contains('B5n4M3l2')), reason: text);
      }
      await service.dispose();
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('what the runner wrote on stderr reaches a detail as one short '
        'line, with control and direction characters removed', () async {
      final process = CodeSandboxProcess(
        executable: afterExec(r'''
i=0
while [ $i -lt 200 ]; do printf '\033[31mred\342\200\256evil\n' >&2; i=$((i+1)); done
exit 9'''),
      );
      final session = await process.start(
        CodeSandboxStart(
          code: 'x',
          limits: CodeModeLimits(wallClockMs: 10000),
          returnBudgetChars: 30400,
          catalog: const [],
        ),
      );
      session.events.listen((_) {});
      final outcome = await session.outcome;
      expect(outcome.errorKind, 'exited');
      final said = outcome.detail!.split('Runner said: ').last;
      expect(
        said.length,
        lessThanOrEqualTo(CodeSandboxProcess.stderrTailChars),
      );
      expect(said, isNot(contains('\n')));
      expect(said, isNot(contains('\x1b')));
      expect(said, isNot(contains('\u202e')));
      expect(said, contains('red'));
    });
  });
}
