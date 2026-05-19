import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkConfig', () {
    group('isRestricted', () {
      test('returns false when allowAll is true and no allow/deny lists', () {
        const config = NetworkConfig(allowAll: true);
        expect(config.isRestricted, isFalse);
      });

      test('returns true when allowAll is false', () {
        const config = NetworkConfig(allowAll: false);
        expect(config.isRestricted, isTrue);
      });

      test('returns true when allowedDomains is non-empty', () {
        const config = NetworkConfig(
          allowAll: true,
          allowedDomains: ['example.com'],
        );
        expect(config.isRestricted, isTrue);
      });

      test('returns true when deniedDomains is non-empty', () {
        const config = NetworkConfig(
          allowAll: true,
          deniedDomains: ['bad.com'],
        );
        expect(config.isRestricted, isTrue);
      });

      test('returns true when all three conditions apply', () {
        const config = NetworkConfig(
          allowAll: false,
          allowedDomains: ['good.com'],
          deniedDomains: ['bad.com'],
        );
        expect(config.isRestricted, isTrue);
      });
    });

    group('isBlocked', () {
      test('returns false when allowAll is true', () {
        const config = NetworkConfig(allowAll: true);
        expect(config.isBlocked, isFalse);
      });

      test('returns true when allowAll is false and allowedDomains empty', () {
        const config = NetworkConfig(allowAll: false);
        expect(config.isBlocked, isTrue);
      });

      test(
          'returns false when allowAll is false but allowedDomains is non-empty',
          () {
        const config = NetworkConfig(
          allowAll: false,
          allowedDomains: ['example.com'],
        );
        expect(config.isBlocked, isFalse);
      });

      test('returns false when allowAll is true with allowedDomains', () {
        const config = NetworkConfig(
          allowAll: true,
          allowedDomains: ['example.com'],
        );
        expect(config.isBlocked, isFalse);
      });
    });

    group('defaults', () {
      test('allowAll defaults to true', () {
        const config = NetworkConfig();
        expect(config.allowAll, isTrue);
      });

      test('allowedDomains defaults to empty', () {
        const config = NetworkConfig();
        expect(config.allowedDomains, isEmpty);
      });

      test('deniedDomains defaults to empty', () {
        const config = NetworkConfig();
        expect(config.deniedDomains, isEmpty);
      });
    });
  });

  group('FilesystemConfig', () {
    test('defaults all lists to empty', () {
      const config = FilesystemConfig();
      expect(config.denyRead, isEmpty);
      expect(config.allowRead, isEmpty);
      expect(config.allowWrite, isEmpty);
      expect(config.denyWrite, isEmpty);
    });

    test('accepts lists with entries', () {
      const config = FilesystemConfig(
        denyRead: ['/etc/passwd'],
        allowRead: ['/home/agent'],
        allowWrite: ['/tmp'],
        denyWrite: ['/root'],
      );
      expect(config.denyRead, ['/etc/passwd']);
      expect(config.allowRead, ['/home/agent']);
      expect(config.allowWrite, ['/tmp']);
      expect(config.denyWrite, ['/root']);
    });
  });

  group('SandboxConfig', () {
    test('stores all fields', () {
      const network = NetworkConfig(allowAll: false);
      const filesystem = FilesystemConfig(allowWrite: ['/tmp']);

      const config = SandboxConfig(
        sessionId: 'session-1',
        network: network,
        filesystem: filesystem,
        allowAllUnixSockets: true,
        parentProxy: 'http://proxy:8080',
        skipMandatoryHomeRcDenies: true,
      );

      expect(config.sessionId, 'session-1');
      expect(config.network, network);
      expect(config.filesystem, filesystem);
      expect(config.allowAllUnixSockets, isTrue);
      expect(config.parentProxy, 'http://proxy:8080');
      expect(config.skipMandatoryHomeRcDenies, isTrue);
    });

    test('optional params default to null/false', () {
      const network = NetworkConfig();
      const filesystem = FilesystemConfig();

      const config = SandboxConfig(
        sessionId: 'session-1',
        network: network,
        filesystem: filesystem,
      );

      expect(config.allowAllUnixSockets, isFalse);
      expect(config.parentProxy, isNull);
      expect(config.skipMandatoryHomeRcDenies, isFalse);
    });
  });
}
