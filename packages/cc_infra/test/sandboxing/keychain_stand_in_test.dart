import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/sandboxing/macos_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:test/test.dart';

/// Real-process proof for the keychain stand-in.
///
/// The bug this pins: managed Claude Code accounts signed out about once a day.
/// Inside the sandbox `security add-generic-password` fails against the
/// keychain deny after 0.3–2.7 s. Claude Code gives that write 2 s and treats a
/// timeout as transient, which skips its `.credentials.json` fallback. So a
/// token refresh that hit a slow failure dropped a pair the server had already
/// rotated, and only a fresh login could repair the account.
///
/// The stand-in has to answer fast, stay narrow, and stay out of an agent's
/// reach. Each of those needs a live process to verify.
void main() {
  group(
    'keychain stand-in (real process)',
    () {
      late Directory root;
      late Directory work;
      late SandboxManager manager;

      const session = 'keychain-stand-in-test';

      setUp(() {
        root = Directory.systemTemp.createTempSync('cc-keychain-stand-in-');
        work = Directory('${root.path}/work')..createSync(recursive: true);
        manager = SandboxManager();
      });

      tearDown(() async {
        await manager.disposeSession(session);
        if (root.existsSync()) {
          root.deleteSync(recursive: true);
        }
      });

      Future<ProcessResult> runSandboxed(String script) async {
        final spec = SandboxSpec(
          sessionId: session,
          workspaceId: 'ws',
          agentId: 'agent',
          bindMounts: [
            SandboxBindMount(hostPath: work.path, guestPath: work.path),
          ],
          guestWorkdir: work.path,
          networkEnabled: false,
          mode: Mode.chat,
        );
        final config = await buildSandboxConfigFromPolicy(
          const SandboxPolicyResolver().resolve(
            spec: spec,
            homeDir: Platform.environment['HOME'],
            runDir: '${work.path}/.cc-runs/$session',
          ),
        );
        // Not `bash -l`: a login shell runs path_helper, which moves /usr/bin
        // ahead of the stand-in. The CLI spawns `security` from its own
        // environment, which is what a plain `-c` reproduces.
        final wrap = await manager.wrap(
          config: config,
          argv: ['bash', '-c', script],
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

      String standIn() =>
          '${MacosSandbox.installKeychainStandIn(manager.profilesDir)}'
          '/security';

      test('`security` resolves to the stand-in', () async {
        final result = await runSandboxed('command -v security');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect((result.stdout as String).trim(), standIn());
      });

      /// Runs [command] in the sandbox and returns its exit code and how long
      /// it took there (sandbox setup excluded: building the config alone
      /// takes seconds).
      Future<({int exitCode, double seconds})> timed(String command) async {
        final result = await runSandboxed(
          'TIMEFORMAT=%R; { time $command >/dev/null 2>&1; } 2>&1; '
          r'echo "exit=$?"',
        );
        final lines = (result.stdout as String).trim().split('\n');
        return (
          exitCode: int.parse(lines.last.substring('exit='.length)),
          seconds: double.parse(lines.first),
        );
      }

      test('a password lookup reports "no item" (44) at once', () async {
        final r = await timed(
          'security find-generic-password -a me -w -s "Claude Code-credentials"',
        );
        expect(r.exitCode, 44);
        expect(r.seconds, lessThan(1));
      });

      // The call that dropped tokens: Claude Code writes through `security -i`
      // with a 2 s timeout, and only a FAST non-zero exit sends it to the file.
      test('a keychain write fails fast instead of timing out', () async {
        final r = await timed(
          r'printf "add-generic-password -U -a me -s cc-test -X 6869\n" '
          '| security -i',
        );
        expect(r.exitCode, 1);
        expect(r.seconds, lessThan(1));
      });

      test('certificate reads still reach the real tool', () async {
        final result = await runSandboxed(
          'security find-certificate -c "Apple Root CA" '
          '/System/Library/Keychains/SystemRootCertificates.keychain',
        );
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('Apple Root CA'));
      });

      test('a session cannot rewrite or move the stand-in', () async {
        await manager.ensureInitialized();
        final path = standIn();
        final dir = File(path).parent.path;
        // One sandbox, three attempts: each setup costs seconds.
        final result = await runSandboxed(
          'echo "exit 0" > "$path" 2>/dev/null; echo "rewrite=\$?"; '
          'mv "$dir" "$dir.moved" 2>/dev/null; echo "move=\$?"; '
          'echo x > "$dir/other" 2>/dev/null; echo "plant=\$?"',
        );
        final out = result.stdout as String;
        expect(out, isNot(contains('rewrite=0')));
        expect(out, isNot(contains('move=0')));
        expect(out, isNot(contains('plant=0')));
        expect(out, contains('plant='), reason: result.stderr as String);
        expect(File(path).readAsStringSync(), MacosSandbox.keychainStandIn);
      });
    },
    skip: Platform.isMacOS ? null : 'Seatbelt and the login keychain are macOS',
  );
}
