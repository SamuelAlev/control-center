import 'dart:io';

import 'package:cc_infra/src/sandboxing/linux_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config.dart';
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
      expect(
        args,
        containsAll(['--unshare-pid', '--unshare-uts', '--unshare-ipc']),
      );
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

    test('unshares net even when bridges are configured', () {
      // A restricted network always unshares the net namespace (not only when
      // fully blocked). NET_ADMIN is scoped to the netns so the inner process
      // can bring the sandbox loopback up — the bound bridge sockets + loopback
      // are how the socat bridges and HTTP_PROXY calls still reach the proxy.
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
      expect(args, contains('--unshare-net'));
      // Numeric CAP_NET_ADMIN (12), never the name — see the note in
      // buildBwrapArgs: some libcap builds (CI's ubuntu-24.04 runner) fail
      // cap_from_name for every name, and libcap's numeric path cannot
      // misresolve.
      expect(args, containsAll(['--cap-add', '12']));
      // The bridge socket is still bound into the sandbox so it works inside
      // the unshared netns.
      expect(args, containsAll(['--bind', '/tmp/x', '/tmp/x']));
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

  group('buildBwrapArgs — denyRead', () {
    test('maps non-existent denyRead paths to /dev/null shadow', () {
      // A non-existent path is treated as a file (isDirectorySync → false).
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(denyRead: ['/foo/secret.env']),
        ),
        innerCommand: 'echo hi',
      );
      expect(
        args,
        containsAll(['--ro-bind-try', '/dev/null', '/foo/secret.env']),
      );
    });

    test('all denyRead paths get shadowed', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(
            denyRead: ['/Users/me/.ssh', '/Users/me/.aws'],
          ),
        ),
        innerCommand: 'echo hi',
      );
      expect(
        args,
        containsAll(['--ro-bind-try', '/dev/null', '/Users/me/.ssh']),
      );
      expect(
        args,
        containsAll(['--ro-bind-try', '/dev/null', '/Users/me/.aws']),
      );
    });
  });

  group('buildBwrapArgs — denyWrite', () {
    test('maps denyWrite paths to /dev/null shadow', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(denyWrite: ['/etc/sensitive']),
        ),
        innerCommand: 'echo hi',
      );
      expect(
        args,
        containsAll(['--ro-bind-try', '/dev/null', '/etc/sensitive']),
      );
    });

    test(
      'maps a denyWrite DIRECTORY to a read-only re-bind, not /dev/null',
      () {
        // /dev/null cannot shadow a directory — bwrap refuses the mount
        // ("Can't create file at …: Is a directory") and the whole sandbox
        // dies at spawn. Protected checkouts ARE directories, so this is the
        // every-dispatch case.
        final dir = Directory.systemTemp.createTempSync('cc-lx-deny-dir-');
        addTearDown(() => dir.deleteSync(recursive: true));
        final args = LinuxSandbox.buildBwrapArgs(
          config: SandboxConfig(
            sessionId: 't',
            network: const NetworkConfig(),
            filesystem: FilesystemConfig(denyWrite: [dir.path]),
          ),
          innerCommand: 'echo hi',
        );
        expect(args, containsAll(['--ro-bind-try', dir.path, dir.path]));
        expect(
          args,
          isNot(contains('/dev/null')),
          reason: 'a directory must never be shadowed by /dev/null',
        );
      },
    );
  });

  group('buildBwrapArgs — workingDirectory', () {
    test('injects --chdir when workingDirectory is provided', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        innerCommand: 'echo hi',
        workingDirectory: '/home/user/work',
      );
      expect(args, containsAll(['--chdir', '/home/user/work']));
    });

    test('does NOT include --chdir when workingDirectory is null', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        innerCommand: 'echo hi',
      );
      expect(args, isNot(contains('--chdir')));
    });
  });

  group('buildBwrapArgs — HOME', () {
    test('sets HOME to workingDirectory when provided', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        innerCommand: 'echo hi',
        workingDirectory: '/home/user/work',
      );
      expect(args, containsAll(['--setenv', 'HOME', '/home/user/work']));
    });

    test('sets HOME to /tmp when workingDirectory is null', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        innerCommand: 'echo hi',
      );
      expect(args, containsAll(['--setenv', 'HOME', '/tmp']));
    });
  });

  group('buildBwrapArgs — multiple allowWrite', () {
    test('binds multiple writable paths', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(allowWrite: ['/work/a', '/work/b']),
        ),
        innerCommand: 'echo hi',
      );
      expect(args, containsAll(['--bind', '/work/a', '/work/a']));
      expect(args, containsAll(['--bind', '/work/b', '/work/b']));
    });
  });

  group('buildBwrapArgs — bridge bind mounts', () {
    test('binds bridge socket paths into sandbox', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        innerCommand: 'echo hi',
        bridges: const [
          LinuxSocketBridge(
            hostSocketPath: '/tmp/foo.sock',
            sandboxSocketPath: '/tmp/foo.sock',
            sandboxLoopbackPort: 3128,
          ),
        ],
      );
      expect(args, containsAll(['--bind', '/tmp/foo.sock', '/tmp/foo.sock']));
    });
  });

  group('buildBwrapArgs — default flags always present', () {
    test('includes --die-with-parent', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        innerCommand: 'echo hi',
      );
      expect(args.first, '--die-with-parent');
    });

    test('includes --dev /dev', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        innerCommand: 'echo hi',
      );
      expect(args, containsAll(['--dev', '/dev']));
    });

    test('includes standard ro-bind-try entries', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        innerCommand: 'echo hi',
      );
      expect(args, containsAll(['--ro-bind-try', '/usr', '/usr']));
      expect(args, containsAll(['--ro-bind-try', '/bin', '/bin']));
      expect(args, containsAll(['--ro-bind-try', '/etc', '/etc']));
    });

    test('always tmpfs /tmp', () {
      final args = LinuxSandbox.buildBwrapArgs(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        innerCommand: 'echo hi',
      );
      expect(args, containsAll(['--tmpfs', '/tmp']));
    });
  });

  group('wrapCommand — inner command assembly', () {
    test('no bridges — wraps user command with bash -c', () {
      final result = LinuxSandbox.wrapCommand(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        argv: ['ls', '-la'],
      );
      expect(result.executable, 'bwrap');
      expect(result.argv.last, 'ls -la');
      expect(result.argv[result.argv.length - 2], '-c');
      expect(result.argv[result.argv.length - 3], '/bin/bash');
      expect(result.argv[result.argv.length - 4], '--');
    });

    test('with bridges — prepends socat listeners', () {
      final result = LinuxSandbox.wrapCommand(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        argv: ['ls', '-la'],
        bridges: const [
          LinuxSocketBridge(
            hostSocketPath: '/tmp/http.sock',
            sandboxSocketPath: '/tmp/http.sock',
            sandboxLoopbackPort: 3128,
          ),
        ],
      );
      expect(result.argv.last, contains('socat TCP-LISTEN:3128'));
      expect(result.argv.last, contains('UNIX-CONNECT:/tmp/http.sock'));
    });

    test('with bridges — multiple socat listeners ordered', () {
      final result = LinuxSandbox.wrapCommand(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        argv: ['ls', '-la'],
        bridges: const [
          LinuxSocketBridge(
            hostSocketPath: '/tmp/http.sock',
            sandboxSocketPath: '/tmp/http.sock',
            sandboxLoopbackPort: 3128,
          ),
          LinuxSocketBridge(
            hostSocketPath: '/tmp/socks.sock',
            sandboxSocketPath: '/tmp/socks.sock',
            sandboxLoopbackPort: 1080,
          ),
        ],
      );
      final inner = result.argv.last;
      expect(inner, contains('socat TCP-LISTEN:3128'));
      expect(inner, contains('socat TCP-LISTEN:1080'));
      expect(inner, contains('UNIX-CONNECT:/tmp/http.sock'));
      expect(inner, contains('UNIX-CONNECT:/tmp/socks.sock'));
    });

    test('custom bwrapPath', () {
      final result = LinuxSandbox.wrapCommand(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        argv: ['echo', 'hi'],
        bwrapPath: '/usr/local/bin/bwrap',
      );
      expect(result.executable, '/usr/local/bin/bwrap');
    });

    test('custom binShell', () {
      final result = LinuxSandbox.wrapCommand(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        argv: ['echo', 'hi'],
        binShell: '/bin/zsh',
      );
      expect(result.argv[result.argv.length - 3], '/bin/zsh');
    });

    test('workingDirectory propagates to buildBwrapArgs', () {
      final result = LinuxSandbox.wrapCommand(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        argv: ['echo', 'hi'],
        workingDirectory: '/home/user/proj',
      );
      expect(result.argv, containsAll(['--chdir', '/home/user/proj']));
    });
  });

  group('wrapCommand — shell quoting in inner command', () {
    test('quotes args with spaces', () {
      final result = LinuxSandbox.wrapCommand(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        argv: ['echo', 'hello world'],
      );
      expect(result.argv.last, contains("'hello world'"));
    });

    test('simple args without special chars remain unquoted', () {
      final result = LinuxSandbox.wrapCommand(
        config: const SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        ),
        argv: ['ls', '-la'],
      );
      expect(result.argv.last, 'ls -la');
    });
  });
}
