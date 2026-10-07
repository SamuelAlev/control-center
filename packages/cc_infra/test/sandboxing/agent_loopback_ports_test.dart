import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/sandboxing/macos_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:test/test.dart';

/// The agent run gateway (and MCP) ride one host loopback port. A sandbox has
/// to reach it whatever its network posture — a push is routed there even for
/// a run whose "network egress" rule turned the network off, because the
/// gateway, not the sandbox, talks to GitHub.
void main() {
  SandboxSpec spec(String dir, {bool network = false}) => SandboxSpec(
    sessionId: 'lo-test',
    workspaceId: 'ws',
    bindMounts: [SandboxBindMount(hostPath: dir, guestPath: dir)],
    guestWorkdir: dir,
    networkEnabled: network,
    loopbackPorts: const [9020],
  );

  test(
    'the resolver and builder carry the ports to the network config',
    () async {
      final dir = Directory.systemTemp.createTempSync('cc-lo-');
      addTearDown(() => dir.deleteSync(recursive: true));

      final policy = const SandboxPolicyResolver().resolve(
        spec: spec(dir.path),
      );
      expect(policy.loopbackPorts, [9020]);
      final config = await buildSandboxConfigFromPolicy(policy);
      expect(config.network.loopbackPorts, [9020]);
      // Network off is still a restricted config — the port is the exception.
      expect(config.network.isRestricted, isTrue);
    },
  );

  test('the Seatbelt profile opens the port when the network is off', () {
    final profile = MacosSandbox.generateSeatbeltProfile(
      const SandboxConfig(
        sessionId: 's',
        network: NetworkConfig(allowAll: false, loopbackPorts: [9020]),
        filesystem: FilesystemConfig(),
      ),
    );
    expect(profile, contains('(deny network*)'));
    expect(profile, contains('(allow network* (remote tcp "localhost:9020"))'));
  });

  test(
    'a network-off sandbox reaches the port (real process)',
    () async {
      final work = Directory.systemTemp.createTempSync('cc-lo-run-');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((r) {
        r.response.write('gateway');
        r.response.close();
      });
      final manager = SandboxManager();
      addTearDown(() async {
        await manager.disposeSession('lo-run');
        await server.close(force: true);
        work.deleteSync(recursive: true);
      });

      final config = await buildSandboxConfigFromPolicy(
        const SandboxPolicyResolver().resolve(
          spec: SandboxSpec(
            sessionId: 'lo-run',
            workspaceId: 'ws',
            bindMounts: [
              SandboxBindMount(hostPath: work.path, guestPath: work.path),
            ],
            guestWorkdir: work.path,
            networkEnabled: false,
            loopbackPorts: [server.port],
          ),
          homeDir: Platform.environment['HOME'],
          runDir: '${work.path}/.cc-runs/lo-run',
        ),
      );
      final wrap = await manager.wrap(
        config: config,
        argv: [
          'curl',
          '-s',
          '--noproxy',
          '*',
          'http://127.0.0.1:${server.port}/',
        ],
        workingDirectory: work.path,
      );
      final result = await Process.run(
        wrap.executable,
        wrap.argv,
        workingDirectory: work.path,
        environment: wrap.environment,
      );
      expect(result.stdout, 'gateway', reason: '${result.stderr}');
    },
    skip: Platform.isMacOS
        ? null
        : 'production native sandbox policy requires macOS pathname globs',
  );
}
