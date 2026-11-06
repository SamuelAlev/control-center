import 'package:cc_domain/features/rigs/domain/value_objects/rig_image_settings.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:test/test.dart';

void main() {
  RigSpec spec({int ttlHours = 24}) => RigSpec.environment(
    conversationId: 'space-1',
    environmentId: 'env-1',
    worktreePath: '/work/acme',
    egressAllowlist: const ['docker.io'],
    ttlHours: ttlHours,
  );

  group('RigSpec.environment', () {
    test('is its own surface, never an exec machine', () {
      expect(spec().surface, RigSurface.environment);
      expect(spec().isEnvironment, isTrue);
      expect(spec().isExec, isFalse);
      expect(RigSpec.exec(conversationId: 'c').isEnvironment, isFalse);
    });

    test('must carry bridged container traffic', () {
      expect(spec().netBackend, RigNetBackend.virtioNet);
    });

    test('has room for images and a real memory figure for the budget', () {
      expect(spec().storageGb, 16);
      expect(spec().memoryMb, 4096);
      expect(spec().cpuCount, 4);
    });

    test('lives by policy, not by the two-hour default', () {
      expect(spec(ttlHours: 48).ttl, const Duration(hours: 48));
    });

    test('idleness cannot end it before its TTL', () {
      final machine = spec(ttlHours: 6);
      expect(machine.idleTimeout, greaterThanOrEqualTo(machine.ttl));
    });

    test('takes the environment as its slot', () {
      expect(spec().slotId, 'env-1');
    });

    test('round-trips through JSON and compares equal', () {
      final restored = RigSpec.fromJson(spec().toJson());
      expect(restored, spec());
      expect(restored.hashCode, spec().hashCode);
      expect(restored.netBackend, RigNetBackend.virtioNet);
      expect(restored.storageGb, 16);
      expect(restored.isEnvironment, isTrue);
    });

    test('a different net backend or disk is a different spec', () {
      expect(spec().copyWith(storageGb: 8), isNot(spec()));
      expect(spec().copyWith(netBackend: RigNetBackend.tsi), isNot(spec()));
    });

    test('a spec from before these fields reads back with neither', () {
      final old = RigSpec.fromJson(const {'surface': 'computer'});
      expect(old.netBackend, isNull);
      expect(old.storageGb, isNull);
    });

    test('refuses a disk with no size', () {
      expect(
        () => RigSpec(surface: RigSurface.environment, storageGb: 0),
        throwsArgumentError,
      );
    });
  });

  test('the surface has no resizable display', () {
    expect(RigSurface.fromWire('environment'), RigSurface.environment);
    expect(RigSurface.environment.hasResizableDisplay, isFalse);
  });

  group('environmentRigEgressHosts', () {
    test('admits each public registry with its blob hosts, once', () {
      expect(
        environmentRigEgressHosts([
          'nginx:1.27-alpine',
          'redis:7-alpine',
          'ghcr.io/acme/shop:1',
        ]),
        unorderedEquals([
          'docker.io',
          'production.cloudflare.docker.com',
          'production.cloudfront.docker.com',
          'ghcr.io',
          'pkg-containers.githubusercontent.com',
        ]),
      );
    });

    test('reads a digest-pinned reference', () {
      expect(
        environmentRigEgressHosts(['quay.io/acme/tool@sha256:abc']),
        contains('quay.io'),
      );
    });

    test('no images means no hosts', () {
      expect(environmentRigEgressHosts(const []), isEmpty);
    });

    for (final (image, registry) in const [
      ('registry.acme.test/shop:1', 'registry.acme.test'),
      ('registry.acme.test:5000/shop:1', 'registry.acme.test'),
      ('localhost:5000/shop', 'localhost'),
      (
        '123456789.dkr.ecr.eu-central-1.amazonaws.com/shop:1',
        '123456789.dkr.ecr.eu-central-1.amazonaws.com',
      ),
    ]) {
      test('refuses $registry by name', () {
        expect(
          () => environmentRigEgressHosts(['nginx:1', image]),
          throwsA(
            isA<RigPrivateRegistryException>()
                .having((e) => e.registry, 'registry', registry)
                .having((e) => e.image, 'image', image)
                .having(
                  (e) => e.message,
                  'message',
                  contains('no registry credentials'),
                ),
          ),
        );
      });
    }
  });

  group('registryOfImageRef', () {
    test('agrees with how the hosts are derived', () {
      expect(registryOfImageRef('ubuntu:24.04'), 'docker.io');
      expect(registryOfImageRef('acme/shop:1'), 'docker.io');
      expect(registryOfImageRef('ghcr.io/acme/shop'), 'ghcr.io');
      expect(
        registryOfImageRef('registry.acme.test:5000/x'),
        'registry.acme.test',
      );
    });
  });
}
