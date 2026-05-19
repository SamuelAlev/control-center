import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:test/test.dart';

/// End-to-end proof that the OS sandbox is actually ENFORCED, not merely
/// configured.
///
/// This exists because the whole chain — resolver, policy, profile emitter —
/// was correct and fully unit-tested while agent dispatch silently ran with
/// `NoSandboxAdapter()`, so `SandboxSpec.protectedPaths` was computed on every
/// dispatch and then thrown away. Every unit test still passed. The only thing
/// that catches that class of regression is spawning a real process and
/// checking what it can write.
void main() {
  group(
    'sandbox enforcement (real process)',
    () {
      late Directory root;
      late Directory work;
      late Directory protected;
      late SandboxManager manager;

      setUp(() {
        root = Directory.systemTemp.createTempSync('cc-sbx-enforce-');
        work = Directory('${root.path}/work')..createSync(recursive: true);
        protected = Directory('${root.path}/checkout')
          ..createSync(recursive: true);
        File('${protected.path}/tracked.txt').writeAsStringSync('original\n');
        manager = SandboxManager();
      });

      tearDown(() async {
        await manager.disposeSession('enforcement-test');
        if (root.existsSync()) {
          root.deleteSync(recursive: true);
        }
      });

      Future<ProcessResult> runSandboxed(String script) async {
        final spec = SandboxSpec(
          sessionId: 'enforcement-test',
          workspaceId: 'ws',
          agentId: 'agent',
          // Only the agent's own worktree is mounted, exactly as dispatch does.
          bindMounts: [
            SandboxBindMount(hostPath: work.path, guestPath: work.path),
          ],
          guestWorkdir: work.path,
          networkEnabled: false,
          mode: Mode.chat,
          capabilities: AgentCapabilities.safeDefault,
          protectedPaths: [protected.path],
        );
        final config = await buildSandboxConfigFromPolicy(
          const SandboxPolicyResolver().resolve(
            spec: spec,
            capabilities: AgentCapabilities.safeDefault,
            homeDir: Platform.environment['HOME'],
            runDir: '${work.path}/.cc-runs/enforcement-test',
          ),
        );
        final wrap = await manager.wrap(
          config: config,
          argv: ['bash', '-lc', script],
          workingDirectory: work.path,
        );
        final process = await Process.start(
          wrap.executable,
          wrap.argv,
          workingDirectory: work.path,
          environment: wrap.environment,
          runInShell: false,
        );
        final stdoutText = await process.stdout
            .transform(const SystemEncoding().decoder)
            .join();
        final stderrText = await process.stderr
            .transform(const SystemEncoding().decoder)
            .join();
        return ProcessResult(
          process.pid,
          await process.exitCode,
          stdoutText,
          stderrText,
        );
      }

      test('a sandboxed command still runs', () async {
        final result = await runSandboxed('echo alive');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('alive'));
      });

      test('writes inside the agent worktree are allowed', () async {
        final result = await runSandboxed('echo ok > ${work.path}/out.txt');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(File('${work.path}/out.txt').existsSync(), isTrue);
      });

      test('writes to a protected checkout are denied', () async {
        final target = '${protected.path}/tracked.txt';
        final result = await runSandboxed('echo pwned > $target');
        expect(
          result.exitCode,
          isNot(0),
          reason: 'the write should have been refused by the sandbox',
        );
        expect(
          File(target).readAsStringSync().trim(),
          'original',
          reason:
              'SandboxSpec.protectedPaths must survive as a deny-write rule',
        );
      });

      test(
        'a protected path reached through a symlink is still denied',
        () async {
          // macOS resolves /var/folders -> /private/var/folders (and /tmp ->
          // /private/tmp) before matching, so a rule written against the
          // unresolved spelling never fires. `Directory.systemTemp` is exactly
          // that case, which is why this test uses it rather than $HOME.
          final target = '${protected.path}/tracked.txt';
          final resolved = protected.resolveSymbolicLinksSync();
          expect(
            resolved,
            isNot(protected.path),
            reason: 'this test is only meaningful on a symlinked temp root',
            skip: resolved == protected.path,
          );
          final result = await runSandboxed(
            'echo pwned > $resolved/tracked.txt',
          );
          expect(result.exitCode, isNot(0));
          expect(File(target).readAsStringSync().trim(), 'original');
        },
      );
    },
    // The sandbox is a host capability: macOS always has sandbox-exec, Linux
    // needs bwrap + socat, Windows has no backend at all. Skip rather than
    // fail where the host cannot sandbox — `runCcServer` makes the same call.
    skip: _skipReason(),
  );
}

String? _skipReason() {
  if (Platform.isMacOS) {
    return null;
  }
  if (Platform.isLinux) {
    // CI installs bwrap + socat (ci.yml's "Install sandbox tooling" step), so
    // this never fires there — the enforcement suite RUNS. It exists for a
    // bare local container without the tools, where the alternative is a
    // ProcessException from deep inside `wrap` instead of this actionable
    // message.
    for (final tool in const ['bwrap', 'socat']) {
      if (!_hasTool(tool)) {
        return 'Linux sandbox needs $tool on PATH (sudo apt-get install -y '
            'bubblewrap socat); skipping the real-process enforcement suite';
      }
    }
    return null;
  }
  return 'no OS-native sandbox backend on ${Platform.operatingSystem}';
}

bool _hasTool(String name) {
  try {
    return Process.runSync('which', [name]).exitCode == 0;
  } catch (_) {
    return false;
  }
}
