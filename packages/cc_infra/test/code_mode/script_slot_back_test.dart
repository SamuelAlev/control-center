// The half-clock rule on the way back from a person, against the real runner
// (CC_CODEMODE_RUNNER): a script that gave its slot up while a person
// decided gets it back within half the time its clock had left at the
// answer, or it ends `server_busy`, which the run counts, so it calls its
// tools directly. Its record ends like any script that ends early.
import 'dart:async';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/tools.dart';
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
    name: 'bash',
    namespace: ScriptToolNamespace.builtin,
    description: 'Run a command.',
    inputSchema: const {'type': 'object'},
    tier: ToolApprovalTier.exec,
    effects: const {ActionClass.processSpawn},
  ),
];

void main() {
  late CodeSandboxProcess process;
  late MemoryExecutions records;
  late CodeExecutionService service;
  late FakeEmbeddings embeddings;

  // `bash` waits for an approval; `read` holds its run's slot until the
  // test lets it go.
  late Completer<void> approval;
  late Completer<void> approvalAsked;
  late Map<String, Completer<void>> busy;
  // What reached a tool, by its `cmd`.
  late List<Object?> invoked;

  setUp(() async {
    process = CodeSandboxProcess(executable: realRunnerPath());
    expect((await process.selfTest()).isAvailable, isTrue);
    records = MemoryExecutions();
    embeddings = FakeEmbeddings();
    service = CodeExecutionService(
      embeddings: embeddings,
      sandbox: process,
      executions: records,
      store: MemoryStore(),
      serverProcessCap: 1,
    );
    approval = Completer<void>();
    approvalAsked = Completer<void>();
    busy = {};
    invoked = [];
  });

  tearDown(() async {
    for (final c in busy.values) {
      if (!c.isCompleted) {
        c.complete();
      }
    }
    await service.dispose();
    expect(process.liveProcessCount, 0);
  });

  Future<NestedCallOutcome> gate(NestedCallRequest r) async {
    if (r.name == 'bash' && (r.arguments as Map)['cmd'] != 'push') {
      invoked.add((r.arguments as Map)['cmd']);
      return NestedCallOutcome(status: NestedCallStatus.completed, value: 2);
    }
    if (r.name == 'bash') {
      r.onPersonWait!(true);
      approvalAsked.complete();
      await approval.future;
      r.onPersonWait!(false);
      return NestedCallOutcome(
        status: NestedCallStatus.completed,
        value: 'pushed',
        gateDecision: NestedCallGateDecision.approved,
      );
    }
    final run = r.origin.executionId!.split('/').first;
    await busy.putIfAbsent(run, Completer.new).future;
    return NestedCallOutcome(status: NestedCallStatus.completed, value: 1);
  }

  void release(String run) {
    final c = busy.putIfAbsent(run, Completer.new);
    if (!c.isCompleted) {
      c.complete();
    }
  }

  Future<CodeExecutionResult> execute(
    String ws,
    String run,
    String code, {
    int clockMs = 3000,
    CancellationToken cancel = CancellationToken.none,
  }) => service.execute(
    CodeExecutionRequest(
      readOnly: false,
      past: null,
      workspaceId: ws,
      runId: run,
      parentToolCallId: 'call_1',
      surface: CodeExecutionSurface.harness,
      code: code,
      description: 'slot back',
      limits: CodeModeLimits(wallClockMs: clockMs),
      tools: _tools,
    ),
    callNested: gate,
    cancel: cancel,
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

  /// A waits on an approval with its slot given up; B, of another
  /// workspace, takes the only slot and holds it.
  Future<(Future<CodeExecutionResult>, Future<CodeExecutionResult>)>
  squatted() async {
    final a = execute(
      'ws-1',
      'A',
      "const r = await tools.bash({cmd: 'push'}); return r;",
    );
    await approvalAsked.future;
    await until(() => service.parkedRunners == 1, 'A to park');
    final b = execute('ws-2', 'B', 'await tools.read({}); return 1;');
    await until(() => service.slotsInUse == 1, 'B to take the slot');
    return (a, b);
  }

  test('a slot that does not come back within half the clock left at the '
      'answer ends the script server_busy, which withdraws scripts; its '
      'record is finished with its call (review L1)', () async {
    final (a, b) = await squatted();
    final answered = Stopwatch()..start();
    approval.complete();
    final ra = await a.timeout(const Duration(seconds: 20));
    expect(ra.execution.status, CodeExecutionStatus.timedOut);
    expect(ra.execution.errorKind, CodeExecutionErrorKind.serverBusy);
    expect(
      CodeExecutionErrorKind.withdrawsScripts,
      contains(ra.execution.errorKind),
    );
    expect(ra.result.text, contains('after a person answered'));
    expect(ra.result.text, contains('Script timed out'));
    expect(
      answered.elapsed,
      lessThan(const Duration(milliseconds: 2500)),
      reason: 'at half the clock left, not at its end',
    );
    // Finished once, its call as it was: nothing rolled back.
    final row = records.rows[ra.execution.id]!;
    expect(row.execution.status, CodeExecutionStatus.timedOut);
    expect(row.execution.errorKind, CodeExecutionErrorKind.serverBusy);
    expect(row.calls.single.toolName, 'bash');
    expect(row.calls.single.status, NestedCallStatus.completed);
    expect(records.finishes.where((id) => id == ra.execution.id), hasLength(1));
    // Its parked place is given back; B keeps its slot.
    expect(service.parkedRunners, 0);
    expect(service.slotsInUse, 1);
    release('B');
    expect((await b).execution.status, CodeExecutionStatus.completed);
    expect(service.slotsInUse, 0);
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('a slot that comes back in time changes nothing', () async {
    final (a, b) = await squatted();
    approval.complete();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    release('B');
    final ra = await a.timeout(const Duration(seconds: 20));
    expect(ra.execution.status, CodeExecutionStatus.completed);
    expect(ra.result.text, contains('pushed'));
    expect((await b).execution.status, CodeExecutionStatus.completed);
    expect(service.slotsInUse, 0);
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('a slot granted about when the script is stopped is given back, '
      'whichever comes first', () async {
    // A's clock has about 2.9 s left at the answer, so its bound is about
    // 1.45 s: B lets the slot go around then.
    for (final ms in [1350, 1450, 1550]) {
      approval = Completer<void>();
      approvalAsked = Completer<void>();
      busy.clear();
      final (a, b) = await squatted();
      approval.complete();
      await Future<void>.delayed(Duration(milliseconds: ms));
      release('B');
      final ra = await a.timeout(const Duration(seconds: 20));
      expect(
        ra.execution.status,
        anyOf(CodeExecutionStatus.completed, CodeExecutionStatus.timedOut),
        reason: '$ms ms: ${ra.result.text}',
      );
      expect((await b).execution.status, CodeExecutionStatus.completed);
      await until(() => service.slotsInUse == 0, 'every slot back ($ms ms)');
      expect(service.parkedRunners, 0, reason: '$ms ms');
      expect(service.activeRuns, 0, reason: '$ms ms');
    }
    // The slot is free: a new script runs at once.
    release('C');
    final rc = await execute('ws-3', 'C', 'return 3;');
    expect(rc.execution.status, CodeExecutionStatus.completed);
  }, timeout: const Timeout(Duration(minutes: 2)));

  /// A waits on an approval with its slot given up; the test holds the
  /// only slot itself, to give it back when it chooses.
  Future<Future<CodeExecutionResult>> held({
    String code = "const r = await tools.bash({cmd: 'push'}); return r;",
    int clockMs = 3000,
    CancellationToken cancel = CancellationToken.none,
  }) async {
    final a = execute('ws-1', 'A', code, clockMs: clockMs, cancel: cancel);
    await approvalAsked.future;
    await until(() => service.parkedRunners == 1, 'A to park');
    expect(await service.slots.acquire('ws-squat', tree: 'squat'), isTrue);
    return a;
  }

  group('the half-clock rule\'s exceptions (review lows)', () {
    test('a cancel already under way when the bound runs out ends the '
        'script cancelled, not server_busy', () async {
      final source = CancellationTokenSource();
      final a = await held(cancel: source.token);
      service.slotBackDue = source.cancel;
      approval.complete();
      final ra = await a.timeout(const Duration(seconds: 20));
      expect(ra.execution.status, CodeExecutionStatus.cancelled);
      expect(ra.execution.errorKind, isNot(CodeExecutionErrorKind.serverBusy));
      expect(
        CodeExecutionErrorKind.withdrawsScripts,
        isNot(contains(ra.execution.errorKind)),
      );
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('a cancel that comes after the stop leaves it server_busy', () async {
      final source = CancellationTokenSource();
      final a = await held(cancel: source.token);
      service.slotBackDue = () => scheduleMicrotask(source.cancel);
      approval.complete();
      final ra = await a.timeout(const Duration(seconds: 20));
      expect(ra.execution.errorKind, CodeExecutionErrorKind.serverBusy);
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('a shutdown already under way when the bound runs out does not '
        'end the script server_busy', () async {
      final a = await held();
      service.slotBackDue = () => unawaited(service.dispose());
      approval.complete();
      final ra = await a.timeout(const Duration(seconds: 20));
      expect(
        ra.execution.errorKind,
        isNot(CodeExecutionErrorKind.serverBusy),
        reason: ra.result.text,
      );
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('less than twice the floor left at the answer sets no bound: the '
        'script ends at its own deadline, which withdraws nothing', () async {
      // At the edge: a millisecond under twice the floor.
      final a = await held(clockMs: 2 * CodeModeLimits.wallClock.floor - 1);
      final answered = Stopwatch()..start();
      approval.complete();
      final ra = await a.timeout(const Duration(seconds: 20));
      expect(ra.execution.status, CodeExecutionStatus.timedOut);
      expect(
        ra.execution.errorKind,
        isNot(CodeExecutionErrorKind.serverBusy),
        reason: ra.result.text,
      );
      expect(
        CodeExecutionErrorKind.withdrawsScripts,
        isNot(contains(ra.execution.errorKind)),
      );
      expect(
        answered.elapsed,
        greaterThan(const Duration(milliseconds: 1200)),
        reason: 'at its deadline, not at half of what it had left',
      );
    }, timeout: const Timeout(Duration(minutes: 1)));
  });

  test('a slot granted between the stop and the end starts no queued call: '
      'its row ends cancelled and its tool is never invoked', () async {
    final a = await held(
      code:
          "const p1 = tools.bash({cmd: 'push'}); "
          "const p2 = tools.bash({cmd: 'second'}); "
          'return [await p1, await p2];',
    );
    // The grant lands right after the stop, before the runner is gone.
    service.slotBackDue = () => service.slots.release('ws-squat', 'squat');
    approval.complete();
    final ra = await a.timeout(const Duration(seconds: 20));
    expect(ra.execution.errorKind, CodeExecutionErrorKind.serverBusy);
    expect(invoked, isEmpty);
    final calls = records.rows[ra.execution.id]!.calls;
    expect(calls, hasLength(2));
    expect(calls.last.status, NestedCallStatus.cancelled);
    expect(calls.last.error, 'The script ended before the call started.');
    await until(() => service.slotsInUse == 0, 'every slot back');
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('a slot granted between the stop and the end starts no models.* '
      'batch', () async {
    final a = await held(
      code:
          "const q = tools.bash({cmd: 'push'}); "
          "const v = models.embed(['a']); "
          'await q; return await v;',
    );
    service.slotBackDue = () => service.slots.release('ws-squat', 'squat');
    approval.complete();
    final ra = await a.timeout(const Duration(seconds: 20));
    expect(ra.execution.errorKind, CodeExecutionErrorKind.serverBusy);
    expect(embeddings.calls, 0);
    await until(() => service.slotsInUse == 0, 'every slot back');
  }, timeout: const Timeout(Duration(minutes: 1)));
}
