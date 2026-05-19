import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:test/test.dart';

/// Real-process proof for the Claude Code credential path.
///
/// The bug this pins: every Seatbelt profile denies reads under
/// `~/Library/Keychains`, which is where Claude Code 2.1 keeps its OAuth
/// credential on macOS. A denied keychain lookup does not raise — `security`
/// reports "The specified item could not be found in the keychain" — so the CLI
/// concluded it was signed out and printed `Not logged in · Please run /login`
/// on a machine where the operator was signed in. Every unit test passed,
/// because the profile was exactly what it claimed to be.
///
/// The fix is a Control-Center-owned `CLAUDE_CONFIG_DIR`
/// ([SandboxSpec.runnerStateDirs]), NOT opening the keychain. Both halves of
/// that sentence need a live process to verify, so both are here.
void main() {
  group(
    'Claude Code config dir (real process)',
    () {
      late Directory root;
      late Directory work;
      late Directory stateDir;
      late SandboxManager manager;

      const session = 'claude-cfg-test';

      setUp(() {
        root = Directory.systemTemp.createTempSync('cc-claude-cfg-');
        work = Directory('${root.path}/work')..createSync(recursive: true);
        // Deliberately INSIDE the bind mount. The server's data dir often sits
        // under a checkout (`apps/cc_server/data` when running from source), so
        // "the account dir is inside a region the profile also denies" is the
        // normal case, not an exotic one — and it is the case that fails if the
        // re-allow is not emitted last.
        stateDir = Directory('${work.path}/data/claude-accounts/acct')
          ..createSync(recursive: true);
        File(
          '${stateDir.path}/.credentials.json',
        ).writeAsStringSync('{"claudeAiOauth":{"accessToken":"tok"}}');
        manager = SandboxManager();
      });

      tearDown(() async {
        await manager.disposeSession(session);
        if (root.existsSync()) {
          root.deleteSync(recursive: true);
        }
      });

      Future<ProcessResult> runSandboxed(
        String script, {
        Mode mode = Mode.chat,
        List<String> protectedPaths = const [],
        List<String> runnerStateDirs = const [],
      }) async {
        final spec = SandboxSpec(
          sessionId: session,
          workspaceId: 'ws',
          agentId: 'agent',
          bindMounts: [
            SandboxBindMount(hostPath: work.path, guestPath: work.path),
          ],
          guestWorkdir: work.path,
          networkEnabled: false,
          mode: mode,
          capabilities: AgentCapabilities.safeDefault,
          protectedPaths: protectedPaths,
          runnerStateDirs: runnerStateDirs,
        );
        final config = await buildSandboxConfigFromPolicy(
          const SandboxPolicyResolver().resolve(
            spec: spec,
            capabilities: AgentCapabilities.safeDefault,
            homeDir: Platform.environment['HOME'],
            runDir: '${work.path}/.cc-runs/$session',
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
        final out = await process.stdout
            .transform(const SystemEncoding().decoder)
            .join();
        final err = await process.stderr
            .transform(const SystemEncoding().decoder)
            .join();
        return ProcessResult(process.pid, await process.exitCode, out, err);
      }

      test('the credential is readable inside the sandbox', () async {
        final result = await runSandboxed(
          'cat ${stateDir.path}/.credentials.json',
          runnerStateDirs: [stateDir.path],
        );
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('accessToken'));
      });

      // Not a nicety: the CLI rewrites `.credentials.json` when it renews the
      // access token. A read-only account dir turns every run that outlives the
      // token into a mid-turn 401 — which reads as a flaky model, not as a
      // permissions bug.
      test('the credential is REWRITABLE inside the sandbox', () async {
        final result = await runSandboxed(
          'echo refreshed > ${stateDir.path}/.credentials.json',
          runnerStateDirs: [stateDir.path],
        );
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(
          File('${stateDir.path}/.credentials.json').readAsStringSync(),
          contains('refreshed'),
        );
      });

      test('it stays writable in a read-only mode', () async {
        // The worktree is read-only in review mode…
        final denied = await runSandboxed(
          'echo pwned > ${work.path}/tracked.txt',
          mode: Mode.review,
          runnerStateDirs: [stateDir.path],
        );
        expect(
          denied.exitCode,
          isNot(0),
          reason: 'review mode must not let the agent write the worktree',
        );

        // …and the account dir inside it is not, because a read-only mode
        // restricts what the AGENT may change, never whether the CLI may renew
        // its own credential.
        final allowed = await runSandboxed(
          'echo refreshed > ${stateDir.path}/.credentials.json',
          mode: Mode.review,
          runnerStateDirs: [stateDir.path],
        );
        expect(allowed.exitCode, 0, reason: allowed.stderr as String);
      });

      test('it stays writable inside a protected path', () async {
        final result = await runSandboxed(
          'echo refreshed > ${stateDir.path}/.credentials.json',
          protectedPaths: [work.path],
          runnerStateDirs: [stateDir.path],
        );
        expect(result.exitCode, 0, reason: result.stderr as String);
      });

      test('without the declaration it is NOT writable — the guard is real', () async {
        // Same paths, `runnerStateDirs` omitted. If this ever passes, the
        // preceding tests prove nothing: they would be measuring the ambient
        // `$HOME`/temp allowance rather than the re-allow under test.
        final result = await runSandboxed(
          'echo pwned > ${stateDir.path}/.credentials.json',
          protectedPaths: [work.path],
        );
        expect(result.exitCode, isNot(0));
      });

      test('the login keychain is STILL denied', () async {
        // The fix must not have bought credential access by opening the
        // keychain — that would hand every sandboxed agent every password on
        // the machine. `security` exits 44 (or prints "could not be found")
        // when the profile hides the keychain files.
        final result = await runSandboxed(
          'security find-generic-password -s "Claude Code-credentials" -w '
          '2>&1 || true',
          runnerStateDirs: [stateDir.path],
        );
        expect(result.stdout, isNot(contains('sk-ant')));
      }, skip: !Platform.isMacOS ? 'macOS keychain only' : null);
    },
    // Seatbelt/bwrap only, and the enforcement suite already declares the same
    // constraint.
    skip: !Platform.isMacOS && !Platform.isLinux
        ? 'native sandbox is macOS/Linux only'
        : null,
  );
}
