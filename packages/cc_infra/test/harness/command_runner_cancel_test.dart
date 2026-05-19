@Timeout(Duration(seconds: 20))
library;

import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/harness/harness_command_runner.dart';
import 'package:test/test.dart';

void main() {
  test(
    'cancelling the run kills an in-flight command instead of waiting',
    () async {
      final runner = SandboxedHarnessCommandRunner(
        mode: Mode.chat,
        capabilities: const AgentCapabilities(),
      );
      final source = CancellationTokenSource();
      final sw = Stopwatch()..start();
      // Cancel shortly after the command starts; without kill-on-cancel this
      // would block for the full 30s sleep.
      unawaited(
        Future<void>.delayed(
          const Duration(milliseconds: 300),
        ).then((_) => source.cancel()),
      );
      final result = await runner.run(
        'sleep 30',
        timeoutSeconds: 30,
        cancel: source.token,
      );
      sw.stop();
      expect(
        sw.elapsed,
        lessThan(const Duration(seconds: 10)),
        reason: 'cancellation should kill the process promptly',
      );
      expect(result.timedOut, isFalse);
      expect(result.exitCode, isNot(0));
    },
  );
}
