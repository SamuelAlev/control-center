// The runner protocol against REAL runners: the one built from this tree
// (CC_CODEMODE_RUNNER) speaks the server's protocol, and a runner built
// before protocol 2 (CC_CODEMODE_BASELINE_RUNNER, optional: no such binary
// ships, so the case is skipped where none is at hand) is refused at its
// self-test and at its handshake with the reinstall text.
import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

void main() {
  CodeSandboxStart start() => CodeSandboxStart(
    code: 'return 1',
    limits: CodeModeLimits(wallClockMs: 5000),
    returnBudgetChars: 30400,
    catalog: const [],
  );

  test('the runner of this tree speaks the server protocol', () async {
    final host = CodeSandboxProcess(executable: realRunnerPath());
    addTearDown(host.dispose);
    expect((await host.selfTest()).isAvailable, isTrue);
    final session = await host.start(start());
    session.events.listen((_) {});
    await session.outcome;
    expect(session.handshake.protocol, CodeSandboxProcess.protocolVersion);
  });

  final baseline = Platform.environment['CC_CODEMODE_BASELINE_RUNNER'];
  test(
    'a protocol 1 runner is refused at its self-test and at its handshake',
    () async {
      final host = CodeSandboxProcess(executable: baseline!);
      addTearDown(host.dispose);
      final answer = await host.selfTest();
      expect(answer.isAvailable, isFalse);
      expect(
        (answer as CodeRunnerUnavailable).reason,
        'The code mode runner speaks protocol 1; this server speaks '
        '${CodeSandboxProcess.protocolVersion}. Reinstall the application or '
        'server bundle.',
      );
      expect(host.availability.isAvailable, isFalse);
      await expectLater(
        host.start(start()),
        throwsA(
          isA<CodeSandboxStartException>()
              .having((e) => e.errorKind, 'errorKind', 'protocol')
              .having(
                (e) => e.message,
                'message',
                contains('Reinstall the application or server bundle.'),
              ),
        ),
      );
    },
    skip: baseline == null
        ? 'CC_CODEMODE_BASELINE_RUNNER names no protocol 1 runner'
        : null,
  );
}
