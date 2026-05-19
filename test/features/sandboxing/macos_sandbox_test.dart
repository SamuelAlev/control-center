import 'dart:io';

import 'package:cc_infra/src/sandboxing/macos_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateSeatbeltProfile', () {
    test('includes version + allow-default for a baseline config', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(profile, contains('(version 1)'));
      expect(profile, contains('(allow default)'));
      // No network rule when not restricted.
      expect(profile, isNot(contains('(deny network*)')));
    });

    test('emits deny file-read* for each denyRead path', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          denyRead: ['/Users/me/.ssh', '/Users/me/.aws'],
        ),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(
        profile,
        contains('(deny file-read* (subpath "/Users/me/.ssh"))'),
      );
      expect(
        profile,
        contains('(deny file-read* (subpath "/Users/me/.aws"))'),
      );
    });

    test('restricts network to proxy ports when an allowlist is set', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(
          allowAll: false,
          allowedDomains: ['github.com'],
        ),
        filesystem: FilesystemConfig(),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(
        config,
        httpProxyPort: 1234,
        socksProxyPort: 5678,
      );
      expect(profile, contains('(deny network*)'));
      expect(
        profile,
        contains('(allow network* (remote tcp "localhost:1234"))'),
      );
      expect(
        profile,
        contains('(allow network* (remote tcp "localhost:5678"))'),
      );
    });

    test('write rules go from blanket deny to per-subpath allow', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          allowWrite: ['/Users/me/work'],
        ),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      // The blanket deny must come *before* the subpath allow to take effect.
      final denyIdx = profile.indexOf('(deny file-write*)');
      final allowIdx =
          profile.indexOf('(allow file-write* (subpath "/Users/me/work"))');
      expect(denyIdx, isNonNegative);
      expect(allowIdx, isNonNegative);
      expect(denyIdx, lessThan(allowIdx));
    });

    test('emits allow file-read* for each allowRead path', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          allowRead: ['/Users/me/documents'],
        ),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(
        profile,
        contains('(allow file-read* (subpath "/Users/me/documents"))'),
      );
    });

    test('emits deny file-write* for explicit denyWrite paths', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          denyWrite: ['/etc/hosts'],
        ),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(
        profile,
        contains('(deny file-write* (literal "/etc/hosts"))'),
      );
    });

    test('denyRead paths appear before allowRead paths in output', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          denyRead: ['/Users/me/.ssh'],
          allowRead: ['/Users/me/docs'],
        ),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      final denyIdx = profile.indexOf('(deny file-read*');
      final allowIdx = profile.indexOf('(allow file-read*');
      expect(denyIdx, isNonNegative);
      expect(allowIdx, isNonNegative);
      expect(denyIdx, lessThan(allowIdx));
    });

    test('denyWrite rules come after blanket deny + before mandatory denies', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          allowWrite: ['/Users/me/work'],
          denyWrite: ['/Users/me/work/.env'],
        ),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      final blanketDenyIdx = profile.indexOf('(deny file-write*)');
      final denyEnvIdx =
          profile.indexOf('(deny file-write* (subpath "/Users/me/work/.env"))');
      expect(blanketDenyIdx, isNonNegative);
      expect(denyEnvIdx, isNonNegative);
      expect(blanketDenyIdx, lessThan(denyEnvIdx));
    });

    test('includes standby write paths when allowWrite is present', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          allowWrite: ['/Users/me/work'],
        ),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      // Standby paths that macOS processes need.
      expect(profile, contains('(allow file-write* (subpath "/private/tmp"))'));
      expect(
        profile,
        contains('(allow file-write* (subpath "/private/var/folders"))'),
      );
      expect(profile, contains('(allow file-write* (literal "/dev/null"))'));
      expect(profile, contains('(allow file-write* (literal "/dev/stdout"))'));
      expect(profile, contains('(allow file-write* (literal "/dev/stderr"))'));
    });

    test('no write section when allowWrite and denyWrite are both empty', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(profile, isNot(contains('file-write')));
    });

    test('no network section when network is fully open', () {
      // Default NetworkConfig: allowAll=true, no domains.
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(profile, isNot(contains('(deny network*)')));
      expect(profile, isNot(contains('(allow network*)')));
    });

    test('network restricted — includes DNS + unix-socket outbound rules', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(
          allowAll: false,
          allowedDomains: ['api.example.com'],
        ),
        filesystem: FilesystemConfig(),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(profile, contains('(deny network*)'));
      expect(profile, contains('(allow network* (remote ip "localhost:*"))'));
      expect(profile, contains('(allow network* (local ip))'));
      expect(
        profile,
        contains(
          '(allow network-outbound (literal "/private/var/run/mDNSResponder"))',
        ),
      );
      expect(
        profile,
        contains('(allow network-outbound (remote unix-socket))'),
      );
      expect(
        profile,
        contains(
          '(allow network-outbound (control-name "com.apple.netsrc"))',
        ),
      );
    });

    test('network restricted without proxy ports — no TCP port rules', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(
          allowAll: false,
          allowedDomains: ['github.com'],
        ),
        filesystem: FilesystemConfig(),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      // Should not contain any TCP port-specific rules.
      expect(profile, isNot(contains('(allow network* (remote tcp ')));
    });

    test('multiple allowWrite — all appear in profile', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          allowWrite: ['/Users/me/work', '/Users/me/tmp'],
        ),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(
        profile,
        contains('(allow file-write* (subpath "/Users/me/work"))'),
      );
      expect(
        profile,
        contains('(allow file-write* (subpath "/Users/me/tmp"))'),
      );
    });

    test('generateSeatbeltProfile — denying and allowing same path', () {
      // denyRead should still emit deny even if same path appears in allowRead.
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          denyRead: ['/Users/me/shared'],
          allowRead: ['/Users/me/shared', '/Users/me/docs'],
        ),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      final denyIdx = profile.indexOf(
        '(deny file-read* (subpath "/Users/me/shared"))',
      );
      final allowIdx = profile.indexOf(
        '(allow file-read* (subpath "/Users/me/shared"))',
      );
      expect(denyIdx, isNonNegative);
      expect(allowIdx, isNonNegative);
      // Deny comes before allow, so deny takes precedence.
      expect(denyIdx, lessThan(allowIdx));
    });

    test('escape — backslashes and quotes in paths are escaped', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          denyRead: [r'/Users/me/weird\"path'],
        ),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(
        profile,
        contains(r'(deny file-read* (subpath "/Users/me/weird\\\"path"))'),
      );
    });

    test('mandatory deny paths within allowWrite regions', () {
      // allowWrite regions trigger mandatory deny for .git/hooks, .git/config,
      // .npmrc inside those regions.
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          allowWrite: ['/Users/me/project'],
        ),
        skipMandatoryHomeRcDenies: true,
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(
        profile,
        contains(
          '(deny file-write* (subpath "/Users/me/project/.git/hooks"))',
        ),
      );
      expect(
        profile,
        contains(
          '(deny file-write* (subpath "/Users/me/project/.git/config"))',
        ),
      );
      expect(
        profile,
        contains(
          '(deny file-write* (subpath "/Users/me/project/.npmrc"))',
        ),
      );
    });
  });

  group('wrapCommand', () {
    test('builds sandbox-exec argv with profile file', () {
      final tempDir = Directory.systemTemp.createTempSync('sb-test-');
      try {
        final result = MacosSandbox.wrapCommand(
          config: const SandboxConfig(
            sessionId: 's1',
            network: NetworkConfig(),
            filesystem: FilesystemConfig(),
          ),
          argv: ['ls', '-la'],
          profilesDir: tempDir,
        );
        expect(result.executable, '/usr/bin/sandbox-exec');
        expect(result.argv[0], '-f');
        expect(result.argv[1], result.profilePath);
        expect(result.argv[2], '/bin/bash');
        expect(result.argv[3], '-c');
        expect(result.argv[4], 'ls -la');
        // Profile file was created.
        expect(File(result.profilePath).existsSync(), isTrue);
        expect(result.profilePath, contains('sandbox-s1.sb'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('wrapCommand with workingDirectory prepends cd', () {
      final tempDir = Directory.systemTemp.createTempSync('sb-test-');
      try {
        final result = MacosSandbox.wrapCommand(
          config: const SandboxConfig(
            sessionId: 's1',
            network: NetworkConfig(),
            filesystem: FilesystemConfig(),
          ),
          argv: ['ls', '-la'],
          profilesDir: tempDir,
          workingDirectory: '/Users/me/work',
        );
        // Last arg should be: cd /Users/me/work && ls -la
        final inner = result.argv.last;
        expect(inner, contains('cd'));
        expect(inner, contains('/Users/me/work'));
        expect(inner, contains('&&'));
        expect(inner, contains('ls -la'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('custom binShell', () {
      final tempDir = Directory.systemTemp.createTempSync('sb-test-');
      try {
        final result = MacosSandbox.wrapCommand(
          config: const SandboxConfig(
            sessionId: 's1',
            network: NetworkConfig(),
            filesystem: FilesystemConfig(),
          ),
          argv: ['echo', 'hi'],
          profilesDir: tempDir,
          binShell: '/bin/zsh',
        );
        expect(result.argv[2], '/bin/zsh');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('with proxy ports adds them to profile', () {
      final tempDir = Directory.systemTemp.createTempSync('sb-test-');
      try {
        final result = MacosSandbox.wrapCommand(
          config: const SandboxConfig(
            sessionId: 's1',
            network: NetworkConfig(
              allowAll: false,
              allowedDomains: ['github.com'],
            ),
            filesystem: FilesystemConfig(),
          ),
          argv: ['curl', 'https://github.com'],
          profilesDir: tempDir,
          httpProxyPort: 8080,
          socksProxyPort: 1080,
        );
        // Profile file should contain proxy rules.
        final profile = File(result.profilePath).readAsStringSync();
        expect(profile, contains('(allow network* (remote tcp "localhost:8080"))'));
        expect(profile, contains('(allow network* (remote tcp "localhost:1080"))'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('shell quoting — args with special chars', () {
      final tempDir = Directory.systemTemp.createTempSync('sb-test-');
      try {
        final result = MacosSandbox.wrapCommand(
          config: const SandboxConfig(
            sessionId: 's1',
            network: NetworkConfig(),
            filesystem: FilesystemConfig(),
          ),
          argv: ['bash', '-c', 'echo "hello world"'],
          profilesDir: tempDir,
        );
        // The inner command in the -c arg should quote the "$" properly.
        expect(result.argv.last, contains('"hello world"'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
