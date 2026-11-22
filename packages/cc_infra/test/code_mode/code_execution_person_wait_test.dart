// A script that waits on a person starts nothing new, against the real
// runner: while any of its nested calls waits on a person, the calls it
// sends meanwhile are held in order and start only once no wait is open and
// it holds a runner slot again. Calls already running go on.
import 'dart:async';
import 'dart:math' as math;

import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

final _tools = [
  ScriptToolDescriptor(
    name: 'read',
    namespace: ScriptToolNamespace.builtin,
    description: 'Read.',
    inputSchema: const {'type': 'object'},
  ),
  ScriptToolDescriptor(
    name: 'ask_user',
    namespace: ScriptToolNamespace.builtin,
    description: 'Ask.',
    inputSchema: const {'type': 'object'},
  ),
];

const _notStarted = 'The script ended before the call started.';

void main() {
  // Each service disposes its sandbox, so each test has its own.
  late CodeSandboxProcess process;
  late MemoryExecutions executions;

  setUp(() async {
    process = CodeSandboxProcess(executable: realRunnerPath());
    expect((await process.selfTest()).isAvailable, isTrue);
    executions = MemoryExecutions();
  });

  CodeExecutionService build({int cap = 4, FakeEmbeddings? embeddings}) {
    final service = CodeExecutionService(
      sandbox: process,
      executions: executions,
      store: MemoryStore(),
      embeddings: embeddings,
      serverProcessCap: cap,
    );
    addTearDown(service.dispose);
    return service;
  }

  CodeExecutionRequest req(
    String ws,
    String run,
    String code, {
    CodeModeLimits? limits,
  }) => CodeExecutionRequest(
    readOnly: false,
    past: null,
    workspaceId: ws,
    runId: run,
    parentToolCallId: 'call_1',
    surface: CodeExecutionSurface.harness,
    code: code,
    description: 'person wait',
    limits: limits ?? CodeModeLimits(),
    tools: _tools,
  );

  Future<void> until(bool Function() condition, String what) async {
    final clock = Stopwatch()..start();
    while (!condition()) {
      if (clock.elapsed > const Duration(seconds: 20)) {
        fail('timed out waiting for $what');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 400));

  List<CodeExecutionCall> rowsOf(CodeExecutionResult r) =>
      executions.rows[r.execution.id]!.calls;

  NestedCallOutcome ok(Object? value) =>
      NestedCallOutcome(status: NestedCallStatus.completed, value: value);

  test('calls a parked script sends do not run until its card is answered '
      'and it holds a slot again', () async {
    final service = build(cap: 1);
    final card = Completer<void>();
    final releaseB = Completer<void>();
    final seen = <String>[];
    Future<NestedCallOutcome> gate(NestedCallRequest r) async {
      final k = r.arguments['k'] as String;
      if (k == 'card') {
        r.onPersonWait!(true);
        await card.future;
        r.onPersonWait!(false);
      } else if (k == 'b') {
        await releaseB.future;
      } else {
        seen.add(k);
      }
      return ok(k);
    }

    final a = service.execute(
      req('ws-1', 'A', '''
const pending = tools.read({k: 'card'});
const side = [];
for (let i = 0; i < 5; i++) side.push(tools.read({k: 'side-' + i}));
await pending;
return (await Promise.all(side)).length;
'''),
      callNested: gate,
    );
    await until(() => service.parkedRunners == 1, 'A to park');
    final b = service.execute(
      req('ws-2', 'B', "await tools.read({k: 'b'}); return 1;"),
      callNested: gate,
    );
    await until(() => service.slotsInUse == 1, 'B to take the slot');
    await settle();
    expect(seen, isEmpty, reason: 'calls ran while the script was parked');

    card.complete();
    await settle();
    expect(seen, isEmpty, reason: 'calls ran before the slot was back');

    releaseB.complete();
    final ra = await a.timeout(const Duration(seconds: 30));
    expect((await b).execution.status, CodeExecutionStatus.completed);
    expect(ra.execution.status, CodeExecutionStatus.completed);
    expect(seen, ['side-0', 'side-1', 'side-2', 'side-3', 'side-4']);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('a call sent after the answer, before the slot is back, waits for '
      'the slot: a parked script starts no tool without one', () async {
    final service = build(cap: 1);
    final answer = Completer<void>();
    final releaseB = Completer<void>();
    final seen = <String>[];
    Future<NestedCallOutcome> gate(NestedCallRequest r) async {
      final k = r.arguments['k'] as String;
      if (k == 'card') {
        r.onPersonWait!(true);
        await answer.future;
        r.onPersonWait!(false);
      } else if (k == 'b') {
        await releaseB.future;
      } else {
        seen.add(k);
      }
      return ok(k);
    }

    // The read leaves the runner well after the answer: the wait is closed
    // by then, and only the missing slot holds it.
    final a = service.execute(
      req('ws-1', 'A', '''
tools.read({k: 'card'}).catch(() => {});
await sleep(1500);
return await tools.read({k: 'late'});
'''),
      callNested: gate,
    );
    await until(() => service.parkedRunners == 1, 'A to park');
    final b = service.execute(
      req('ws-2', 'B', "await tools.read({k: 'b'}); return 1;"),
      callNested: gate,
    );
    await until(() => service.slotsInUse == 1, 'B to take the slot');
    answer.complete();
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    expect(seen, isEmpty, reason: 'a call started without a slot');

    releaseB.complete();
    final ra = await a.timeout(const Duration(seconds: 30));
    expect((await b).execution.status, CodeExecutionStatus.completed);
    expect(ra.execution.status, CodeExecutionStatus.completed);
    expect(seen, ['late']);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('a wait a gate leaves open when its call returns is closed then, and '
      'the next call starts', () async {
    final service = build();
    var reads = 0;
    final res = await service
        .execute(
          req(
            'ws-1',
            'R',
            "await tools.ask_user({question: 'x'}); "
                'return await tools.read({});',
          ),
          callNested: (r) async {
            if (r.name == 'ask_user') {
              // Opens a wait and never says it ended.
              r.onPersonWait!(true);
              return ok('yes');
            }
            reads++;
            return ok(1);
          },
        )
        .timeout(const Duration(seconds: 20));
    expect(res.execution.status, CodeExecutionStatus.completed);
    expect(reads, 1);
  }, timeout: const Timeout(Duration(minutes: 1)));

  test(
    'reads sent while an unanswered question holds the clock do not run, '
    'and after the answer the script ends timed_out at its own time',
    () async {
      final service = build(cap: 1);
      // Three scripts of ws-1 park on questions nobody answers: the
      // workspace's parked share (3 at cap 1) is full, so the script below
      // keeps its slot while its own question is open.
      final parkedAnswer = Completer<void>();
      final fillers = [
        for (var i = 0; i < 3; i++)
          service.execute(
            req('ws-1', 'P$i', "return await tools.ask_user({question: 'x'});"),
            callNested: (r) async {
              r.onPersonWait!(true);
              await parkedAnswer.future;
              r.onPersonWait!(false);
              return ok('ok');
            },
          ),
      ];
      await until(() => service.parkedRunnersOf('ws-1') == 3, 'fillers');

      var reads = 0;
      var readsDuringWait = 0;
      var waiting = false;
      Timer? answerAfter;
      final answer = Completer<void>();
      final clock = Stopwatch();
      Future<NestedCallOutcome> gate(NestedCallRequest r) async {
        if (r.name == 'ask_user') {
          r.onPersonWait!(true);
          waiting = true;
          answerAfter = Timer(const Duration(seconds: 3), () {
            waiting = false;
            answer.complete();
          });
          await answer.future;
          r.onPersonWait!(false);
          return ok('yes');
        }
        reads++;
        if (waiting) {
          readsDuringWait++;
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
        return ok(1);
      }

      clock.start();
      final res = await service
          .execute(
            req(
              'ws-1',
              'R',
              "const q = tools.ask_user({question: 'anyone?'}); let n = 0; "
                  'for (let i = 0; i < 48; i++) { await tools.read({i}); n++; } '
                  'await q; return n;',
              limits: CodeModeLimits(wallClockMs: 2000),
            ),
            callNested: gate,
          )
          .timeout(const Duration(seconds: 60));
      final elapsed = clock.elapsedMilliseconds;
      answerAfter?.cancel();
      parkedAnswer.complete();
      await Future.wait(fillers);

      expect(readsDuringWait, 0, reason: 'reads ran during the person wait');
      expect(res.execution.status, CodeExecutionStatus.timedOut);
      expect(reads, inInclusiveRange(1, 8));
      expect(elapsed, inInclusiveRange(4500, 9000));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('two calls waiting at once, answered in reverse order: a call sent '
      'meanwhile starts only after both answers', () async {
    final service = build();
    final answers = {'w1': Completer<void>(), 'w2': Completer<void>()};
    final opened = <String>{};
    final seen = <String>[];
    Future<NestedCallOutcome> gate(NestedCallRequest r) async {
      final k = r.arguments['k'] as String;
      seen.add(k);
      final answer = answers[k];
      if (answer != null) {
        // Both calls start before either wait opens.
        await Future<void>.delayed(const Duration(milliseconds: 150));
        r.onPersonWait!(true);
        opened.add(k);
        await answer.future;
        r.onPersonWait!(false);
      }
      return ok(k);
    }

    final run = service.execute(
      req('ws-1', 'run-1', '''
const a = tools.read({k: 'w1'});
const b = tools.read({k: 'w2'});
const t0 = Date.now();
while (Date.now() - t0 < 600) {}
const c = tools.read({k: 'after'});
return await Promise.all([a, b, c]);
'''),
      callNested: gate,
    );
    await until(() => opened.length == 2, 'both waits');
    await settle();
    await settle();
    expect(seen, ['w1', 'w2']);

    answers['w2']!.complete();
    await settle();
    expect(seen, ['w1', 'w2'], reason: 'started while w1 was still open');

    answers['w1']!.complete();
    final r = await run.timeout(const Duration(seconds: 30));
    expect(r.execution.status, CodeExecutionStatus.completed);
    expect(seen, ['w1', 'w2', 'after']);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('held calls count against the call limit when they arrive and '
      'against the in-flight cap when they start', () async {
    final service = build();
    final answer = Completer<void>();
    var inFlight = 0;
    var maxInFlight = 0;
    var started = 0;
    var startedDuringWait = 0;
    Future<NestedCallOutcome> gate(NestedCallRequest r) async {
      if (r.name == 'ask_user') {
        r.onPersonWait!(true);
        await answer.future;
        r.onPersonWait!(false);
        return ok('yes');
      }
      started++;
      if (!answer.isCompleted) {
        startedDuringWait++;
      }
      inFlight++;
      maxInFlight = math.max(maxInFlight, inFlight);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      inFlight--;
      return ok(1);
    }

    final run = service.execute(
      req(
        'ws-1',
        'run-1',
        "const q = tools.ask_user({question: 'go?'}); const reads = []; "
            'for (let i = 0; i < 6; i++) reads.push(tools.read({i})); '
            'const settled = await Promise.allSettled(reads); await q; '
            "return settled.map(s => s.status === 'fulfilled' ? 'ok' : "
            's.reason.status);',
        limits: CodeModeLimits(maxNestedCalls: 5, maxInFlightCalls: 2),
      ),
      callNested: gate,
    );
    await settle();
    await settle();
    expect(started, 0);
    answer.complete();
    final r = await run.timeout(const Duration(seconds: 30));
    expect(r.execution.status, CodeExecutionStatus.completed);
    expect(startedDuringWait, 0);
    expect(started, 4);
    expect(maxInFlight, 2);
    expect(r.result.text, contains('limit_exceeded'));
    expect(rowsOf(r), hasLength(5));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('an answer in the same turn as the end starts no held call; the held '
      'call is a row that says it never started', () async {
    final service = build();
    final seen = <String>[];
    Future<NestedCallOutcome> gate(NestedCallRequest r) async {
      if (r.name == 'ask_user') {
        r.onPersonWait!(true);
        await r.cancel.whenCancelled;
        // The answer lands as the script ends.
        r.onPersonWait!(false);
        return NestedCallOutcome(
          status: NestedCallStatus.cancelled,
          errorMessage: 'The script ended.',
        );
      }
      seen.add(r.arguments['k'] as String);
      return ok(1);
    }

    final r = await service
        .execute(
          req(
            'ws-1',
            'run-1',
            "tools.ask_user({question: 'x'}); tools.read({k: 'held'}); "
                'const t0 = Date.now(); while (Date.now() - t0 < 300) {} '
                'return 1;',
          ),
          callNested: gate,
        )
        .timeout(const Duration(seconds: 30));
    await settle();
    expect(r.execution.status, CodeExecutionStatus.completed);
    expect(seen, isEmpty);
    final held = rowsOf(r).singleWhere((c) => c.sequence == 2);
    expect(held.status, NestedCallStatus.cancelled);
    expect(held.error, _notStarted);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('a runner that computes while it waits on a person is ended by its '
      'CPU budget; the call it sent meanwhile never starts', () async {
    final service = build();
    final seen = <String>[];
    Future<NestedCallOutcome> gate(NestedCallRequest r) async {
      if (r.name == 'ask_user') {
        r.onPersonWait!(true);
        await r.cancel.whenCancelled;
        r.onPersonWait!(false);
        return NestedCallOutcome(
          status: NestedCallStatus.cancelled,
          errorMessage: 'The script ended.',
        );
      }
      seen.add(r.arguments['k'] as String);
      return ok(1);
    }

    final r = await service
        .execute(
          req(
            'ws-1',
            'run-1',
            "tools.ask_user({question: 'x'}); tools.read({k: 'held'}); "
                'while (true) {}',
            limits: CodeModeLimits(cpuMs: 1000),
          ),
          callNested: gate,
        )
        .timeout(const Duration(seconds: 60));
    expect(r.execution.status, isNot(CodeExecutionStatus.completed));
    expect(seen, isEmpty);
    final held = rowsOf(r).singleWhere((c) => c.sequence == 2);
    expect(held.status, NestedCallStatus.cancelled);
    expect(held.error, _notStarted);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('a script cancelled while a call is held ends cancelled, and the held '
      'call never starts', () async {
    final service = build();
    final seen = <String>[];
    final opened = Completer<void>();
    Future<NestedCallOutcome> gate(NestedCallRequest r) async {
      if (r.name == 'ask_user') {
        r.onPersonWait!(true);
        opened.complete();
        await r.cancel.whenCancelled;
        r.onPersonWait!(false);
        return NestedCallOutcome(
          status: NestedCallStatus.cancelled,
          errorMessage: 'The script ended.',
        );
      }
      seen.add(r.arguments['k'] as String);
      return ok(1);
    }

    final cancel = CancellationTokenSource();
    final run = service.execute(
      req(
        'ws-1',
        'run-1',
        "const q = tools.ask_user({question: 'x'}); "
            "await tools.read({k: 'held'}); return await q;",
      ),
      callNested: gate,
      cancel: cancel.token,
    );
    await opened.future;
    await settle();
    cancel.cancel();
    final r = await run.timeout(const Duration(seconds: 30));
    expect(r.execution.status, CodeExecutionStatus.cancelled);
    expect(seen, isEmpty);
    final held = rowsOf(r).singleWhere((c) => c.sequence == 2);
    expect(held.status, NestedCallStatus.cancelled);
    expect(held.error, _notStarted);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('models.* waits like a tool call while a person decides', () async {
    final embeddings = FakeEmbeddings();
    final service = build(embeddings: embeddings);
    final answer = Completer<void>();
    var callsAtAnswer = -1;
    Future<NestedCallOutcome> gate(NestedCallRequest r) async {
      r.onPersonWait!(true);
      await answer.future;
      r.onPersonWait!(false);
      return ok('yes');
    }

    final run = service.execute(
      req(
        'ws-1',
        'run-1',
        "const q = tools.ask_user({question: 'x'}); "
            "const v = await models.embed(['a']); await q; return v.length;",
      ),
      callNested: gate,
    );
    await settle();
    await settle();
    callsAtAnswer = embeddings.calls;
    answer.complete();
    final r = await run.timeout(const Duration(seconds: 30));
    expect(r.execution.status, CodeExecutionStatus.completed);
    expect(callsAtAnswer, 0);
    expect(embeddings.calls, 1);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
