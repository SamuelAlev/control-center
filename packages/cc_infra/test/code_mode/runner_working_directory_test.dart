// The runner starts in a fixed neutral directory, not the server's: on macOS
// and Linux that is `/`. Against the real runner, read with lsof while a
// script runs (macOS only: that is where it was proved).
@TestOn('mac-os')
library;

import 'dart:async';
import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

void main() {
  test(
    'the working directory of a runner is /, whatever the server\'s is',
    () async {
      expect(
        runnerWorkingDirectory('/opt/bundle/bin/codemode/cc_codemode'),
        '/',
      );
      // From `/` the check below would prove nothing.
      if (Directory.current.path == '/') {
        markTestSkipped('the test process already runs in /');
        return;
      }

      final process = CodeSandboxProcess(executable: realRunnerPath());
      expect((await process.selfTest()).isAvailable, isTrue);
      final service = CodeExecutionService(
        sandbox: process,
        executions: MemoryExecutions(),
        store: MemoryStore(),
      );
      addTearDown(service.dispose);
      final release = Completer<void>();
      final called = Completer<void>();
      final run = service.execute(
        CodeExecutionRequest(
          readOnly: false,
          past: null,
          workspaceId: 'ws-1',
          runId: 'run-1',
          parentToolCallId: 'call_1',
          surface: CodeExecutionSurface.harness,
          code: 'await tools.read({}); return 1;',
          description: 'cwd',
          limits: CodeModeLimits(),
          tools: [
            ScriptToolDescriptor(
              name: 'read',
              namespace: ScriptToolNamespace.builtin,
              description: 'Read.',
              inputSchema: const {'type': 'object'},
            ),
          ],
        ),
        callNested: (r) async {
          called.complete();
          await release.future;
          return NestedCallOutcome(
            status: NestedCallStatus.completed,
            value: 1,
          );
        },
      );
      await called.future.timeout(const Duration(seconds: 20));
      final children = Process.runSync('/usr/bin/pgrep', ['-P', '$pid']);
      final runners = [
        for (final line in '${children.stdout}'.split('\n'))
          if (int.tryParse(line.trim()) case final child?)
            if ('${Process.runSync('/bin/ps', ['-o', 'comm=', '-p', '$child']).stdout}'
                .contains('cc_codemode'))
              child,
      ];
      // Runners of other test files share this process; every one of them
      // that is still running must start in `/`. One that exits between
      // pgrep and lsof has no working directory left to report, so it is
      // skipped; this script's runner cannot exit while its call is held, so
      // at least one is read.
      expect(runners, isNotEmpty);
      var read = 0;
      for (final runner in runners) {
        final cwd = _cwdOf(runner);
        if (cwd != null) {
          expect(cwd, '/', reason: 'runner $runner');
          read++;
        }
      }
      expect(read, greaterThan(0));
      release.complete();
      expect((await run).execution.status, CodeExecutionStatus.completed);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}

/// The working directory lsof reports for [pid], or null once the process
/// is gone, a zombie or exiting: a runner of another test file can exit
/// between pgrep and lsof. A live process always has one, so lsof is asked
/// again until it answers or the process is gone.
String? _cwdOf(int pid) {
  for (var attempt = 0; attempt < 50; attempt++) {
    final lsof = Process.runSync('/usr/sbin/lsof', [
      '-a',
      '-p',
      '$pid',
      '-d',
      'cwd',
      '-Fn',
    ]);
    final names = [
      for (final line in '${lsof.stdout}'.split('\n'))
        if (line.startsWith('n')) line.substring(1),
    ];
    if (names.isNotEmpty) {
      return names.single;
    }
    final stat =
        '${Process.runSync('/bin/ps', ['-o', 'stat=', '-p', '$pid']).stdout}'
            .trim();
    if (stat.isEmpty || stat.contains('Z') || stat.contains('E')) {
      return null;
    }
    sleep(const Duration(milliseconds: 100));
  }
  fail('lsof reported no working directory for the live runner $pid');
}
