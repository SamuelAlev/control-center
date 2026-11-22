// Slot squatting, through the REAL runner (CC_CODEMODE_RUNNER): a run and
// its subagents (one run tree) hold at most half of their workspace's runner
// slots, so scripts parked in sleep() cannot keep the workspace's other runs
// waiting for a whole wall clock.
import 'dart:async';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

void main() {
  final runner = realRunnerPath();

  test(
    'a run tree holds at most half its workspace share; another run of '
    'the workspace is admitted at once, its tree waits in the queue',
    () async {
      final process = CodeSandboxProcess(executable: runner);
      expect((await process.selfTest()).isAvailable, isTrue);
      // Cap 4: a workspace holds 3, a run tree 1.
      final service = CodeExecutionService(
        sandbox: process,
        executions: MemoryExecutions(),
        store: MemoryStore(),
        serverProcessCap: 4,
      );
      expect(service.workspaceShare, 3);
      expect(service.treeShare, 1);

      CodeExecutionRequest request(String run, String code, {String? tree}) {
        final r = CodeExecutionRequest(
          readOnly: false,
          past: null,
          workspaceId: 'ws-1',
          runId: run,
          parentToolCallId: 'call_1',
          surface: CodeExecutionSurface.harness,
          code: code,
          description: 'sleeps',
          limits: CodeModeLimits(),
          tools: const [],
        );
        return tree == null ? r : r.inRunTree(tree);
      }

      Future<CodeExecutionResult> execute(CodeExecutionRequest r) =>
          service.execute(
            r,
            callNested: (_) async => NestedCallOutcome(
              status: NestedCallStatus.completed,
              value: const {},
            ),
          );

      // A run and two subagents, each sleeping.
      final squatters = [
        for (final run in ['parent', 'child-1', 'child-2'])
          execute(request(run, 'await sleep(3000); return 1;', tree: 'tree-a')),
      ];
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(
        service.slotsHeldBy('ws-1'),
        1,
        reason: 'the tree holds its share',
      );

      final clock = Stopwatch()..start();
      final other = await execute(request('other', 'return 2;'));
      expect(other.execution.status, CodeExecutionStatus.completed);
      expect(
        clock.elapsedMilliseconds,
        lessThan(2000),
        reason: 'admitted while the tree sleeps, not after it',
      );

      // The tree's waiting scripts run in turn, each with the wall clock its
      // wait left (at least the floor), and all complete.
      for (final r in await Future.wait(squatters)) {
        expect(r.execution.status, CodeExecutionStatus.completed);
      }
      expect(service.slotsInUse, 0);
      await service.dispose();
      expect(process.liveProcessCount, 0);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
