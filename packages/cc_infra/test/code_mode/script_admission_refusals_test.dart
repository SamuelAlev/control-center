// Refusals that leave a run without a script are counted
// (CodeExecutionErrorKind.withdrawsScripts) whenever the cause is the
// server's, so the run calls its tools directly: a script that had to queue
// for a runner past half its wall clock is refused `server_busy` rather than
// run on what the queue left of it, and an `init` frame that cannot carry
// the run's tool catalog is refused `catalog` before any runner is spawned.
// Through the REAL runner (CC_CODEMODE_RUNNER) and fake runners.
import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

/// A catalog whose `init` frame is over [CodeModeLimits.maxFrameBytes]:
/// 1,400 tools with descriptions of 2,048 three-byte characters.
final List<Map<String, Object?>> _hugeCatalog = [
  for (var i = 0; i < 1400; i++)
    {
      'name': 'mcp__srv__tool_$i',
      'namespace': 'srv',
      'description': '道' * 2048,
      'inputSchema': const {'type': 'object'},
    },
];

/// The real runner's port, with every script given [_hugeCatalog].
class _HugeCatalogSandbox implements CodeSandboxPort {
  _HugeCatalogSandbox(this._inner);

  final CodeSandboxProcess _inner;

  @override
  CodeRunnerAvailability get availability => _inner.availability;

  @override
  Future<CodeRunnerAvailability> selfTest() => _inner.selfTest();

  @override
  Future<CodeSandboxSession> start(
    CodeSandboxStart request, {
    CancellationToken cancel = CancellationToken.none,
  }) => _inner.start(
    CodeSandboxStart(
      code: request.code,
      limits: request.limits,
      returnBudgetChars: 30400,
      catalog: _hugeCatalog,
      store: request.store,
      storeWritable: request.storeWritable,
    ),
    cancel: cancel,
  );

  @override
  Future<void> dispose() => _inner.dispose();
}

void main() {
  final runner = realRunnerPath();

  CodeExecutionRequest request(String run, String code, {int? timeoutMs}) =>
      CodeExecutionRequest(
        readOnly: false,
        past: null,
        workspaceId: 'ws-1',
        runId: run,
        parentToolCallId: 'call_1',
        surface: CodeExecutionSurface.harness,
        code: code,
        description: 'admission',
        limits: CodeModeLimits(),
        tools: const [],
        timeoutMs: timeoutMs,
      );

  Future<CodeExecutionResult> execute(
    CodeExecutionService service,
    CodeExecutionRequest r,
  ) => service.execute(
    r,
    callNested: (_) async =>
        NestedCallOutcome(status: NestedCallStatus.completed, value: const {}),
  );

  group('a script that queued for a runner', () {
    late CodeSandboxProcess process;
    late CodeExecutionService service;

    setUp(() async {
      process = CodeSandboxProcess(executable: runner);
      expect((await process.selfTest()).isAvailable, isTrue);
      service = CodeExecutionService(
        sandbox: process,
        executions: MemoryExecutions(),
        store: MemoryStore(),
        serverProcessCap: 1,
      );
    });

    tearDown(() async {
      await service.dispose();
      expect(process.liveProcessCount, 0);
    });

    test('past half its wall clock is refused server_busy, which withdraws '
        'scripts, and names the wait (review N2)', () async {
      // Another run holds the only slot 3.7 s; the victim asks for 4 s and
      // needs 1.5 s of work.
      final squatter = execute(
        service,
        request('squatter', 'await sleep(3700); return 1;'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final clock = Stopwatch()..start();
      final victim = await execute(
        service,
        request(
          'victim',
          'const end = Date.now() + 1500; while (Date.now() < end) {} '
              'return 2;',
          timeoutMs: 4000,
        ),
      );
      expect(victim.execution.status, CodeExecutionStatus.refused);
      expect(victim.execution.errorKind, CodeExecutionErrorKind.serverBusy);
      expect(
        CodeExecutionErrorKind.withdrawsScripts,
        contains(victim.execution.errorKind),
      );
      expect(victim.result.text, contains('waited'));
      expect(victim.result.text, contains('half of its 4 s limit'));
      expect(victim.result.text, contains('at most 1 script at once'));
      expect(
        clock.elapsedMilliseconds,
        lessThan(3000),
        reason: 'refused at the half, not when the slot came',
      );
      expect((await squatter).execution.status, CodeExecutionStatus.completed);
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('a little runs with what the wait left of its clock', () async {
      final squatter = execute(
        service,
        request('squatter', 'await sleep(500); return 1;'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final victim = await execute(
        service,
        request(
          'victim',
          'const end = Date.now() + 1500; while (Date.now() < end) {} '
              'return 2;',
          timeoutMs: 4000,
        ),
      );
      expect(
        victim.execution.status,
        CodeExecutionStatus.completed,
        reason: victim.result.text,
      );
      expect(victim.execution.limits.wallClockMs, lessThan(4000));
      expect(victim.execution.limits.wallClockMs, greaterThan(2000));
      expect((await squatter).execution.status, CodeExecutionStatus.completed);
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('that did not queue keeps the floor: a 1 s script on an idle '
        'server runs', () async {
      final r = await execute(
        service,
        request('idle', 'return 1;', timeoutMs: 1000),
      );
      expect(
        r.execution.status,
        CodeExecutionStatus.completed,
        reason: r.result.text,
      );
    });
  });

  group('an init frame that cannot carry the run\'s tool catalog', () {
    test('is refused catalog before a runner is spawned', () async {
      final tmp = await Directory.systemTemp.createTemp('codemode-catalog-');
      addTearDown(() => tmp.delete(recursive: true));
      final marker = File(p.join(tmp.path, 'spawned'));
      final fake = FakeRunners(
        tmp,
      ).script('/usr/bin/touch ${marker.path}\nexit 1');
      final host = CodeSandboxProcess(
        executable: fake,
        retestInterval: Duration.zero,
      );
      await expectLater(
        host.start(
          CodeSandboxStart(
            code: 'return 1',
            limits: CodeModeLimits(),
            returnBudgetChars: 30400,
            catalog: _hugeCatalog,
          ),
        ),
        throwsA(
          isA<CodeSandboxStartException>()
              .having(
                (e) => e.errorKind,
                'kind',
                CodeExecutionErrorKind.catalog,
              )
              .having((e) => e.message, 'message', contains('too large')),
        ),
      );
      expect(marker.existsSync(), isFalse, reason: 'no runner spawned');
      expect(host.liveProcessCount, 0);
      expect(host.retests, 0, reason: 'not a launch failure');
      await host.dispose();
    });

    test(
      'ends the script catalog, which withdraws scripts (review N1)',
      () async {
        final process = CodeSandboxProcess(executable: runner);
        expect((await process.selfTest()).isAvailable, isTrue);
        final service = CodeExecutionService(
          sandbox: _HugeCatalogSandbox(process),
          executions: MemoryExecutions(),
          store: MemoryStore(),
          serverProcessCap: 1,
        );
        final r = await execute(service, request('run-1', 'return 1;'));
        expect(r.execution.errorKind, CodeExecutionErrorKind.catalog);
        expect(
          CodeExecutionErrorKind.withdrawsScripts,
          contains(r.execution.errorKind),
        );
        expect(r.result.text, contains('too large for a script'));
        expect(process.liveProcessCount, 0);
        await service.dispose();
      },
    );
  });
}
