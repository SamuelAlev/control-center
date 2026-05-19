import 'package:control_center/features/sandboxing/data/runtime/linux_sandbox.dart';
import 'package:control_center/features/sandboxing/data/runtime/sandbox_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildBwrapArgs', () {
    test('always sets PID/IPC/UTS unshare + binds standard system dirs', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        innerCommand: 'echo hi',
      );
      expect(args, containsAll(['--unshare-pid', '--unshare-uts', '--unshare-ipc']));
      expect(args, containsAll(['--proc', '/proc']));
      expect(args, containsAll(['--ro-bind-try', '/lib', '/lib']));
    });

    test('unshares net when network is explicitly blocked', () {
      // allowAll=false + empty allowedDomains → full block → --unshare-net.
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(allowAll: false),
          filesystem: FilesystemConfig(),
        ),
        innerCommand: 'echo hi',
      );
      expect(args, contains('--unshare-net'));
    });

    test('does NOT unshare net under default-allow', () {
      // The default NetworkConfig() = allowAll: true = no Seatbelt/bwrap
      // network restriction, so the namespace stays attached.
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        innerCommand: 'echo hi',
      );
      expect(args, isNot(contains('--unshare-net')));
    });

    test('does NOT unshare net when bridges are configured', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(
            allowAll: false,
            allowedDomains: ['github.com'],
          ),
          filesystem: FilesystemConfig(),
        ),
        innerCommand: 'echo hi',
        bridges: const [
          LinuxSocketBridge(
            hostSocketPath: '/tmp/x',
            sandboxSocketPath: '/tmp/x',
            sandboxLoopbackPort: 3128,
          ),
        ],
      );
      expect(args, isNot(contains('--unshare-net')));
    });

    test('binds every allowWrite path read-write', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(allowWrite: ['/work']),
        ),
        innerCommand: 'echo hi',
      );
      // --bind /work /work appears as three consecutive elements.
      final idx = args.indexOf('--bind');
      expect(idx, isNonNegative);
      expect(args[idx + 1], '/work');
      expect(args[idx + 2], '/work');
    });

    test('ends with -- bash -c <inner>', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        innerCommand: 'echo hi',
      );
      expect(args.last, 'echo hi');
      expect(args[args.length - 2], '-c');
      expect(args[args.length - 3], '/bin/bash');
      expect(args[args.length - 4], '--');
    });
  });
}
