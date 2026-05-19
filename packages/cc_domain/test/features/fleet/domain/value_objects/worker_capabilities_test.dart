import 'dart:convert';

import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:test/test.dart';

/// Covers [WorkerCapabilities] and the [FleetCaps] key set: construction,
/// JSON round-trips (incl. the tolerant `fromJson` defaults and the empty-input
/// `fromJsonString` shortcut), the scheduler-facing `keys` derivation, and
/// value equality / hashCode.
void main() {
  group('FleetCaps', () {
    test('exposes stable string constants', () {
      expect(FleetCaps.flutter, 'flutter');
      expect(FleetCaps.ml, 'ml');
      expect(FleetCaps.linux, 'linux');
      expect(FleetCaps.macos, 'macos');
      expect(FleetCaps.windows, 'windows');
      expect(FleetCaps.arm64, 'arm64');
      expect(FleetCaps.x64, 'x64');
      expect(FleetCaps.sandbox, 'sandbox');
      expect(FleetCaps.parallel, 'parallel');
      expect(FleetCaps.alwaysOn, 'always-on');
    });

    test('all contains every well-known key with no extras', () {
      expect(FleetCaps.all, {
        FleetCaps.flutter,
        FleetCaps.ml,
        FleetCaps.linux,
        FleetCaps.macos,
        FleetCaps.windows,
        FleetCaps.arm64,
        FleetCaps.x64,
        FleetCaps.sandbox,
        FleetCaps.parallel,
        FleetCaps.alwaysOn,
      });
    });
  });

  group('WorkerCapabilities construction', () {
    test('defaults the optional flags to false and sets to empty sets', () {
      const caps = WorkerCapabilities(
        os: 'linux',
        arch: 'arm64',
        cores: 4,
        ramMb: 1024,
      );
      expect(caps.os, 'linux');
      expect(caps.arch, 'arm64');
      expect(caps.cores, 4);
      expect(caps.ramMb, 1024);
      expect(caps.hasFlutter, isFalse);
      expect(caps.hasMl, isFalse);
      expect(caps.alwaysOn, isFalse);
      expect(caps.acceptsParallel, isFalse);
      expect(caps.sandboxBackends, isEmpty);
      expect(caps.extra, isEmpty);
    });

    test('round-trips every field', () {
      const caps = WorkerCapabilities(
        os: 'macos',
        arch: 'x64',
        cores: 8,
        ramMb: 32768,
        hasFlutter: true,
        hasMl: true,
        alwaysOn: true,
        acceptsParallel: true,
        sandboxBackends: {'native-macos', 'docker'},
        extra: {'gpu-a100'},
      );
      expect(caps.os, 'macos');
      expect(caps.arch, 'x64');
      expect(caps.cores, 8);
      expect(caps.ramMb, 32768);
      expect(caps.hasFlutter, isTrue);
      expect(caps.hasMl, isTrue);
      expect(caps.alwaysOn, isTrue);
      expect(caps.acceptsParallel, isTrue);
      expect(caps.sandboxBackends, {'native-macos', 'docker'});
      expect(caps.extra, {'gpu-a100'});
    });
  });

  group('WorkerCapabilities.keys', () {
    test('always includes the arch and maps known OSes to FleetCaps', () {
      expect(
        const WorkerCapabilities(
          os: 'macos',
          arch: 'arm64',
          cores: 1,
          ramMb: 0,
        ).keys,
        {FleetCaps.macos, FleetCaps.arm64},
      );
      expect(
        const WorkerCapabilities(
          os: 'linux',
          arch: 'x64',
          cores: 1,
          ramMb: 0,
        ).keys,
        {FleetCaps.linux, FleetCaps.x64},
      );
      expect(
        const WorkerCapabilities(
          os: 'windows',
          arch: 'arm64',
          cores: 1,
          ramMb: 0,
        ).keys,
        {FleetCaps.windows, FleetCaps.arm64},
      );
    });

    test('does not add an OS key for an unknown OS', () {
      expect(
        const WorkerCapabilities(
          os: 'freebsd',
          arch: 'arm64',
          cores: 1,
          ramMb: 0,
        ).keys,
        {FleetCaps.arm64},
      );
    });

    test('advertising a capability adds the matching key', () {
      final keys = const WorkerCapabilities(
        os: 'macos',
        arch: 'arm64',
        cores: 1,
        ramMb: 0,
        hasFlutter: true,
        hasMl: true,
        alwaysOn: true,
        acceptsParallel: true,
        sandboxBackends: {'native-macos'},
        extra: {'custom-tag'},
      ).keys;
      expect(keys, contains(FleetCaps.flutter));
      expect(keys, contains(FleetCaps.ml));
      expect(keys, contains(FleetCaps.alwaysOn));
      expect(keys, contains(FleetCaps.parallel));
      expect(keys, contains(FleetCaps.sandbox));
      expect(keys, contains('custom-tag'));
    });

    test('empty sandbox backends do not advertise the sandbox key', () {
      final keys = const WorkerCapabilities(
        os: 'linux',
        arch: 'x64',
        cores: 1,
        ramMb: 0,
      ).keys;
      expect(keys.contains(FleetCaps.sandbox), isFalse);
    });
  });

  group('WorkerCapabilities JSON', () {
    test('toJson serialises sorted sets and all flags', () {
      const caps = WorkerCapabilities(
        os: 'macos',
        arch: 'arm64',
        cores: 8,
        ramMb: 4096,
        hasFlutter: true,
        hasMl: false,
        alwaysOn: true,
        acceptsParallel: false,
        sandboxBackends: {'native-macos', 'native-linux'},
        extra: {'b', 'a'},
      );
      final json = caps.toJson();
      expect(json['os'], 'macos');
      expect(json['arch'], 'arm64');
      expect(json['cores'], 8);
      expect(json['ramMb'], 4096);
      expect(json['hasFlutter'], isTrue);
      expect(json['hasMl'], isFalse);
      expect(json['alwaysOn'], isTrue);
      expect(json['acceptsParallel'], isFalse);
      // Sets serialised as sorted lists.
      expect(json['sandboxBackends'], ['native-linux', 'native-macos']);
      expect(json['extra'], ['a', 'b']);
    });

    test('toJsonString round-trips through fromJson', () {
      const caps = WorkerCapabilities(
        os: 'linux',
        arch: 'x64',
        cores: 16,
        ramMb: 8192,
        hasFlutter: true,
        acceptsParallel: true,
        sandboxBackends: {'native-linux'},
        extra: {'k'},
      );
      final decoded = WorkerCapabilities.fromJson(
        jsonDecode(caps.toJsonString()) as Map<String, dynamic>,
      );
      expect(decoded, caps);
    });

    test('fromJson tolerates missing fields with unknown/1/0 defaults', () {
      final caps = WorkerCapabilities.fromJson(const {});
      expect(caps.os, 'unknown');
      expect(caps.arch, 'unknown');
      expect(caps.cores, 1);
      expect(caps.ramMb, 0);
      expect(caps.hasFlutter, isFalse);
      expect(caps.hasMl, isFalse);
      expect(caps.alwaysOn, isFalse);
      expect(caps.acceptsParallel, isFalse);
      expect(caps.sandboxBackends, isEmpty);
      expect(caps.extra, isEmpty);
    });

    test('fromJson tolerates null-typed list fields', () {
      final caps = WorkerCapabilities.fromJson(const {
        'os': 'macos',
        'arch': 'arm64',
        'sandboxBackends': null,
        'extra': null,
      });
      expect(caps.os, 'macos');
      expect(caps.arch, 'arm64');
      expect(caps.sandboxBackends, isEmpty);
      expect(caps.extra, isEmpty);
    });

    test('fromJsonString returns the unknown default on empty input', () {
      final caps = WorkerCapabilities.fromJsonString('   ');
      expect(caps.os, 'unknown');
      expect(caps.arch, 'unknown');
      expect(caps.cores, 1);
      expect(caps.ramMb, 0);
    });

    test('fromJsonString parses a populated JSON document', () {
      final caps = WorkerCapabilities.fromJsonString(
        jsonEncode(const {
          'os': 'linux',
          'arch': 'x64',
          'cores': 4,
          'ramMb': 2048,
          'hasFlutter': true,
        }),
      );
      expect(caps.os, 'linux');
      expect(caps.arch, 'x64');
      expect(caps.cores, 4);
      expect(caps.ramMb, 2048);
      expect(caps.hasFlutter, isTrue);
    });
  });

  group('WorkerCapabilities equality and hashCode', () {
    test('equal by value across every field', () {
      const a = WorkerCapabilities(
        os: 'macos',
        arch: 'arm64',
        cores: 8,
        ramMb: 4096,
        hasFlutter: true,
        hasMl: true,
        alwaysOn: true,
        acceptsParallel: true,
        sandboxBackends: {'native-macos'},
        extra: {'tag'},
      );
      const b = WorkerCapabilities(
        os: 'macos',
        arch: 'arm64',
        cores: 8,
        ramMb: 4096,
        hasFlutter: true,
        hasMl: true,
        alwaysOn: true,
        acceptsParallel: true,
        sandboxBackends: {'native-macos'},
        extra: {'tag'},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('set fields compare equal regardless of insertion order', () {
      const a = WorkerCapabilities(
        os: 'linux',
        arch: 'x64',
        cores: 1,
        ramMb: 0,
        sandboxBackends: {'a', 'b'},
      );
      const b = WorkerCapabilities(
        os: 'linux',
        arch: 'x64',
        cores: 1,
        ramMb: 0,
        sandboxBackends: {'b', 'a'},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differ when any scalar field changes', () {
      const base = WorkerCapabilities(
        os: 'linux',
        arch: 'x64',
        cores: 4,
        ramMb: 1024,
        hasFlutter: true,
        hasMl: true,
        alwaysOn: true,
        acceptsParallel: true,
      );
      expect(
        base ==
            const WorkerCapabilities(
              os: 'macos',
              arch: 'x64',
              cores: 4,
              ramMb: 1024,
            ),
        isFalse,
      );
      expect(
        base ==
            const WorkerCapabilities(
              os: 'linux',
              arch: 'arm64',
              cores: 4,
              ramMb: 1024,
            ),
        isFalse,
      );
      expect(
        base ==
            const WorkerCapabilities(
              os: 'linux',
              arch: 'x64',
              cores: 8,
              ramMb: 1024,
            ),
        isFalse,
      );
      expect(
        base ==
            const WorkerCapabilities(
              os: 'linux',
              arch: 'x64',
              cores: 4,
              ramMb: 2048,
            ),
        isFalse,
      );
      expect(
        base ==
            const WorkerCapabilities(
              os: 'linux',
              arch: 'x64',
              cores: 4,
              ramMb: 1024,
              hasFlutter: false,
            ),
        isFalse,
      );
      expect(
        base ==
            const WorkerCapabilities(
              os: 'linux',
              arch: 'x64',
              cores: 4,
              ramMb: 1024,
              hasMl: false,
            ),
        isFalse,
      );
      expect(
        base ==
            const WorkerCapabilities(
              os: 'linux',
              arch: 'x64',
              cores: 4,
              ramMb: 1024,
              alwaysOn: false,
            ),
        isFalse,
      );
      expect(
        base ==
            const WorkerCapabilities(
              os: 'linux',
              arch: 'x64',
              cores: 4,
              ramMb: 1024,
              acceptsParallel: false,
            ),
        isFalse,
      );
    });

    test('differ when set contents differ', () {
      const a = WorkerCapabilities(
        os: 'linux',
        arch: 'x64',
        cores: 1,
        ramMb: 0,
        sandboxBackends: {'a'},
      );
      const b = WorkerCapabilities(
        os: 'linux',
        arch: 'x64',
        cores: 1,
        ramMb: 0,
        sandboxBackends: {'a', 'b'},
      );
      expect(a == b, isFalse);
    });

    test('refuses non-WorkerCapabilities operands', () {
      const caps = WorkerCapabilities(
        os: 'linux',
        arch: 'x64',
        cores: 1,
        ramMb: 0,
      );
      expect(caps == Object(), isFalse);
    });
  });
}
