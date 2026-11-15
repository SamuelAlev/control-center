// Run sandboxes are Seatbelt and bubblewrap; Windows has none.
@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/sandboxing/agent_run_client_access.dart';
import 'package:cc_infra/src/sandboxing/linux_sandbox.dart';
import 'package:cc_infra/src/sandboxing/macos_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:test/test.dart';

/// Every run's shims and Claude Code's hook start the agent run client
/// inside the run's sandbox, and every other run's hook trusts it: each
/// sandbox may run it and none may change it, wherever it is installed.
void main() {
  late Directory root;
  late String home;
  late String work;
  late String client;
  late String source;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc-run-client-');
    // The kernel's spelling (`/var` is a link), so the rules name what the
    // processes touch.
    home = '${root.resolveSymbolicLinksSync()}/home';
    work = '$home/work';
    // Installed inside a tree the run may write, the worst case.
    client = '$work/tools/cc server';
    source = '$work/tools/client.dart';
    File(client)
      ..createSync(recursive: true)
      ..writeAsStringSync('#!/bin/sh\necho "client \$*"\n');
    Process.runSync('/bin/chmod', ['755', client]);
    File(source).writeAsStringSync('// client\n');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  Future<SandboxConfig> config() => buildSandboxConfigFromPolicy(
    const SandboxPolicyResolver().resolve(
      spec: SandboxSpec(
        sessionId: 'run-client',
        workspaceId: 'ws',
        agentId: 'agent',
        bindMounts: [SandboxBindMount(hostPath: work, guestPath: work)],
        guestWorkdir: work,
        networkEnabled: false,
        mode: Mode.chat,
      ),
      homeDir: home,
      runDir: '$work/.cc-runs/run-client',
    ),
  );

  test(
    'the client is an exec literal, read-only and an install root',
    () async {
      final base = await config();
      final granted = withAgentRunClient(base, [client, source]);

      expect(granted.allowedExecutables, contains(client));
      expect(granted.allowedExecutables, isNot(contains(source)));
      expect(granted.filesystem.allowRead, containsAll([client, source]));
      expect(
        granted.filesystem.hostExecutables.installRoots,
        containsAll([client, source]),
      );
      expect(withAgentRunClient(base, const []), same(base));
    },
  );

  test('macOS: runs by its literal path after every exec deny, and is never '
      'writable', () async {
    final profile = MacosSandbox.generateSeatbeltProfile(
      withAgentRunClient(await config(), [client, source]),
    );
    final lines = profile.split('\n');
    final allow = lines.indexOf('(allow process-exec (literal "$client"))');
    final homeDeny = lines.indexOf('(deny process-exec (subpath "$home"))');

    expect(allow, isNot(-1), reason: profile);
    expect(homeDeny, isNot(-1), reason: profile);
    expect(allow, greaterThan(homeDeny));
    // Never its directory: that would re-open whatever sits beside it.
    expect(profile, isNot(contains('(subpath "$work/tools")')));
    for (final file in [client, source]) {
      expect(
        lines,
        contains('(deny file-write* (literal "$file"))'),
        reason: file,
      );
    }
    expect(lines, contains('(deny file-write-unlink (literal "$work/tools"))'));
  });

  test('Linux: each file is bound read-only where it lives', () async {
    // Linux refuses the policy's secret-write globs, so a plain config with
    // the writable tree around the client.
    final args = LinuxSandbox.buildBwrapArgs(
      config: withAgentRunClient(
        SandboxConfig(
          sessionId: 'run-client',
          network: const NetworkConfig(),
          filesystem: FilesystemConfig(allowWrite: [work]),
        ),
        [client, source],
      ),
      innerCommand: 'true',
    );
    String bound(String path) {
      for (var i = 0; i + 2 < args.length; i++) {
        if (args[i + 1] == path && args[i + 2] == path) {
          return args[i];
        }
      }
      return '';
    }

    expect(bound(client), anyOf('--ro-bind-try', '--ro-bind'));
    expect(bound(source), anyOf('--ro-bind-try', '--ro-bind'));
    // The writable tree around it comes later, and the files are bound read
    // only again after it.
    final lastWritable = args.lastIndexOf(work);
    final lastClient = args.lastIndexOf(client);
    expect(lastClient, greaterThan(lastWritable));
    expect(args[lastClient - 2], startsWith('--ro-bind'));
  });

  group('real Seatbelt', () {
    Future<ProcessResult> run(String script) async {
      final manager = SandboxManager(
        hiddenPaths: const [],
        agentRunClient: [client, source],
      );
      addTearDown(manager.reset);
      final wrap = await manager.wrap(
        config: await config(),
        argv: ['/bin/sh', '-c', script],
        workingDirectory: work,
      );
      return Process.run(
        wrap.executable,
        wrap.argv,
        workingDirectory: work,
        environment: {...wrap.environment, 'C': client, 'W': work},
      );
    }

    test('the run may start the client', () async {
      final result = await run(r'"$C" hook');
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(result.stdout, 'client hook\n');
    });

    test('the run can neither change nor move it', () async {
      await run(
        r'printf x > "$C"; printf x >> "$C"; /bin/chmod 600 "$C"; '
        r'/bin/mv "$C" "$W/gone"; /bin/mv "$W/tools" "$W/tools2"; '
        r'/bin/rm -f "$C"',
      );
      expect(File(client).readAsStringSync(), contains('echo "client'));
      expect(File(client).statSync().modeString(), 'rwxr-xr-x');
      expect(File('$work/gone').existsSync(), isFalse);
      expect(Directory('$work/tools2').existsSync(), isFalse);
    });
  }, skip: Platform.isMacOS ? false : 'real Seatbelt only');
}
