import 'dart:io';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:cc_infra/src/dispatch/host_commit_signer.dart';
import 'package:cc_infra/src/sandboxing/macos_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:test/test.dart';

class _NoRules implements ActionPolicyRepository {
  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NeverAsked implements ConfirmationPort {
  @override
  Future<bool> requestApproval(ConfirmationRequest request) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoBroker implements CredentialBrokerPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Real-process proof for the sandbox's SSH signing shim.
///
/// The bug this pins: with `commit.gpgsign` and 1Password's `op-ssh-sign`, a
/// sandboxed `git commit` died with "1Password: Could not connect to socket"
/// and "failed to write commit object", because the profile denies unix
/// sockets. The shim sends the commit object to the gateway, which signs it
/// on the host. Here the host signer is plain `/usr/bin/ssh-keygen` with a
/// throwaway key, so the signature can be verified end to end.
void main() {
  group('ssh signing shim (real process)', () {
    late Directory root;
    late Directory work;
    late String globalConfig;
    late String signingConfig;
    late SandboxManager manager;
    late HttpServer host;
    late AgentRunGateway gateway;

    const session = 'ssh-sign-shim-test';
    const email = 'agent@example.com';

    setUp(() async {
      root = Directory.systemTemp.createTempSync('cc-ssh-sign-shim-');
      work = Directory('${root.path}/work')..createSync(recursive: true);
      final key = '${root.path}/signing_key';
      final keygen = Process.runSync('/usr/bin/ssh-keygen', [
        '-q',
        '-t',
        'ed25519',
        '-N',
        '',
        '-C',
        email,
        '-f',
        key,
      ]);
      expect(keygen.exitCode, 0, reason: keygen.stderr as String);
      final publicKey = File('$key.pub').readAsStringSync().trim();
      File(
        '${root.path}/allowed_signers',
      ).writeAsStringSync('$email $publicKey\n');
      globalConfig = '${root.path}/gitconfig';
      signingConfig =
          '''
[user]
  name = Agent
  email = $email
  signingkey = $key
[gpg]
  format = ssh
[gpg "ssh"]
  allowedSignersFile = ${root.path}/allowed_signers
[commit]
  gpgsign = true
[init]
  defaultBranch = main
''';
      File(globalConfig).writeAsStringSync(signingConfig);
      final gitEnv = {
        ...Platform.environment,
        'GIT_CONFIG_GLOBAL': globalConfig,
        'GIT_CONFIG_NOSYSTEM': '1',
      };
      manager = SandboxManager(gitEnvironment: gitEnv);
      host = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      gateway = AgentRunGateway(
        guard: ActionGuardService(
          repository: _NoRules(),
          confirmationPort: _NeverAsked(),
        ),
        broker: _NoBroker(),
        loopbackBase: () async => Uri.parse('http://127.0.0.1:${host.port}'),
        signer: HostCommitSigner(environment: gitEnv),
        mayUseHostSigner: (_) async => true,
      );
      host.listen(gateway.handle);
    });

    tearDown(() async {
      await manager.disposeSession(session);
      await host.close(force: true);
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    Future<ProcessResult> runSandboxed(
      String script, {
      bool withLease = true,
      String? homeDir,
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
        loopbackPorts: [host.port],
        mode: Mode.chat,
      );
      final config = await buildSandboxConfigFromPolicy(
        const SandboxPolicyResolver().resolve(
          spec: spec,
          homeDir: homeDir ?? Platform.environment['HOME'],
          runDir: '${work.path}/.cc-runs/$session',
        ),
      );
      final wrap = await manager.wrap(
        config: config,
        argv: ['bash', '-c', script],
        workingDirectory: work.path,
      );
      final lease = withLease
          ? await gateway.open(
              const AgentRunGrant(
                workspaceId: 'ws',
                conversationId: 'c',
                committerEmail: email,
              ),
            )
          : null;
      final env = <String, String>{
        ...wrap.environment,
        'GIT_CONFIG_GLOBAL': globalConfig,
        'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_CONFIG_COUNT': '0',
      };
      if (lease != null) {
        env.addAll(lease.environment(env));
      }
      try {
        return await Process.run(
          wrap.executable,
          wrap.argv,
          workingDirectory: work.path,
          environment: env,
        );
      } finally {
        await gateway.close(lease);
      }
    }

    String shimPath() =>
        '${MacosSandbox.installSshSignShim(manager.profilesDir)}'
        '/${MacosSandbox.sshSignShimName}';

    test('a sandboxed signed commit is signed on the host', () async {
      final result = await runSandboxed(
        'git init -q && git commit -q --allow-empty -m signed && '
        'git verify-commit HEAD && '
        r'echo "program=$(git config gpg.ssh.program)" && '
        r'echo "user=$CC_GIT_SSH_PROGRAM" && '
        r'echo "count=$GIT_CONFIG_COUNT" && '
        'git config --get-regexp "^url\\..*pushinsteadof" | wc -l',
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      final out = result.stdout as String;
      expect(out, contains('program=${shimPath()}'));
      // Verification ran the user's own program (git's default here).
      expect(out, contains('user=ssh-keygen'));
      // The lease's four push-routing entries survive; the signer is fifth.
      expect(out, contains('count=5'));
      expect(out.trim().split('\n').last.trim(), '3');
      expect(result.stderr, contains('Good "git" signature for $email'));
    });

    test('without SSH signing, git is left exactly as configured', () async {
      File(globalConfig).writeAsStringSync('''
[user]
  name = Agent
  email = $email
''');
      final result = await runSandboxed(
        r'echo "program=$(git config gpg.ssh.program)"; '
        r'echo "count=$GIT_CONFIG_COUNT"; echo "user=$CC_GIT_SSH_PROGRAM"',
      );
      final out = result.stdout as String;
      expect(out, contains('program=\n'));
      expect(out, contains('count=4'));
      expect(out, contains('user=\n'));
    });

    test('a commit made as someone else is not signed', () async {
      final result = await runSandboxed(
        'git init -q && GIT_COMMITTER_EMAIL=mallory@example.com '
        'git commit -q --allow-empty -m forged',
      );
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('names mallory@example.com'));
    });

    test('a session without an agent run says why it cannot sign', () async {
      final result = await runSandboxed(
        'git init -q && git commit -q --allow-empty -m unsigned',
        withLease: false,
      );
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('cannot sign commits (no agent run)'));
    });

    test('a session cannot rewrite the global git config', () async {
      // A stand-in home: the deny is asserted, never tried on the real one.
      final home = '${root.path}/home';
      final config = File('$home/.config/git/config')
        ..createSync(recursive: true)
        ..writeAsStringSync(signingConfig);
      final result = await runSandboxed(
        'echo "[gpg \\"ssh\\"] program = /tmp/evil" >> "${config.path}" '
        '2>/dev/null; echo "append=\$?"; '
        'echo x > "$home/.config/git/allowed_signers" 2>/dev/null; '
        'echo "plant=\$?"; '
        'mv "$home/.config/git" "$home/.config/moved" 2>/dev/null; '
        'echo "move=\$?"',
        homeDir: home,
      );
      final out = result.stdout as String;
      expect(out, contains('append='), reason: result.stderr as String);
      expect(out, isNot(contains('append=0')));
      expect(out, isNot(contains('plant=0')));
      expect(out, isNot(contains('move=0')));
      expect(config.readAsStringSync(), signingConfig);
    });
  }, skip: Platform.isMacOS ? null : 'Seatbelt is macOS');
}
