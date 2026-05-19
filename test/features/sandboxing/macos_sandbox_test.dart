import 'package:control_center/features/sandboxing/data/runtime/macos_sandbox.dart';
import 'package:control_center/features/sandboxing/data/runtime/sandbox_config.dart';
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
  });
}
