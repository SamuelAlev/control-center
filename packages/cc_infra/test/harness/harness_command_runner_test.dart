@TestOn('!windows')
library;

import 'dart:io';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/harness/harness_command_runner.dart';
import 'package:test/test.dart';

/// Exercises [SandboxedHarnessCommandRunner] along its no-sandbox fallback
/// path (env sanitization only) — the path used when no native sandbox is
/// available. Covers: command policy allow/deny/prompt, the confirmation flow
/// (approved / user-denied / no-approver), real process exec + output capture,
/// timeout, cancellation and bounded-output truncation with a spill file.
///
/// POSIX-only: every path here ends in `bash -lc`, and on the GitHub Windows
/// runner the PATH `bash` is the WSL stub with no distro installed (exit 1,
/// UTF-16 "Windows Subsystem for Linux has no installed distributions").
/// The policy engine itself is platform-neutral and covered by unit tests.
void main() {
  late Directory cwd;

  setUp(() => cwd = Directory.systemTemp.createTempSync('harness_cmd_'));
  tearDown(() => cwd.deleteSync(recursive: true));

  SandboxedHarnessCommandRunner runner({
    ConfirmationPort? confirmationPort,
    Map<String, String> baseEnv = const {},
    int maxOutputChars = 16000,
  }) => SandboxedHarnessCommandRunner(
    mode: Mode.chat,
    capabilities: const AgentCapabilities(),
    confirmationPort: confirmationPort,
    workspaceId: 'ws',
    agentId: 'a',
    conversationId: 'c',
    baseEnv: baseEnv,
    maxOutputChars: maxOutputChars,
  );

  group('SandboxedHarnessCommandRunner — command policy', () {
    test('allow path runs the command and returns exit 0 + stdout', () async {
      final res = await runner().run('echo hello', workdir: cwd.path);
      expect(res.denied, isFalse);
      expect(res.exitCode, 0);
      expect(res.stdout.trim(), 'hello');
    });

    test('deny path blocks a dangerous command before exec', () async {
      final res = await runner().run('rm -rf /', workdir: cwd.path);
      expect(res.denied, isTrue);
      expect(res.exitCode, 126);
      expect(res.denyReason, contains('denied by policy'));
    });

    test('prompt with no approver connected is denied', () async {
      final res = await runner(
        confirmationPort: null,
      ).run('git push', workdir: cwd.path);
      expect(res.denied, isTrue);
      expect(res.denyReason, contains('no approver'));
    });

    test('prompt approved by the approver runs the command', () async {
      final res = await runner(
        confirmationPort: _Approver(approve: true),
      ).run('git push', workdir: cwd.path);
      // git push with no repo fails the git binary, but the runner must NOT
      // have denied it — proving the approval gate passed.
      expect(res.denied, isFalse);
    });

    test('prompt denied by the approver is denied', () async {
      final res = await runner(
        confirmationPort: _Approver(approve: false),
      ).run('git push', workdir: cwd.path);
      expect(res.denied, isTrue);
      expect(res.denyReason, contains('denied by user'));
    });
  });

  group('SandboxedHarnessCommandRunner — env + output', () {
    test('base env is exposed to the child', () async {
      final res = await runner(
        baseEnv: {'CC_TEST_VAR': 'envval'},
      ).run(r'echo "$CC_TEST_VAR"', workdir: cwd.path);
      expect(res.stdout.trim(), 'envval');
    });

    test(
      'dangerous env vars (LD_PRELOAD) are stripped from the child',
      () async {
        final res = await runner().run(
          r'echo "${LD_PRELOAD:-unset}"',
          workdir: cwd.path,
        );
        expect(res.stdout.trim(), 'unset');
      },
    );

    test('per-call env overrides base env', () async {
      final res = await runner(baseEnv: {'CC_TEST_VAR': 'base'}).run(
        r'echo "$CC_TEST_VAR"',
        workdir: cwd.path,
        env: {'CC_TEST_VAR': 'override'},
      );
      expect(res.stdout.trim(), 'override');
    });

    test('a non-zero exit is reported without denial', () async {
      final res = await runner().run('exit 7', workdir: cwd.path);
      expect(res.exitCode, 7);
      expect(res.denied, isFalse);
      expect(res.ok, isFalse);
    });

    test('stderr is captured separately from stdout', () async {
      final res = await runner().run(
        'echo to-stdout; echo to-stderr 1>&2',
        workdir: cwd.path,
      );
      expect(res.stdout, contains('to-stdout'));
      expect(res.stderr, contains('to-stderr'));
    });
  });

  group('SandboxedHarnessCommandRunner — bounded output + spill', () {
    test('truncates oversized stdout and keeps a spill file', () async {
      // Emit more than the cap; the spill file should be retained.
      final res = await runner(maxOutputChars: 200).run(
        r'for i in $(seq 1 100); do echo "line $i"; done',
        workdir: cwd.path,
      );
      expect(res.stdout, contains('truncated'));
      // The spill pointer is appended when stdout was truncated.
      expect(res.stdout, contains('full stdout saved to'));
      // Spill dir exists under the workspace.
      final spillDir = Directory('${cwd.path}/.cc-runs/bash-output');
      expect(spillDir.existsSync(), isTrue);
      expect(spillDir.listSync().whereType<File>(), isNotEmpty);
    });

    test('does not keep a spill file when output fits inline', () async {
      await runner(maxOutputChars: 10000).run('echo small', workdir: cwd.path);
      final spillDir = Directory('${cwd.path}/.cc-runs/bash-output');
      if (spillDir.existsSync()) {
        expect(spillDir.listSync().whereType<File>(), isEmpty);
      }
    });
  });

  group('SandboxedHarnessCommandRunner — timeout + cancellation', () {
    test('a command exceeding timeoutSeconds is killed (exit 124)', () async {
      final res = await runner().run(
        'sleep 30',
        workdir: cwd.path,
        timeoutSeconds: 1,
      );
      expect(res.timedOut, isTrue);
      expect(res.exitCode, 124);
    });

    test(
      'a pre-cancelled token kills the command and marks the result',
      () async {
        final source = CancellationTokenSource()..cancel();
        final res = await runner().run(
          'sleep 30',
          workdir: cwd.path,
          cancel: source.token,
        );
        expect(res.stderr, contains('cancelled'));
      },
    );
  });
}

class _Approver implements ConfirmationPort {
  _Approver({required this.approve});
  final bool approve;
  @override
  Future<bool> requestApproval(ConfirmationRequest request) async => approve;
}
