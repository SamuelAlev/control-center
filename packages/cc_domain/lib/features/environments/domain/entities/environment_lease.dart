/// A block of host ports held by one space.
///
/// Ports are host-wide, which is why this is the one global table: it names
/// resources every workspace on the machine shares, and stores IDs only.
class EnvironmentLease {
  /// Creates an [EnvironmentLease].
  EnvironmentLease({
    required this.block,
    required this.firstPort,
    required this.size,
    required this.workspaceId,
    required this.spaceId,
    required this.definitionId,
    required this.createdAt,
    this.poolKey,
    this.poolSlot,
  }) {
    if (block < 0 || firstPort < 1024 || size < 1) {
      throw ArgumentError('Invalid lease range');
    }
    if (workspaceId.isEmpty || spaceId.isEmpty || definitionId.isEmpty) {
      throw ArgumentError('EnvironmentLease needs ids');
    }
  }

  /// Block index in the configured range.
  final int block;

  /// First port.
  final int firstPort;

  /// Ports in the block.
  final int size;

  /// Holding workspace.
  final String workspaceId;

  /// Holding space.
  final String spaceId;

  /// The definition.
  final String definitionId;

  /// When it was taken.
  final DateTime createdAt;

  /// A name pool, when the environment uses one.
  final String? poolKey;

  /// The pool slot.
  final int? poolSlot;

  /// The port at [index].
  int portAt(int index) {
    if (index < 0 || index >= size) {
      throw RangeError.index(index, this, 'index', null, size);
    }
    return firstPort + index;
  }

  /// Every port in the block.
  List<int> get ports => [for (var i = 0; i < size; i++) firstPort + i];

  @override
  bool operator ==(Object other) =>
      other is EnvironmentLease &&
      other.block == block &&
      other.firstPort == firstPort &&
      other.size == size &&
      other.workspaceId == workspaceId &&
      other.spaceId == spaceId &&
      other.definitionId == definitionId &&
      other.poolKey == poolKey &&
      other.poolSlot == poolSlot;

  @override
  int get hashCode => Object.hash(
    block,
    firstPort,
    size,
    workspaceId,
    spaceId,
    definitionId,
    poolKey,
    poolSlot,
  );
}
