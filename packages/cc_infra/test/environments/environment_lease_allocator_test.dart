import 'dart:io';

import 'package:cc_domain/features/environments/domain/entities/environment_lease.dart';
import 'package:cc_infra/src/environments/environment_lease_allocator.dart';
import 'package:cc_infra/src/environments/environment_probes.dart';
import 'package:test/test.dart';

import 'helpers/environment_fakes.dart';

void main() {
  late InMemoryLeases repository;
  late Set<int> busy;

  EnvironmentLeaseAllocator allocator({
    int firstPort = 42000,
    int lastPort = 49999,
    int blockSize = 32,
  }) => EnvironmentLeaseAllocator(
    repository: repository,
    firstPort: firstPort,
    lastPort: lastPort,
    blockSize: blockSize,
    hasListener: (port) async => busy.contains(port),
  );

  setUp(() {
    repository = InMemoryLeases();
    busy = {};
  });

  Future<EnvironmentLease> take(
    EnvironmentLeaseAllocator allocator,
    String space,
  ) =>
      allocator.acquire(workspaceId: 'ws', spaceId: space, definitionId: 'def');

  test('defaults to 250 blocks of 32 from 42000', () async {
    final subject = allocator();
    expect(subject.blockCount, 250);
    final lease = await take(subject, 'a');
    expect(lease.block, 0);
    expect(lease.firstPort, 42000);
    expect(lease.size, 32);
  });

  test('takes the lowest free block, and reuses a released one', () async {
    final subject = allocator();
    final a = await take(subject, 'a');
    final b = await take(subject, 'b');
    expect((a.block, b.block), (0, 1));
    await subject.release(workspaceId: 'ws', spaceId: 'a', definitionId: 'def');
    expect((await take(subject, 'c')).block, 0);
  });

  test('a space keeps its lease', () async {
    final subject = allocator();
    final first = await take(subject, 'a');
    expect(await take(subject, 'a'), first);
    expect(repository.leases, hasLength(1));
  });

  test('parallel starts get different blocks', () async {
    final subject = allocator();
    final leases = await Future.wait([
      for (var i = 0; i < 20; i++) take(subject, 'space-$i'),
    ]);
    expect(leases.map((lease) => lease.block).toSet(), hasLength(20));
  });

  test('skips a block with any listener, and reports it', () async {
    busy = {42031, 42040};
    final subject = allocator();
    expect((await take(subject, 'a')).block, 2);
    expect(subject.skippedBlocks, {0: 42031, 1: 42040});
  });

  test('a clear error when nothing is free', () async {
    final subject = allocator(firstPort: 42000, lastPort: 42063);
    await take(subject, 'a');
    await take(subject, 'b');
    await expectLater(
      take(subject, 'c'),
      throwsA(
        isA<EnvironmentLeaseException>().having(
          (e) => e.message,
          'message',
          contains('No free port block in 42000-42063'),
        ),
      ),
    );
  });

  test('a lease from an older range still blocks its ports', () async {
    repository.leases.add(
      EnvironmentLease(
        block: 99,
        firstPort: 42016,
        size: 32,
        workspaceId: 'ws',
        spaceId: 'old',
        definitionId: 'def',
        createdAt: DateTime(2026),
      ),
    );
    final lease = await take(allocator(), 'a');
    expect(lease.firstPort, 42064);
  });

  test('releaseSpace drops every lease of a space', () async {
    final subject = allocator();
    await subject.acquire(workspaceId: 'ws', spaceId: 'a', definitionId: 'x');
    await subject.acquire(workspaceId: 'ws', spaceId: 'a', definitionId: 'y');
    await subject.releaseSpace(workspaceId: 'ws', spaceId: 'a');
    expect(repository.leases, isEmpty);
  });

  group('pool', () {
    Future<EnvironmentLease> slot(
      EnvironmentLeaseAllocator subject,
      String space, {
      int? n,
      String key = 'shop',
    }) => subject.acquirePoolSlot(
      workspaceId: 'ws',
      spaceId: space,
      definitionId: 'def',
      poolKey: key,
      poolSize: 3,
      slot: n,
    );

    test('a slot always maps to the same block', () async {
      final subject = allocator();
      final first = await slot(subject, 'a', n: 2);
      await subject.release(
        workspaceId: 'ws',
        spaceId: 'a',
        definitionId: 'def',
      );
      await take(subject, 'noise');
      final again = await slot(subject, 'b', n: 2);
      expect(again.firstPort, first.firstPort);
      expect(again.poolSlot, 2);
      expect(again.poolKey, 'shop');
      expect(
        allocator().poolBlock('shop', 2),
        first.block,
        reason: 'stable across instances, so across restarts',
      );
    });

    test('takes the lowest free slot', () async {
      final subject = allocator();
      expect((await slot(subject, 'a')).poolSlot, 1);
      expect((await slot(subject, 'b')).poolSlot, 2);
    });

    test('stays clear of where ordinary leases start', () async {
      final subject = allocator();
      for (var n = 1; n <= 8; n++) {
        expect(subject.poolBlock('shop', n), greaterThan(124));
      }
    });

    test('refuses a taken slot, and a pool that is full', () async {
      final subject = allocator();
      await slot(subject, 'a', n: 1);
      await expectLater(
        slot(subject, 'b', n: 1),
        throwsA(isA<EnvironmentLeaseException>()),
      );
      await slot(subject, 'b');
      await slot(subject, 'c');
      await expectLater(
        slot(subject, 'd'),
        throwsA(isA<EnvironmentLeaseException>()),
      );
    });

    test('a listener in a fixed block is an error, not a move', () async {
      final subject = allocator();
      final port = subject.firstPort + subject.poolBlock('shop', 1) * 32 + 4;
      busy = {port};
      await expectLater(
        slot(subject, 'a', n: 1),
        throwsA(
          isA<EnvironmentLeaseException>().having(
            (e) => e.message,
            'message',
            contains('$port'),
          ),
        ),
      );
    });

    test('rejects a slot outside the pool', () async {
      await expectLater(
        slot(allocator(), 'a', n: 4),
        throwsA(isA<EnvironmentLeaseException>()),
      );
    });
  });

  group('assignEnvironmentPorts', () {
    final lease = EnvironmentLease(
      block: 0,
      firstPort: 42000,
      size: 4,
      workspaceId: 'ws',
      spaceId: 's',
      definitionId: 'd',
      createdAt: DateTime(2026),
    );

    test('does not depend on the order keys arrive in', () {
      expect(
        assignEnvironmentPorts(lease: lease, keys: ['web', 'db.5432', 'api']),
        assignEnvironmentPorts(lease: lease, keys: ['api', 'web', 'db.5432']),
      );
    });

    test('existing assignments never move, new keys fill the gaps', () {
      final ports = assignEnvironmentPorts(
        lease: lease,
        keys: ['aaa', 'web'],
        existing: const {'web': 42001, 'gone.80': 42002},
      );
      expect(ports, {'web': 42001, 'gone.80': 42002, 'aaa': 42000});
    });

    test('a duplicate key gets one port', () {
      expect(assignEnvironmentPorts(lease: lease, keys: ['web', 'web']), {
        'web': 42000,
      });
    });

    test('a full block names the key that did not fit', () {
      expect(
        () => assignEnvironmentPorts(
          lease: lease,
          keys: ['a', 'b', 'c', 'd', 'e'],
        ),
        throwsA(
          isA<EnvironmentLeaseException>().having(
            (e) => e.message,
            'message',
            allOf(contains('"e"'), contains('42000-42003')),
          ),
        ),
      );
    });
  });

  group('probeLoopbackListener', () {
    test('sees listeners on 127.0.0.1, on ::1 and on the wildcard', () async {
      final v4 = await ServerSocket.bind('127.0.0.1', 0);
      addTearDown(v4.close);
      expect(await probeLoopbackListener(v4.port), isTrue);

      final v6 = await ServerSocket.bind('::1', 0);
      addTearDown(v6.close);
      expect(await probeLoopbackListener(v6.port), isTrue);

      final any = await ServerSocket.bind('0.0.0.0', 0);
      addTearDown(any.close);
      expect(await probeLoopbackListener(any.port), isTrue);
    });

    test('a closed port is free', () async {
      final socket = await ServerSocket.bind('127.0.0.1', 0);
      final port = socket.port;
      await socket.close();
      expect(await probeLoopbackListener(port), isFalse);
    });
  });
}
