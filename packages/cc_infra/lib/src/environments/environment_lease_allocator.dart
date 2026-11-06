import 'dart:convert';

import 'package:cc_domain/features/environments/domain/entities/environment_lease.dart';
import 'package:cc_domain/features/environments/domain/repositories/environment_repositories.dart';
import 'package:cc_infra/src/environments/environment_probes.dart';
import 'package:pool/pool.dart';

/// A port or block could not be provided.
class EnvironmentLeaseException implements Exception {
  /// Creates an [EnvironmentLeaseException].
  const EnvironmentLeaseException(this.message);

  /// Client-safe explanation.
  final String message;

  @override
  String toString() => message;
}

/// Hands out blocks of host ports across every workspace on this machine.
///
/// A block is taken under one mutex and written through
/// [EnvironmentLeaseRepository.tryInsert], so two starts can't take the same
/// one. Build one allocator per host: the mutex is what makes it host-wide.
class EnvironmentLeaseAllocator {
  /// Creates an [EnvironmentLeaseAllocator] over `firstPort..lastPort`,
  /// inclusive, in blocks of [blockSize].
  EnvironmentLeaseAllocator({
    required this._repository,
    this.firstPort = 42000,
    this.lastPort = 49999,
    this.blockSize = 32,
    this._hasListener = probeLoopbackListener,
    this._now = DateTime.now,
  }) {
    if (firstPort < 1024 || lastPort > 65535 || lastPort < firstPort) {
      throw ArgumentError('Invalid port range $firstPort-$lastPort');
    }
    if (blockSize < 1 || blockSize > lastPort - firstPort + 1) {
      throw ArgumentError('Invalid block size $blockSize');
    }
  }

  /// First port of the range.
  final int firstPort;

  /// Last port of the range, inclusive.
  final int lastPort;

  /// Ports per block.
  final int blockSize;

  final EnvironmentLeaseRepository _repository;
  final EnvironmentListenerProbe _hasListener;
  final DateTime Function() _now;
  final Pool _mutex = Pool(1);
  final Map<int, int> _skipped = {};

  /// Whole blocks in the range.
  int get blockCount => (lastPort - firstPort + 1) ~/ blockSize;

  /// Blocks passed over because something listens in them, by block, with the
  /// port that answered. For the Checks screen.
  Map<int, int> get skippedBlocks => Map.unmodifiable(_skipped);

  /// The space's lease, taking the lowest free block when it has none.
  Future<EnvironmentLease> acquire({
    required String workspaceId,
    required String spaceId,
    required String definitionId,
  }) => _mutex.withResource(() async {
    final held = await _repository.forSpace(workspaceId, spaceId, definitionId);
    if (held != null) {
      return held;
    }
    for (var block = 0; block < blockCount; block++) {
      final leases = await _repository.all();
      if (_isLeased(leases, block)) {
        continue;
      }
      final busy = await _firstListener(block);
      if (busy != null) {
        _skipped[block] = busy;
        continue;
      }
      _skipped.remove(block);
      final lease = _lease(block, workspaceId, spaceId, definitionId);
      if (await _repository.tryInsert(lease)) {
        return lease;
      }
    }
    throw EnvironmentLeaseException(
      'No free port block in $firstPort-$lastPort: all $blockCount blocks are '
      'leased or have a listener',
    );
  });

  /// The space's lease in the pool [poolKey], taking [slot] or, without one,
  /// the lowest slot in `1..poolSize` that is free.
  Future<EnvironmentLease> acquirePoolSlot({
    required String workspaceId,
    required String spaceId,
    required String definitionId,
    required String poolKey,
    required int poolSize,
    int? slot,
  }) => _mutex.withResource(() async {
    if (poolSize < 1 || poolSize > _poolRegion) {
      throw EnvironmentLeaseException(
        'A pool holds 1 to $_poolRegion slots, not $poolSize',
      );
    }
    if (slot != null && (slot < 1 || slot > poolSize)) {
      throw EnvironmentLeaseException('Pool slot $slot is outside 1-$poolSize');
    }
    final held = await _repository.forSpace(workspaceId, spaceId, definitionId);
    if (held != null) {
      return held;
    }
    String? refusal;
    for (final candidate in [
      if (slot != null) slot else ...[for (var n = 1; n <= poolSize; n++) n],
    ]) {
      final leases = await _repository.all();
      final block = poolBlock(poolKey, candidate);
      if (leases.any(
        (lease) => lease.poolKey == poolKey && lease.poolSlot == candidate,
      )) {
        refusal = 'Pool slot $candidate of $poolKey is in use';
        continue;
      }
      if (_isLeased(leases, block)) {
        refusal =
            'The block of pool slot $candidate of $poolKey, ${_first(block)}, '
            'is leased to another environment';
        continue;
      }
      final busy = await _firstListener(block);
      if (busy != null) {
        _skipped[block] = busy;
        refusal =
            'Port $busy, in the block of pool slot $candidate of $poolKey, '
            'already has a listener';
        continue;
      }
      final lease = _lease(
        block,
        workspaceId,
        spaceId,
        definitionId,
        poolKey: poolKey,
        poolSlot: candidate,
      );
      if (await _repository.tryInsert(lease)) {
        return lease;
      }
      refusal = 'Pool slot $candidate of $poolKey was just taken';
    }
    throw EnvironmentLeaseException(
      refusal ?? 'Pool $poolKey has no free slot',
    );
  });

  /// The fixed block of [slot] in the pool [poolKey].
  ///
  /// Pools live in the upper half of the range, working down, and ordinary
  /// leases fill from the bottom, so the two only meet on a very full host.
  /// The offset comes from a stable hash of the key: `String.hashCode` changes
  /// between runs, and a slot's ports have to outlive the process.
  int poolBlock(String poolKey, int slot) {
    final offset = _fnv1a(poolKey) % _poolRegion;
    return blockCount - 1 - ((offset + slot - 1) % _poolRegion);
  }

  /// Releases a space's lease for a definition.
  Future<void> release({
    required String workspaceId,
    required String spaceId,
    required String definitionId,
  }) => _mutex.withResource(
    () => _repository.release(workspaceId, spaceId, definitionId),
  );

  /// Releases every lease of a space.
  Future<void> releaseSpace({
    required String workspaceId,
    required String spaceId,
  }) =>
      _mutex.withResource(() => _repository.releaseSpace(workspaceId, spaceId));

  int get _poolRegion => blockCount > 1 ? blockCount ~/ 2 : 1;

  int _first(int block) => firstPort + block * blockSize;

  EnvironmentLease _lease(
    int block,
    String workspaceId,
    String spaceId,
    String definitionId, {
    String? poolKey,
    int? poolSlot,
  }) => EnvironmentLease(
    block: block,
    firstPort: _first(block),
    size: blockSize,
    workspaceId: workspaceId,
    spaceId: spaceId,
    definitionId: definitionId,
    createdAt: _now(),
    poolKey: poolKey,
    poolSlot: poolSlot,
  );

  /// By port range rather than block index: leases outlive a change to the
  /// range setting, and an old lease's index means something else after one.
  bool _isLeased(List<EnvironmentLease> leases, int block) {
    final start = _first(block);
    return leases.any(
      (lease) =>
          start < lease.firstPort + lease.size &&
          lease.firstPort < start + blockSize,
    );
  }

  Future<int?> _firstListener(int block) async {
    final start = _first(block);
    final ports = [for (var i = 0; i < blockSize; i++) start + i];
    final answers = await Future.wait(ports.map(_hasListener));
    for (final (index, busy) in answers.indexed) {
      if (busy) {
        return ports[index];
      }
    }
    return null;
  }

  static int _fnv1a(String value) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}

/// Gives every one of [keys] a port from [lease], on top of [existing].
///
/// Existing assignments never move, whether or not the key is still wanted: a
/// branch that drops a service and brings it back gets the same port. New keys
/// are taken in sorted order, so the result doesn't depend on the order a tool
/// printed them in, and each gets the lowest free index.
///
/// Throws [EnvironmentLeaseException] when the block is full.
Map<String, int> assignEnvironmentPorts({
  required EnvironmentLease lease,
  required Iterable<String> keys,
  Map<String, int> existing = const {},
}) {
  final assigned = {...existing};
  final used = assigned.values.toSet();
  var index = 0;
  for (final key in keys.toSet().toList()..sort()) {
    if (assigned.containsKey(key)) {
      continue;
    }
    while (index < lease.size && used.contains(lease.portAt(index))) {
      index++;
    }
    if (index >= lease.size) {
      throw EnvironmentLeaseException(
        'Port block ${lease.firstPort}-${lease.firstPort + lease.size - 1} is '
        'full: all ${lease.size} ports are assigned, so "$key" has none. Use '
        'fewer published ports, or raise the block size in the server settings',
      );
    }
    final port = lease.portAt(index);
    assigned[key] = port;
    used.add(port);
  }
  return assigned;
}
