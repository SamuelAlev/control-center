// Runner slots across person waits, against the real runner: a script that
// waits on a person more than once while the server is full gives back
// exactly what it took, and never waits for a slot it already holds.
import 'dart:async';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
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
  // Each service disposes its sandbox, so each test has its own.
  late CodeSandboxProcess process;

  setUp(() async {
    process = CodeSandboxProcess(executable: realRunnerPath());
    expect((await process.selfTest()).isAvailable, isTrue);
  });

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
    description: 'slots',
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

  /// A gate whose `bash` call waits on a person twice in a row (a guard card
  /// then a second card, as two gated pushes in one command do), and whose
  /// `read` calls wait until their run is released.
  ({
    ScriptNestedCall gate,
    Completer<void> started,
    List<Completer<void>> cards,
    void Function(String run) release,
  })
  twoCardGate() {
    final cards = [Completer<void>(), Completer<void>()];
    final started = Completer<void>();
    final busy = <String, Completer<void>>{};
    Future<NestedCallOutcome> gate(NestedCallRequest r) async {
      if (r.name == 'bash') {
        started.complete();
        for (final card in cards) {
          r.onPersonWait!(true);
          await card.future;
          r.onPersonWait!(false);
        }
        return NestedCallOutcome(
          status: NestedCallStatus.completed,
          value: 'ok',
          gateDecision: NestedCallGateDecision.approved,
        );
      }
      final run = r.origin.executionId!.split('/').first;
      await busy.putIfAbsent(run, Completer.new).future;
      return NestedCallOutcome(status: NestedCallStatus.completed, value: 1);
    }

    return (
      gate: gate,
      started: started,
      cards: cards,
      release: (run) {
        final c = busy.putIfAbsent(run, Completer.new);
        if (!c.isCompleted) {
          c.complete();
        }
      },
    );
  }

  test('two person waits in one call while the server is full take one '
      'slot back, not two (cap 3, share 2)', () async {
    final service = CodeExecutionService(
      sandbox: process,
      executions: MemoryExecutions(),
      store: MemoryStore(),
      serverProcessCap: 3,
    );
    expect(service.workspaceShare, 2);
    final g = twoCardGate();

    final a = service.execute(
      req('ws-1', 'A', "await tools.bash({cmd: 'push'}); return 'a';"),
      callNested: g.gate,
    );
    await g.started.future;
    await until(
      () => service.parkedRunners == 1 && service.slotsInUse == 0,
      'A to park',
    );
    final others = [
      for (final (ws, run) in [('ws-2', 'B1'), ('ws-2', 'B2'), ('ws-3', 'B3')])
        service.execute(
          req(ws, run, 'await tools.read({}); return 1;'),
          callNested: g.gate,
        ),
    ];
    await until(() => service.slotsInUse == 3, 'the server to fill');

    // Both cards are answered while no slot is free.
    g.cards[0].complete();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    g.cards[1].complete();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    g
      ..release('B1')
      ..release('B2');
    final ra = await a;
    g.release('B3');
    for (final r in await Future.wait(others)) {
      expect(r.execution.status, CodeExecutionStatus.completed);
    }
    expect(ra.execution.status, CodeExecutionStatus.completed);
    expect(service.slotsInUse, 0, reason: 'a slot leaked');
    expect(service.parkedRunners, 0);
    expect(service.activeRuns, 0);
    await service.dispose();
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('with one slot, a script whose call waits twice while another script '
      'holds the slot finishes once that one ends, not at its wall '
      'clock', () async {
    final service = CodeExecutionService(
      sandbox: process,
      executions: MemoryExecutions(),
      store: MemoryStore(),
      serverProcessCap: 1,
    );
    final g = twoCardGate();
    final clock = Stopwatch()..start();
    final a = service.execute(
      req(
        'ws-1',
        'A',
        "await tools.bash({cmd: 'push'}); return 'a';",
        limits: CodeModeLimits(wallClockMs: 60000),
      ),
      callNested: g.gate,
    );
    await g.started.future;
    await until(() => service.parkedRunners == 1, 'A to park');
    final b = service.execute(
      req('ws-2', 'B', 'await tools.read({}); return 1;'),
      callNested: g.gate,
    );
    await until(() => service.slotsInUse == 1, 'B to take the slot');
    g.cards[0].complete();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    g.cards[1].complete();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    g.release('B');
    final rb = await b;
    final ra = await a.timeout(const Duration(seconds: 20));
    expect(rb.execution.status, CodeExecutionStatus.completed);
    expect(ra.execution.status, CodeExecutionStatus.completed);
    expect(clock.elapsed, lessThan(const Duration(seconds: 30)));
    expect(service.slotsInUse, 0);
    expect(service.parkedRunners, 0);
    await service.dispose();
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('after the answer the wait for a slot counts against the wall clock: '
      'a script that cannot get one back ends timed out, and its parked '
      'place is given back', () async {
    final service = CodeExecutionService(
      sandbox: process,
      executions: MemoryExecutions(),
      store: MemoryStore(),
      serverProcessCap: 1,
    );
    final g = twoCardGate();
    final a = service.execute(
      req(
        'ws-1',
        'A',
        "await tools.bash({cmd: 'push'}); return 'a';",
        limits: CodeModeLimits(wallClockMs: 3000),
      ),
      callNested: g.gate,
    );
    await g.started.future;
    await until(() => service.parkedRunners == 1, 'A to park');
    final b = service.execute(
      req('ws-2', 'B', 'await tools.read({}); return 1;'),
      callNested: g.gate,
    );
    await until(() => service.slotsInUse == 1, 'B to take the slot');
    // A person thinks for longer than A's whole wall clock: that time is
    // not A's.
    await Future<void>.delayed(const Duration(milliseconds: 3500));
    final answered = Stopwatch()..start();
    g.cards[0].complete();
    g.cards[1].complete();
    final ra = await a.timeout(const Duration(seconds: 20));
    expect(ra.execution.status, CodeExecutionStatus.timedOut);
    expect(answered.elapsed, lessThan(const Duration(seconds: 10)));
    expect(service.parkedRunners, 0);
    expect(service.slotsInUse, 1, reason: 'B still holds its slot');
    g.release('B');
    expect((await b).execution.status, CodeExecutionStatus.completed);
    expect(service.slotsInUse, 0);
    expect(service.activeRuns, 0);
    await service.dispose();
  }, timeout: const Timeout(Duration(minutes: 2)));
}
