// TEMPORARY end-to-end check — deleted after running. Verifies that on THIS
// host (Nix single-binary coreutils) a real resolved sandbox policy no longer
// blocks ordinary coreutils applets.
//
// macOS-only: the check drives the real Seatbelt runner (`sandbox-exec`),
// which does not exist on Linux — there the exec fails with "No such file or
// directory" before any assertion, teaching nothing about the policy.
@Tags(['e2e'])
library;

import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/sandboxing/macos_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'real policy no longer denies coreutils applets on this host',
    () async {
      final home = Platform.environment['HOME']!;
      final spec = const SandboxPolicyResolver().resolve(
        spec: const SandboxSpec(
          sessionId: 'e2e',
          workspaceId: 'ws',
          bindMounts: [],
          guestWorkdir: '/tmp',
          networkEnabled: false,
          mode: Mode.chat,
          capabilities: AgentCapabilities(),
        ),
        capabilities: const AgentCapabilities(),
        homeDir: home,
      );
      final config = await buildSandboxConfigFromPolicy(spec);

      // ignore: avoid_print
      print('resolved denyExecutables: ${config.denyExecutables}');

      final profile = MacosSandbox.generateSeatbeltProfile(config);
      final execDenies = profile
          .split('\n')
          .where((l) => l.contains('process-exec'))
          .toList();
      // ignore: avoid_print
      print('exec rules:\n${execDenies.join("\n")}');

      expect(
        profile,
        isNot(contains('bin/coreutils"))')),
        reason: 'the coreutils multiplexer must not be denied wholesale',
      );

      // Actually run an applet under the generated profile.
      final dir = Directory.systemTemp.createTempSync('sb-e2e-');
      final wrap = MacosSandbox.wrapCommand(
        config: config,
        argv: ['/bin/sh', '-c', 'dirname /a/b && echo APPLET_OK'],
        profilesDir: dir,
      );
      final result = await Process.run(wrap.executable, wrap.argv);
      // ignore: avoid_print
      print(
        'exit=${result.exitCode} out=${result.stdout} err=${result.stderr}',
      );
      dir.deleteSync(recursive: true);

      expect(result.stdout.toString(), contains('APPLET_OK'));
    },
    // `sandbox-exec` is the macOS Seatbelt runner; on Linux the exec fails
    // with "No such file or directory" before any assertion, teaching
    // nothing about the policy.
    skip: Platform.isMacOS ? false : 'Seatbelt (sandbox-exec) is macOS-only',
  );
}
