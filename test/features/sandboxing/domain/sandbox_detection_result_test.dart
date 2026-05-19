import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Shared fixture values used across tests.
  const linuxPlatform = 'linux';
  const macosPlatform = 'darwin';
  const windowsPlatform = 'windows';

  const linuxNativeCaps = SandboxBackendCapabilities(
    backend: SandboxBackend.native,
    available: true,
    requiresInstall: false,
  );
  const linuxNoneCaps = SandboxBackendCapabilities(
    backend: SandboxBackend.none,
    available: true,
    requiresInstall: false,
  );
  const macosNoneCaps = SandboxBackendCapabilities(
    backend: SandboxBackend.none,
    available: true,
    requiresInstall: false,
    note: 'Sandbox-exec (Seatbelt) unavailable; falling back to no isolation.',
  );

  group('SandboxDetectionResult', () {
    group('construction', () {
      test('creates with all required fields', () {
        final caps = <SandboxBackend, SandboxBackendCapabilities>{
          SandboxBackend.native: linuxNativeCaps,
          SandboxBackend.none: linuxNoneCaps,
        };
        final result = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );

        expect(result.platform, linuxPlatform);
        expect(result.recommendation, SandboxBackend.native);
        expect(result.capabilities, caps);
      });

      test('creates with no-isolation recommendation', () {
        final caps = <SandboxBackend, SandboxBackendCapabilities>{
          SandboxBackend.none: macosNoneCaps,
        };
        final result = SandboxDetectionResult(
          platform: macosPlatform,
          recommendation: SandboxBackend.none,
          capabilities: caps,
        );

        expect(result.platform, macosPlatform);
        expect(result.recommendation, SandboxBackend.none);
        expect(result.capabilities, caps);
      });

      test('creates with empty capabilities map', () {
        const result = SandboxDetectionResult(
          platform: windowsPlatform,
          recommendation: SandboxBackend.native,
          capabilities: <SandboxBackend, SandboxBackendCapabilities>{},
        );

        expect(result.capabilities, isEmpty);
        expect(result.platform, windowsPlatform);
        expect(result.recommendation, SandboxBackend.native);
      });

      test('creates with capabilities that include requiresInstall', () {
        final caps = <SandboxBackend, SandboxBackendCapabilities>{
          SandboxBackend.native: const SandboxBackendCapabilities(
            backend: SandboxBackend.native,
            available: false,
            requiresInstall: true,
            installHint: 'apt-get install bubblewrap socat',
            note: 'Requires root for first-time setup.',
          ),
          SandboxBackend.none: linuxNoneCaps,
        };
        final result = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );

        expect(result.capabilities[SandboxBackend.native]!.requiresInstall,
            isTrue);
        expect(result.capabilities[SandboxBackend.native]!.installHint,
            'apt-get install bubblewrap socat');
        expect(result.capabilities[SandboxBackend.native]!.note,
            'Requires root for first-time setup.');
        expect(result.capabilities[SandboxBackend.native]!.available, isFalse);
      });
    });

    group('field access', () {
      test('platform returns the detected platform name', () {
        const result = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: {
            SandboxBackend.native: linuxNativeCaps,
          },
        );

        expect(result.platform, equals(linuxPlatform));
        expect(result.platform.length, greaterThan(0));
      });

      test('recommendation returns the suggested backend', () {
        const result = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: {
            SandboxBackend.native: linuxNativeCaps,
          },
        );

        expect(result.recommendation, SandboxBackend.native);
        expect(result.recommendation.label, 'Native sandbox');
      });

      test('capabilities map is directly accessible', () {
        final caps = <SandboxBackend, SandboxBackendCapabilities>{
          SandboxBackend.native: linuxNativeCaps,
          SandboxBackend.none: linuxNoneCaps,
        };
        final result = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );

        expect(result.capabilities.length, 2);
        expect(result.capabilities.containsKey(SandboxBackend.native), isTrue);
        expect(result.capabilities.containsKey(SandboxBackend.none), isTrue);
        expect(
            result.capabilities[SandboxBackend.native]!.backend,
            SandboxBackend.native);
      });

      test('all three fields are accessible together', () {
        const result = SandboxDetectionResult(
          platform: 'freebsd',
          recommendation: SandboxBackend.none,
          capabilities: {
            SandboxBackend.none: linuxNoneCaps,
          },
        );

        expect(result.platform, 'freebsd');
        expect(result.recommendation, SandboxBackend.none);
        expect(result.capabilities, isNotEmpty);
      });
    });

    group('equality', () {
      test('identical const instances are equal', () {
        const caps = <SandboxBackend, SandboxBackendCapabilities>{
          SandboxBackend.native: linuxNativeCaps,
          SandboxBackend.none: linuxNoneCaps,
        };
        const a = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );
        const b = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );

        expect(a, equals(b));
        expect(identical(a, b), isTrue);
      });

      test('non-const instances with same values are not identical', () {
        final caps = <SandboxBackend, SandboxBackendCapabilities>{
          SandboxBackend.native: linuxNativeCaps,
        };
        final a = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );
        final b = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );

        expect(identical(a, b), isFalse);
      });

      test('different platform is not equal', () {
        final caps = <SandboxBackend, SandboxBackendCapabilities>{
          SandboxBackend.native: linuxNativeCaps,
        };
        final a = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );
        final b = SandboxDetectionResult(
          platform: macosPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );

        expect(a, isNot(equals(b)));
      });

      test('different recommendation is not equal', () {
        final caps = <SandboxBackend, SandboxBackendCapabilities>{
          SandboxBackend.native: linuxNativeCaps,
          SandboxBackend.none: linuxNoneCaps,
        };
        final a = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );
        final b = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.none,
          capabilities: caps,
        );

        expect(a, isNot(equals(b)));
      });

      test('different capabilities is not equal', () {
        const a = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: {
            SandboxBackend.native: linuxNativeCaps,
          },
        );
        const b = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: {
            SandboxBackend.native: linuxNativeCaps,
            SandboxBackend.none: linuxNoneCaps,
          },
        );

        expect(a, isNot(equals(b)));
      });

      test('different all fields is not equal', () {
        const a = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: {
            SandboxBackend.native: linuxNativeCaps,
          },
        );
        const b = SandboxDetectionResult(
          platform: macosPlatform,
          recommendation: SandboxBackend.none,
          capabilities: {
            SandboxBackend.none: macosNoneCaps,
          },
        );

        expect(a, isNot(equals(b)));
      });

      test('same as self', () {
        const result = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: {
            SandboxBackend.native: linuxNativeCaps,
          },
        );

        // ignore: prefer_const_constructors
        expect(result, equals(result));
      });

      test('not equal to unrelated type', () {
        const result = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: {
            SandboxBackend.native: linuxNativeCaps,
          },
        );

        expect(result, isNot(equals(linuxPlatform)));
        expect(result, isNot(equals(null)));
      });
    });

    group('hashCode', () {
      test('identical const instances have same hashCode', () {
        const caps = <SandboxBackend, SandboxBackendCapabilities>{
          SandboxBackend.native: linuxNativeCaps,
        };
        const a = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );
        const b = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );

        expect(a.hashCode, b.hashCode);
      });

      test('same values produce same hashCode', () {
        const caps = <SandboxBackend, SandboxBackendCapabilities>{
          SandboxBackend.native: linuxNativeCaps,
          SandboxBackend.none: linuxNoneCaps,
        };
        const a = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );
        const b = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );

        expect(a.hashCode, b.hashCode);
      });

      test('different platform produces different hashCode', () {
        final caps = <SandboxBackend, SandboxBackendCapabilities>{
          SandboxBackend.native: linuxNativeCaps,
        };
        final a = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );
        final b = SandboxDetectionResult(
          platform: macosPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );

        expect(a.hashCode, isNot(b.hashCode));
      });

      test('different recommendation produces different hashCode', () {
        final caps = <SandboxBackend, SandboxBackendCapabilities>{
          SandboxBackend.native: linuxNativeCaps,
          SandboxBackend.none: linuxNoneCaps,
        };
        final a = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: caps,
        );
        final b = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.none,
          capabilities: caps,
        );

        expect(a.hashCode, isNot(b.hashCode));
      });

      test('different capabilities produces different hashCode', () {
        const a = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: {
            SandboxBackend.native: linuxNativeCaps,
          },
        );
        const b = SandboxDetectionResult(
          platform: linuxPlatform,
          recommendation: SandboxBackend.native,
          capabilities: {
            SandboxBackend.native: linuxNativeCaps,
            SandboxBackend.none: linuxNoneCaps,
          },
        );

        expect(a.hashCode, isNot(b.hashCode));
      });
    });

    group('edge cases', () {
      test('platform with special characters', () {
        const result = SandboxDetectionResult(
          platform: 'linux-gnu/x86_64',
          recommendation: SandboxBackend.native,
          capabilities: {
            SandboxBackend.native: linuxNativeCaps,
          },
        );

        expect(result.platform, 'linux-gnu/x86_64');
      });

      test('platform with empty string', () {
        const result = SandboxDetectionResult(
          platform: '',
          recommendation: SandboxBackend.none,
          capabilities: {},
        );

        expect(result.platform, isEmpty);
        expect(result.recommendation, SandboxBackend.none);
        expect(result.capabilities, isEmpty);
      });

      test('capabilities with single none backend', () {
        final caps = <SandboxBackend, SandboxBackendCapabilities>{
          SandboxBackend.none: const SandboxBackendCapabilities(
            backend: SandboxBackend.none,
            available: true,
          ),
        };
        final result = SandboxDetectionResult(
          platform: 'unknown',
          recommendation: SandboxBackend.none,
          capabilities: caps,
        );

        expect(result.capabilities.length, 1);
        expect(result.capabilities[SandboxBackend.none]!.available, isTrue);
        expect(result.capabilities.containsKey(SandboxBackend.native), isFalse);
      });
    });
  });
}
