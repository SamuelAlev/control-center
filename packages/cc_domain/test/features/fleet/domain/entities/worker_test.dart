import 'package:cc_domain/features/fleet/domain/entities/worker.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_status.dart';
import 'package:test/test.dart';

/// Covers construction, the schedulable/heartbeat predicates, copyWith field
/// preservation and the equality contract for [Worker].
void main() {
  group('Worker construction', () {
    test('round-trips every field through the constructor', () {
      final createdAt = DateTime(2025, 6, 1);
      final lastHeartbeat = DateTime(2025, 6, 2);
      final drainedAt = DateTime(2025, 6, 3);
      final revokedAt = DateTime(2025, 6, 4);
      const caps = WorkerCapabilities(
        os: 'macos',
        arch: 'arm64',
        cores: 8,
        ramMb: 16384,
        hasFlutter: true,
      );

      final worker = Worker(
        id: 'w1',
        name: 'mbp',
        capabilities: caps,
        status: WorkerStatus.online,
        protocolVersion: 3,
        credentialRef: 'cred-1',
        pairedDeviceId: 'dev-1',
        registeredBy: 'u1',
        lastHeartbeatAt: lastHeartbeat,
        drainedAt: drainedAt,
        revokedAt: revokedAt,
        lastError: 'oops',
        createdAt: createdAt,
      );

      expect(worker.id, 'w1');
      expect(worker.name, 'mbp');
      expect(worker.capabilities, caps);
      expect(worker.status, WorkerStatus.online);
      expect(worker.protocolVersion, 3);
      expect(worker.credentialRef, 'cred-1');
      expect(worker.pairedDeviceId, 'dev-1');
      expect(worker.registeredBy, 'u1');
      expect(worker.lastHeartbeatAt, lastHeartbeat);
      expect(worker.drainedAt, drainedAt);
      expect(worker.revokedAt, revokedAt);
      expect(worker.lastError, 'oops');
      expect(worker.createdAt, createdAt);
    });

    test('defaults protocolVersion to 0 and leaves optionals null', () {
      final worker = Worker(
        id: 'w1',
        name: 'n',
        capabilities: const WorkerCapabilities(
          os: 'linux',
          arch: 'x64',
          cores: 1,
          ramMb: 1,
        ),
        status: WorkerStatus.offline,
        createdAt: DateTime(2025, 6, 1),
      );
      expect(worker.protocolVersion, 0);
      expect(worker.credentialRef, isNull);
      expect(worker.pairedDeviceId, isNull);
      expect(worker.registeredBy, isNull);
      expect(worker.lastHeartbeatAt, isNull);
      expect(worker.drainedAt, isNull);
      expect(worker.revokedAt, isNull);
      expect(worker.lastError, isNull);
    });
  });

  group('Worker schedulability', () {
    const caps = WorkerCapabilities(
      os: 'macos',
      arch: 'arm64',
      cores: 1,
      ramMb: 1,
    );

    test('isSchedulable is true only when online and not drained/revoked', () {
      expect(
        Worker(
          id: 'w',
          name: 'n',
          capabilities: caps,
          status: WorkerStatus.online,
          createdAt: DateTime(2025, 6, 1),
        ).isSchedulable,
        isTrue,
      );

      // status gating
      for (final status in WorkerStatus.values) {
        final schedulable = Worker(
          id: 'w',
          name: 'n',
          capabilities: caps,
          status: status,
          createdAt: DateTime(2025, 6, 1),
        ).isSchedulable;
        expect(
          schedulable,
          status == WorkerStatus.online,
          reason: '$status schedulability',
        );
      }
    });

    test('a drained online worker is not schedulable', () {
      expect(
        Worker(
          id: 'w',
          name: 'n',
          capabilities: caps,
          status: WorkerStatus.online,
          drainedAt: DateTime(2025, 6, 1),
          createdAt: DateTime(2025, 6, 1),
        ).isSchedulable,
        isFalse,
      );
    });

    test('a revoked online worker is not schedulable', () {
      expect(
        Worker(
          id: 'w',
          name: 'n',
          capabilities: caps,
          status: WorkerStatus.online,
          revokedAt: DateTime(2025, 6, 1),
          createdAt: DateTime(2025, 6, 1),
        ).isSchedulable,
        isFalse,
      );
    });

    test('capabilityKeys delegates to the capabilities value object', () {
      final worker = Worker(
        id: 'w',
        name: 'n',
        capabilities: const WorkerCapabilities(
          os: 'macos',
          arch: 'arm64',
          cores: 1,
          ramMb: 1,
          hasFlutter: true,
          extra: {'custom'},
        ),
        status: WorkerStatus.online,
        createdAt: DateTime(2025, 6, 1),
      );
      expect(
        worker.capabilityKeys,
        containsAll(<String>{'arm64', 'macos', 'flutter', 'custom'}),
      );
    });
  });

  group('Worker heartbeat', () {
    const caps = WorkerCapabilities(
      os: 'linux',
      arch: 'x64',
      cores: 1,
      ramMb: 1,
    );
    const ttl = Duration(seconds: 30);

    test('heartbeatExpired is true when there was never a heartbeat', () {
      final worker = Worker(
        id: 'w',
        name: 'n',
        capabilities: caps,
        status: WorkerStatus.online,
        createdAt: DateTime(2025, 6, 1),
      );
      expect(worker.heartbeatExpired(DateTime(2025, 6, 1), ttl), isTrue);
    });

    test('heartbeatExpired is false within the ttl', () {
      final last = DateTime(2025, 6, 1, 12);
      final worker = Worker(
        id: 'w',
        name: 'n',
        capabilities: caps,
        status: WorkerStatus.online,
        lastHeartbeatAt: last,
        createdAt: DateTime(2025, 6, 1),
      );
      // exactly ttl later is NOT expired (uses strict >).
      expect(worker.heartbeatExpired(last.add(ttl), ttl), isFalse);
      expect(
        worker.heartbeatExpired(
          last.add(ttl + const Duration(seconds: 1)),
          ttl,
        ),
        isTrue,
      );
    });
  });

  group('Worker equality', () {
    Worker make({
      String id = 'w1',
      String name = 'n',
      WorkerStatus status = WorkerStatus.online,
      String? lastError,
      DateTime? lastHeartbeatAt,
    }) => Worker(
      id: id,
      name: name,
      capabilities: const WorkerCapabilities(
        os: 'linux',
        arch: 'x64',
        cores: 1,
        ramMb: 1,
      ),
      status: status,
      lastError: lastError,
      lastHeartbeatAt: lastHeartbeatAt,
      createdAt: DateTime(2025, 6, 1),
    );

    test('equal instances match by value and hashCode', () {
      final a = make();
      final b = make();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differing fields break equality', () {
      expect(make(id: 'w1') == make(id: 'w2'), isFalse);
      expect(make(name: 'a') == make(name: 'b'), isFalse);
      expect(
        make(status: WorkerStatus.online) == make(status: WorkerStatus.offline),
        isFalse,
      );
      expect(make(lastError: 'x') == make(lastError: 'y'), isFalse);
      expect(
        make(lastHeartbeatAt: DateTime(2025, 6, 1)) ==
            make(lastHeartbeatAt: DateTime(2025, 6, 2)),
        isFalse,
      );
    });

    test('a non-Worker is never equal', () {
      expect(make() == Object(), isFalse);
    });
  });

  group('Worker.copyWith', () {
    final base = Worker(
      id: 'w1',
      name: 'mbp',
      capabilities: const WorkerCapabilities(
        os: 'macos',
        arch: 'arm64',
        cores: 8,
        ramMb: 16384,
        hasFlutter: true,
      ),
      status: WorkerStatus.online,
      protocolVersion: 3,
      credentialRef: 'cred-1',
      pairedDeviceId: 'dev-1',
      registeredBy: 'u1',
      lastHeartbeatAt: DateTime(2025, 6, 2),
      drainedAt: DateTime(2025, 6, 3),
      revokedAt: DateTime(2025, 6, 4),
      lastError: 'oops',
      createdAt: DateTime(2025, 6, 1),
    );

    test('a single-field copyWith preserves every other field', () {
      final next = base.copyWith(status: WorkerStatus.draining);

      expect(next.status, WorkerStatus.draining);
      // id and createdAt are not copyWith-able — they must be untouched.
      expect(next.id, 'w1');
      expect(next.createdAt, DateTime(2025, 6, 1));
      // every copyWith-able field is preserved.
      expect(next.name, 'mbp');
      expect(next.capabilities, base.capabilities);
      expect(next.protocolVersion, 3);
      expect(next.credentialRef, 'cred-1');
      expect(next.pairedDeviceId, 'dev-1');
      expect(next.registeredBy, 'u1');
      expect(next.lastHeartbeatAt, DateTime(2025, 6, 2));
      expect(next.drainedAt, DateTime(2025, 6, 3));
      expect(next.revokedAt, DateTime(2025, 6, 4));
      expect(next.lastError, 'oops');
    });

    test('a no-op copyWith is equal to the original', () {
      expect(base.copyWith(), base);
    });

    test('copyWith cannot change the identity fields', () {
      // id and createdAt have no copyWith param — a no-op copy must preserve them
      // exactly. This guards against a future refactor accidentally dropping
      // them from the constructor call inside copyWith.
      final next = base.copyWith(name: 'renamed');
      expect(next.id, base.id);
      expect(next.createdAt, base.createdAt);
      expect(next.name, 'renamed');
    });
  });
}
